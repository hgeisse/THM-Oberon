//
// xmtbuf.v -- serial line transmitter buffer
//


`timescale 1ns / 1ps
`default_nettype none


module xmtbuf(clk, rst, bit_len,
              write, ready, empty, data_in, serial_out);
    input clk;
    input rst;
    input [15:0] bit_len;
    input write;
    output reg ready;
    output empty;
    input [7:0] data_in;
    output serial_out;

  reg [1:0] state;
  reg [7:0] data_hold;
  reg sr_load;
  wire sr_empty;

  xmt xmt_0(
    .clk(clk),
    .rst(rst),
    .bit_len(bit_len),
    .sr_load(sr_load),
    .sr_empty(sr_empty),
    .parallel_in(data_hold),
    .serial_out(serial_out)
  );

  always @(posedge clk) begin
    if (rst) begin
      state <= 2'b00;
      ready <= 1'b1;
      sr_load <= 1'b0;
    end else begin
      case (state)
        2'b00:
          begin
            if (write) begin
              state <= 2'b01;
              data_hold <= data_in;
              ready <= 1'b0;
              sr_load <= 1'b1;
            end
          end
        2'b01:
          begin
            state <= 2'b10;
            ready <= 1'b1;
            sr_load <= 1'b0;
          end
        2'b10:
          begin
            if (sr_empty & ~write) begin
              state <= 2'b00;
              ready <= 1'b1;
              sr_load <= 1'b0;
            end else
            if (sr_empty & write) begin
              state <= 2'b01;
              data_hold <= data_in;
              ready <= 1'b0;
              sr_load <= 1'b1;
            end else
            if (~sr_empty & write) begin
              state <= 2'b11;
              data_hold <= data_in;
              ready <= 1'b0;
              sr_load <= 1'b0;
            end
          end
        2'b11:
          begin
            if (sr_empty) begin
              state <= 2'b01;
              ready <= 1'b0;
              sr_load <= 1'b1;
            end
          end
      endcase
    end
  end

  assign empty = ready & sr_empty;

endmodule
