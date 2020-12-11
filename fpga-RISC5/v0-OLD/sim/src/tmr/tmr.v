//
// tmr.v -- millisecond timer
//


`timescale 1ns/1ps
`default_nettype none


module tmr(clk, rst, dout);
    input clk;
    input rst;
    output [31:0] dout;

  wire millisec;
  reg [15:0] cnt0;
  reg [31:0] cnt1;

  assign millisec = (cnt0[15:0] == 16'd24999);

  always @(posedge clk) begin
    if (rst) begin
      cnt0[15:0] <= 16'd0;
    end else begin
      if (millisec) begin
        cnt0[15:0] <= 16'd0;
      end else begin
        cnt0[15:0] <= cnt0[15:0] + 16'd1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      cnt1[31:0] <= 32'd0;
    end else begin
      if (millisec) begin
        cnt1[31:0] <= cnt1[31:0] + 32'd1;
      end
    end
  end

  assign dout[31:0] = cnt1[31:0];

endmodule
