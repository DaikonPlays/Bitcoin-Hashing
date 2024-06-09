module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

enum logic [ 4:0] {IDLE, BLOCK, COMPUTE, WRITE, READ} state;
logic [31:0] hout[num_nonces];

parameter int k[64] = '{
    32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
    32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
    32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
    32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
    32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
    32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
    32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
    32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

// Student to add rest of the code here
parameter integer NUM_OF_WORDS = 20;
parameter integer  MESSAGE_SIZE = NUM_OF_WORDS * 32;
logic [31:0] w[64];
logic [31:0] message[20];
logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
logic [31:0] a, b, c, d, e, f, g, h;
logic [ 7:0] i, j;
logic [15:0] offset; // in word address
logic [ 7:0] num_blocks;
logic [ 7:0] currentBlock;
logic        cur_we;
logic [15:0] cur_addr;
logic [31:0] cur_write_data;
logic [31:0] s0, s1;
logic [31:0] nonce;
logic [31:0] og_h0, og_h1, og_h2, og_h3, og_h4, og_h5, og_h6, og_h7; 
logic [31:0] phase1h0, phase1h1, phase1h2, phase1h3, phase1h4, phase1h5, phase1h6, phase1h7;
logic [31:0] phase;

//fix this poriton
//generate
//always_ff
//sha256_ block
//for (q = 0; q < NUM_NONCES; q++) begin : generate_sha256_blocks sha256_block block (
///.clk(clk),
//.reset_n(reset_n), .state(state), .mem_read_data(mem_read_data), ...);
//    end
//endgenerate

assign num_blocks = determine_num_blocks(NUM_OF_WORDS); 

//determines the number of blocks needed 
function logic [15:0] determine_num_blocks(input logic [31:0] size);
  determine_num_blocks = ((NUM_OF_WORDS+2)/16) + 1; 
endfunction

function logic [255:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w,
                                 input logic [7:0] t);
    logic [31:0] S1, S0, ch, maj, t1, t2; // internal signals
begin
    S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
    // Student to add remaning code below
    // Refer to SHA256 discussion slides to get logic for this function
    ch = (e & f) ^ ((~e) & g);
    t1 = ch + S1 + h + k[t] + w;
    S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
    maj = (a & b) ^ (a & c) ^ (b & c);
    t2 = maj + S0;
    sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
end
endfunction

assign mem_clk = clk;
assign mem_addr = cur_addr + offset + (currentBlock-1)*16;
assign mem_we = cur_we;
assign mem_write_data = cur_write_data;

function logic [31:0] rightrotate(input logic [31:0] x,
                                  input logic [ 7:0] r);
   rightrotate = (x >> r) | (x << (32 - r));
endfunction

