//
// ram.v -- controller for 1Mx16 asynchronous static RAM
//


`timescale 1ns/1ps
`default_nettype none


module ram(adr, ben, rd, wr, din, dout);
    input [23:0] adr;
    input ben;
    input rd;
    input wr;
    input [31:0] din;
    output [31:0] dout;

endmodule
