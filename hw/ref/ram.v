//
// ram.v -- memory, 2^18 words, 16 bits per word, byte enable lines
//


`timescale 1ns/1ps
`default_nettype none


module ram(clk, ce_n,
           oe_n, we_n,
           ub_n, lb_n,
           addr, data);
    input clk;
    input ce_n;
    input oe_n;
    input we_n;
    input ub_n;
    input lb_n;
    input [17:0] addr;
    inout [15:0] data;

  reg [7:0] umem[0:262143];
  reg [7:0] lmem[0:262143];

  always @(posedge clk) begin
    if (~ce_n & ~we_n & ~ub_n) begin
      umem[addr] <= data[15:8];
    end
    if (~ce_n & ~we_n & ~lb_n) begin
      lmem[addr] <= data[ 7:0];
    end
  end

  assign data[15:8] =
    ~ce_n & ~oe_n & we_n & ~ub_n ? umem[addr] : 8'hzz;
  assign data[ 7:0] =
    ~ce_n & ~oe_n & we_n & ~lb_n ? lmem[addr] : 8'hzz;

endmodule
