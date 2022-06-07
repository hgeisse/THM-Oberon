//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg clk;			// clock, 100 MHz
  reg rst;			// reset, active high

  reg stall_in;
  reg [23:0] addr;
  wire [31:0] inst;
  wire stall_out;

  wire inst_stb;
  wire [23:2] inst_addr;
  wire [31:0] inst_dout;
  wire inst_ack;

  wire data_stb;
  wire data_we;
  wire [23:2] data_addr;
  wire [31:0] data_din;
  wire [31:0] data_dout;
  wire data_ack;

  //
  // simulation control
  //

  initial begin
    #0          $timeformat(-9, 1, " ns", 12);
                $dumpfile("dump.vcd");
                $dumpvars(0, risc5test);
                clk = 1;
                rst = 1;
    #51         rst = 0;
                stall_in = 1;
    #100	stall_in = 0;
                addr[23:0] = 24'hD46C24;
    #500	stall_in = 1;
    #30000      $finish;
  end

  //
  // clock generator
  //

  always begin
    #5 clk = ~clk;		// 10 nsec cycle time
  end

  //
  // module instantiations
  //

  icache icache_0(
    .clk(clk),
    .rst(rst),
    .stall_in(stall_in),
    .addr(addr[23:0]),
    .inst(inst[31:0]),
    .stall_out(stall_out),
    .mem_stb(inst_stb),
    .mem_addr(inst_addr[23:2]),
    .mem_dout(inst_dout[31:0]),
    .mem_ack(inst_ack)
  );

  assign data_stb = 1'b0;
  assign data_we = 1'b0;
  assign data_addr[23:2] = 22'h0;
  assign data_din[31:0] = 32'h0;

  ramctrl ramctrl_0(
    .clk(clk),
    .rst(rst),
    .inst_stb(inst_stb),
    .inst_addr(inst_addr[23:2]),
    .inst_dout(inst_dout[31:0]),
    .inst_ack(inst_ack),
    .data_stb(data_stb),
    .data_we(data_we),
    .data_addr(data_addr[23:2]),
    .data_din(data_din[31:0]),
    .data_dout(data_dout[31:0]),
    .data_ack(data_ack)
  );

endmodule
