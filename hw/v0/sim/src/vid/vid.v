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

  //----------------------------
  // processor interface
  //----------------------------

  always @(posedge clk) begin
    if (en & wr & ~(adr[14] & adr[13])) begin
      vidmem[adr] <= din;
    end
  end

endmodule
