//
// sdc.v -- SD card interface
//


`timescale 1ns / 1ps
`default_nettype none


module sdc(clk, rst,
           stb, we, addr,
           data_in, data_out, ack,
           ss_n, sclk, mosi, miso);
    // internal interface
    input clk;
    input rst;
    input stb;
    input we;
    input addr;
    input [31:0] data_in;
    output [31:0] data_out;
    output ack;
    // external interface
    output ss_n;
    output sclk;
    output mosi;
    input miso;

  wire rd_data;
  wire wr_data;
  wire rd_ctrl;
  wire wr_ctrl;

  wire spi_rdy;
  wire [31:0] dataRx;

  reg [3:0] spi_ctrl;

  assign rd_data = stb & ~we & ~addr;	// read received data
  assign wr_data = stb &  we & ~addr;	// write data to transmit
  assign rd_ctrl = stb & ~we &  addr;	// read status
  assign wr_ctrl = stb &  we &  addr;	// write control

  always @(posedge clk) begin
    if (rst) begin
      spi_ctrl[3:0] <= 4'h0;
    end else begin
      if (wr_ctrl) begin
        spi_ctrl[3:0] <= data_in[3:0];
      end
    end
  end

  assign ss_n = ~spi_ctrl[0];

  sdc_spi sdc_spi_0(
    .clk(clk),
    .rst(rst),
    .fast(spi_ctrl[2]),
    .start(wr_data),
    .dataTx(data_in[31:0]),
    .dataRx(dataRx[31:0]),
    .rdy(spi_rdy),
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso)
  );

  assign data_out =
    rd_data ? dataRx[31:0] :
    rd_ctrl ? { 28'h0000000, 3'b000, spi_rdy } :
    32'h00000000;

  assign ack = stb;

endmodule
