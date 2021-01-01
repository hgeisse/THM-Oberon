//
// clk_rst.v -- clock and reset generator
//


`timescale 1ns/1ps
`default_nettype none


module clk_rst(clk_in, rst_in_n,
               clk_ok, clk_75, clk_25, clk_25_q, rst);
    input clk_in;
    input rst_in_n;
    output clk_ok;
    output reg clk_75;
    output reg clk_25;
    output reg clk_25_q;
    output rst;

  reg rst_p_n;
  reg rst_s_n;
  reg [3:0] rst_counter;
  wire rst_counting;

  assign clk_ok = 1'b1;

  initial begin
    clk_25 = 1'b0;
    clk_25_q = 1'b0;
  end

  always @(posedge clk_in) begin
    clk_25 = ~clk_25;
  end

  always @(negedge clk_in) begin
    clk_25_q = ~clk_25_q;
  end

  always @(posedge clk_25) begin
    clk_75 = 1'b1;
    #6.66 clk_75 = 1'b0;
    #6.67 clk_75 = 1'b1;
    #6.67 clk_75 = 1'b0;
    #6.67 clk_75 = 1'b1;
    #6.66 clk_75 = 1'b0;
  end

  assign rst_counting =
    (rst_counter[3:0] == 4'hF) ? 1'b0 : 1'b1;

  always @(posedge clk_25) begin
    rst_p_n <= rst_in_n;
    rst_s_n <= rst_p_n;
    if (~rst_s_n | ~clk_ok) begin
      rst_counter[3:0] <= 4'h0;
    end else begin
      if (rst_counting) begin
        rst_counter[3:0] <= rst_counter[3:0] + 4'h1;
      end
    end
  end

  assign rst = rst_counting;

endmodule
