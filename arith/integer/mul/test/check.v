//
// check.v -- test bench
//


`timescale 1ns / 1ps
`default_nettype none


module check;

  reg clk;
  reg rst;

  reg [131:0] ref_data_mem[0:2499];
  reg [11:0] ref_data_index;
  reg read_ref;
  reg inc_index;
  reg [131:0] ref_data;
  wire [31:0] x;
  wire [31:0] y;
  wire op_unsigned;
  wire [31:0] ref_hi;
  wire [31:0] ref_lo;

  reg run;
  wire stall;
  wire [63:0] z;
  wire [31:0] res_hi;
  wire [31:0] res_lo;
  reg set_err;
  reg error;
  reg done;

  initial begin
    #0        $timeformat(-9, 1, " ns", 12);
              $dumpfile("dump.vcd");
              $dumpvars(0, check);
              $readmemh("ref.dat", ref_data_mem);
              clk = 1'b0;
              rst = 1'b1;
    #115      rst = 1'b0;
    #3501000  $finish;
  end

  always begin
    #20 clk = ~clk;		// 40 nsec cycle time
  end

  Multiplier Multiplier_0(
    .clk(clk),
    .run(run),
    .stall(stall),
    .op_unsigned(op_unsigned),
    .x(x[31:0]),
    .y(y[31:0]),
    .z(z[63:0])
  );

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
    end else begin
      state <= next_state;
    end
  end

  reg [2:0] state;
  reg [2:0] next_state;

  always @(*) begin
    case (state)
      3'd0:  // reset
        begin
          next_state = 1;
          read_ref = 0;
          inc_index = 0;
          run = 0;
          set_err = 0;
          done = 0;
        end
      3'd1:  // read
        begin
          next_state = 2;
          read_ref = 1;
          inc_index = 0;
          run = 0;
          set_err = 0;
          done = 0;
        end
      3'd2:  // start
        begin
          next_state = 3;
          read_ref = 0;
          inc_index = 0;
          run = 1;
          set_err = 0;
          done = 0;
        end
      3'd3:  // compute, compare
        begin
          if (stall) begin
            next_state = 3;
          end else begin
            if (ref_data_index != 2499) begin
              next_state = 1;
            end else begin
              next_state = 4;
            end
          end
          read_ref = 0;
          inc_index = ~stall;
          run = 1;
          set_err = ~stall;
          done = 0;
        end
      3'd4:  // halt
        begin
          next_state = 4;
          read_ref = 0;
          inc_index = 0;
          run = 0;
          set_err = 0;
          done = 1;
        end
    endcase
  end

  always @(posedge clk) begin
    if (read_ref) begin
      ref_data <= ref_data_mem[ref_data_index];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ref_data_index <= 0;
    end else begin
      if (inc_index) begin
        ref_data_index <= ref_data_index + 1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      error <= 0;
    end else begin
      if (set_err) begin
        error <= error | ((res_hi != ref_hi) || (res_lo != ref_lo));
      end
    end
  end

  assign x = ref_data[131:100];
  assign y = ref_data[99:68];
  assign op_unsigned = ref_data[64];
  assign ref_hi = ref_data[63:32];
  assign ref_lo = ref_data[31:0];
  assign res_hi = z[63:32];
  assign res_lo = z[31:0];

endmodule
