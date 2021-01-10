//
// cpu.v -- the RISC5 CPU core
//


`timescale 1ns / 1ps
`default_nettype none


module cpu_core(clk, rst,
                bus_stb, bus_we, bus_ben, bus_addr,
                bus_din, bus_dout, bus_ack);
    input clk;				// system clock
    input rst;				// system reset
    output bus_stb;			// bus strobe
    output bus_we;			// bus write enable
    output bus_ben;			// 0: word, 1: byte
    output [23:0] bus_addr;		// bus address
    input [31:0] bus_din;		// bus data input, for reads
    output [31:0] bus_dout;		// bus data output, for writes
    input bus_ack;			// bus acknowledge

  // program counter
  wire [1:0] pc_src;		// pc source selector
  wire [23:0] pc_next;		// value written into pc
  wire pc_we;			// pc write enable
  reg [23:0] pc;		// program counter
  // bus
  // instruction register & decoder
  wire [31:0] instr;		// instruction
  wire ir_we;			// instruction register write enable
  reg [31:0] ir;		// instruction register
  wire [1:0] ir_pq;		// instr format pq
  wire ir_u;			// instr modifier u
  wire ir_v;			// instr modifier v
  wire [3:0] ir_a;		// instr register a
  wire [3:0] ir_b;		// instr register b
  wire [3:0] ir_c;		// instr register c
  wire [3:0] ir_op;		// instr operation
  wire [15:0] ir_imm;		// instr immediate
  // register file
  reg [31:0] regs[0:15];	// 16 32-bit registers
  wire [3:0] reg_a1;		// register address 1
  reg [31:0] reg_do1;		// register data out 1
  wire [1:0] reg_a2_src;	// register address 2 source selector
  wire [3:0] reg_a2;		// register address 2
  reg [31:0] reg_do2;		// register data out 2
  wire [31:0] reg_di2;		// register data in 2
  wire reg_we2;			// register write enable 2
  // alu
  wire alu_src1;		// alu source 1 selector
  wire [31:0] alu_op1;		// alu operand 1
  wire [1:0] alu_src2;		// alu source 2 selector
  wire [31:0] alu_op2;		// alu operand 2
  wire alu_add;			// alu add, regardless of ir_op
  wire [3:0] alu_fnc;		// alu function
  wire [31:0] alu_res;		// alu result
  reg [31:0] alu_out;		// alu result, 1 cycle delay

  //------------------------------------------------------------

  // program counter
  assign pc_next =
    (pc_src == 2'b00) ? 24'hFFE000 :	// reset
    (pc_src == 2'b01) ? alu_res[23:0] :	// next
    (pc_src == 2'b10) ? alu_out[23:0] :	// branch
    (pc_src == 2'b11) ? 24'hFFE000 :	// exception
    24'hxxxxxx;
  always @(posedge clk) begin
    if (pc_we) begin
      pc <= pc_next;
    end
  end

  // bus
  assign bus_addr = pc;

  // instruction register & decoder
  assign instr = bus_din;
  always @(posedge clk) begin
    if (ir_we) begin
      ir <= instr;
    end
  end
  assign ir_pq = ir[31:30];
  assign ir_u = ir[29];
  assign ir_v = ir[28];
  assign ir_a = ir[27:24];
  assign ir_b = ir[23:20];
  assign ir_c = ir[3:0];
  assign ir_op = ir[19:16];
  assign ir_imm = ir[15:0];

  // !!!!! delete me !!!!!
  initial begin
    regs[ 0] = 32'h00000000;
    regs[ 1] = 32'h11111111;
    regs[ 2] = 32'h22222222;
    regs[ 3] = 32'h33333333;
    regs[ 4] = 32'h44444444;
    regs[ 5] = 32'h55555555;
    regs[ 6] = 32'h66666666;
    regs[ 7] = 32'h77777777;
    regs[ 8] = 32'h88888888;
    regs[ 9] = 32'h99999999;
    regs[10] = 32'haaaaaaaa;
    regs[11] = 32'hbbbbbbbb;
    regs[12] = 32'hcccccccc;
    regs[13] = 32'hdddddddd;
    regs[14] = 32'heeeeeeee;
    regs[15] = 32'hffffffff;
  end

  // register file
  assign reg_a1 = ir_b;
  assign reg_a2 =
    (reg_a2_src == 2'b00) ? ir_c :	// arith: op2
    (reg_a2_src == 2'b01) ? ir_a :	// arith or load: dst, store: src
    (reg_a2_src == 2'b10) ? 4'hF :	// call: link
    4'hx;
  assign reg_di2 = alu_out;
  always @(posedge clk) begin
    reg_do1 <= regs[reg_a1];
    reg_do2 <= regs[reg_a2];
    if (reg_we2) begin
      regs[reg_a2] <= reg_di2;
    end
  end

  // alu
  assign alu_op1 = (alu_src1 == 1'b0) ? { 8'h00, pc } : reg_do1;
  assign alu_op2 =
    (alu_src2 == 2'b00) ? 32'h00000004 :
    (alu_src2 == 2'b01) ? reg_do2 :
    (alu_src2 == 2'b10) ? { {16{ir_v}}, ir_imm } :
    32'hxxxxxxxx;
  assign alu_fnc = alu_add ? 4'h8 : ir_op;
  alu alu_0(
    .op1(alu_op1),
    .op2(alu_op2),
    .fnc(alu_fnc),
    .res(alu_res)
  );
  always @(posedge clk) begin
    alu_out <= alu_res;
  end

  // ctrl
  ctrl ctrl_0(
    .clk(clk),
    .rst(rst),
    .ir_pq(ir_pq),
    .bus_ack(bus_ack),
    .pc_src(pc_src),
    .pc_we(pc_we),
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_ben(bus_ben),
    .ir_we(ir_we),
    .reg_a2_src(reg_a2_src),
    .reg_we2(reg_we2),
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .alu_add(alu_add)
  );

endmodule


//--------------------------------------------------------------
// alu -- arithmetic/logic unit, shifter, floating-point
//--------------------------------------------------------------


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


module alu(op1, op2, fnc, res);
    input [31:0] op1;
    input [31:0] op2;
    input [3:0] fnc;
    output reg [31:0] res;

  wire [31:0] lsl_res;
  wire [31:0] asr_res;
  wire [31:0] ror_res;

  lsl lsl_0(
    .value(op1),
    .shcnt(op2[4:0]),
    .res(lsl_res)
  );

  asr asr_0(
    .value(op1),
    .shcnt(op2[4:0]),
    .res(asr_res)
  );

  ror ror_0(
    .value(op1),
    .shcnt(op2[4:0]),
    .res(ror_res)
  );

  always @(*) begin
    case (fnc)
      4'h0: res = op2;
      4'h1: res = lsl_res;
      4'h2: res = asr_res;
      4'h3: res = ror_res;
      4'h4: res = op1 & op2;
      4'h5: res = op1 & ~op2;
      4'h6: res = op1 | op2;
      4'h7: res = op1 ^ op2;
      4'h8: res = op1 + op2;
      4'h9: res = op1 - op2;
      4'hA: res = 32'hxxxxxxxx;
      4'hB: res = 32'hxxxxxxxx;
      4'hC: res = 32'hxxxxxxxx;
      4'hD: res = 32'hxxxxxxxx;
      4'hE: res = 32'hxxxxxxxx;
      4'hF: res = 32'hxxxxxxxx;
    endcase
  end

endmodule


//--------------------------------------------------------------
// ctrl -- instruction fetch/execute controller
//--------------------------------------------------------------


module ctrl(clk, rst,
            ir_pq,
            bus_ack,
            pc_src, pc_we,
            bus_stb, bus_we, bus_ben,
            ir_we,
            reg_a2_src, reg_we2,
            alu_src1, alu_src2, alu_add);
    input clk;
    input rst;
    input [1:0] ir_pq;
    input bus_ack;
    output reg [1:0] pc_src;
    output reg pc_we;
    output reg bus_stb;
    output reg bus_we;
    output reg bus_ben;
    output reg ir_we;
    output reg reg_we2;
    output reg [1:0] reg_a2_src;
    output reg alu_src1;
    output reg [1:0] alu_src2;
    output reg alu_add;

  reg [3:0] state;
  reg [3:0] next_state;

  // state machine
  always @(posedge clk) begin
    if (rst) begin
      state <= 4'd0;
    end else begin
      state <= next_state;
    end
  end

  // output logic
  always @(*) begin
    case (state)
      4'd0:  // reset
        begin
          next_state = 4'd1;
          pc_src = 2'b00;
          pc_we = 1'b1;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
      4'd1:  // fetch instr, inc pc by 4
        begin
          if (~bus_ack) begin
            next_state = 4'd1;
          end else begin
            next_state = 4'd2;
          end
          pc_src = 2'b01;
          if (~bus_ack) begin
            pc_we = 1'b0;
          end else begin
            pc_we = 1'b1;
          end
          bus_stb = 1'b1;
          bus_we = 1'b0;
          bus_ben = 1'b0;
          if (~bus_ack) begin
            ir_we = 1'b0;
          end else begin
            ir_we = 1'b1;
          end
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'b0;
          alu_src2 = 2'b00;
          alu_add = 1'b1;
        end
      4'd2:  // decode, fetch register operands
        begin
          case (ir_pq)
            2'b00:  // register/register instructions
              begin
                next_state = 4'd3;
              end
            2'b01:  // register/immediate instructions
              begin
                next_state = 4'd5;
              end
            2'b10:  // memory instructions
              begin
                next_state = 4'd12;
              end
            2'b11:  // branch instructions
              begin
                next_state = 4'd14;
              end
          endcase
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'b00;
          reg_we2 = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
      4'd3:  // format 0 execute
        begin
          next_state = 4'd4;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'b1;
          alu_src2 = 2'b01;
          alu_add = 1'b0;
        end
      4'd4:  // format 0 writeback
        begin
          next_state = 4'd1;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_we2 = 1'b1;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
      4'd5:  // format 1 execute
        begin
          next_state = 4'd6;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'b1;
          alu_src2 = 2'b10;
          alu_add = 1'b0;
        end
      4'd6:  // format 1 writeback
        begin
          next_state = 4'd1;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_we2 = 1'b1;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
      4'd12:  // halt: format 2 (memory)
        begin
          next_state = 4'd12;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
      4'd14:  // halt: format 3 (branch)
        begin
          next_state = 4'd14;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
      default:  // all other states: unused
        begin
          next_state = 4'd0;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 2'bxx;
          alu_add = 1'bx;
        end
    endcase
  end

endmodule
