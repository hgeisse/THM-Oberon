//
// spi.v -- SPI interface
//


`timescale 1ns/1ps
`default_nettype none


module spi(clk, rst,
           data_en, ctrl_en, wr,
           din, dout, status,
           ss_n, sclk,
           mosi, miso);
    // internal interface
    input clk;
    input rst;
    input data_en;
    input ctrl_en;
    input wr;
    input [31:0] din;
    output [31:0] dout;
    output [31:0] status;
    // external interface
    output ss_n;
    output sclk;
    output mosi;
    input miso;

  reg [3:0] spi_ctrl;
  wire spi_start;
  wire spi_rdy;

  always @(posedge clk) begin
    if (rst) begin
      spi_ctrl[3:0] <= 4'h0;
    end else begin
      if (ctrl_en & wr) begin
        spi_ctrl[3:0] <= din[3:0];
      end
    end
  end

  assign ss_n = ~spi_ctrl[0];

  assign spi_start = data_en & wr;

  spi_rt spi_rt_1(
    .clk(clk),
    .rst(rst),
    .start(spi_start),
    .fast(spi_ctrl[2]),
    .dataTx(din[31:0]),
    .dataRx(dout[31:0]),
    .rdy(spi_rdy),
    .MISO(miso),
    .MOSI(mosi),
    .SCLK(sclk)
  );

  assign status[31:0] = { 31'b0, spi_rdy };

endmodule
