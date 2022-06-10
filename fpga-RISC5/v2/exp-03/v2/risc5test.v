//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg clk;			// clock, 100 MHz
  reg rst;			// reset, active high

  wire cache_ready_out;
  wire cache_valid_in;
  wire [23:0] cache_addr_in;
  wire cache_ready_in;
  wire cache_valid_out;
  wire [31:0] cache_data_out;
  wire test_ended;
  wire test_error;

  wire inst_stb;
  wire [23:0] inst_addr;
  wire [31:0] inst_dout;
  wire inst_ack;

  //
  // simulation control
  //

  initial begin
    #0          $timeformat(-9, 1, " ns", 12);
                $dumpfile("dump.vcd");
                $dumpvars(0, risc5test);
                clk = 1;
                rst = 1;
    #51         rst = 0;
    #200000     $finish;
  end

  //
  // clock generator
  //

  always begin
    #5 clk = ~clk;		// 10 nsec cycle time
  end

  //
  // module instantiations
  //

  icachetest icachetest_0(
    .clk(clk),
    .rst(rst),
    //----------------
    .ready_in(cache_ready_out),
    .valid_out(cache_valid_in),
    .addr_out(cache_addr_in[23:0]),
    //----------------
    .ready_out(cache_ready_in),
    .valid_in(cache_valid_out),
    .data_in(cache_data_out[31:0]),
    //----------------
    .test_ended(test_ended),
    .test_error(test_error)
  );

  icache icache_0(
    .clk(clk),
    .rst(rst),
    //----------------
    .cache_ready_out(cache_ready_out),
    .cache_valid_in(cache_valid_in),
    .cache_addr_in(cache_addr_in[23:0]),
    //----------------
    .cache_ready_in(cache_ready_in),
    .cache_valid_out(cache_valid_out),
    .cache_data_out(cache_data_out[31:0]),
    //----------------
    .memory_stb(inst_stb),
    .memory_addr(inst_addr[23:2]),
    .memory_dout(inst_dout[31:0]),
    .memory_ack(inst_ack)
  );

  ramctrl ramctrl_0(
    .clk(clk),
    .rst(rst),
    //----------------
    .inst_stb(inst_stb),
    .inst_addr(inst_addr[23:2]),
    .inst_dout(inst_dout[31:0]),
    .inst_ack(inst_ack),
    //----------------
    .data_stb(1'b0),
    .data_we(1'b0),
    .data_addr(22'h0),
    .data_din(32'h0),
    .data_dout(),
    .data_ack()
  );

endmodule
