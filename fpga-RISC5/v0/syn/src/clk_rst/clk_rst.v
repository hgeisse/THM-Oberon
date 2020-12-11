//
// clk_rst.v -- clock and reset generator
//


`timescale 1ns/1ps
`default_nettype none


module clk_rst(clk_in, rst_in_n,
               clk_ok, clk_75, clk_25, rst);
    input clk_in;
    input rst_in_n;
    output clk_ok;
    output clk_75;
    output clk_25;
    output rst;

  wire [1:0] inclk;
  wire [5:0] outclk;
  wire locked;

  reg rst_p_n;
  reg rst_s_n;
  reg [23:0] rst_counter;
  wire rst_counting;

  //------------------------------------------------------------

  assign inclk[1:0] = { 1'b0, clk_in };

  altpll #(
    .intended_device_family("Cyclone IV E"),
    .lpm_type("altpll"),
    .pll_type("auto"),
    .operation_mode("normal"),
    // 50 MHz input
    .inclk0_input_frequency(20000),	// cycle time in picosec
    // 75 MHz output, in-phase
    .clk1_multiply_by(12),
    .clk1_divide_by(8),
    .clk1_duty_cycle(50),		// in %
    .clk1_phase_shift(0),		// in picosec
    // 25 MHz output, in-phase
    .clk0_multiply_by(8),
    .clk0_divide_by(16),
    .clk0_duty_cycle(50),		// in %
    .clk0_phase_shift(0)		// in picosec
  ) clk_pll (
    .inclk(inclk[1:0]),
    .clk(outclk[5:0]),
    .locked(locked)
  );

  assign clk_75 = outclk[1];
  assign clk_25 = outclk[0];

  assign clk_ok = locked;

  //------------------------------------------------------------

  assign rst_counting =
    (rst_counter[23:0] == 24'hFFFFFF) ? 1'b0 : 1'b1;

  always @(posedge clk_25) begin
    rst_p_n <= rst_in_n;
    rst_s_n <= rst_p_n;
    if (~rst_s_n | ~clk_ok) begin
      rst_counter[23:0] <= 24'h000000;
    end else begin
      if (rst_counting) begin
        rst_counter[23:0] <= rst_counter[23:0] + 24'h000001;
      end
    end
  end

  assign rst = rst_counting;

endmodule
