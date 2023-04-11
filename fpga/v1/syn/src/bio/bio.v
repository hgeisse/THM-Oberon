//
// bio.v -- board-specific I/O
//


`timescale 1ns / 1ps
`default_nettype none


module bio(clk, rst,
           stb, we, data_in, data_out, ack,
           led_g, led_r,
           hex7_n, hex6_n, hex5_n, hex4_n,
           hex3_n, hex2_n, hex1_n, hex0_n,
           key3_n, key2_n, key1_n, sw);
    // internal interface
    input clk;
    input rst;
    input stb;
    input we;
    input [31:0] data_in;
    output [31:0] data_out;
    output ack;
    // external interface
    output reg [8:0] led_g;
    output reg [17:0] led_r;
    output reg [6:0] hex7_n;
    output reg [6:0] hex6_n;
    output reg [6:0] hex5_n;
    output reg [6:0] hex4_n;
    output reg [6:0] hex3_n;
    output reg [6:0] hex2_n;
    output reg [6:0] hex1_n;
    output reg [6:0] hex0_n;
    input key3_n;
    input key2_n;
    input key1_n;
    input [17:0] sw;

  reg key3_p_n;
  reg key3_s_n;
  reg key2_p_n;
  reg key2_s_n;
  reg key1_p_n;
  reg key1_s_n;
  reg [17:0] sw_p;
  reg [17:0] sw_s;

  always @(posedge clk) begin
    if (rst) begin
      led_g[8:0] <= 9'h0;
      led_r[17:0] <= 18'h0;
      hex7_n[6:0] <= ~7'h0;
      hex6_n[6:0] <= ~7'h0;
      hex5_n[6:0] <= ~7'h0;
      hex4_n[6:0] <= ~7'h0;
      hex3_n[6:0] <= ~7'h0;
      hex2_n[6:0] <= ~7'h0;
      hex1_n[6:0] <= ~7'h0;
      hex0_n[6:0] <= ~7'h0;
    end else begin
      if (stb & we) begin
        led_g[7:0] <= data_in[7:0];
      end
    end
  end

  always @(posedge clk) begin
    key3_p_n <= key3_n;
    key3_s_n <= key3_p_n;
    key2_p_n <= key2_n;
    key2_s_n <= key2_p_n;
    key1_p_n <= key1_n;
    key1_s_n <= key1_p_n;
    sw_p[17:0] <= sw[17:0];
    sw_s[17:0] <= sw_p[17:0];
  end

  assign data_out[31:0] =
    { sw_s[17:8], 10'b0, ~key3_s_n, ~key2_s_n, ~key1_s_n, rst, sw_s[7:0] };

  assign ack = stb;

endmodule
