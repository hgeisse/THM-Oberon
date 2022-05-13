//
// RAM16X1D.v -- XILINX primitive
//


`timescale 1ns / 1ps
`default_nettype none


module RAM16X1D(DPO, SPO,
                A0, A1, A2, A3,
                D,
                DPRA0, DPRA1, DPRA2, DPRA3,
                WCLK, WE);
    parameter INIT = 16'h0000;
    output DPO, SPO;
    input  A0, A1, A2, A3, D, DPRA0, DPRA1, DPRA2, DPRA3, WCLK, WE;

  reg [15:0] mem;
  wire [3:0] adr;

  assign adr = { A3, A2, A1, A0 };
  assign SPO = mem[adr];
  assign DPO = mem[{ DPRA3, DPRA2, DPRA1, DPRA0 }];

  initial begin
    mem = INIT;
  end

  always @(posedge WCLK) begin
    if (WE == 1'b1) begin
      mem[adr] <= #1 D;
    end
  end

endmodule
