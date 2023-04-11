//
// DCM.v -- XILINX primitive
//          NOTE: this is merely a fixed clock multiplier 25 MHz --> 75 MHz
//


`timescale 1ns / 1ps
`default_nettype none


module DCM(CLKIN, CLKFX);
    parameter CLKFX_MULTIPLY = 3;
    parameter CLK_FEEDBACK = "NONE";
    input CLKIN;
    output reg CLKFX;

  initial begin
    CLKFX = 0;
  end

  always @(posedge CLKIN) begin
    #7 CLKFX = 0;
    #6 CLKFX = 1;
    #7 CLKFX = 0;
    #7 CLKFX = 1;
    #6 CLKFX = 0;
    #7 CLKFX = 1;
  end

endmodule
