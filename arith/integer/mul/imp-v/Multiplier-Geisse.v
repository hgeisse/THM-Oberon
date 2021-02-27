//
// Multiplier.v -- integer multiply, signed and unsigned
//


`timescale 1ns / 1ps
`default_nettype none


module Multiplier(clk, run, stall,
                  op_unsigned, x, y, z);
    input clk;
    input run;
    output stall;
    input op_unsigned;
    input [31:0] x;
    input [31:0] y;
    output [63:0] z;

  reg [5:0] counter;
  reg x_neg;
  reg y_neg;
  reg [31:0] y_abs;
  reg [63:0] q;
  wire [64:1] s;
  wire [64:1] t;

  always @(posedge clk) begin
    if (run) begin
      counter[5:0] <= counter[5:0] + 6'd1;
    end else begin
      counter[5:0] <= 6'd0;
    end
  end

  assign stall = run & (counter[5:0] != 6'd33);

  assign s[64:32] = { 1'b0, q[63:32] } + { 1'b0, y_abs };
  assign s[31: 1] = q[31:1];
  assign t[64: 1] = { 1'b0, q[63:1] };

  always @(posedge clk) begin
    if (counter[5:0] == 6'd0) begin
      // prepare operands
      if (~op_unsigned & x[31]) begin
        // negate first operand
        x_neg <= 1'b1;
        q[63:32] <= 32'b0;
        q[31: 0] <= ~x[31:0] + 32'b1;
      end else begin
        // use first operand as is
        x_neg <= 1'b0;
        q[63:32] <= 32'b0;
        q[31: 0] <= x[31:0];
      end
      if (~op_unsigned & y[31]) begin
        // negate second operand
        y_neg <= 1'b1;
        y_abs[31:0] <= ~y[31:0] + 32'b1;
      end else begin
        // use second operand as is
        y_neg <= 1'b0;
        y_abs[31:0] <= y[31:0];
      end
    end else begin
      // do a multiplication step
      if (q[0]) begin
        q[63:0] <= s[64:1];
      end else begin
        q[63:0] <= t[64:1];
      end
    end
  end

  assign z[63:0] = (x_neg == y_neg) ? q[63:0] : ~q[63:0] + 64'b1;

endmodule
