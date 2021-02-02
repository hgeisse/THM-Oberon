//
// tmr.v -- millisecond timer
//


`timescale 1ns / 1ps
`default_nettype none


module tmr(clk, rst, stb, data_out, ack);
    input clk;
    input rst;
    input stb;
    output [31:0] data_out;
    output ack;

  wire millisec;
  reg [15:0] cnt0;
  reg [31:0] cnt1;

  assign millisec = (cnt0[15:0] == 16'd49999);

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

  assign data_out[31:0] = cnt1[31:0];

  assign ack = stb;

endmodule
