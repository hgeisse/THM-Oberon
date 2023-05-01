//
// tmr.v -- millisecond timer
//


`timescale 1ns / 1ps
`default_nettype none


module tmr(clk, rst, stb, we, data_in, data_out, ack, irq);
    input clk;
    input rst;
    input stb;
    input we;
    input [31:0] data_in;
    output [31:0] data_out;
    output ack;
    output irq;

  wire millisec;
  reg [15:0] cnt0;
  reg [31:0] cnt1;
  reg tick;
  reg expired;
  reg ien;

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
      tick <= 1'b0;
    end else begin
      if (millisec) begin
        cnt1[31:0] <= cnt1[31:0] + 32'd1;
        tick <= 1'b1;
      end else begin
        tick <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      expired <= 1'b0;
    end else begin
      if (tick) begin
        expired <= 1'b1;
      end else begin
        if (stb & ~we) begin
          expired <= 1'b0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ien <= 1'b0;
    end else begin
      if (stb & we) begin
        ien <= data_in[0];
      end
    end
  end

  assign data_out[31:0] = cnt1[31:0];

  assign ack = stb;

  assign irq = expired & ien;

endmodule
