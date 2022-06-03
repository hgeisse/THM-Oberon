//
// cpu.v -- the RISC5 CPU
//


`timescale 1ns / 1ps
`default_nettype none


`define START_ADDR	24'hFFE000	// PC on reset
//`define START_ADDR	24'h000000	// PC on reset


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

  wire [3:0] rb;
  wire [3:0] rc;
  wire [31:0] data_1;
  wire [31:0] data_2;

  assign rb[3:0] = instr[23:20];
  assign rc[3:0] = instr[3:0];

  regs regs_0(
    .clk(clk),
    .rst(rst),
    .rd_reg_1(rb[3:0]),
    .rd_data_1(),
    .rd_reg_2(rc[3:0]),
    .rd_data_2(),
    .wr_reg(4'h0),
    .wr_data(32'h0),
    .wr_en(1'b0)
  );

  //
  // EX stage
  //

  wire [3:0] fnc;
  wire [31:0] op1;
  wire [31:0] op2;
  wire [31:0] res;

  assign fnc[3:0] = 4'h0;
  assign op1[31:0] = rd_data_1;
  assign op2[31:0] = rd_data_2;

  alu alu_0(
    .clk(clk),
    .rst(rst),
    .fnc(fnc[3:0]),
    .op1(op1[31:0]),
    .op2(op2[31:0]),
    .res(res[31:0])
  );

  //
  // MEM stage
  //

  //
  // WB stage
  //

endmodule
