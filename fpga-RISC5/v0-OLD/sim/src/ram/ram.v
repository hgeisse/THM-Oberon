//
// ram.v -- controller for 1Mx16 asynchronous static RAM
//          only half of it is actually used
//          accessible as 256Kx32 or 1Mx8
//


`timescale 1ns/1ps
`default_nettype none


module ram(clk, clk_q, rst,
           adr, en, ben, wr,
           din, dout, memwait);
    // internal interface
    input clk;		// 25 MHz system clock
    input clk_q;	// 25 MHz system clock, quadrature, for SRAM write
    input rst;		// system reset
    input [19:0] adr;	// byte address
    input en;		// RAM enable
    input ben;		// byte enable
    input wr;		// write
    input [31:0] din;	// data from CPU to RAM
    output [31:0] dout;	// data from RAM to CPU
    output memwait;	// word accesses need 2 clock cycles

  wire [19:0] sram_addr;
  wire [15:0] sram_data;
  wire sram_ce_n;
  wire sram_oe_n;
  wire sram_we_n;
  wire sram_ub_n;
  wire sram_lb_n;

  reg second_cycle;
  wire adr1;
  reg [15:0] sram_hold;

  //
  // generate memory wait signal
  // every word access needs a second clock cycle
  //

  always @(posedge clk) begin
    if (rst) begin
      second_cycle <= 1'b0;
    end else begin
      if (en & ~ben & ~second_cycle) begin
        second_cycle <= 1'b1;
      end else begin
        second_cycle <= 1'b0;
      end
    end
  end

  assign memwait = en & ~ben & ~second_cycle;

  //
  // SRAM address
  // byte access: LSB of address supplied by user
  // word access: LSB of address supplied by FSM
  //

  assign adr1 = ben ? adr[1] : second_cycle;
  assign sram_addr[19:0] = { 1'b0, adr[19:2], adr1 };

  //
  // bidirectional data to/from SRAM
  // 1) be careful to avoid data bus contention
  // 2) in case of a read word, we need a buffer to
  // hold the low 16 bits read in the first cycle
  //

  assign sram_data[15:0] =
    (en & wr) ? (adr1 ? din[31:16] : din[15:0]) : 16'hzzzz;

  always @(posedge clk) begin
    if (~adr1) begin
      sram_hold[15:0] <= sram_data[15:0];
    end
  end

  //
  // data output to CPU
  //

  assign dout[31:0] =
    { sram_data[15:0], (ben ? sram_data[15:0] : sram_hold[15:0]) };

  //
  // SRAM control signals
  // the write pulse lies at the center of the wr input
  // (generated twice in case of write word)
  //

  assign sram_ce_n = ~en;
  assign sram_oe_n = ~en | wr;
  assign sram_we_n = ~(en & wr & clk_q);
  assign sram_ub_n = ben & ~adr[0];
  assign sram_lb_n = ben & adr[0];

  //
  // create an instance of the SRAM chip simulation
  //

  sram sram_1(
    .addr(sram_addr[19:0]),
    .data(sram_data[15:0]),
    .ce_n(sram_ce_n),
    .oe_n(sram_oe_n),
    .we_n(sram_we_n),
    .ub_n(sram_ub_n),
    .lb_n(sram_lb_n)
  );

endmodule
