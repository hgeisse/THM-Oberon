//
// IOBUF.v -- XILINX primitive
//


`timescale 1ns / 1ps
`default_nettype none


module IOBUF(O, IO, I, T);
    output O;
    inout IO;
    input I;
    input T;

  assign O = IO;
  assign IO = ~T ? I : 1'bz;

endmodule
