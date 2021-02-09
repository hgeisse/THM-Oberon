//
// vid.v -- video controller for 1024x768 B/W screen
//


`timescale 1ns / 1ps
`default_nettype none


module vid(pclk, clk, rst,
           stb, we, addr, data_in,
           hsync, vsync, pxclk,
           sync_n, blank_n, r, g, b);
    // internal interface
    input pclk;
    input clk;
    input rst;
    input stb;
    input we;
    input [14:0] addr;
    input [31:0] data_in;
    // external interface;
    output reg hsync;
    output reg vsync;
    output pxclk;
    output sync_n;
    output blank_n;
    output [7:0] r;
    output [7:0] g;
    output [7:0] b;

  reg [31:0] video_mem[0:24575];

  //----------------------------
  // processor interface
  //----------------------------

  // the vertical address runs backwards
  // i.e., compute 767 - vert. address
  // (but keep the horizontal address)

  wire [14:0] rev_addr;

  assign rev_addr[14] = ~(addr[14] ^ addr[13]);
  assign rev_addr[13] = addr[13];
  assign rev_addr[12:5] = ~addr[12:5];
  assign rev_addr[4:0] = addr[4:0];

  always @(posedge clk) begin
    if (stb & we & ~(rev_addr[14] & rev_addr[13])) begin
      video_mem[rev_addr] <= data_in;
    end
  end

  //----------------------------
  // monitor interface
  //----------------------------

  // stage 0: timing generator

  reg [10:0] hcount_0;
  reg hblnk_0;
  reg hsync_0;

  reg [9:0] vcount_0;
  reg vblnk_0;
  reg vsync_0;

  wire [14:0] memaddr_0;
  wire [4:0] pixaddr_0;

  always @(posedge pclk) begin
    if (rst) begin
      hcount_0 <= 11'd0;
      hblnk_0 <= 1'b0;
      hsync_0 <= 1'b0;
    end else begin
      if (hcount_0 == 11'd1327) begin
        hcount_0 <= 11'd0;
        hblnk_0 <= 1'b0;
      end else begin
        hcount_0 <= hcount_0 + 11'd1;
      end
      if (hcount_0 == 11'd1023) begin
        hblnk_0 <= 1'b1;
      end
      if (hcount_0 == 11'd1047) begin
        hsync_0 <= 1'b1;
      end
      if (hcount_0 == 11'd1183) begin
        hsync_0 <= 1'b0;
      end
    end
  end

  always @(posedge pclk) begin
    if (rst) begin
      vcount_0 <= 10'd0;
      vblnk_0 <= 1'b0;
      vsync_0 <= 1'b0;
    end else begin
      if (hcount_0 == 11'd1327) begin
        if (vcount_0 == 10'd805) begin
          vcount_0 <= 10'd0;
          vblnk_0 <= 1'b0;
        end else begin
          vcount_0 <= vcount_0 + 10'd1;
        end
        if (vcount_0 == 10'd767) begin
          vblnk_0 <= 1'b1;
        end
        if (vcount_0 == 10'd770) begin
          vsync_0 <= 1'b1;
        end
        if (vcount_0 == 10'd776) begin
          vsync_0 <= 1'b0;
        end
      end
    end
  end

  assign memaddr_0[14:0] = { vcount_0[9:0], hcount_0[9:5] };
  assign pixaddr_0[4:0] = hcount_0[4:0];

  // stage 1: video memory access

  reg [31:0] viddat_1;
  reg hblnk_1;
  reg hsync_1;
  reg vblnk_1;
  reg vsync_1;
  reg [4:0] pixaddr_1;

  always @(posedge pclk) begin
    viddat_1 <= video_mem[memaddr_0];
  end

  always @(posedge pclk) begin
    hblnk_1 <= hblnk_0;
    hsync_1 <= hsync_0;
    vblnk_1 <= vblnk_0;
    vsync_1 <= vsync_0;
    pixaddr_1[4:0] <= pixaddr_0[4:0];
  end

  // stage 2: pixel shift register

  reg [31:0] psr_2;
  reg hblnk_2;
  reg hsync_2;
  reg vblnk_2;
  reg vsync_2;

  always @(posedge pclk) begin
    if (pixaddr_1 == 5'b00000) begin
      psr_2[31:0] <= viddat_1[31:0];
    end else begin
      psr_2[31:0] <= { 1'b0, psr_2[31:1] };
    end
  end

  always @(posedge pclk) begin
    hblnk_2 <= hblnk_1;
    hsync_2 <= hsync_1;
    vblnk_2 <= vblnk_1;
    vsync_2 <= vsync_1;
  end

  // hsync and vsync are directly connected to the monitor

  always @(posedge pclk) begin
    hsync <= ~hsync_2;
    vsync <= ~vsync_2;
  end

  // all other signals are passed through the registered DAC

  assign pxclk = pclk;
  assign sync_n = 1'b0;
  assign blank_n = ~hblnk_2 & ~vblnk_2;
  assign r[7:0] = ~blank_n ? 8'h00 : (psr_2[0] ? 8'h00 : 8'h7C);
  assign g[7:0] = ~blank_n ? 8'h00 : (psr_2[0] ? 8'h00 : 8'hD4);
  assign b[7:0] = ~blank_n ? 8'h00 : (psr_2[0] ? 8'h00 : 8'hD6);

endmodule
