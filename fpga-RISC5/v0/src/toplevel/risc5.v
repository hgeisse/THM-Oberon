//
// risc5.v -- RISC5 top-level description
//


`timescale 1ns/1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n,
             sram_addr,
             sram_dq,
             sram_ce_n,
             sram_oe_n,
             sram_we_n,
             sram_ub_n,
             sram_lb_n,
             vga_hsync,
             vga_vsync,
             vga_clk,
             vga_sync_n,
             vga_blank_n,
             vga_r,
             vga_g,
             vga_b,
             ps2_0_clk,
             ps2_0_data,
             ps2_1_clk,
             ps2_1_data,
             rs232_0_rxd,
             rs232_0_txd,
             sdcard_ss_n,
             sdcard_sclk,
             sdcard_mosi,
             sdcard_miso,
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
    // SRAM
    output [19:0] sram_addr;
    inout [15:0] sram_dq;
    output sram_ce_n;
    output sram_oe_n;
    output sram_we_n;
    output sram_ub_n;
    output sram_lb_n;
    // VGA display
    output vga_hsync;
    output vga_vsync;
    output vga_clk;
    output vga_sync_n;
    output vga_blank_n;
    output [7:0] vga_r;
    output [7:0] vga_g;
    output [7:0] vga_b;
    // keyboard
    input ps2_0_clk;
    input ps2_0_data;
    // mouse
    inout ps2_1_clk;
    inout ps2_1_data;
    // RS-232
    input rs232_0_rxd;
    output rs232_0_txd;
    // SPI
    output sdcard_ss_n;
    output sdcard_sclk;
    output sdcard_mosi;
    input sdcard_miso;
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
  wire clk_q;				// system clock, 25 MHz, quadrature
  wire rst;				// system reset
  // cpu
  wire memwait;
  wire [31:0] inbus;
  wire [31:0] inbus0;
  wire [23:0] adr;
  wire rd;
  wire wr;
  wire ben;
  wire [31:0] outbus;
  // ram
  wire ram_en;
  wire [19:0] ram_adr;
  // vid
  wire vid_en;
  wire [19:0] vid_adr;
  // i/o
  wire io_en;
  wire [3:0] io_adr;
  // tmr
  wire tmr_en;
  wire [31:0] tmr_data;
  // kbd_ms
  wire kbd_en;
  wire [31:0] kbd_dout;
  wire ms_en;
  wire [31:0] ms_dout;
  // ser
  wire ser_data_en;
  wire ser_ctrl_en;
  wire [31:0] ser_data;
  wire [31:0] ser_status;
  // spi
  wire spi_data_en;
  wire spi_ctrl_en;
  wire [31:0] spi_data;
  wire [31:0] spi_status;
  // bio
  wire bio_en;
  wire [31:0] bio_data;

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_1(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
    .clk_75(pclk),
    .clk_25(clk),
    .clk_25_q(clk_q),
    .rst(rst)
  );

  RISC5cpu cpu_1(
    .clk(clk),
    .rst(rst),
    .memwait(memwait),
    .inbus(inbus[31:0]),
    .codebus(inbus0[31:0]),
    .adr(adr[23:0]),
    .rd(rd),
    .wr(wr),
    .ben(ben),
    .outbus(outbus[31:0])
  );

  ram ram1(
    .clk(clk),
    .clk_q(clk_q),
    .rst(rst),
    .adr(ram_adr[19:0]),
    .en(ram_en),
    .ben(ben),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(inbus0[31:0]),
    .memwait(memwait),
    .sram_addr(sram_addr[19:0]),
    .sram_data(sram_dq[15:0]),
    .sram_ce_n(sram_ce_n),
    .sram_oe_n(sram_oe_n),
    .sram_we_n(sram_we_n),
    .sram_ub_n(sram_ub_n),
    .sram_lb_n(sram_lb_n)
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

  tmr tmr_1(
    .clk(clk),
    .rst(rst),
    .dout(tmr_data[31:0])
  );

  kbd_ms kbd_ms_1(
    .clk(clk),
    .rst(rst),
    .kbd_done(kbd_en & rd),
    .kbd_dout(kbd_dout[31:0]),
    .ms_dout(ms_dout[31:0]),
    .kbd_clk(ps2_0_clk),
    .kbd_data(ps2_0_data),
    .ms_clk(ps2_1_clk),
    .ms_data(ps2_1_data)
  );

  ser ser_1(
    .clk(clk),
    .rst(rst),
    .data_en(ser_data_en),
    .ctrl_en(ser_ctrl_en),
    .rd(rd),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(ser_data[31:0]),
    .status(ser_status[31:0]),
    .rxd(rs232_0_rxd),
    .txd(rs232_0_txd)
  );

  spi spi_1(
    .clk(clk),
    .rst(rst),
    .data_en(spi_data_en),
    .ctrl_en(spi_ctrl_en),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(spi_data[31:0]),
    .status(spi_status[31:0]),
    .ss_n(sdcard_ss_n),
    .sclk(sdcard_sclk),
    .mosi(sdcard_mosi),
    .miso(sdcard_miso)
  );

  bio bio_1(
    .clk(clk),
    .rst(rst),
    .en(bio_en),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(bio_data[31:0]),
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

  assign ram_en = (adr[23:20] == 4'h0);
  assign ram_adr = adr[19:0];

  assign vid_en = (adr[23:20] == 4'h0) & (adr[19:0] >= 20'hE7F00);
  assign vid_adr = adr[19:0] - 20'hE7F00;

  assign io_en = (adr[23:6] == 18'h3FFFF);
  assign io_adr = adr[5:2];
  assign tmr_en = io_en & (io_adr == 4'd0);
  assign bio_en = io_en & (io_adr == 4'd1);
  assign ser_data_en = io_en & (io_adr == 4'd2);
  assign ser_ctrl_en = io_en & (io_adr == 4'd3);
  assign spi_data_en = io_en & (io_adr == 4'd4);
  assign spi_ctrl_en = io_en & (io_adr == 4'd5);
  assign ms_en = io_en & (io_adr == 4'd6);
  assign kbd_en = io_en & (io_adr == 4'd7);

  //--------------------------------------
  // data multiplexer
  //--------------------------------------

  assign inbus[31:0] =
    ~io_en ? inbus0[31:0] :
    tmr_en ? tmr_data[31:0] :
    bio_en ? bio_data[31:0] :
    ser_data_en ? ser_data[31:0] :
    ser_ctrl_en ? ser_status[31:0] :
    spi_data_en ? spi_data[31:0] :
    spi_ctrl_en ? spi_status[31:0] :
    ms_en ? ms_dout[31:0] :
    kbd_en ? kbd_dout[31:0] :
    32'h0;

endmodule
