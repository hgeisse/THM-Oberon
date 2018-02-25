//
// risc5top.v -- RISC5 toplevel description
//


`timescale 1ns/1ps
`default_nettype none


module risc5top(
    input clk_in,
    input rst_in_n);

  wire clk;
  reg  rst_n;
  wire stall;
  wire [31:0] inbus;
  wire [31:0] inbus0;
  wire [23:0] adr;
  wire rd;
  wire wr;
  wire ben;
  wire [31:0] outbus;

  wire [17:0] ram_adr;
  wire ram_ce0_n;
  wire ram_ce1_n;
  wire ram_be0_n;
  wire ram_be1_n;
  wire ram_we_n;
  wire ram_oe_n;
  wire [3:0] ram_be_n;
  wire [31:0] ram_dat;

  wire ioen;
  wire [3:0] iowa;

  assign clk = clk_in;

  always @(posedge clk) begin
    rst_n <= rst_in_n;
  end

  assign stall = 1'b0;

  RISC5 cpu(
    .clk(clk),
    .rst(rst_n),
    .stallX(stall),
    .inbus(inbus[31:0]),
    .codebus(inbus0[31:0]),
    .adr(adr[23:0]),
    .rd(rd),
    .wr(wr),
    .ben(ben),
    .outbus(outbus[31:0])
  );

  assign ram_adr[17:0] = adr[19:2];
  assign ram_ce0_n = ben & adr[1];
  assign ram_ce1_n = ben & ~adr[1];
  assign ram_be0_n = ben & adr[0];
  assign ram_be1_n = ben & ~adr[0];
  assign ram_we_n = ~wr;
  assign ram_oe_n = wr;
  assign ram_be_n[3:0] =
    { ram_be1_n, ram_be0_n, ram_be1_n, ram_be0_n };

  assign inbus0[31:0] = ram_dat[31:0];
  assign ram_dat[31:0] = wr ? outbus[31:0] : 32'hzzzzzzzz;

  ram ic11(
    .clk(clk),
    .ce_n(ram_ce1_n),
    .oe_n(ram_oe_n),
    .we_n(ram_we_n),
    .ub_n(ram_be_n[3]),
    .lb_n(ram_be_n[2]),
    .addr(ram_adr[17:0]),
    .data(ram_dat[31:16])
  );

  ram ic10(
    .clk(clk),
    .ce_n(ram_ce0_n),
    .oe_n(ram_oe_n),
    .we_n(ram_we_n),
    .ub_n(ram_be_n[1]),
    .lb_n(ram_be_n[0]),
    .addr(ram_adr[17:0]),
    .data(ram_dat[15:0])
  );

  assign ioen = (adr[23:6] == 18'h3FFFF);
  assign iowa[3:0] = adr[5:2];
  assign inbus = ~ioen ? inbus0 : 32'h00000000;

endmodule
