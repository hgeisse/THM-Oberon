//
// cpu.v -- the RISC5 CPU core
//


`timescale 1ns / 1ps
`default_nettype none


module cpu_core(clk, rst,
                bus_stb, bus_we, bus_size, bus_addr,
                bus_din, bus_dout, bus_ack);
    input clk;				// system clock
    input rst;				// system reset
    output bus_stb;			// bus strobe
    output bus_we;			// bus write enable
    output bus_size;			// 0: byte, 1: word
    output [23:0] bus_addr;		// bus address
    input [31:0] bus_din;		// bus data input, for reads
    output [31:0] bus_dout;		// bus data output, for writes
    input bus_ack;			// bus acknowledge

  reg [23:0] pc;
  wire [23:0] pc_next;

  assign pc_next[23:0] = rst ? 24'hFFE000 : pc[23:0] + 24'h000004;

  always @(posedge clk) begin
    pc[23:0] <= pc_next[23:0];
  end

endmodule
