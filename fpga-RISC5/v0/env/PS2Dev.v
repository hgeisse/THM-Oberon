//
// PS2Dev.v -- PS/2 Interface
//


`timescale 1ns / 1ps
`default_nettype none


module PS2Dev(PS2C, PS2D, msclk, msdat);
    output reg PS2C;
    output reg PS2D;
    inout msclk;
    inout msdat;

  initial begin
    #0          PS2C = 1'b0;
                PS2D = 1'b0;
  end

endmodule
