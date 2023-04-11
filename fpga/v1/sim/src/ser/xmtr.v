//
// xmtr.v -- serial transmitter
//


`timescale 1ns / 1ps
`default_nettype none


`define TICKS_PER_CHAR		32'h0000000C	// output speed


module xmtr(
    input clk,
    input rst,
    input start,
    input [7:0] data,
    output rdy);

  integer serial_out;
  reg [31:0] counter;
  reg [7:0] data_hold;

  initial begin
    serial_out = $fopen("serial.out", "w");
  end

  always @(posedge clk) begin
    if (rst) begin
      counter[31:0] <= 32'd0;
    end else begin
      if (counter[31:0] == 32'd0) begin
        if (start) begin
          data_hold[7:0] <= data[7:0];
          counter[31:0] <= `TICKS_PER_CHAR;
        end
      end else begin
        if (counter[31:0] == 32'd1) begin
          $fdisplay(serial_out, "char = 0x%h", data_hold);
        end
        counter[31:0] <= counter[31:0] - 32'd1;
      end
    end
  end

  assign rdy = counter[31:0] == 32'd0;

endmodule
