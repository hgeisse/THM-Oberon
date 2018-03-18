//
// risc5.v -- RISC5 toplevel description
//


`timescale 1ns/1ps
`default_nettype none


module risc5(
    input clk_in,
    input rst_in_n);

  wire clk_75;
  wire clk_25;
  wire rst;

  wire stall;
  wire [31:0] inbus;
  wire [31:0] inbus0;
  wire [23:0] adr;
  wire rd;
  wire wr;
  wire ben;
  wire [31:0] outbus;

  wire [3:0] iowadr;
  wire ioenb;

  clk_rst clk_rst_1(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_75(clk_75),
    .clk_25(clk_25),
    .rst(rst)
  );

  RISC5cpu cpu_1(
    .clk(clk_25),
    .rst(rst),
    .stallX(stall),
    .inbus(inbus[31:0]),
    .codebus(inbus0[31:0]),
    .adr(adr[23:0]),
    .rd(rd),
    .wr(wr),
    .ben(ben),
    .outbus(outbus[31:0])
  );

  ram ram_1(
    .adr(adr[23:0]),
    .ben(ben),
    .rd(rd),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(inbus0[31:0])
  );

  assign stall = 1'b0;

  assign iowadr[3:0] = adr[5:2];
  assign ioenb = (adr[23:6] == 18'h3FFFF);
  assign inbus[31:0] = ~ioenb ? inbus0[31:0] : 32'h0;

endmodule
