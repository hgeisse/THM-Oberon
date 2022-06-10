//
// icache.v -- instruction cache
//


`timescale 1ns/1ps
`default_nettype none


module icache(clk, rst,
              cache_ready_out, cache_valid_in, cache_addr_in,
              cache_ready_in, cache_valid_out, cache_data_out,
              memory_stb, memory_addr, memory_dout, memory_ack);
    input clk;
    input rst;
    //----------------
    output cache_ready_out;
    input cache_valid_in;
    input [23:0] cache_addr_in;
    //----------------
    input cache_ready_in;
    output cache_valid_out;
    output [31:0] cache_data_out;
    //----------------
    output memory_stb;
    output [23:2] memory_addr;
    input [31:0] memory_dout;
    input memory_ack;

  //--------------------------------------------

  reg x_valid;
  reg [23:2] x_addr;
  wire [31:0] x_data;

  assign cache_ready_out = cache_ready_in;

  always @(posedge clk) begin
    x_valid <= cache_valid_in;
    x_addr[23:2] <= cache_addr_in[23:2];
  end

  assign x_data[31:0] =
    ~x_valid ?
      32'hxxxxxxxx :
      { ~x_addr[18:14], x_addr[5:2], ~x_addr[9:7], x_addr[13:10],
        x_addr[8:6], ~x_addr[13:10], x_addr[23:19], ~x_addr[5:2] };

  assign cache_valid_out = x_valid;
  assign cache_data_out[31:0] = x_data[31:0];

  //--------------------------------------------

  assign memory_stb = 1'b0;
  assign memory_addr[23:2] = 22'h0;

endmodule
