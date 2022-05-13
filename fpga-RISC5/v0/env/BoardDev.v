//
// BoardDev.v -- Board Device
//


`timescale 1ns / 1ps
`default_nettype none


module BoardDev(btn, swi, leds);
    output reg [3:0] btn;
    output reg [7:0] swi;
    input [7:0] leds;

  initial begin
    #0          btn[3:0] = 4'b1000;
                swi[7:0] = 8'b00000000;
    #145        btn[3:0] = 4'b0000;
  end

endmodule
