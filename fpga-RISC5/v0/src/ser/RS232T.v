`timescale 1ns / 1ps  // NW 4.5.09 / 15.8.10 / 15.11.10
`default_nettype none  // HG 22.03.2018
// HG 22.03.2018: rst polarity changed

// RS232 transmitter for 9600 or 115200 bps, 8 bit data
// clock is 25 MHz; 25000 / 2604 = 9.6 KHz, 25000 / 217 = 115.2 KHz

module RS232T(
    input clk,
    input rst,
    input start, // request to accept and send a byte
    input fsel,  // frequency selection
    input [7:0] data,
    output rdy,
    output TxD);

wire endtick, endbit;
wire [11:0] limit;
reg run;
reg [11:0] tick;
reg [3:0] bitcnt;
reg [8:0] shreg;

assign limit = fsel ? 12'd217 : 12'd2604;
assign endtick = tick == limit;
assign endbit = bitcnt == 9;
assign rdy = ~run;
assign TxD = shreg[0];

always @ (posedge clk) begin
  run <= (rst | endtick & endbit) ? 1'b0 : start ? 1'b1 : run;
  tick <= (run & ~endtick) ? tick + 12'd1 : 12'd0;
  bitcnt <= (endtick & ~endbit) ? bitcnt + 4'd1 :
    (endtick & endbit) ? 4'd0 : bitcnt;
  shreg <= rst ? 9'd1 : start ? {data, 1'b0} :
    endtick ? {1'b1, shreg[8:1]} : shreg;
end

endmodule
