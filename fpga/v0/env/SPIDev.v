//
// SPIDev.v -- SPI interface
//


`timescale 1ns / 1ps
`default_nettype none


module SPIDev(MISO, MOSI, SCLK, SS, NEN);
    output reg [1:0] MISO;
    input [1:0] MOSI;
    input [1:0] SCLK;
    input [1:0] SS;
    input NEN;

  initial begin
    #0          MISO[1:0] = 2'b00;
  end

endmodule
