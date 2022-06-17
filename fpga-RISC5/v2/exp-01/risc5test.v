//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg clk;			// clock, 100 MHz
  reg rst;			// reset, active high

  reg ram_stb;
  reg ram_we;
  reg [21:0] ram_addr;
  reg [31:0] ram_data_in;
  wire [31:0] ram_data_out;
  wire ram_ack;

  reg prom_stb;
  reg [8:0] prom_addr;
  wire [31:0] prom_data_out;
  wire prom_ack;

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
                ram_stb = 0;
    #100        ram_stb = 1;
                ram_we = 0;
                ram_addr[21:0] = 22'h1000;
    #70         ram_stb = 0;
    #80         ram_stb = 1;
                ram_we = 1;
                ram_addr[21:0] = 22'h1000;
    #70         ram_stb = 0;
    #80         ram_stb = 1;
                ram_we = 0;
                ram_addr[21:0] = 22'h1000;
    #70         ram_stb = 0;
    #100        prom_stb = 0;
    #100        prom_stb = 1;
                prom_addr[8:0] = 9'h1A8;
    #40         prom_stb = 0;
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

  ram ram_0(
    .clk(clk),
    .rst(rst),
    .stb(ram_stb),
    .we(ram_we),
    .addr(ram_addr[21:0]),
    .data_in(ram_data_in[31:0]),
    .data_out(ram_data_out[31:0]),
    .ack(ram_ack)
  );

  prom prom_0(
    .clk(clk),
    .rst(rst),
    .stb(prom_stb),
    .addr(prom_addr[8:0]),
    .data_out(prom_data_out[31:0]),
    .ack(prom_ack)
  );

  //
  // write data generator
  //

  always @(posedge clk) begin
    if (rst) begin
      ram_data_in[31:0] <= 32'h44444444;
    end else begin
      if (ram_we & ram_ack) begin
        ram_data_in[31:0] <= ram_data_in[31:0] + 32'h11111111;
      end
    end
  end

endmodule
