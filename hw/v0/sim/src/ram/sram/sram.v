//
// sram.v -- 1Mx16 asynchronous static RAM
//


`timescale 1ns/1ps
`default_nettype none


module sram(addr, data, ce_n, oe_n, we_n, ub_n, lb_n);
    input [19:0] addr;
    inout [15:0] data;
    input ce_n;
    input oe_n;
    input we_n;
    input ub_n;
    input lb_n;

  reg [7:0] umem[0:1048575];
  reg [7:0] lmem[0:1048575];

  always @(*) begin
    if (~ce_n & ~we_n & ~ub_n) begin
      umem[addr] = data[15:8];
    end
    if (~ce_n & ~we_n & ~lb_n) begin
      lmem[addr] = data[ 7:0];
    end
  end

  assign data[15:8] =
    ~ce_n & ~oe_n & we_n & ~ub_n ? umem[addr] : 8'hzz;
  assign data[ 7:0] =
    ~ce_n & ~oe_n & we_n & ~lb_n ? lmem[addr] : 8'hzz;

endmodule
