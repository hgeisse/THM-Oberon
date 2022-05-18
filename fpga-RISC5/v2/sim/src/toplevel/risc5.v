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
  wire pclk;				// pixel clock, 75 MHz
  wire clk;				// system clock, 100 MHz
  wire rst;				// system reset

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_0(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
    .clk_75(pclk),
    .clk_100(clk),
    .rst(rst)
  );

  cpu cpu_0(
    .clk(clk),
    .rst(rst)
  );

endmodule
