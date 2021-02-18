//
// mouse.v -- PS/2 mouse interface
//


`timescale 1ns / 1ps
`default_nettype none


// 3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1                 bit
// 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
// ===============================================================
// p y y y y y y y y 0 1 p x x x x x x x x 0 1 p Y X t s 1 M R L 0 normal
// ---------------------------------------------------------------
// p ----response--- 0 1 --InitBuf echoed--- 1 1 1 1 1 1 1 1 1 1 1 init
// ---------------------------------------------------------------
// p = parity (ignored); X, Y = overflow; s, t = x, y sign bits


module mouse(clk, rst,
             dout,
             mouse_clk, mouse_data);
    input clk;
    input rst;
    output [27:0] dout;
    inout mouse_clk;
    inout mouse_data;

  reg [9:0] x, y;
  reg [2:0] btns;
  reg Q0, Q1, run;
  reg [31:0] shreg;
  wire shift, endbit, reply;
  wire [9:0] dx, dy;

  // initially need to send F4 cmd (start reporting)
  // add start and parity bits
  localparam InitBuf = 32'b11111111111111111111110_11110100_0;
  assign mouse_clk = rst ? 1'b0 : 1'bz;  // initial drive clock low
  assign mouse_data = ~run & ~shreg[0] ? 1'b0 : 1'bz;
  assign shift = Q1 & ~Q0;  // falling edge detector
  assign reply = ~run & ~shreg[11];  // start bit of echoed InitBuf, if resp.
  assign endbit = run & ~shreg[0];  // normal packet received
  assign dx = {{2{shreg[5]}}, shreg[7] ? 8'b0 : shreg[19:12]};  // sign+overfl
  assign dy = {{2{shreg[6]}}, shreg[8] ? 8'b0 : shreg[30:23]};  // sign+overfl
  assign dout = {run, btns, 2'b0, y, 2'b0, x};

  always @ (posedge clk) begin
    run <= ~rst & (reply | run);
    Q0 <= mouse_clk;
    Q1 <= Q0;
    shreg <= rst ? InitBuf :
             (endbit | reply) ? -1 :
             shift ? { mouse_data, shreg[31:1] } :
             shreg;
    x <= rst ? 10'd0 : endbit ? x + dx : x;
    y <= rst ? 10'd0 : endbit ? y + dy : y;
    btns <= rst ? 3'd0 : endbit ? { shreg[1], shreg[3], shreg[2] } : btns;
  end

endmodule
