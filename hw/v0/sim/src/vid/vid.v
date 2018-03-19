//
// vid.v -- video controller for 1024x768 B/W screen
//


`timescale 1ns/1ps
`default_nettype none


module vid(clk, rst, pclk);
    input clk;
    input rst;
    input pclk;

  reg [31:0] vidmem[0:24575];

  //
  // processor interface
  //

  //
  // monitor interface
  //

  reg [10:0] hcount;
  reg hblank;
  reg hsynch;

  reg [9:0] vcount;
  reg vblank;
  reg vsynch;

  always @(posedge pclk) begin
    if (rst) begin
      hcount <= 11'd0;
      hblank <= 1'b0;
      hsynch <= 1'b0;
    end else begin
      if (hcount == 11'd1327) begin
        hcount <= 11'd0;
        hblank <= 1'b0;
      end else begin
        hcount <= hcount + 11'd1;
      end
      if (hcount == 11'd1023) begin
        hblank <= 1'b1;
      end
      if (hcount == 11'd1047) begin
        hsynch <= 1'b1;
      end
      if (hcount == 11'd1183) begin
        hsynch <= 1'b0;
      end
    end
  end

  always @(posedge pclk) begin
    if (rst) begin
      vcount <= 10'd0;
      vblank <= 1'b0;
      vsynch <= 1'b0;
    end else begin
      if (hcount == 11'd1327) begin
        if (vcount == 10'd805) begin
          vcount <= 10'd0;
          vblank <= 1'b0;
        end else begin
          vcount <= vcount + 10'd1;
        end
        if (vcount == 10'd767) begin
          vblank <= 1'b1;
        end
        if (vcount == 10'd770) begin
          vsynch <= 1'b1;
        end
        if (vcount == 10'd776) begin
          vsynch <= 1'b0;
        end
      end
    end
  end

endmodule
