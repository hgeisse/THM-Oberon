//
// vid.v -- video controller for 1024x768 B/W screen
//


`timescale 1ns / 1ps
`default_nettype none


module vid(pclk, clk, rst,
           stb, we, addr, data_in);
    // internal interface
    input pclk;
    input clk;
    input rst;
    input stb;
    input we;
    input [14:0] addr;
    input [31:0] data_in;

  reg [31:0] video_mem[0:24575];

  //----------------------------
  // processor interface
  //----------------------------

  integer video_out;

  initial begin
    video_out = $fopen("video.out", "w");
  end

  // the vertical address runs backwards
  // i.e., compute 767 - vert. address
  // (but keep the horizontal address)

  wire [14:0] rev_addr;

  assign rev_addr[14] = ~(addr[14] ^ addr[13]);
  assign rev_addr[13] = addr[13];
  assign rev_addr[12:5] = ~addr[12:5];
  assign rev_addr[4:0] = addr[4:0];

  always @(posedge clk) begin
    if (stb & we & ~(rev_addr[14] & rev_addr[13])) begin
      video_mem[rev_addr] <= data_in;
      $fdisplay(video_out, "addr = 0x%h, data = 0x%h", rev_addr, data_in);
    end
  end

endmodule
