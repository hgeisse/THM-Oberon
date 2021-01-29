//
// risc5.v -- RISC5 top-level description
//


`timescale 1ns/1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n,
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

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_0(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
    .clk_100_ps(),
    .clk_100(mclk),
    .clk_75(pclk),
    .clk_50(clk),
    .rst(rst)
  );

  //--------------------------------------
  // test
  //--------------------------------------

  reg [25:0] counter0;
  reg [25:0] counter1;
  reg [25:0] counter2;

  always @(posedge clk) begin
    if (rst) begin
      counter0 <= 26'd0;
    end else begin
      counter0 <= counter0 + 26'd1;
    end
  end
  always @(posedge pclk) begin
    if (rst) begin
      counter1 <= 26'd0;
    end else begin
      counter1 <= counter1 + 26'd1;
    end
  end
  always @(posedge mclk) begin
    if (rst) begin
      counter2 <= 26'd0;
    end else begin
      counter2 <= counter2 + 26'd1;
    end
  end

  assign led_g[0] = clk_ok;
  assign led_g[1] = rst;
  assign led_g[2] = counter0[25];
  assign led_g[3] = counter1[25];
  assign led_g[4] = counter2[25];
  assign led_g[5] = ~key1_n;
  assign led_g[6] = ~key2_n;
  assign led_g[7] = ~key3_n;
  assign led_g[8] = 1'b0;

  assign led_r[17:0] = sw[17:0];

  assign hex7_n[6:0] = 7'h7F;
  assign hex6_n[6:0] = 7'h7F;
  assign hex5_n[6:0] = 7'h7F;
  assign hex4_n[6:0] = 7'h7F;
  assign hex3_n[6:0] = 7'h7F;
  assign hex2_n[6:0] = 7'h7F;
  assign hex1_n[6:0] = 7'h7F;
  assign hex0_n[6:0] = 7'h7F;

endmodule
