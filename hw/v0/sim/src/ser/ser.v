//
// ser.v -- RS232 interface
//


`timescale 1ns/1ps
`default_nettype none


module ser(clk, rst,
           data_en, ctrl_en, rd, wr,
           din, dout, status);
    // internal interface
    input clk;
    input rst;
    input data_en;
    input ctrl_en;
    input rd;
    input wr;
    input [31:0] din;
    output [31:0] dout;
    output [31:0] status;

endmodule
