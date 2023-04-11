//
// vx.v -- video experiment
//


`timescale 1ns/1ps
`default_nettype none


// screen resolution: 16 pixels x 12 pixels
// video memory organized as 4-bit nibbles
// horizontal blanking: 3 pixels
// vertical blanking: 2 pixels


module vx;

  //
  // simulation control
  //

  initial begin
    #0          $timeformat(-9, 1, " ns", 12);
                $dumpfile("dump.vcd");
                $dumpvars(0, vx);
    #5000       $finish;
  end

  //
  // clock
  //

  reg clk;

  initial begin
    #0  clk = 1'b0;
  end

  always begin
    #5  clk = ~clk;
  end

  //
  // video memory
  //

  reg [3:0] vmem[0:47];

  initial begin
    #0  vmem[ 0] = 4'hB;
        vmem[ 1] = 4'hE;
        vmem[ 2] = 4'h3;
        vmem[ 3] = 4'h3;
        vmem[ 4] = 4'h2;
        vmem[ 5] = 4'h7;
        vmem[ 6] = 4'h2;
        vmem[ 7] = 4'h7;
        vmem[ 8] = 4'h9;
        vmem[ 9] = 4'h6;
        vmem[10] = 4'h5;
        vmem[11] = 4'hD;
        vmem[12] = 4'hF;
        vmem[13] = 4'h7;
        vmem[14] = 4'hF;
        vmem[15] = 4'hA;
        vmem[16] = 4'h3;
        vmem[17] = 4'h6;
        vmem[18] = 4'h2;
        vmem[19] = 4'hF;
        vmem[20] = 4'h8;
        vmem[21] = 4'hF;
        vmem[22] = 4'hF;
        vmem[23] = 4'hC;
        vmem[24] = 4'hB;
        vmem[25] = 4'hA;
        vmem[26] = 4'h9;
        vmem[27] = 4'h3;
        vmem[28] = 4'h1;
        vmem[29] = 4'hC;
        vmem[30] = 4'h6;
        vmem[31] = 4'hC;
        vmem[32] = 4'hB;
        vmem[33] = 4'h9;
        vmem[34] = 4'h0;
        vmem[35] = 4'hD;
        vmem[36] = 4'h1;
        vmem[37] = 4'h2;
        vmem[38] = 4'h5;
        vmem[39] = 4'hA;
        vmem[40] = 4'h9;
        vmem[41] = 4'hA;
        vmem[42] = 4'h8;
        vmem[43] = 4'h8;
        vmem[44] = 4'h2;
        vmem[45] = 4'h7;
        vmem[46] = 4'h2;
        vmem[47] = 4'h6;
  end

  //
  // stage 0: timing generator
  //

  reg [4:0] hcount_0;
  reg hblank_0;
  reg [3:0] vcount_0;
  reg vblank_0;
  wire [5:0] memaddr_0;
  wire [1:0] pixaddr_0;

  initial begin
    #0  hcount_0 = 5'd18;
        hblank_0 = 1'b1;
        vcount_0 = 4'd13;
        vblank_0 = 1'b1;
  end

  always @(posedge clk) begin
    if (hcount_0 == 5'd18) begin
      hcount_0 <= 5'd0;
      hblank_0 <= 1'b0;
    end else begin
      hcount_0 <= hcount_0 + 5'd1;
    end
    if (hcount_0 == 5'd15) begin
      hblank_0 <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (hcount_0 == 5'd18) begin
      if (vcount_0 == 4'd13) begin
        vcount_0 <= 4'd0;
        vblank_0 <= 1'b0;
      end else begin
        vcount_0 <= vcount_0 + 4'd1;
      end
      if (vcount_0 == 4'd11) begin
        vblank_0 <= 1'b1;
      end
    end
  end

  assign memaddr_0[5:0] = { vcount_0[3:0], hcount_0[3:2] };
  assign pixaddr_0[1:0] = hcount_0[1:0];

  //
  // stage 1: video memory access
  //

  reg [3:0] vdat_1;
  reg hblank_1;
  reg vblank_1;
  reg [1:0] pixaddr_1;

  always @(posedge clk) begin
    vdat_1 <= vmem[memaddr_0];
  end

  always @(posedge clk) begin
    hblank_1 <= hblank_0;
    vblank_1 <= vblank_0;
    pixaddr_1[1:0] <= pixaddr_0[1:0];
  end

  //
  // stage 2: shift register
  //

  reg [3:0] sr_2;
  reg hblank_2;
  reg vblank_2;
  wire pixel_2;

  always @(posedge clk) begin
    if (pixaddr_1 == 2'b00) begin
      sr_2[3:0] <= vdat_1[3:0];
    end else begin
      sr_2[3:0] <= { 1'b0, sr_2[3:1] };
    end
  end

  always @(posedge clk) begin
    hblank_2 <= hblank_1;
    vblank_2 <= vblank_1;
  end

  assign pixel_2 = sr_2[0] & ~hblank_2 & ~vblank_2;

endmodule
