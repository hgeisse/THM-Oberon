//
// bsw.v -- buttons and switches
//


`timescale 1ns/1ps
`default_nettype none


module bsw(clk, rst,
           stb, we,
           data_in, data_out,
           ack, irq,
           keys_n, sw);
    // internal interface
    input clk;
    input rst;
    input stb;
    input we;
    input [31:0] data_in;
    output [31:0] data_out;
    output ack;
    output irq;
    // external interface
    input [3:0] keys_n;
    input [7:0] sw;

  reg [3:0] keys_p_n;
  reg [3:0] keys_s_n;
  reg [7:0] sw_p;
  reg [7:0] sw_s;

  reg [3:0] keys_delayed_n;
  wire [3:0] raising;
  wire [3:0] falling;
  reg [3:0] pressed;
  reg [3:0] released;

  reg [3:0] ien_pressed;
  reg [3:0] ien_released;
  wire any_pressed;
  wire any_released;

  always @(posedge clk) begin
    keys_p_n[3:0] <= keys_n[3:0];
    keys_s_n[3:0] <= keys_p_n[3:0];
    sw_p[7:0] <= sw[7:0];
    sw_s[7:0] <= sw_p[7:0];
  end

  always @(posedge clk) begin
    keys_delayed_n[3:0] <= keys_s_n[3:0];
  end

  assign raising[3:0] = keys_delayed_n[3:0] & ~keys_s_n[3:0];
  assign falling[3:0] = ~keys_delayed_n[3:0] & keys_s_n[3:0];

  always @(posedge clk) begin
    if (rst | (stb & ~we)) begin
      pressed[3:0] <= 4'b0000;
      released[3:0] <= 4'b0000;
    end else begin
      pressed[3:0] <= pressed[3:0] | raising[3:0];
      released[3:0] <= released[3:0] | falling[3:0];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ien_pressed[3:0] <= 4'h0;
      ien_released[3:0] <= 4'h0;
    end else begin
      if (stb & we) begin
        ien_pressed[3:0] <= data_in[31:28];
        ien_released[3:0] <= data_in[27:24];
      end
    end
  end

  assign data_out[31:0] =
    { pressed[3:0], released[3:0], 12'h0, ~keys_s_n[3:0], sw_s[7:0] };

  assign ack = stb;

  assign any_pressed = | (pressed[3:0] & ien_pressed[3:0]);
  assign any_released = | (released[3:0] & ien_released[3:0]);
  assign irq = any_pressed | any_released;

endmodule
