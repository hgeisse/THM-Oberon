//
// shift.v -- the shifters (lsl, asr/lsr, ror)
//


`timescale 1ns / 1ps
`default_nettype none


module lsl(value, shcnt, res);
    input [31:0] value;
    input [4:0] shcnt;
    output [31:0] res;

  reg [31:0] aux_0;
  reg [31:0] aux_1;

  always @(*) begin
    case (shcnt[1:0])
      2'b00: aux_0 = value[31:0];
      2'b01: aux_0 = { value[30:0], 1'b0 };
      2'b10: aux_0 = { value[29:0], 2'b0 };
      2'b11: aux_0 = { value[28:0], 3'b0 };
    endcase
  end
  always @(*) begin
    case (shcnt[3:2])
      2'b00: aux_1 = aux_0[31:0];
      2'b01: aux_1 = { aux_0[27:0],  4'b0 };
      2'b10: aux_1 = { aux_0[23:0],  8'b0 };
      2'b11: aux_1 = { aux_0[19:0], 12'b0 };
    endcase
  end
  assign res = ~shcnt[4] ? aux_1 : { aux_1[15:0], 16'b0 };

endmodule


module asr(op_unsigned, value, shcnt, res);
    input op_unsigned;
    input [31:0] value;
    input [4:0] shcnt;
    output [31:0] res;

  reg [31:0] aux_0;
  reg [31:0] aux_1;

  always @(*) begin
    case (shcnt[1:0])
      2'b00: aux_0 = value[31:0];
      2'b01: aux_0 = { {1{~op_unsigned & value[31]}}, value[31:1] };
      2'b10: aux_0 = { {2{~op_unsigned & value[31]}}, value[31:2] };
      2'b11: aux_0 = { {3{~op_unsigned & value[31]}}, value[31:3] };
    endcase
  end
  always @(*) begin
    case (shcnt[3:2])
      2'b00: aux_1 = aux_0[31:0];
      2'b01: aux_1 = { { 4{~op_unsigned & value[31]}}, aux_0[31: 4] };
      2'b10: aux_1 = { { 8{~op_unsigned & value[31]}}, aux_0[31: 8] };
      2'b11: aux_1 = { {12{~op_unsigned & value[31]}}, aux_0[31:12] };
    endcase
  end
  assign res = ~shcnt[4] ? aux_1 :
                           { {16{~op_unsigned & value[31]}}, aux_1[31:16] };

endmodule


module ror(value, shcnt, res);
    input [31:0] value;
    input [4:0] shcnt;
    output [31:0] res;

  reg [31:0] aux_0;
  reg [31:0] aux_1;

  always @(*) begin
    case (shcnt[1:0])
      2'b00: aux_0 = value[31:0];
      2'b01: aux_0 = { value[0:0], value[31:1] };
      2'b10: aux_0 = { value[1:0], value[31:2] };
      2'b11: aux_0 = { value[2:0], value[31:3] };
    endcase
  end
  always @(*) begin
    case (shcnt[3:2])
      2'b00: aux_1 = aux_0[31:0];
      2'b01: aux_1 = { aux_0[ 3:0], aux_0[31: 4] };
      2'b10: aux_1 = { aux_0[ 7:0], aux_0[31: 8] };
      2'b11: aux_1 = { aux_0[11:0], aux_0[31:12] };
    endcase
  end
  assign res = ~shcnt[4] ? aux_1 : { aux_1[15:0], aux_1[31:16] };

endmodule
