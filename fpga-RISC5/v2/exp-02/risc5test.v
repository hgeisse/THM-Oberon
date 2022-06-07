//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg clk;			// clock, 100 MHz
  reg rst;			// reset, active high

  reg inst_stb;
  reg [23:0] inst_addr;
  wire [31:0] inst_dout;
  wire inst_ack;

  reg data_stb;
  reg data_we;
  reg [23:0] data_addr;
  reg [31:0] data_din;
  wire [31:0] data_dout;
  wire data_ack;

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
                inst_stb = 0;
                data_stb = 0;
    #100	inst_stb = 1;
                inst_addr[23:0] = 24'h4000;
                data_stb = 1;
                data_we = 0;
                data_addr[23:0] = 24'h4040;
    #70		data_stb = 0;
    #140	inst_stb = 0;
    #80         data_stb = 1;
                data_we = 1;
                data_addr[23:0] = 24'h4040;
    #70         data_stb = 0;
    #80         data_stb = 1;
                data_we = 0;
                data_addr[23:0] = 24'h4040;
    #70         data_stb = 0;
    #30000      $finish;
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

  ramctrl ramctrl_0(
    .clk(clk),
    .rst(rst),
    .inst_stb(inst_stb),
    .inst_addr(inst_addr[23:2]),
    .inst_dout(inst_dout[31:0]),
    .inst_ack(inst_ack),
    .data_stb(data_stb),
    .data_we(data_we),
    .data_addr(data_addr[23:2]),
    .data_din(data_din[31:0]),
    .data_dout(data_dout[31:0]),
    .data_ack(data_ack)
  );

  //
  // write data generator
  //

  always @(posedge clk) begin
    if (rst) begin
      data_din[31:0] <= 32'h44444444;
    end else begin
      if (data_we & data_ack) begin
        data_din[31:0] <= data_din[31:0] + 32'h11111111;
      end
    end
  end

endmodule
