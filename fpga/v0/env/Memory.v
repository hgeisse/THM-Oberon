//
// Memory.v -- Main memory
//             1 MByte SRAM, organized as 256Kx32 Bit
//


`timescale 1ns / 1ps
`default_nettype none


module Memory(SRce0, SRce1, SRwe, SRoe,
              SRbe, SRadr, SRdat);
    input SRce0;
    input SRce1;
    input SRwe;
    input SRoe;
    input [3:0] SRbe;
    input [17:0] SRadr;
    inout [31:0] SRdat;

  SramChip ic0(
    .A(SRadr[17:0]),
    .CE_n(SRce0),
    .UB_n(SRbe[1]),
    .LB_n(SRbe[0]),
    .WE_n(SRwe),
    .OE_n(SRoe),
    .IO(SRdat[15:0])
  );

  SramChip ic1(
    .A(SRadr[17:0]),
    .CE_n(SRce1),
    .UB_n(SRbe[3]),
    .LB_n(SRbe[2]),
    .WE_n(SRwe),
    .OE_n(SRoe),
    .IO(SRdat[31:16])
  );

endmodule


//
// ISSI 256Kx16, 10 ns SRAM
//


module SramChip(A, CE_n, UB_n, LB_n, WE_n, OE_n, IO);
    input [17:0] A;
    input CE_n;
    input UB_n;
    input LB_n;
    input WE_n;
    input OE_n;
    inout [15:0] IO;

  reg [7:0] hiArray[0:262143];
  wire [7:0] hiOut;
  wire hiCtrl;

  reg [7:0] loArray[0:262143];
  wire [7:0] loOut;
  wire loCtrl;

  assign hiOut = hiArray[A];
  assign loOut = loArray[A];

  always @(negedge WE_n) begin
    if (~CE_n & ~UB_n) begin
      hiArray[A] <= IO[15:8];
    end
  end

  always @(negedge WE_n) begin
    if (~CE_n & ~LB_n) begin
      loArray[A] <= IO[7:0];
    end
  end

  assign hiCtrl = ~CE_n & WE_n & ~OE_n & ~UB_n;
  assign loCtrl = ~CE_n & WE_n & ~OE_n & ~LB_n;

  assign IO[15:8] = hiCtrl ? hiOut : 8'bzzzzzzzz;
  assign IO[ 7:0] = loCtrl ? loOut : 8'bzzzzzzzz;

endmodule
