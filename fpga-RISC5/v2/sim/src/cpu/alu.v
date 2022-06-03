//
// alu.v -- arithmetic/logic unit
//


`timescale 1ns / 1ps
`default_nettype none


module alu(clk, rst,
           fnc, op1, op2, res);
    input clk;				// system clock
    input rst;				// system reset
    input [3:0] fnc;
    input [31:0] op1;
    input [31:0] op2;
    output reg [31:0] res;

  always @(*) begin
    case (fnc[3:0])
      4'h0: res = op2;
      4'h1: res = 32'h0;
      4'h2: res = 32'h0;
      4'h3: res = 32'h0;
      4'h4: res = op1 & op2;
      4'h5: res = op1 & ~op2;
      4'h6: res = op1 | op2;
      4'h7: res = op1 ^ op2;
      4'h8: res = op1 + op2;
      4'h9: res = op1 - op2;
      4'hA: res = 32'h0;
      4'hB: res = 32'h0;
      4'hC: res = 32'h0;
      4'hD: res = 32'h0;
      4'hE: res = 32'h0;
      4'hF: res = 32'h0;
    endcase
  end

endmodule
