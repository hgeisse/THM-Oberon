//
// lcd.v -- LCD interface
//


`timescale 1ns / 1ps
`default_nettype none


module lcd(clk, rst,
           stb, we, addr,
           data_in, data_out, ack,
           lcd_on, lcd_en, lcd_rw, lcd_rs,
           lcd_data);
    // internal interface
    input clk;
    input rst;
    input stb;
    input we;
    input addr;
    input [31:0] data_in;
    output [31:0] data_out;
    output ack;
    //external interface
    output lcd_on;
    output lcd_en;
    output lcd_rw;
    output lcd_rs;
    inout [7:0] lcd_data;

  wire rd_data;
  wire wr_data;
  wire rd_ctrl;
  wire wr_ctrl;

  reg [7:0] data_ibuf;
  reg [7:0] data_obuf;
  reg ctrl_on;
  reg ctrl_en;
  reg ctrl_rw;
  reg ctrl_rs;

  assign rd_data = stb & ~we & ~addr;
  assign wr_data = stb &  we & ~addr;
  assign rd_ctrl = stb & ~we &  addr;
  assign wr_ctrl = stb &  we &  addr;

  always @(posedge clk) begin
    if (rst) begin
      data_ibuf[7:0] <= 8'h00;
    end else begin
      if (wr_data) begin
        data_ibuf[7:0] <= data_in[7:0];
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      data_obuf[7:0] <= 8'h00;
    end else begin
      if (ctrl_rw & ctrl_en) begin
        data_obuf[7:0] <= lcd_data[7:0];
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ctrl_on <= 1'b0;
      ctrl_en <= 1'b0;
      ctrl_rw <= 1'b0;
      ctrl_rs <= 1'b0;
    end else begin
      if (wr_ctrl) begin
        ctrl_on <= data_in[3];
        ctrl_en <= data_in[2];
        ctrl_rw <= data_in[1];
        ctrl_rs <= data_in[0];
      end
    end
  end

  assign data_out =
    rd_data ? { 24'h000000, data_obuf[7:0] } :
    rd_ctrl ? { 28'h0000000, ctrl_on, ctrl_en, ctrl_rw, ctrl_rs } :
    32'h00000000;

  assign ack = stb;

  //----------------------------

  assign lcd_on = ctrl_on;
  assign lcd_en = ctrl_en;
  assign lcd_rw = ctrl_rw;
  assign lcd_rs = ctrl_rs;

  assign lcd_data[7:0] = ctrl_rw ? 8'hzz : data_ibuf[7:0];

endmodule
