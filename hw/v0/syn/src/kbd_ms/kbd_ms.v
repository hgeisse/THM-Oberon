//
// kbd_ms.v -- keyboard and mouse interface
//


`timescale 1ns/1ps
`default_nettype none


module kbd_ms(clk, rst,
              kbd_done,
              kbd_dout,
              ms_dout,
              kbd_clk, kbd_data,
              ms_clk, ms_data);
    // internal interface
    input clk;
    input rst;
    input kbd_done;
    output [31:0] kbd_dout;
    output [31:0] ms_dout;
    // external interface
    input kbd_clk;
    input kbd_data;
    inout ms_clk;
    inout ms_data;

  wire keyboard_rdy;
  wire [7:0] keyboard_data;
  wire [27:0] mouse_data;

  PS2 PS2_1(
    .clk(clk),
    .rst(rst),
    .done(kbd_done),
    .rdy(keyboard_rdy),
    .shift(),  // not connected
    .data(keyboard_data[7:0]),
    .PS2C(kbd_clk),
    .PS2D(kbd_data)
  );

  MouseP MouseP_1(
    .clk(clk),
    .rst(rst),
    .out(mouse_data[27:0]),
    .msclk(ms_clk),
    .msdat(ms_data)
  );

  assign kbd_dout[31:0] = { 24'b0, keyboard_data[7:0] };
  assign ms_dout[31:0] = { 3'b0, keyboard_rdy, mouse_data[27:0] };

endmodule
