//
// risc5.v -- RISC5 top-level description
//


`timescale 1ns/1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n,
             vga_hsync,
             vga_vsync,
             vga_clk,
             vga_sync_n,
             vga_blank_n,
             vga_r,
             vga_g,
             vga_b,
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
    // VGA display
    output vga_hsync;
    output vga_vsync;
    output vga_clk;
    output vga_sync_n;
    output vga_blank_n;
    output [7:0] vga_r;
    output [7:0] vga_g;
    output [7:0] vga_b;
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
  wire clk_ok;				// system clocks stable
  wire pclk;				// pixel clock, 75 MHz
  wire clk;				// system clock, 25 MHz
  wire rst;				// system reset
  // cpu
  wire stall;
  wire [31:0] inbus;
  wire [31:0] inbus0;
  wire [23:0] adr;
  wire rd;
  wire wr;
  wire ben;
  wire [31:0] outbus;
  // ram
  // vid
  wire vid_en;
  wire [19:0] vid_adr;
  // i/o
  wire io_en;
  wire [3:0] io_adr;
  // bio
  wire bio_en;
  wire [31:0] bio_dout;

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_1(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
    .clk_75(pclk),
    .clk_25(clk),
    .rst(rst)
  );

  RISC5cpu cpu_1(
    .clk(clk),
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

  vid vid1(
    .pclk(pclk),
    .clk(clk),
    .rst(rst),
    .en(vid_en),
    .wr(wr),
    .adr(vid_adr[16:2]),
    .din(outbus[31:0]),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .pxclk(vga_clk),
    .sync_n(vga_sync_n),
    .blank_n(vga_blank_n),
    .r(vga_r[7:0]),
    .g(vga_g[7:0]),
    .b(vga_b[7:0])
  );

  bio bio_1(
    .clk(clk),
    .rst(rst),
    .en(bio_en),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(bio_dout[31:0]),
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
  // address decoder
  //--------------------------------------

  assign vid_en = (adr[23:20] == 4'h0) & (adr[19:0] >= 20'hE7F00);
  assign vid_adr = adr[19:0] - 20'hE7F00;

  assign io_en = (adr[23:6] == 18'h3FFFF);
  assign io_adr = adr[5:2];
  //assign tmr_en = io_en & (io_adr == 4'd0);
  assign bio_en = io_en & (io_adr == 4'd1);
  //assign _en = io_en & (io_adr == 4'd2);
  //assign _en = io_en & (io_adr == 4'd3);
  //assign _en = io_en & (io_adr == 4'd4);
  //assign _en = io_en & (io_adr == 4'd5);
  //assign _en = io_en & (io_adr == 4'd6);
  //assign _en = io_en & (io_adr == 4'd7);

  //--------------------------------------
  // data multiplexer
  //--------------------------------------

  assign inbus[31:0] = ~io_en ? inbus0[31:0] :
                       bio_en ? bio_dout[31:0] :
                       32'h0;

  assign stall = 1'b0;

endmodule
