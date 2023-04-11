//
// sdc_spi.v -- SD card SPI interface
//


`timescale 1ns / 1ps
`default_nettype none


module sdc_spi(clk, rst,
               fast, start, dataTx, dataRx, rdy,
               sclk, mosi, miso);
    input clk;
    input rst;
    input fast;
    input start;
    input [31:0] dataTx;
    output [31:0] dataRx;
    output reg rdy;
    output sclk;
    output mosi;
    input miso;

  wire endbit, endtick;
  reg [31:0] shreg;
  reg [6:0] tick;
  reg [4:0] bitcnt;

  assign endtick = fast ? (tick == 3) : (tick == 127);
  assign endbit = fast ? (bitcnt == 31) : (bitcnt == 7);
  assign dataRx = fast ? shreg : {24'b0, shreg[7:0]};
  assign mosi = (rst | rdy) ? 1'b1 : shreg[7];
  assign sclk = (rst | rdy) ? 1'b0 : fast ? tick[1] : tick[6];

  always @ (posedge clk) begin
    tick <= (rst | rdy | endtick) ? 7'd0 : tick + 7'd1;
    rdy <= (rst | endtick & endbit) ? 1'b1 : start ? 1'b0 : rdy;
    bitcnt <= (rst | start) ? 5'd0 :
      (endtick & ~endbit) ? bitcnt + 5'd1 : bitcnt;
    shreg <= rst ? -1 : start ? dataTx : endtick ?
      { shreg[30:24], miso, shreg[22:16], shreg[31], shreg[14:8],
        shreg[23], shreg[6:0], (fast ? shreg[15] : miso) } : shreg;
  end

endmodule
