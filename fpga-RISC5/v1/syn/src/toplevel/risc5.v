//
// risc5.v -- RISC5 top-level description
//


`timescale 1ns / 1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n,
             sdram_clk,
             sdram_cke,
             sdram_cs_n,
             sdram_ras_n,
             sdram_cas_n,
             sdram_we_n,
             sdram_ba,
             sdram_a,
             sdram_dqm,
             sdram_dq,
             led_g,
             led_r,
             hex7_n,
             hex6_n,
             hex5_n,
             hex4_n,
             hex3_n,
             hex2_n,
             hex1_n,
             hex0_n,
             key3_n,
             key2_n,
             key1_n,
             sw
            );

    // clock and reset
    input clk_in;
    input rst_in_n;
    // SDRAM
    output sdram_clk;
    output sdram_cke;
    output sdram_cs_n;
    output sdram_ras_n;
    output sdram_cas_n;
    output sdram_we_n;
    output [1:0] sdram_ba;
    output [12:0] sdram_a;
    output [3:0] sdram_dqm;
    inout [31:0] sdram_dq;
    // board I/O
    output [8:0] led_g;
    output [17:0] led_r;
    output [6:0] hex7_n;
    output [6:0] hex6_n;
    output [6:0] hex5_n;
    output [6:0] hex4_n;
    output [6:0] hex3_n;
    output [6:0] hex2_n;
    output [6:0] hex1_n;
    output [6:0] hex0_n;
    input key3_n;
    input key2_n;
    input key1_n;
    input [17:0] sw;

  // clk_rst
  wire clk_ok;				// clocks stable
  wire mclk;				// memory clock, 100 MHz
  wire pclk;				// pixel clock, 75 MHz
  wire clk;				// system clock, 50 MHz
  wire rst;				// system reset
  // cpu
  wire bus_stb;				// bus strobe
  wire bus_we;				// bus write enable
  wire [23:2] bus_addr;			// bus address (word address)
  wire [31:0] bus_din;			// bus data input, for reads
  wire [31:0] bus_dout;			// bus data output, for writes
  wire bus_ack;				// bus acknowledge
  // prom
  wire prom_stb;			// prom strobe
  wire [31:0] prom_dout;		// prom data output
  wire prom_ack;			// prom acknowledge
  // ram
  wire ram_stb;				// ram strobe
  wire [26:2] ram_addr;			// ram address
  wire [31:0] ram_dout;			// ram data output
  wire ram_ack;				// ram acknowledge
  // i/o
  wire i_o_stb;				// i/o strobe
  // tmr
  wire tmr_stb;				// timer strobe
  wire [31:0] tmr_dout;			// timer data output
  wire tmr_ack;				// timer acknowledge
  // bio
  wire bio_stb;				// board i/o strobe
  wire [31:0] bio_dout;			// board i/o data output
  wire bio_ack;				// board i/o acknowledge

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_0(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
    .clk_100_ps(sdram_clk),
    .clk_100(mclk),
    .clk_75(pclk),
    .clk_50(clk),
    .rst(rst)
  );

  cpu cpu_0(
    .clk(clk),
    .rst(rst),
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_addr(bus_addr[23:2]),
    .bus_din(bus_din[31:0]),
    .bus_dout(bus_dout[31:0]),
    .bus_ack(bus_ack)
  );

  prom prom_0(
    .clk(clk),
    .rst(rst),
    .stb(prom_stb),
    .we(bus_we),
    .addr(bus_addr[10:2]),
    .data_out(prom_dout[31:0]),
    .ack(prom_ack)
  );

  assign ram_addr[26:2] = { 3'b000, bus_addr[23:2] };
  ram ram_0(
    .clk_ok(clk_ok),
    .clk2(mclk),
    .clk(clk),
    .rst(rst),
    .stb(ram_stb),
    .we(bus_we),
    .addr(ram_addr[26:2]),
    .data_in(bus_dout[31:0]),
    .data_out(ram_dout[31:0]),
    .ack(ram_ack),
    .sdram_cke(sdram_cke),
    .sdram_cs_n(sdram_cs_n),
    .sdram_ras_n(sdram_ras_n),
    .sdram_cas_n(sdram_cas_n),
    .sdram_we_n(sdram_we_n),
    .sdram_ba(sdram_ba[1:0]),
    .sdram_a(sdram_a[12:0]),
    .sdram_dqm(sdram_dqm[3:0]),
    .sdram_dq(sdram_dq[31:0])
  );

  tmr tmr_0(
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
    .data_out(tmr_dout[31:0]),
    .ack(tmr_ack)
  );

  bio bio_0(
    .clk(clk),
    .rst(rst),
    .stb(bio_stb),
    .we(bus_we),
    .data_in(bus_dout[31:0]),
    .data_out(bio_dout[31:0]),
    .ack(bio_ack),
    .led_g(led_g[8:0]),
    .led_r(led_r[17:0]),
    .hex7_n(hex7_n[6:0]),
    .hex6_n(hex6_n[6:0]),
    .hex5_n(hex5_n[6:0]),
    .hex4_n(hex4_n[6:0]),
    .hex3_n(hex3_n[6:0]),
    .hex2_n(hex2_n[6:0]),
    .hex1_n(hex1_n[6:0]),
    .hex0_n(hex0_n[6:0]),
    .key3_n(key3_n),
    .key2_n(key2_n),
    .key1_n(key1_n),
    .sw(sw[17:0])
  );

  //--------------------------------------
  // address decoder (16 MB addr space)
  //--------------------------------------

  // PROM: 2 KB @ 0xFFE000
  assign prom_stb =
    (bus_stb == 1'b1 && bus_addr[23:12] == 12'hFFE
                     && bus_addr[11] == 1'b0) ? 1'b1 : 1'b0;

  // RAM: 1 MB @ 0x000000
  assign ram_stb =
    (bus_stb == 1'b1 && bus_addr[23:20] == 4'h0) ? 1'b1 : 1'b0;

  // I/O: 64 bytes (16 words) @ 0xFFFFC0
  assign i_o_stb =
    (bus_stb == 1'b1 && bus_addr[23:8] == 16'hFFFF
                     && bus_addr[7:6] == 2'b11) ? 1'b1 : 1'b0;
  assign tmr_stb =
    (i_o_stb == 1'b1 && bus_addr[5:2] == 4'h0) ? 1'b1 : 1'b0;
  assign bio_stb =
    (i_o_stb == 1'b1 && bus_addr[5:2] == 4'h1) ? 1'b1 : 1'b0;

  //--------------------------------------
  // data and acknowledge multiplexers
  //--------------------------------------

  assign bus_din[31:0] =
    prom_stb ? prom_dout[31:0] :
    ram_stb  ? ram_dout[31:0]  :
    tmr_stb  ? tmr_dout[31:0]  :
    bio_stb  ? bio_dout[31:0]  :
    32'h00000000;

  assign bus_ack =
    prom_stb ? prom_ack :
    ram_stb  ? ram_ack  :
    tmr_stb  ? tmr_ack  :
    bio_stb  ? bio_ack  :
    1'b0;

endmodule
