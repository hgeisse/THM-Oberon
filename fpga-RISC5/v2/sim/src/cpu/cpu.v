//
// cpu.v -- the RISC5 CPU
//


`timescale 1ns / 1ps
`default_nettype none


`define START_ADDR	24'hFFE000	// PC on reset


module cpu(clk, rst);
    input clk;				// system clock
    input rst;				// system reset

  //
  // IF stage
  //

  wire [23:0] pc_next;
  reg [23:0] pc;
  wire [31:0] instr;

  assign pc_next[23:0] = rst ? `START_ADDR : pc[23:0] + 24'h4;

  always @(posedge clk) begin
    pc[23:0] <= pc_next[23:0];
  end

  icache icache_0(
    .clk(clk),
    .rst(rst),
    .addr(pc[23:0]),
    .instr_out(instr[31:0])
  );

  //
  // ID stage
  //

  //
  // EX stage
  //

  //
  // MEM stage
  //

  //
  // WB stage
  //

endmodule