always_ff @(posedge clk, negedge reset_n)
begin
  if(!reset_n) begin
    cur_we <= 1'b0;
    state <= IDLE;
  end 
  else case (state)
    // Initialize h values h0 to h7 and a to h, other variables and memory we, address offset, etc
    IDLE: begin 
       if(start) begin
       // Student to add rest of the code  
        h0 <= 32'h6a09e667;
        h1 <= 32'hbb67ae85;
        h2 <= 32'h3c6ef372;
        h3 <= 32'ha54ff53a;
        h4 <= 32'h510e527f;
        h5 <= 32'h9b05688c;
        h6 <= 32'h1f83d9ab;
        h7 <= 32'h5be0cd19;
        og_h0 <= 32'h6a09e667;
        og_h1 <= 32'hbb67ae85;
        og_h2 <= 32'h3c6ef372;
        og_h3 <= 32'ha54ff53a;
        og_h4 <= 32'h510e527f;
        og_h5 <= 32'h9b05688c;
        og_h6 <= 32'h1f83d9ab;
        og_h7 <= 32'h5be0cd19;
        cur_addr <= message_addr;
        offset <= 0;
        cur_we <= 0;
        i <= 0; j <= 0;
        currentBlock <= 1; 
        cur_write_data <= 0;
        state <= READ;
        phase <= 1;
        nonce <= 0;
      end
      else begin
        state <= IDLE;
      end
    end
    
    READ: begin
      if(currentBlock < num_blocks) begin 
          if(offset == 0) offset = offset + 1;
          else if(offset < 16)begin
            message[offset - 1] <= mem_read_data;
            state <= READ;
            offset = offset + 1;
          end
          else begin
            state <= BLOCK;
            message[offset - 1] <= mem_read_data;       
          end
      end
      else begin
          if(offset == 0) offset = offset + 1;
          else if(offset <= 4) begin
            state <= READ;
            message[offset - 1] <= mem_read_data;
            offset = offset + 1;
          end
          else state <= BLOCK;
      end
    end

    BLOCK: begin
        //sets up the blocks for appropriate words
        if(phase != 3)begin
  	      {a, b, c, d, e, f, g, h} <= {h0, h1, h2, h3, h4, h5, h6, h7};
        for(j = 0; j < 16; j++) begin
          //first block
          if(phase == 1) w[j] <= message[j]; 
          //second block
          else if((phase == 2) && j < 3) w[j] <= message[j]; 
          else if((phase == 2) && j == 3) w[j] <= nonce;
          else if((j == 15) & (phase == 2)) w[15] <= MESSAGE_SIZE[31:0]; 
          else if((phase == 2) && j == 4) w[j] <= 32'h80000000;
          else w[j] <= 32'h00000000;
      end
        end
        else begin
           {w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7]} <= {h0, h1, h2, h3, h4, h5, h6, h7};
           w[8] <= 32'h80000000;    
           for(j=9; j< 15;j++) w[j] <= 32'h00000000;
           w[15] <= 32'd256;
           {a,b,c,d,e,f,g,h} <= {og_h0,og_h1,og_h2,og_h3,og_h4,og_h5,og_h6,og_h7};
           {h0,h1,h2,h3,h4,h5,h6,h7} <= {og_h0,og_h1,og_h2,og_h3,og_h4,og_h5,og_h6,og_h7};
        end       
        if(phase == 2) begin
        {h0,h1,h2,h3,h4,h5,h6,h7} <= {phase1h0, phase1h1, phase1h2, phase1h3, phase1h4, phase1h5, phase1h6, phase1h7};
        {a,b,c,d,e,f,g,h} <= {phase1h0, phase1h1, phase1h2, phase1h3, phase1h4, phase1h5, phase1h6, phase1h7};
        end
        i <= 0; j <= 0;
	    offset <= 0;
	    state <= COMPUTE;
		end

    // For each block compute h function
    // Go back to BLOCK stage after each block h computation is completed and if
    // there are still number of message blocks available in memory otherwise
    // move to WRITE stage
    COMPUTE: begin
	// 64 processing rounds steps for 512-bit block 
      if(i < 64) begin
        {a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, w[0], i);
        for(j = 0; j < 15; j++) begin
          w[j] <= w[j + 1];
        end
        s0 = rightrotate(w[1], 7) ^ rightrotate(w[1], 18) ^ (w[1] >> 3);
        s1 = rightrotate(w[14], 17) ^ rightrotate(w[14], 19) ^ (w[14] >> 10);
        w[15] = s0 + s1 + w[0] + w[9];
        i = i + 1;
        state = COMPUTE;
		end
		else begin
        h0 <= h0 + a;
        h1 <= h1 + b;
        h2 <= h2 + c;
        h3 <= h3 + d;
        h4 <= h4 + e;
        h5 <= h5 + f;
        h6 <= h6 + g;
        h7 <= h7 + h;  
        if(currentBlock == num_blocks)begin
          if(nonce < 16) begin
            if(phase == 2)begin
            state <= BLOCK;
            i <= 0; j <=0; offset <= 0;
            phase = phase + 1;
            end
            else if(phase == 3) begin
              i <= 0; j <=0; offset <= 0;
              state <= BLOCK;
              phase <= 2;
              nonce <= nonce + 1;
              hout[nonce] <= h0 + a;
            end
          end
            else if(nonce == 16) begin
              state <= WRITE;
              offset <= 0;
              cur_addr <= output_addr;
              cur_we <= 1;
              i <= 0;
          end
    end
        else if(currentBlock == 1) begin
            i <= 0; j <=0; offset <= 0;
            phase <= phase + 1;
            state <= READ;
            phase1h0 <= h0 + a;
            phase1h1 <= h1 + b;
            phase1h2 <= h2 + c;
            phase1h3 <= h3 + d;
            phase1h4 <= h4 + e;
            phase1h5 <= h5 + f;
            phase1h6 <= h6 + g;
            phase1h7 <= h7 + h; 
            currentBlock <= currentBlock + 1;
          end
    end

    end

    // h0 to h7 each are 32 bit hes, which makes up total 256 bit value
    // h0 to h7 after compute stage has final computed h value
    // write back these h0 to h7 to memory starting from output_addr
    WRITE: begin
        currentBlock <= 1;
        if(i==nunm_nonces)
        state <= IDLE;
          cur_write_data <= hout[i];
      if (i != 0) offset++;
      i = i + 1;
    end
  endcase
end

assign done = (state == IDLE);
		


endmodule
