//
// vid.v -- video controller for 1024x768 B/W screen
//


`timescale 1ns/1ps
`default_nettype none


module vid(pclk, clk, rst,
           en, wr, adr, din);
    // internal interface
    input pclk;
    input clk;
    input rst;
    input en;
    input wr;
    input [14:0] adr;
    input [31:0] din;

  reg [31:0] vidmem[0:24575];
  wire [14:0] rev_adr;

  //----------------------------
  // processor interface
  //----------------------------

  // the vertical address runs backwards
  // i.e., compute 767 - vert. address
  // (but keep the horizontal address)

  assign rev_adr[14] = ~(adr[14] ^ adr[13]);
  assign rev_adr[13] = adr[13];
  assign rev_adr[12:5] = ~adr[12:5];
  assign rev_adr[4:0] = adr[4:0];

  always @(posedge clk) begin
    if (en & wr & ~(rev_adr[14] & rev_adr[13])) begin
      vidmem[rev_adr] <= din;
    end
  end

endmodule
