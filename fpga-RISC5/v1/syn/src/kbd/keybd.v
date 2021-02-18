//
// keybd.v -- PS/2 keyboard interface
//


`timescale 1ns / 1ps
`default_nettype none


module keybd(clk, rst,
             done, rdy, dout,
             keybd_clk, keybd_data);
    input clk;
    input rst;
    input done;   // "byte has been read"
    output rdy;   // "byte is available"
    output [7:0] dout;
    input keybd_clk;   // serial input
    input keybd_data;

  reg Q0, Q1;  // synchronizer and falling edge detector
  reg [10:0] shreg;
  reg [3:0] inptr, outptr;
  reg [7:0] fifo [15:0];  // 16 byte buffer
  wire endbit;
  wire shift;

  assign endbit = ~shreg[0];  //start bit reached correct pos
  assign shift = Q1 & ~Q0;
  assign dout = fifo[outptr];
  assign rdy = ~(inptr == outptr);

  always @ (posedge clk) begin
    Q0 <= keybd_clk;
    Q1 <= Q0;
    shreg <= (rst | endbit) ? 11'h7FF :
             shift ? { keybd_data, shreg[10:1] } :
             shreg;
    outptr <= rst ? 4'd0 :
              rdy & done ? outptr + 4'd1 :
              outptr;
    inptr <= rst ? 4'd0 :
             endbit ? inptr + 4'd1 :
             inptr;
    if (endbit) begin
      fifo[inptr] <= shreg[8:1];
    end
  end

endmodule
