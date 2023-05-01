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
             rs232_1_rxd,
             rs232_1_txd,
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
             sw,
             lcd_on,
             lcd_en,
             lcd_rw,
             lcd_rs,
             lcd_data
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
    // RS-232 0
    input rs232_0_rxd;
    output rs232_0_txd;
    // RS-232 1
    input rs232_1_rxd;
    output rs232_1_txd;
    // SD card
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
    // LCD
    output lcd_on;
    output lcd_en;
    output lcd_rw;
    output lcd_rs;
    inout [7:0] lcd_data;

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
  wire [15:0] bus_irq;			// bus interrupt requests
  // prom
  wire prom_stb;			// prom strobe
  wire [31:0] prom_dout;		// prom data output
  wire prom_ack;			// prom acknowledge
  // ram
  wire ram_stb;				// ram strobe
  wire [26:2] ram_addr;			// ram address
  wire [31:0] ram_dout;			// ram data output
  wire ram_ack;				// ram acknowledge
  // vid
  wire vid_stb;				// video buffer strobe
  // i/o
  wire i_o_stb;				// i/o strobe
  // tmr
  wire tmr_stb;				// timer strobe
  wire [31:0] tmr_dout;			// timer data output
  wire tmr_ack;				// timer acknowledge
  wire tmr_irq;				// timer interrupt request
  // bio
  wire bio_stb;				// board i/o strobe
  wire [31:0] bio_dout;			// board i/o data output
  wire bio_ack;				// board i/o acknowledge
  // ser 0
  wire ser_0_stb;			// serial line 0 strobe
  wire [31:0] ser_0_dout;		// serial line 0 data output
  wire ser_0_ack;			// serial line 0 acknowledge
  wire ser_0_rcv_irq;			// serial line 0 rcv interrupt request
  wire ser_0_xmt_irq;			// serial line 0 xmt interrupt request
  // sdc
  wire sdc_stb;				// SDC strobe
  wire [31:0] sdc_dout;			// SDC data output
  wire sdc_ack;				// SDC acknowledge
  // kbd
  wire kbd_stb;				// keyboard strobe
  wire [31:0] kbd_dout;			// keyboard data output
  wire kbd_ack;				// keyboard acknowledge
  // extended i/o
  wire x_i_o_stb;			// extended i/o strobe
  // hpt 0
  wire hpt_0_stb;			// high prec timer 0 strobe
  wire [31:0] hpt_0_dout;		// high prec timer 0 data output
  wire hpt_0_ack;			// high prec timer 0 acknowledge
  wire hpt_0_irq;			// high prec timer 0 interrupt request
  // lcd
  wire lcd_stb;				// LCD strobe
  wire [31:0] lcd_dout;			// LCD data output
  wire lcd_ack;				// LCD acknowledge
  // bsw
  wire bsw_stb;				// buttons/switches strobe
  wire [31:0] bsw_dout;			// buttons/switches data output
  wire bsw_ack;				// buttons/switches acknowledge
  wire bsw_irq;				// buttons/switches interrupt request
  // hpt 1
  wire hpt_1_stb;			// high prec timer 1 strobe
  wire [31:0] hpt_1_dout;		// high prec timer 1 data output
  wire hpt_1_ack;			// high prec timer 1 acknowledge
  wire hpt_1_irq;			// high prec timer 1 interrupt request
  // ser 1
  wire ser_1_stb;			// serial line 1 strobe
  wire [31:0] ser_1_dout;		// serial line 1 data output
  wire ser_1_ack;			// serial line 1 acknowledge
  wire ser_1_rcv_irq;			// serial line 1 rcv interrupt request
  wire ser_1_xmt_irq;			// serial line 1 xmt interrupt request

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
    .bus_ack(bus_ack),
    .bus_irq(bus_irq[15:0])
  );

  prom prom_0(
    .clk(clk),
    .rst(rst),
    .stb(prom_stb),
    .we(bus_we),
    .addr(bus_addr[11:2]),
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

  vid vid_0(
    .pclk(pclk),
    .clk(clk),
    .rst(rst),
    .stb(vid_stb),
    .we(bus_we),
    .addr(bus_addr[16:2]),
    .data_in(bus_dout[31:0]),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .pxclk(vga_clk),
    .sync_n(vga_sync_n),
    .blank_n(vga_blank_n),
    .r(vga_r[7:0]),
    .g(vga_g[7:0]),
    .b(vga_b[7:0])
  );

  tmr tmr_0(
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
    .we(bus_we),
    .data_in(bus_dout[31:0]),
    .data_out(tmr_dout[31:0]),
    .ack(tmr_ack),
    .irq(tmr_irq)
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

  ser ser_0(
    .clk(clk),
    .rst(rst),
    .stb(ser_0_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(ser_0_dout[31:0]),
    .ack(ser_0_ack),
    .rcv_irq(ser_0_rcv_irq),
    .xmt_irq(ser_0_xmt_irq),
    .rxd(rs232_0_rxd),
    .txd(rs232_0_txd)
  );

  sdc sdc_0(
    .clk(clk),
    .rst(rst),
    .stb(sdc_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(sdc_dout[31:0]),
    .ack(sdc_ack),
    .ss_n(sdcard_ss_n),
    .sclk(sdcard_sclk),
    .mosi(sdcard_mosi),
    .miso(sdcard_miso)
  );

  kbd kbd_0(
    .clk(clk),
    .rst(rst),
    .stb(kbd_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_out(kbd_dout[31:0]),
    .ack(kbd_ack),
    .keybd_clk(ps2_0_clk),
    .keybd_data(ps2_0_data),
    .mouse_clk(ps2_1_clk),
    .mouse_data(ps2_1_data)
  );

  hpt hpt_0(
    .clk(clk),
    .rst(rst),
    .stb(hpt_0_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(hpt_0_dout[31:0]),
    .ack(hpt_0_ack),
    .irq(hpt_0_irq)
  );

  lcd lcd_0(
    .clk(clk),
    .rst(rst),
    .stb(lcd_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(lcd_dout[31:0]),
    .ack(lcd_ack),
    .lcd_on(lcd_on),
    .lcd_en(lcd_en),
    .lcd_rw(lcd_rw),
    .lcd_rs(lcd_rs),
    .lcd_data(lcd_data[7:0])
  );

  bsw bsw_0(
    .clk(clk),
    .rst(rst),
    .stb(bsw_stb),
    .we(bus_we),
    .data_in(bus_dout[31:0]),
    .data_out(bsw_dout[31:0]),
    .ack(bsw_ack),
    .irq(bsw_irq),
    .keys_n({ key3_n, key2_n, key1_n, rst_in_n }),
    .sw(sw[7:0])
  );

  hpt hpt_1(
    .clk(clk),
    .rst(rst),
    .stb(hpt_1_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(hpt_1_dout[31:0]),
    .ack(hpt_1_ack),
    .irq(hpt_1_irq)
  );

  ser ser_1(
    .clk(clk),
    .rst(rst),
    .stb(ser_1_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(ser_1_dout[31:0]),
    .ack(ser_1_ack),
    .rcv_irq(ser_1_rcv_irq),
    .xmt_irq(ser_1_xmt_irq),
    .rxd(rs232_1_rxd),
    .txd(rs232_1_txd)
  );

  //--------------------------------------
  // address decoder (16 MB addr space)
  //--------------------------------------

  // PROM: 4 KB @ 0xFFE000
  assign prom_stb =
    (bus_stb == 1'b1 && bus_addr[23:12] == 12'hFFE) ? 1'b1 : 1'b0;

  // RAM: (16 MB - 8 KB) @ 0x000000
  assign ram_stb =
    (bus_stb == 1'b1 && bus_addr[23:13] != 11'h7FF) ? 1'b1 : 1'b0;

  // VID: 96 KB @ 0xFE0000
  assign vid_stb =
    (bus_stb == 1'b1 && bus_addr[23:17] == 7'h7F
                     && bus_addr[16:15] != 2'b11) ? 1'b1 : 1'b0;

  // I/O: 64 bytes (16 words) @ 0xFFFFC0
  assign i_o_stb =
    (bus_stb == 1'b1 && bus_addr[23:8] == 16'hFFFF
                     && bus_addr[7:6] == 2'b11) ? 1'b1 : 1'b0;
  assign tmr_stb =
    (i_o_stb == 1'b1 && bus_addr[5:2] == 4'b0000) ? 1'b1 : 1'b0;
  assign bio_stb =
    (i_o_stb == 1'b1 && bus_addr[5:2] == 4'b0001) ? 1'b1 : 1'b0;
  assign ser_0_stb =
    (i_o_stb == 1'b1 && bus_addr[5:3] == 3'b001) ? 1'b1 : 1'b0;
  assign sdc_stb =
    (i_o_stb == 1'b1 && bus_addr[5:3] == 3'b010) ? 1'b1 : 1'b0;
  assign kbd_stb =
    (i_o_stb == 1'b1 && bus_addr[5:3] == 3'b011) ? 1'b1 : 1'b0;

  // extended I/O: 64 bytes (16 words) @ 0xFFFF80
  assign x_i_o_stb =
    (bus_stb == 1'b1 && bus_addr[23:8] == 16'hFFFF
                     && bus_addr[7:6] == 2'b10) ? 1'b1 : 1'b0;
  assign hpt_0_stb =
    (x_i_o_stb == 1'b1 && bus_addr[5:3] == 3'b000) ? 1'b1 : 1'b0;
  assign lcd_stb =
    (x_i_o_stb == 1'b1 && bus_addr[5:3] == 3'b001) ? 1'b1 : 1'b0;
  assign bsw_stb =
    (x_i_o_stb == 1'b1 && bus_addr[5:2] == 4'b0100) ? 1'b1 : 1'b0;
  assign hpt_1_stb =
    (x_i_o_stb == 1'b1 && bus_addr[5:3] == 3'b011) ? 1'b1 : 1'b0;
  assign ser_1_stb =
    (x_i_o_stb == 1'b1 && bus_addr[5:3] == 3'b100) ? 1'b1 : 1'b0;

  //--------------------------------------
  // data and acknowledge multiplexers
  //--------------------------------------

  assign bus_din[31:0] =
    prom_stb  ? prom_dout[31:0]  :
    ram_stb   ? ram_dout[31:0]   :
    tmr_stb   ? tmr_dout[31:0]   :
    bio_stb   ? bio_dout[31:0]   :
    ser_0_stb ? ser_0_dout[31:0] :
    sdc_stb   ? sdc_dout[31:0]   :
    kbd_stb   ? kbd_dout[31:0]   :
    hpt_0_stb ? hpt_0_dout[31:0] :
    lcd_stb   ? lcd_dout[31:0]   :
    bsw_stb   ? bsw_dout[31:0]   :
    hpt_1_stb ? hpt_1_dout[31:0] :
    ser_1_stb ? ser_1_dout[31:0] :
    32'h00000000;

  assign bus_ack =
    prom_stb  ? prom_ack  :
    ram_stb   ? ram_ack   :
    tmr_stb   ? tmr_ack   :
    bio_stb   ? bio_ack   :
    ser_0_stb ? ser_0_ack :
    sdc_stb   ? sdc_ack   :
    kbd_stb   ? kbd_ack   :
    hpt_0_stb ? hpt_0_ack :
    lcd_stb   ? lcd_ack   :
    bsw_stb   ? bsw_ack   :
    hpt_1_stb ? hpt_1_ack :
    ser_1_stb ? ser_1_ack :
    1'b0;

  //--------------------------------------
  // bus interrupt request assignments
  //--------------------------------------

  assign bus_irq[15] = hpt_0_irq;
  assign bus_irq[14] = hpt_1_irq;
  assign bus_irq[13] = 1'b0;
  assign bus_irq[12] = 1'b0;
  assign bus_irq[11] = tmr_irq;
  assign bus_irq[10] = 1'b0;
  assign bus_irq[ 9] = 1'b0;
  assign bus_irq[ 8] = 1'b0;
  assign bus_irq[ 7] = ser_0_rcv_irq;
  assign bus_irq[ 6] = ser_0_xmt_irq;
  assign bus_irq[ 5] = ser_1_rcv_irq;
  assign bus_irq[ 4] = ser_1_xmt_irq;
  assign bus_irq[ 3] = bsw_irq;
  assign bus_irq[ 2] = 1'b0;
  assign bus_irq[ 1] = 1'b0;
  assign bus_irq[ 0] = 1'b0;

endmodule
