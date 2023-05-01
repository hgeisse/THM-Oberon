//
// prom.v -- PROM interface and PROM simulation
//           1024 x 32 bit = 4 KB
//


`timescale 1ns / 1ps
`default_nettype none


module prom(clk, rst,
            stb, we, addr,
            data_out, ack);
    input clk;
    input rst;
    input stb;
    input we;
    input [11:2] addr;
    output reg [31:0] data_out;
    output reg ack;

  reg [31:0] mem[0:1023];

  initial begin
    $readmemh("../prom.mem", mem);
  end

  always @(posedge clk) begin
    if (stb & ~we) begin
      data_out <= mem[addr];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ack <= 1'b0;
    end else begin
      if (stb & ~we) begin
        ack <= ~ack;
      end
    end
  end

endmodule
