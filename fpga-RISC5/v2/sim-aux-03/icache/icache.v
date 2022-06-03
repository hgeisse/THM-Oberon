//
// icache.v -- instruction cache
//


`timescale 1ns/1ps
`default_nettype none


//
// organization
//
// capacity		: 4K x 32 bit = 16 KB
// block size		: 8 x 32 bit = 32 byte
// associativity	: direct-mapped
// number of blocks	: 512
// tag memory		: 512 x 10 bit
// flags		: v (valid)
// cached address space	: 16 MB
//


module icache(clk, rst,
              stall_in, addr,
              inst, stall_out,
              mem_stb, mem_addr,
              mem_dout, mem_ack);
    input clk;				// system clock
    input rst;				// system reset
    // pipeline interface
    input stall_in;
    input [23:0] addr;
    output reg [31:0] inst;
    output stall_out;
    // memory interface
    output mem_stb;
    output [23:2] mem_addr;
    input [31:0] mem_dout;
    input mem_ack;

  reg [31:0] cache_data[0:4095];
  reg [9:0] cache_tag[0:511];
  reg cache_valid[0:511];

  wire [9:0] tag;			// 24 - (9 + 3 + 2) addr bits
  wire [8:0] index;			// 512 blocks
  wire [2:0] word;			// 8 words / block
  wire [1:0] byte;			// 4 bytes / word, ignored

  wire [11:0] word_index;		// store data as words, avoid mux

  reg [9:0] tg;
  reg v;

  wire miss;

  assign tag[9:0] = addr[23:14];
  assign index[8:0] = addr[13:5];
  assign word[2:0] = addr[4:2];
  assign byte[1:0] = addr[1:0];

  assign word_index[11:0] = { index[8:0], word[2:0] };

  always @(posedge clk) begin
    inst <= cache_data[word_index];
    tg <= cache_tag[index];
    v <= cache_valid[index];
  end

  assign miss = ~v | (tg[9:0] != tag[9:0]);

  integer i;
  initial begin
    for (i = 0; i < 512; i++) begin
      cache_valid[i] = 1'b0;
    end
  end

endmodule
