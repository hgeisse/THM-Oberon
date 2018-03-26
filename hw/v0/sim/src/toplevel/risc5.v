//
// risc5.v -- RISC5 toplevel description
//


`timescale 1ns/1ps
`default_nettype none


module risc5(clk_in,
             rst_in_n
            );

    // clock and reset
    input clk_in;
    input rst_in_n;

  // clk_rst
  wire clk_ok;				// system clocks stable
  wire pclk;				// pixel clock, 75 MHz
  wire clk;				// system clock, 25 MHz
  wire rst;				// system reset
  // cpu
  wire memwait;
  wire [31:0] inbus;
  wire [31:0] inbus0;
  wire [23:0] adr;
  wire rd;
  wire wr;
  wire ben;
  wire [31:0] outbus;
  // ram
  wire ram_en;
  wire [19:0] ram_adr;
  // vid
  wire vid_en;
  wire [19:0] vid_adr;
  // i/o
  wire io_en;
  wire [3:0] io_adr;
  //ser
  wire ser_data_en;
  wire ser_ctrl_en;
  wire [31:0] ser_data;
  wire [31:0] ser_status;
  // bio
  wire bio_en;
  wire [31:0] bio_dout;

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk_rst clk_rst_1(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n),
    .clk_ok(clk_ok),
    .clk_75(pclk),
    .clk_25(clk),
    .rst(rst)
  );

  RISC5cpu cpu_1(
    .clk(clk),
    .rst(rst),
    .memwait(memwait),
    .inbus(inbus[31:0]),
    .codebus(inbus0[31:0]),
    .adr(adr[23:0]),
    .rd(rd),
    .wr(wr),
    .ben(ben),
    .outbus(outbus[31:0])
  );

  ram ram_1(
    .pclk(pclk),
    .clk(clk),
    .rst(rst),
    .adr(ram_adr[19:0]),
    .en(ram_en),
    .ben(ben),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(inbus0[31:0]),
    .memwait(memwait)
  );

  vid vid_1(
    .pclk(pclk),
    .clk(clk),
    .rst(rst),
    .en(vid_en),
    .wr(wr),
    .adr(vid_adr[16:2]),
    .din(outbus[31:0])
  );

  ser ser_1(
    .clk(clk),
    .rst(rst),
    .data_en(ser_data_en),
    .ctrl_en(ser_ctrl_en),
    .rd(rd),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(ser_data[31:0]),
    .status(ser_status[31:0])
  );

  bio bio_1(
    .clk(clk),
    .rst(rst),
    .en(bio_en),
    .wr(wr),
    .din(outbus[31:0]),
    .dout(bio_dout[31:0])
  );

  //--------------------------------------
  // address decoder
  //--------------------------------------

  assign ram_en = (adr[23:20] == 4'h0);
  assign ram_adr = adr[19:0];

  assign vid_en = (adr[23:20] == 4'h0) & (adr[19:0] >= 20'hE7F00);
  assign vid_adr = adr[19:0] - 20'hE7F00;

  assign io_en = (adr[23:6] == 18'h3FFFF);
  assign io_adr = adr[5:2];
  //assign tmr_en = io_en & (io_adr == 4'd0);
  assign bio_en = io_en & (io_adr == 4'd1);
  assign ser_data_en = io_en & (io_adr == 4'd2);
  assign ser_ctrl_en = io_en & (io_adr == 4'd3);
  //assign _en = io_en & (io_adr == 4'd4);
  //assign _en = io_en & (io_adr == 4'd5);
  //assign _en = io_en & (io_adr == 4'd6);
  //assign _en = io_en & (io_adr == 4'd7);

  //--------------------------------------
  // data multiplexer
  //--------------------------------------

  assign inbus[31:0] = ~io_en ? inbus0[31:0] :
                       //tmr_en ? tmr_dout[31:0] :
                       bio_en ? bio_dout[31:0] :
                       ser_data_en ? ser_data[31:0] :
                       ser_ctrl_en ? ser_status[31:0] :
                       // _en ? xx[31:0] :
                       // _en ? xx[31:0] :
                       // _en ? xx[31:0] :
                       // _en ? xx[31:0] :
                       32'h0;

endmodule