//
// icache.v -- instruction cache
//


`timescale 1ns / 1ps
`default_nettype none


//
// Geometry:
//     total capacity 16 KB (4 KW)
//     block size 32 bytes (8 words)
//     512 blocks
//     direct-mapped
//


module icache(clk, rst,
              addr, instr_out);
    input clk;				// system clock
    input rst;				// system reset
    input [23:0] addr;			// byte addr of instr to fetch
    output reg [31:0] instr_out;	// instruction fetched

  reg [31:0] cache_data[0:4095];
  //reg [9:0] cache_tag[0:511];
  //reg cache_valid[0:511];

  wire [9:0] tag;			// 24 - (9 + 3 + 2) addr bits
  wire [8:0] index;			// 512 blocks
  wire [2:0] word;			// 8 words / block

  wire [11:0] word_index;		// store data as words, avoid mux

  assign tag[9:0] = addr[23:14];
  assign index[8:0] = addr[13:5];
  assign word[2:0] = addr[4:2];

  assign word_index[11:0] = { index[8:0], word[2:0] };

  always @(posedge clk) begin
    instr_out <= cache_data[word_index];
  end

  initial begin
    $readmemh("src/cpu/icache.dat", cache_data);
  end

endmodule
