//
// rcvbuf.v -- serial line receiver buffer
//


`timescale 1ns / 1ps
`default_nettype none


module rcvbuf(clk, rst, bit_len,
              read, ready, data_out, serial_in);
    input clk;
    input rst;
    input [15:0] bit_len;
    input read;
    output reg ready;
    output reg [7:0] data_out;
    input serial_in;

  wire sr_full;
  wire [7:0] parallel_out;

  rcv rcv_0(
    .clk(clk),
    .rst(rst),
    .bit_len(bit_len),
    .sr_full(sr_full),
    .parallel_out(parallel_out),
    .serial_in(serial_in)
  );

  always @(posedge clk) begin
    if (rst) begin
      ready <= 1'b0;
    end else begin
      if (sr_full) begin
        data_out <= parallel_out;
      end
      if (sr_full | read) begin
        ready <= sr_full;
      end
    end
  end

endmodule
