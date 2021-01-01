//
// cpu_bus.v -- the RISC5 CPU bus interface
//


`timescale 1ns / 1ps
`default_nettype none


module cpu_bus(clk, rst,
               bus_stb, bus_we, bus_addr,
               bus_din, bus_dout, bus_ack,
               cpu_stb, cpu_we, cpu_size, cpu_addr,
               cpu_din, cpu_dout, cpu_ack);
    // bus interface
    input clk;
    input rst;
    output reg bus_stb;
    output reg bus_we;
    output reg [23:2] bus_addr;
    input [31:0] bus_din;
    output reg [31:0] bus_dout;
    input bus_ack;
    // CPU interface
    input cpu_stb;
    input cpu_we;
    input cpu_size;
    input [23:0] cpu_addr;
    output reg [31:0] cpu_din;
    input [31:0] cpu_dout;
    output reg cpu_ack;

endmodule
