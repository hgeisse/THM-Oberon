//
// rcvr.v -- serial receiver
//


`timescale 1ns / 1ps
`default_nettype none


module rcvr(
    input clk,
    input rst,
    input done,
    output reg rdy,
    output reg [7:0] data);

  integer serial_in;
  integer status;
  reg [31:0] counter;
  reg [7:0] data_hold;

  initial begin
    serial_in = $fopen("serial.in", "r");
    if (serial_in != 0) begin
      status = $fscanf(serial_in, "%h", counter[31:0]);
      if (status == 1) begin
        status = $fscanf(serial_in, "%h", data_hold[7:0]);
      end
      if (status != 1) begin
        // cannot read serial.in
        counter[31:0] = 32'hFFFFFFFF;
      end
    end else begin
      // cannot open serial.in
      counter[31:0] = 32'hFFFFFFFF;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      rdy <= 1'b0;
    end else begin
      if (counter[31:0] == 32'd0) begin
        if (done) begin
          status = $fscanf(serial_in, "%h", counter[31:0]);
          if (status == 1) begin
            status = $fscanf(serial_in, "%h", data_hold[7:0]);
          end
          if (status != 1) begin
            // cannot read serial.in
            counter[31:0] = 32'hFFFFFFFF;
          end
          rdy <= 1'b0;
        end
      end else begin
        if (counter[31:0] == 32'd1) begin
          data[7:0] <= data_hold[7:0];
          rdy <= 1'b1;
        end
        // counter == 32'hFFFFFFFF means infinity
        if (counter[31:0] != 32'hFFFFFFFF) begin
          counter[31:0] <= counter[31:0] - 32'd1;
        end
      end
    end
  end

endmodule
