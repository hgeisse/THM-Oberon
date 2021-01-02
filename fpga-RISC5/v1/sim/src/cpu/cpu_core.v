//
// cpu.v -- the RISC5 CPU core
//


`timescale 1ns / 1ps
`default_nettype none


module cpu_core(clk, rst,
                bus_stb, bus_we, bus_size, bus_addr,
                bus_din, bus_dout, bus_ack);
    input clk;				// system clock
    input rst;				// system reset
    output bus_stb;			// bus strobe
    output bus_we;			// bus write enable
    output bus_size;			// 0: byte, 1: word
    output [23:0] bus_addr;		// bus address
    input [31:0] bus_din;		// bus data input, for reads
    output [31:0] bus_dout;		// bus data output, for writes
    input bus_ack;			// bus acknowledge

  // program counter
  wire [23:0] pc;		// program counter
  wire [1:0] pc_src;		// pc source selector
  wire [23:0] pc_next;		// value written into pc

  //------------------------------------------------------------

  // program counter
  assign pc_next[23:0] =
    (pc_src == 2'b00) ? 24'hFFE000 :
    (pc_src == 2'b01) ? pc :
    (pc_src == 2'b10) ? pc + 24'h4 :
    24'hxxxxxx;
  always @(posedge clk) begin
    pc <= pc_next;
  end

  // bus

  // instruction register & decoder

  // register file

  // alu, shift, and muldiv units

  // ctrl
  ctrl ctrl_0(
    .clk(clk),
    .rst(rst)
  );

endmodule


//--------------------------------------------------------------
// ctrl -- the finite state machine within the CPU
//--------------------------------------------------------------


module ctrl(clk, rst);
    input clk;
    input rst;

  reg [1:0] state;
  reg [1:0] next_state;

  // state machine
  always @(posedge clk) begin
    if (rst) begin
      state <= 2'd0;
    end else begin
      state <= next_state;
    end
  end

  // output logic
  always @(*) begin
    case (state)
      2'd0:  // reset
        begin
          next_state = 2'd1;
          pc_src = 2'b00;
        end
      2'd1:  // fetch instr
        begin
          next_state = 2'd2;
          pc_src = 2'b;
        end
      2'd2:  // halt
        begin
          next_state = 2'd2;
          pc_src = 2'b00;
        end
      default:  // all other states: unused
        begin
          next_state = 2'd0;
          pc_src = 2'b00;
        end
    endcase
  end

endmodule
