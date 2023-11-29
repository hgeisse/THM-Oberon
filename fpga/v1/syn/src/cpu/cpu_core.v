//
// cpu_core.v -- the RISC5 CPU core
//


`timescale 1ns / 1ps
`default_nettype none


`define CPU_ID	{ 24'h000000, 8'h81 }	// Version = 8.1


module cpu_core(clk, rst,
                bus_stb, bus_we, bus_ben, bus_addr,
                bus_din, bus_dout, bus_ack, bus_irq);
    input clk;				// system clock
    input rst;				// system reset
    output bus_stb;			// bus strobe
    output bus_we;			// bus write enable
    output [1:0] bus_ben;		// 00: word, 01: half, 10: byte
    output [23:0] bus_addr;		// bus address
    input [31:0] bus_din;		// bus data input, for reads
    output [31:0] bus_dout;		// bus data output, for writes
    input bus_ack;			// bus acknowledge
    input [15:0] bus_irq;		// bus interrupt requests

  // program counter
  wire [1:0] pc_src;		// pc source selector
  wire [23:0] pc_next;		// value written into pc
  wire pc_we;			// pc write enable
  reg [23:0] pc;		// program counter
  // bus
  wire [1:0] aux_ben;		// auxiliary byte enable from ctrl
  wire bus_addr_src;		// bus address source selector
  // instruction register & decoder
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
  wire [19:0] ir_off;		// instr data offset
  wire [21:0] ir_dist;		// instr branch distance
  wire [3:0] ir_ctrl;		// instr control code
  // data register
  reg [31:0] dr;		// data register
  // register file
  reg [31:0] regs[0:15];	// 16 32-bit registers
  wire [3:0] reg_a1;		// register address 1
  reg [31:0] reg_do1;		// register data out 1
  wire [1:0] reg_a2_src;	// register address 2 source selector
  wire [3:0] reg_a2;		// register address 2
  reg [31:0] reg_do2;		// register data out 2
  wire reg_di2_src;		// register data in 2 source selector
  wire [31:0] reg_di2;		// register data in 2
  wire reg_we2;			// register write enable 2
  // special registers
  reg [31:0] ID;		// special register ID
  reg [31:0] H;			// special register H
  reg [31:0] X;			// special register X
  reg N;			// flag register "negative"
  reg Z;			// flag register "zero"
  reg C;			// flag register "carry"
  reg V;			// flag register "overflow"
  reg I;			// interrupt enable flag
  reg P;			// previous interrupt enable flag
  reg [4:0] ACK;		// interrupt most recently acknowledged
  reg [15:0] MASK;		// interrupt request mask
  wire put_spc;			// put special register
  wire reg_set_H;		// set register H
  wire reg_set_NZ;		// set flags N, Z
  wire reg_set_CV;		// set flags C, V
  wire reg_set_I;		// set flag I
  wire irq_ack;			// interrupt acknowledge
  wire irq_ret;			// interrupt return
  // alu
  wire alu_run;			// signal to start alu running
  wire alu_stall;		// alu needs additional clock cycles
  wire alu_src1;		// alu source 1 selector
  wire [31:0] alu_op1;		// alu operand 1
  wire [31:0] alu_imm0;		// alu immediate data from 16 bits imm
  wire [31:0] alu_imm1;		// alu immediate data from 20 bits off
  wire [31:0] alu_imm2;		// alu immediate data from 22 bits dist
  wire [31:0] alu_imm3;		// alu immediate data from 16 bits imm << 16
  wire [31:0] alu_spc;		// alu special register value
  wire [2:0] alu_src2;		// alu source 2 selector
  wire [31:0] alu_op2;		// alu operand 2
  wire [3:0] alu_fnc;		// alu function
  wire [31:0] alu_res;		// alu result
  wire [31:0] alu_out;		// alu result, 1 cycle delay
  wire alu_out_C;		// alu carry, 1 cycle delay
  wire alu_out_V;		// alu overflow, 1 cycle delay
  wire [31:0] alu_out_H;	// alu auxiliary result, 1 cycle delay
  // branch unit
  reg cond;			// condition is true
  wire branch;			// take the branch
  // interrupt unit
  wire [15:0] irq_pend;		// the vector of pending unmasked irqs
  reg [3:0] irq_prio;		// number of highest pending interrupt
  wire interrupt;		// accept the highest pending interrupt

  //------------------------------------------------------------

  // program counter
  assign pc_next =
    (pc_src == 2'b00) ? 24'hFFE000 :		// reset
    (pc_src == 2'b01) ? alu_res[23:0] :		// next instr, branch
    (pc_src == 2'b10) ? 24'h000004 :		// interrupt acknowledge
    (pc_src == 2'b11) ? X[23:0] :		// interrupt return
    24'hxxxxxx;
  always @(posedge clk) begin
    if (pc_we) begin
      pc <= pc_next;
    end
  end

  // bus
  assign bus_ben = { aux_ben[1], aux_ben[0] & ir[0] };
  assign bus_addr =
    (bus_addr_src == 1'b0) ? pc :		// instr fetch
    (bus_addr_src == 1'b1) ? alu_out[23:0] :	// data load/store
    24'hxxxxxx;
  assign bus_dout = reg_do2;

  // instruction register & decoder
  always @(posedge clk) begin
    if (ir_we) begin
      ir <= bus_din;
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
  assign ir_off = ir[19:0];
  assign ir_dist = ir[21:0];
  assign ir_ctrl = ir[7:4];

  // data register
  always @(posedge clk) begin
    dr <= bus_din;
  end

  // register file
  assign reg_a1 = ir_b;
  assign reg_a2 =
    (reg_a2_src == 2'b00) ? ir_c :		// arith: op2
    (reg_a2_src == 2'b01) ? ir_a :		// arith: dst, store: src
    (reg_a2_src == 2'b10) ? 4'hF :		// call: link
    4'hx;
  assign reg_di2 =
    (reg_di2_src == 1'b0) ? alu_out :		// data from ALU
    (reg_di2_src == 1'b1) ? dr :		// data from bus
    32'hxxxxxxxx;
  always @(posedge clk) begin
    reg_do1 <= regs[reg_a1];
    reg_do2 <= regs[reg_a2];
    if (reg_we2) begin
      regs[reg_a2] <= reg_di2;
    end
  end

  // special registers
  always @(posedge clk) begin
    // ID
    if (rst) begin
      ID <= `CPU_ID;
    end else begin
      // nothing to do, this register is read-only
    end
    // H
    if (rst) begin
      H <= 32'h00000000;
    end else begin
      if (put_spc & (ir_c == 4'h1)) begin
        H <= reg_do2;
      end
      if (reg_set_H) begin
        H <= alu_out_H;
      end
    end
    // X
    if (rst) begin
      X <= 32'h00000000;
    end else begin
      if (put_spc & (ir_c == 4'h2)) begin
        X <= reg_do2;
      end
      if (irq_ack) begin
        X <= { 8'h00, pc[23:0] };
      end
    end
    // PSW
    if (rst) begin
      N <= 1'b0;
      Z <= 1'b0;
      C <= 1'b0;
      V <= 1'b0;
      I <= 1'b0;
      P <= 1'b0;
      ACK <= 5'b00000;
      MASK <= 16'h0000;
    end else begin
      if (put_spc & (ir_c == 4'h3)) begin
        N <= reg_do2[31];
        Z <= reg_do2[30];
        C <= reg_do2[29];
        V <= reg_do2[28];
        I <= reg_do2[27];
        P <= reg_do2[26];
        ACK <= reg_do2[20:16];
        MASK <= reg_do2[15:0];
      end
      if (reg_set_NZ) begin
        N <= reg_di2[31];
        Z <= ~|reg_di2[31:0];
      end
      if (reg_set_CV) begin
        C <= alu_out_C;
        V <= alu_out_V;
      end
      if (reg_set_I) begin
        I <= ir[0];
      end
      if (irq_ack) begin
        I <= 1'b0;
        P <= I;
        ACK <= { 1'b0, irq_prio[3:0] };
      end
      if (irq_ret) begin
        I <= P;
      end
    end
  end

  // alu
  assign alu_op1 =
    (alu_src1 == 1'b0) ? { 8'h00, pc } :	// next instr, branch
    (alu_src1 == 1'b1) ? reg_do1 :		// arith, eff. memory addr
    32'hxxxxxxxx;
  assign alu_imm0 = { {16{ir_v}}, ir_imm };
  assign alu_imm1 = { {12{ir_off[19]}}, ir_off };
  assign alu_imm2 = { 8'h00, ir_dist, 2'b00 };
  assign alu_imm3 = { ir_imm, 16'h0000 };
  assign alu_spc =
    (ir_c == 4'h0) ? ID :
    (ir_c == 4'h1) ? H :
    (ir_c == 4'h2) ? X :
    (ir_c == 4'h3) ? { N, Z, C, V, I, P, 5'h00, ACK[4:0], MASK[15:0] } :
    32'hxxxxxxxx;
  assign alu_op2 =
    (alu_src2 == 3'b000) ? 32'h00000004 :	// next instr
    (alu_src2 == 3'b001) ? reg_do2 :		// arithmetic
    (alu_src2 == 3'b010) ? alu_imm0 :		// immediate data
    (alu_src2 == 3'b011) ? alu_imm1 :		// memory offset
    (alu_src2 == 3'b100) ? alu_imm2 :		// branch distance
    (alu_src2 == 3'b101) ? alu_imm3 :		// immediate data << 16
    (alu_src2 == 3'b110) ? alu_spc :		// special register
    32'hxxxxxxxx;
  alu alu_0(
    .clk(clk),
    .run(alu_run),
    .stall(alu_stall),
    .op1(alu_op1),
    .op2(alu_op2),
    .cin(C),
    .fnc(alu_fnc),
    .ir_u(ir_u),
    .ir_v(ir_v),
    .res(alu_res),
    .out(alu_out),
    .out_C(alu_out_C),
    .out_V(alu_out_V),
    .out_H(alu_out_H)
  );

  // branch logic
  always @(*) begin
    case (ir_a[2:0])
      4'h0:  cond = N;
      4'h1:  cond = Z;
      4'h2:  cond = C;
      4'h3:  cond = V;
      4'h4:  cond = C | Z;
      4'h5:  cond = N ^ V;
      4'h6:  cond = (N ^ V) | Z;
      4'h7:  cond = 1'b1;
    endcase
  end
  assign branch = ir_a[3] ^ cond;

  // interrupt logic
  assign irq_pend = bus_irq[15:0] & MASK[15:0];
  always @(*) begin
    if ((| irq_pend[15:8]) != 0) begin
      if ((| irq_pend[15:12]) != 0) begin
        if ((| irq_pend[15:14]) != 0) begin
          if (irq_pend[15] != 0) begin
            irq_prio = 4'd15;
          end else begin
            irq_prio = 4'd14;
          end
        end else begin
          if (irq_pend[13] != 0) begin
            irq_prio = 4'd13;
          end else begin
            irq_prio = 4'd12;
          end
        end
      end else begin
        if ((| irq_pend[11:10]) != 0) begin
          if (irq_pend[11] != 0) begin
            irq_prio = 4'd11;
          end else begin
            irq_prio = 4'd10;
          end
        end else begin
          if (irq_pend[9] != 0) begin
            irq_prio = 4'd9;
          end else begin
            irq_prio = 4'd8;
          end
        end
      end
    end else begin
      if ((| irq_pend[7:4]) != 0) begin
        if ((| irq_pend[7:6]) != 0) begin
          if (irq_pend[7] != 0) begin
            irq_prio = 4'd7;
          end else begin
            irq_prio = 4'd6;
          end
        end else begin
          if (irq_pend[5] != 0) begin
            irq_prio = 4'd5;
          end else begin
            irq_prio = 4'd4;
          end
        end
      end else begin
        if ((| irq_pend[3:2]) != 0) begin
          if (irq_pend[3] != 0) begin
            irq_prio = 4'd3;
          end else begin
            irq_prio = 4'd2;
          end
        end else begin
          if (irq_pend[1] != 0) begin
            irq_prio = 4'd1;
          end else begin
            irq_prio = 4'd0;
          end
        end
      end
    end
  end
  assign interrupt = (| irq_pend) & I;

  // ctrl
  ctrl ctrl_0(
    .clk(clk),
    .rst(rst),
    .ir_pq(ir_pq),
    .ir_u(ir_u),
    .ir_v(ir_v),
    .ir_op(ir_op),
    .ir_ctrl(ir_ctrl),
    .bus_ack(bus_ack),
    .alu_stall(alu_stall),
    .branch(branch),
    .interrupt(interrupt),
    .pc_src(pc_src),
    .pc_we(pc_we),
    .bus_addr_src(bus_addr_src),
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_ben(aux_ben[1:0]),
    .ir_we(ir_we),
    .reg_a2_src(reg_a2_src),
    .reg_di2_src(reg_di2_src),
    .reg_we2(reg_we2),
    .put_spc(put_spc),
    .reg_set_H(reg_set_H),
    .reg_set_NZ(reg_set_NZ),
    .reg_set_CV(reg_set_CV),
    .reg_set_I(reg_set_I),
    .irq_ack(irq_ack),
    .irq_ret(irq_ret),
    .alu_run(alu_run),
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .alu_fnc(alu_fnc)
  );

endmodule


//--------------------------------------------------------------
// alu -- arithmetic/logic unit, shifter, floating-point
//--------------------------------------------------------------


module alu(clk, run, stall,
           op1, op2, cin, fnc, ir_u, ir_v,
           res, out, out_C, out_V, out_H);
    input clk;
    input run;
    output stall;
    input [31:0] op1;
    input [31:0] op2;
    input cin;
    input [3:0] fnc;
    input ir_u;
    input ir_v;
    output reg [31:0] res;
    output reg [31:0] out;
    output reg out_C;
    output reg out_V;
    output reg [31:0] out_H;

  wire [31:0] lsl_res;
  wire [31:0] asr_res;
  wire [31:0] ror_res;
  wire mul_stall;
  wire [31:0] mul_res_hi;
  wire [31:0] mul_res_lo;
  wire div_stall;
  wire [31:0] div_res_quo;
  wire [31:0] div_res_rem;
  wire fpadd_stall;
  wire [31:0] fpadd_res;
  wire fpmul_stall;
  wire [31:0] fpmul_res;
  wire fpdiv_stall;
  wire [31:0] fpdiv_res;
  wire [31:0] op3;
  wire x, y, z;
  wire res_C;
  wire res_V;
  wire [31:0] res_H;

  lsl lsl_0(
    .value(op1),
    .shcnt(op2[4:0]),
    .res(lsl_res)
  );

  asr asr_0(
    .op_unsigned(ir_u),
    .value(op1),
    .shcnt(op2[4:0]),
    .res(asr_res)
  );

  ror ror_0(
    .value(op1),
    .shcnt(op2[4:0]),
    .res(ror_res)
  );

  mul mul_0(
    .clk(clk),
    .run(run & (fnc == 4'hA)),
    .stall(mul_stall),
    .op_unsigned(ir_u),
    .x(op1),
    .y(op2),
    .zhi(mul_res_hi),
    .zlo(mul_res_lo)
  );

  div div_0(
    .clk(clk),
    .run(run & (fnc == 4'hB)),
    .stall(div_stall),
    .op_unsigned(ir_u),
    .x(op1),
    .y(op2),
    .quo(div_res_quo),
    .rem(div_res_rem)
  );

  fpadd fpadd_0(
    .clk(clk),
    .run(run & ((fnc == 4'hC) | (fnc == 4'hD))),
    .stall(fpadd_stall),
    .op(fnc == 4'hD ? 2'b11 : { ir_u, ir_v }),
    .x(op1),
    .y(op2),
    .z(fpadd_res)
  );

  fpmul fpmul_0(
    .clk(clk),
    .run(run & (fnc == 4'hE)),
    .stall(fpmul_stall),
    .x(op1),
    .y(op2),
    .z(fpmul_res)
  );

  fpdiv fpdiv_0(
    .clk(clk),
    .run(run & (fnc == 4'hF)),
    .stall(fpdiv_stall),
    .x(op1),
    .y(op2),
    .z(fpdiv_res)
  );

  assign stall = mul_stall | div_stall |
                 fpadd_stall | fpmul_stall | fpdiv_stall;

  assign op3 = { 31'b0, run & ir_u & cin };
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
      4'h8: res = op1 + op2 + op3;
      4'h9: res = op1 - op2 - op3;
      4'hA: res = mul_res_lo;
      4'hB: res = div_res_quo;
      4'hC: res = fpadd_res;
      4'hD: res = fpadd_res;
      4'hE: res = fpmul_res;
      4'hF: res = fpdiv_res;
    endcase
  end

  always @(posedge clk) begin
    out <= res;
  end

  assign x = op1[31];
  assign y = op2[31];
  assign z = res[31];
  assign res_C =
    (fnc == 4'h8) ? (x & y) | (x & ~z) | (y & ~z) :
    (fnc == 4'h9) ? (~x & y) | (~x & z) | (y & z) :
    1'bx;
  assign res_V =
    (fnc == 4'h8) ? (~x & ~y & z) | (x & y & ~z) :
    (fnc == 4'h9) ? (~x & y & z) | (x & ~y & ~z) :
    1'bx;
  assign res_H =
    (fnc == 4'hA) ? mul_res_hi :
    (fnc == 4'hB) ? div_res_rem :
    32'hxxxxxxxx;

  always @(posedge clk) begin
    out_C <= res_C;
    out_V <= res_V;
    out_H <= res_H;
  end

endmodule


//--------------------------------------------------------------
// ctrl -- instruction fetch/execute controller
//--------------------------------------------------------------


module ctrl(clk, rst,
            ir_pq, ir_u, ir_v, ir_op, ir_ctrl,
            bus_ack, alu_stall, branch, interrupt,
            pc_src, pc_we,
            bus_addr_src, bus_stb, bus_we, bus_ben,
            ir_we, reg_a2_src, reg_di2_src, reg_we2,
            put_spc, reg_set_H, reg_set_NZ, reg_set_CV,
            reg_set_I, irq_ack, irq_ret,
            alu_run, alu_src1, alu_src2, alu_fnc);
    input clk;
    input rst;
    input [1:0] ir_pq;
    input ir_u;
    input ir_v;
    input [3:0] ir_op;
    input [3:0] ir_ctrl;
    input bus_ack;
    input alu_stall;
    input branch;
    input interrupt;
    output reg [1:0] pc_src;
    output reg pc_we;
    output reg bus_addr_src;
    output reg bus_stb;
    output reg bus_we;
    output reg [1:0] bus_ben;
    output reg ir_we;
    output reg [1:0] reg_a2_src;
    output reg reg_di2_src;
    output reg reg_we2;
    output reg put_spc;
    output reg reg_set_H;
    output reg reg_set_NZ;
    output reg reg_set_CV;
    output reg reg_set_I;
    output reg irq_ack;
    output reg irq_ret;
    output reg alu_run;
    output reg alu_src1;
    output reg [2:0] alu_src2;
    output reg [3:0] alu_fnc;

  reg [4:0] state;
  reg [4:0] next_state;

  wire add_or_sub;
  wire mul_or_div;

  // state machine
  always @(posedge clk) begin
    if (rst) begin
      state <= 5'd0;
    end else begin
      state <= next_state;
    end
  end

  // output logic
  assign add_or_sub = (ir_op == 4'h8) | (ir_op == 4'h9);
  assign mul_or_div = (ir_op == 4'hA) | (ir_op == 4'hB);
  always @(*) begin
    case (state)
      5'd0:  // reset
        begin
          next_state = 5'd1;
          pc_src = 2'b00;
          pc_we = 1'b1;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd1:  // fetch instr
        begin
          if (~bus_ack) begin
            next_state = 5'd1;
          end else begin
            next_state = 5'd2;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'b0;
          bus_stb = 1'b1;
          bus_we = 1'b0;
          bus_ben = 2'b00;
          if (~bus_ack) begin
            ir_we = 1'b0;
          end else begin
            ir_we = 1'b1;
          end
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd2:  // inc pc by 4, decode instr, fetch register operands
        begin
          case (ir_pq)
            2'b00:  // format 0: register/register instructions
              begin
                if (ir_u & ~ir_v & (ir_op == 4'h0)) begin
                  // special case: put special register
                  next_state = 5'd13;
                end else begin
                  // normal format 0, including get special register
                  next_state = 5'd3;
                end
              end
            2'b01:  // format 1: register/immediate instructions
              begin
                next_state = 5'd5;
              end
            2'b10:  // format 2: memory instructions
              begin
                next_state = 5'd7;
              end
            2'b11:  // format 3: branch or ctrl instructions
              begin
                if (~ir_u) begin
                  // branch target is in register, or ctrl instruction
                  if (~ir_v) begin
                    // branch or ctrl
                    case (ir_ctrl[3:0])
                      4'h0:  // branch
                        begin
                          next_state = 5'd11;
                        end
                      4'h1:  // return from interrupt
                        begin
                          next_state = 5'd17;
                        end
                      4'h2:  // interrupt disable/enable
                        begin
                          next_state = 5'd15;
                        end
                      default:  // ignore illegal instructions
                        begin
                          next_state = 5'd1;
                        end
                    endcase
                  end else begin
                    // call
                    next_state = 5'd11;
                  end
                end else begin
                  // branch target is sum of pc and immediate distance
                  next_state = 5'd12;
                end
              end
          endcase
          pc_src = 2'b01;
          pc_we = 1'b1;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b00;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'b0;
          alu_src2 = 3'b000;
          alu_fnc = 4'h8;
        end
      5'd3:  // format 0: execute
        begin
          if (alu_stall) begin
            next_state = 5'd3;
          end else begin
            next_state = 5'd4;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b00;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b1;
          alu_src1 = 1'b1;
          if ((ir_op == 4'h0) & ir_u) begin
            // special register
            alu_src2 = 3'b110;
          end else begin
            // general register
            alu_src2 = 3'b001;
          end
          alu_fnc = ir_op;
        end
      5'd4:  // format 0: write-back
        begin
          if (interrupt) begin
            next_state = 5'd16;
          end else begin
            next_state = 5'd1;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_di2_src = 1'b0;
          reg_we2 = 1'b1;
          put_spc = 1'b0;
          reg_set_H = mul_or_div;
          reg_set_NZ = 1'b1;
          reg_set_CV = add_or_sub;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd5:  // format 1: execute
        begin
          if (alu_stall) begin
            next_state = 5'd5;
          end else begin
            next_state = 5'd6;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b00;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b1;
          alu_src1 = 1'b1;
          if ((ir_op == 4'h0) & ir_u) begin
            // imm << 16
            alu_src2 = 3'b101;
          end else begin
            // imm
            alu_src2 = 3'b010;
          end
          alu_fnc = ir_op;
        end
      5'd6:  // format 1: write-back
        begin
          if (interrupt) begin
            next_state = 5'd16;
          end else begin
            next_state = 5'd1;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_di2_src = 1'b0;
          reg_we2 = 1'b1;
          put_spc = 1'b0;
          reg_set_H = mul_or_div;
          reg_set_NZ = 1'b1;
          reg_set_CV = add_or_sub;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd7:  // format 2: address calculation
        begin
          if (~ir_u) begin
            // load
            next_state = 5'd8;
          end else begin
            // store
            next_state = 5'd10;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'b1;
          alu_src2 = 3'b011;
          alu_fnc = 4'h8;
        end
      5'd8:  // format 2 (load): bus read
        begin
          if (~bus_ack) begin
            next_state = 5'd8;
          end else begin
            next_state = 5'd9;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'b1;
          bus_stb = 1'b1;
          bus_we = 1'b0;
          bus_ben = (ir_v ? 2'b10 : 2'b01);
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'b1;
          alu_src2 = 3'b011;
          alu_fnc = 4'h8;
        end
      5'd9:  // format 2 (load): write-back
        begin
          if (interrupt) begin
            next_state = 5'd16;
          end else begin
            next_state = 5'd1;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_di2_src = 1'b1;
          reg_we2 = 1'b1;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b1;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd10:  // format 2 (store): bus write
        begin
          if (~bus_ack) begin
            next_state = 5'd10;
          end else begin
            if (interrupt) begin
              next_state = 5'd16;
            end else begin
              next_state = 5'd1;
            end
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'b1;
          bus_stb = 1'b1;
          bus_we = 1'b1;
          bus_ben = (ir_v ? 2'b10 : 2'b01);
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'b1;
          alu_src2 = 3'b011;
          alu_fnc = 4'h8;
        end
      5'd11:  // format 3: branch register
        begin
          if (interrupt) begin
            next_state = 5'd16;
          end else begin
            next_state = 5'd1;
          end
          pc_src = 2'b01;
          pc_we = branch;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b10;
          reg_di2_src = 1'b0;
          reg_we2 = ir_v & branch;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'b001;
          alu_fnc = 4'h0;
        end
      5'd12:  // format 3: branch pc relative
        begin
          if (interrupt) begin
            next_state = 5'd16;
          end else begin
            next_state = 5'd1;
          end
          pc_src = 2'b01;
          pc_we = branch;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b10;
          reg_di2_src = 1'b0;
          reg_we2 = ir_v & branch;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'b0;
          alu_src2 = 3'b100;
          alu_fnc = 4'h8;
        end
      5'd13:  // put special register: read value from reg
        begin
          next_state = 5'd14;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'b01;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd14:  // put special register: write value to special reg
        begin
          next_state = 5'd1;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b1;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd15:  // set/clear interrupt enable
        begin
          next_state = 5'd1;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b1;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd16:  // interrupt acknowledge
        begin
          next_state = 5'd1;
          pc_src = 2'b10;
          pc_we = 1'b1;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b1;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      5'd17:  // interrupt return
        begin
          next_state = 5'd1;
          pc_src = 2'b11;
          pc_we = 1'b1;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b1;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
      default:  // all other states: unused
        begin
          next_state = 5'd0;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_addr_src = 1'bx;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 2'bxx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_di2_src = 1'bx;
          reg_we2 = 1'b0;
          put_spc = 1'b0;
          reg_set_H = 1'b0;
          reg_set_NZ = 1'b0;
          reg_set_CV = 1'b0;
          reg_set_I = 1'b0;
          irq_ack = 1'b0;
          irq_ret = 1'b0;
          alu_run = 1'b0;
          alu_src1 = 1'bx;
          alu_src2 = 3'bxxx;
          alu_fnc = 4'hx;
        end
    endcase
  end

endmodule
