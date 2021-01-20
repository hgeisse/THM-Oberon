//
// asr.v -- arithmetic shift right
//


`timescale 1ns / 1ps
`default_nettype none


module asr(value, shcnt, res);
    input [31:0] value;
    input [4:0] shcnt;
    output [31:0] res;

  reg [31:0] aux_0;
  reg [31:0] aux_1;

  always @(*) begin
    case (shcnt[1:0])
      2'b00: aux_0 = value[31:0];
      2'b01: aux_0 = { {1{value[31]}}, value[31:1] };
      2'b10: aux_0 = { {2{value[31]}}, value[31:2] };
      2'b11: aux_0 = { {3{value[31]}}, value[31:3] };
    endcase
  end
  always @(*) begin
    case (shcnt[3:2])
      2'b00: aux_1 = aux_0[31:0];
      2'b01: aux_1 = { { 4{value[31]}}, aux_0[31: 4] };
      2'b10: aux_1 = { { 8{value[31]}}, aux_0[31: 8] };
      2'b11: aux_1 = { {12{value[31]}}, aux_0[31:12] };
    endcase
  end
  assign res = ~shcnt[4] ? aux_1 : { {16{value[31]}}, aux_1[31:16] };

endmodule
