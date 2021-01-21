//
// fpdiv.v -- floating-point divide
//


`timescale 1ns / 1ps
`default_nettype none


module fpdiv(clk, run, stall,
             x, y, z);
    input clk;
    input run;
    output stall;
    input [31:0] x;
    input [31:0] y;
    output [31:0] z;

  // fake return = 3.1415927410e-01
  assign z[31:0] = 32'h3EA0D97C;
  assign stall = 1'b0;

endmodule
