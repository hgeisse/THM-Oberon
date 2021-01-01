//
// risc5.v -- RISC5 top-level description
//


`timescale 1ns/1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n);
    // clock and reset
    input clk_in;			// clock, input, 50 MHz
    input rst_in_n;			// reset, input, active low

  // clk_rst
  wire clk_ok;				// system clocks stable
  wire pclk;				// pixel clock, 75 MHz
  wire clk;				// system clock, 50 MHz
  wire rst;				// system reset
  // cpu
  wire bus_stb;				// bus strobe
  wire bus_we;				// bus write enable
  wire [31:2] bus_addr;			// bus address (word address)
  wire [31:0] bus_din;			// bus data input, for reads
  wire [31:0] bus_dout;			// bus data output, for writes
  wire bus_ack;				// bus acknowledge

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_0(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
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

  //--------------------------------------
  // address decoder
  //--------------------------------------

  //--------------------------------------
  // data and acknowledge multiplexers
  //--------------------------------------

endmodule
