//
// icache.v -- instruction cache
//


`timescale 1ns / 1ps
`default_nettype none


module icache(clk, rst,
              addr, instr_out);
    input clk;				// system clock
    input rst;				// system reset
    input [23:0] addr;			// address of instr to fetch
    output [31:0] instr_out;		// instruction fetched

  assign instr_out[31:0] = 32'hDEADBEEF;

endmodule
