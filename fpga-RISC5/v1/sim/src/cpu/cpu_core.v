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
  wire [3:0] alu_fnc;
  wire [31:0] alu_op1;
  wire [31:0] alu_op2;
  wire [31:0] alu_res;
  reg [31:0] alu_out;

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
  assign ir_op = ir[19:16];
  assign ir_c = ir[3:0];

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
    (reg_a2_src == 2'b00) ? ir_c :	// arith op2
    (reg_a2_src == 2'b01) ? ir_a :	// arith or load dst, store src
    (reg_a2_src == 2'b10) ? 4'hF :	// call link
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
  assign alu_fnc = ir_op;
  assign alu_op1 = reg_do1;
  assign alu_op2 = reg_do2;
  alu alu_0(
    .fnc(alu_fnc),
    .op1(alu_op1),
    .op2(alu_op2),
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
    .reg_we2(reg_we2)
  );

endmodule


//--------------------------------------------------------------
// alu -- arithmetic/logic unit, shifter, floating-point
//--------------------------------------------------------------


module alu(fnc, op1, op2, res);
    input [3:0] fnc;
    input [31:0] op1;
    input [31:0] op2;
    output [31:0] res;

  assign res = op1 + op2;

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
            reg_a2_src, reg_we2);
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
        end
      4'd1:  // fetch instr
        begin
          if (~bus_ack) begin
            next_state = 4'd1;
          end else begin
            next_state = 4'd2;
          end
          pc_src = 2'bxx;
          pc_we = 1'b0;
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
        end
      4'd2:  // decode, fetch register operands
        begin
          case (ir_pq)
            2'b00:
              begin
                next_state = 4'd3;
              end
            2'b01:
              begin
                next_state = 4'd10;
              end
            2'b10:
              begin
                next_state = 4'd12;
              end
            2'b11:
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
        end
      4'd10:  // halt: format 1 (immediate)
        begin
          next_state = 4'd10;
          pc_src = 2'bxx;
          pc_we = 1'b0;
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_ben = 1'bx;
          ir_we = 1'b0;
          reg_a2_src = 2'bxx;
          reg_we2 = 1'b0;
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
        end
    endcase
  end

endmodule
