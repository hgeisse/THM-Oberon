//
// risc5.v -- RISC5 top-level description
//


`timescale 1ns / 1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n);
    // clock and reset
    input clk_in;			// clock, input, 50 MHz
    input rst_in_n;			// reset, input, active low

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
  // ser
  wire ser_stb;				// serial line strobe
  wire [31:0] ser_dout;			// serial line data output
  wire ser_ack;				// serial line acknowledge

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_0(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
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

  ram ram_0(
    .clk(clk),
    .rst(rst),
    .stb(ram_stb),
    .we(bus_we),
    .addr(bus_addr[23:2]),
    .data_in(bus_dout[31:0]),
    .data_out(ram_dout[31:0]),
    .ack(ram_ack)
  );

  vid vid_0(
    .pclk(pclk),
    .clk(clk),
    .rst(rst),
    .stb(vid_stb),
    .we(bus_we),
    .addr(bus_addr[16:2]),
    .data_in(bus_dout[31:0])
  );

  tmr tmr_0(
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
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
    .ack(bio_ack)
  );

  ser ser_0(
    .clk(clk),
    .rst(rst),
    .stb(ser_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(ser_dout[31:0]),
    .ack(ser_ack)
  );

  //--------------------------------------
  // address decoder (16 MB addr space)
  //--------------------------------------

  // PROM: 2 KB @ 0xFFE000
  assign prom_stb =
    (bus_stb == 1'b1 && bus_addr[23:12] == 12'hFFE
                     && bus_addr[11] == 1'b0) ? 1'b1 : 1'b0;

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
  assign ser_stb =
    (i_o_stb == 1'b1 && bus_addr[5:3] == 3'b001) ? 1'b1 : 1'b0;

  //--------------------------------------
  // data and acknowledge multiplexers
  //--------------------------------------

  assign bus_din[31:0] =
    prom_stb ? prom_dout[31:0] :
    ram_stb  ? ram_dout[31:0]  :
    tmr_stb  ? tmr_dout[31:0]  :
    bio_stb  ? bio_dout[31:0]  :
    ser_stb  ? ser_dout[31:0]  :
    32'h00000000;

  assign bus_ack =
    prom_stb ? prom_ack :
    ram_stb  ? ram_ack  :
    tmr_stb  ? tmr_ack  :
    bio_stb  ? bio_ack  :
    ser_stb  ? ser_ack  :
    1'b0;

  //--------------------------------------
  // bus interrupt request assignments
  //--------------------------------------

  assign bus_irq[15] = tmr_irq;
  assign bus_irq[14] = 1'b0;
  assign bus_irq[13] = 1'b0;
  assign bus_irq[12] = 1'b0;
  assign bus_irq[11] = 1'b0;
  assign bus_irq[10] = 1'b0;
  assign bus_irq[ 9] = 1'b0;
  assign bus_irq[ 8] = 1'b0;
  assign bus_irq[ 7] = 1'b0;
  assign bus_irq[ 6] = 1'b0;
  assign bus_irq[ 5] = 1'b0;
  assign bus_irq[ 4] = 1'b0;
  assign bus_irq[ 3] = 1'b0;
  assign bus_irq[ 2] = 1'b0;
  assign bus_irq[ 1] = 1'b0;
  assign bus_irq[ 0] = 1'b0;

endmodule
