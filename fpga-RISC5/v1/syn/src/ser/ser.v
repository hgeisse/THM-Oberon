//
// ser.v -- serial line interface
//


`timescale 1ns / 1ps
`default_nettype none


module ser(clk, rst,
           stb, we, addr,
           data_in, data_out, ack,
           rxd, txd);
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
    input rxd;
    output txd;

  wire rd_data;
  wire wr_data;
  wire rd_ctrl;
  wire wr_ctrl;

  wire rcv_rdy;
  wire [7:0] rcv_data;
  wire xmt_rdy;

  reg [15:0] bit_len;

  assign rd_data = stb & ~we & ~addr;	// read received data
  assign wr_data = stb &  we & ~addr;	// write data to transmit
  assign rd_ctrl = stb & ~we &  addr;	// read status
  assign wr_ctrl = stb &  we &  addr;	// set bitrate

  rcvbuf rcvbuf_0(
    .clk(clk),
    .rst(rst),
    .bit_len(bit_len),
    .read(rd_data),
    .ready(rcv_rdy),
    .data_out(rcv_data[7:0]),
    .serial_in(rxd)
  );

  xmtbuf xmtbuf_0(
    .clk(clk),
    .rst(rst),
    .bit_len(bit_len),
    .write(wr_data),
    .ready(xmt_rdy),
    .data_in(data_in[7:0]),
    .serial_out(txd)
  );

  assign data_out =
    rd_data ? { 24'hxxxxxx, rcv_data[7:0] } :
    rd_ctrl ? { 30'hxxxxxxxx, xmt_rdy, rcv_rdy } :
    32'hxxxxxxxx;

  always @(posedge clk) begin
    if (rst) begin
      bit_len <= 16'd5208;
    end else begin
      if (wr_ctrl) begin
        case (data_in[2:0])
					// data rates below for 50 MHz clock
          3'h0:  bit_len <= 16'd20833;	//   2400 baud
          3'h1:  bit_len <= 16'd10417;	//   4800 baud
          3'h2:  bit_len <= 16'd5208;	//   9600 baud
          3'h3:  bit_len <= 16'd2604;	//  19200 baud
          3'h4:  bit_len <= 16'd1600;	//  31250 baud
          3'h5:  bit_len <= 16'd1302;	//  38400 baud
          3'h6:  bit_len <= 16'd868;	//  57600 baud
          3'h7:  bit_len <= 16'd434;	// 115200 baud
        endcase
      end
    end
  end

  assign ack = stb;

endmodule
