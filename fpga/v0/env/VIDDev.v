//
// VIDDev.v -- Video interface
//


`timescale 1ns / 1ps
`default_nettype none


module VIDDev(hsync, vsync, RGB);
    input hsync;
    input vsync;
    input [2:0] RGB;

endmodule
