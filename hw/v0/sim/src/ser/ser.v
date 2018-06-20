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

  reg bitrate;

  wire done_rx;
  wire rdy_rx;
  wire [7:0] data_rx;

  wire start_tx;
  wire rdy_tx;
  wire [7:0] data_tx;

  always @(posedge clk) begin
    if (rst) begin
      bitrate <= 1'b0;
    end else begin
      if (ctrl_en & wr) begin
        bitrate <= din[0];
      end
    end
  end

  assign done_rx = data_en & rd;

  RS232R rcvr(
    .clk(clk),
    .rst(rst),
    .fsel(bitrate),
    .done(done_rx),
    .rdy(rdy_rx),
    .data(data_rx[7:0])
  );

  assign start_tx = data_en & wr;
  assign data_tx[7:0] = din[7:0];

  RS232T xmtr(
    .clk(clk),
    .rst(rst),
    .fsel(bitrate),
    .start(start_tx),
    .rdy(rdy_tx),
    .data(data_tx[7:0])
  );

  assign dout[31:0] = { 24'b0, data_rx };
  assign status[31:0] = { 30'b0, rdy_tx, rdy_rx };

endmodule
