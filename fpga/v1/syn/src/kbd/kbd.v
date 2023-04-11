//
// kbd.v -- keyboard and mouse interface
//


`timescale 1ns / 1ps
`default_nettype none


module kbd(clk, rst,
           stb, we, addr,
           data_out, ack,
           keybd_clk, keybd_data,
           mouse_clk, mouse_data);
    // internal interface
    input clk;
    input rst;
    input stb;
    input we;
    input addr;
    output [31:0] data_out;
    output ack;
    // external interface
    input keybd_clk;
    input keybd_data;
    inout mouse_clk;
    inout mouse_data;

  wire rd_mouse;
  wire rd_keybd;

  wire [27:0] mouse_dout;
  wire keybd_rdy;
  wire [7:0] keybd_dout;

  assign rd_mouse = stb & ~we & ~addr;	// read mouse data, keyboard status
  assign rd_keybd = stb & ~we &  addr;	// read keyboard data

  mouse mouse_0(
    .clk(clk),
    .rst(rst),
    .dout(mouse_dout[27:0]),
    .mouse_clk(mouse_clk),
    .mouse_data(mouse_data)
  );

  keybd keybd_0(
    .clk(clk),
    .rst(rst),
    .done(rd_keybd),
    .rdy(keybd_rdy),
    .dout(keybd_dout[7:0]),
    .keybd_clk(keybd_clk),
    .keybd_data(keybd_data)
  );

  assign data_out =
    rd_mouse ? { 3'b000, keybd_rdy, mouse_dout[27:0] } :
    rd_keybd ? { 24'h000000, keybd_dout[7:0] } :
    32'h00000000;

  assign ack = stb;

endmodule
