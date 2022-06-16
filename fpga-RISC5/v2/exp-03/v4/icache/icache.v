//
// icache.v -- instruction cache
//


`timescale 1ns/1ps
`default_nettype none


//
// organization
//
// capacity             : 4K x 32 bit = 16 KB
// block size           : 8 x 32 bit = 32 byte
// number of blocks     : 512
// associativity        : 1 (direct-mapped)
// number of sets       : 512
// tag memory           : 512 x 10 bit
// flags                : v (valid)
// cached address space : 24 bits (16 MB)
//


module icache(clk, rst,
              cache_ready_out, cache_valid_in, cache_addr_in,
              cache_ready_in, cache_valid_out, cache_data_out,
              memory_stb, memory_addr, memory_dout, memory_ack);
    input clk;
    input rst;
    //----------------
    output cache_ready_out;
    input cache_valid_in;
    input [23:0] cache_addr_in;
    //----------------
    input cache_ready_in;
    output cache_valid_out;
    output [31:0] cache_data_out;
    //----------------
    output memory_stb;
    output [23:2] memory_addr;
    input [31:0] memory_dout;
    input memory_ack;

  reg valid_buf;

  wire [9:0] tag;		// 24 - (9 + 3 + 2) addr bits
  wire [8:0] index;		// 512 blocks
  wire [2:0] word;		// 8 words per block
  wire [1:0] byte;		// 4 bytes per word, ignored

  reg [9:0] tag_buf;
  reg [8:0] index_buf;
  reg [2:0] word_buf;

  wire [8:0] rd_index;
  wire [2:0] rd_word;
  wire [11:0] rd_word_index;

  wire [8:0] wr_index;
  wire [2:0] wr_word;
  wire [11:0] wr_word_index;

  reg block_valid[0:511];
  reg block_valid_out;
  reg [9:0] block_tag[0:511];
  reg [9:0] block_tag_out;
  reg [31:0] block_data[0:4095];
  reg [31:0] block_data_out;

  wire hit;

  reg [2:0] wr_word_cnt;
  reg memory_ack_buf;
  wire rd_again;

  reg [9:0] index_cnt;
  wire invalidate;

  //--------------------------------------------

  assign cache_ready_out =
    cache_ready_in & (hit | ~valid_buf) & ~invalidate;

  always @(posedge clk) begin
    if (rst) begin
      valid_buf <= 1'b0;
    end else begin
      if (cache_ready_out) begin
        valid_buf <= cache_valid_in;
      end
    end
  end

  assign cache_valid_out = valid_buf & hit;

  //--------------------------------------------

  assign tag[9:0] = cache_addr_in[23:14];
  assign index[8:0] = cache_addr_in[13:5];
  assign word[2:0] = cache_addr_in[4:2];
  assign byte[1:0] = cache_addr_in[1:0];

  always @(posedge clk) begin
    if (cache_ready_out) begin
      tag_buf[9:0] <= tag[9:0];
      index_buf[8:0] <= index[8:0];
      word_buf[2:0] <= word[2:0];
    end
  end

  assign rd_index[8:0] = rd_again ? index_buf[8:0] : index[8:0];
  assign rd_word[2:0] = rd_again ? word_buf[2:0] : word[2:0];
  assign rd_word_index[11:0] = { rd_index[8:0], rd_word[2:0] };

  assign wr_index[8:0] = invalidate ? index_cnt[8:0] : index_buf[8:0];
  assign wr_word[2:0] = wr_word_cnt[2:0];
  assign wr_word_index[11:0] = { wr_index[8:0], wr_word[2:0] };

  always @(posedge clk) begin
    if (cache_ready_out | rd_again) begin
      block_valid_out <= block_valid[rd_index];
      block_tag_out <= block_tag[rd_index];
      block_data_out <= block_data[rd_word_index];
    end
    if (memory_ack | invalidate) begin
      block_valid[wr_index] <= ~invalidate;
      block_tag[wr_index] <= tag_buf;
      block_data[wr_word_index] <= memory_dout;
    end
  end

  assign cache_data_out[31:0] = block_data_out[31:0];

  //--------------------------------------------

  assign hit = block_valid_out & (block_tag_out[9:0] == tag_buf[9:0]);

  assign memory_stb = ~hit & valid_buf & ~memory_ack_buf;
  assign memory_addr[23:2] = { tag_buf[9:0], index_buf[8:0], 3'b000 };

  always @(posedge clk) begin
    if (~memory_ack) begin
      wr_word_cnt[2:0] <= 3'b000;
    end else begin
      wr_word_cnt[2:0] <= wr_word_cnt[2:0] + 3'b001;
    end
  end

  always @(posedge clk) begin
    memory_ack_buf <= memory_ack;
  end

  assign rd_again = ~memory_ack & memory_ack_buf;

  //--------------------------------------------

  always @(posedge clk) begin
    if (rst) begin
      index_cnt[9:0] <= 10'd0;
    end else begin
      if (~index_cnt[9]) begin
        index_cnt[9:0] <= index_cnt[9:0] + 10'd1;
      end
    end
  end

  assign invalidate = ~index_cnt[9];

endmodule
