//
// cpu_bus.v -- the RISC5 CPU bus interface
//


`timescale 1ns / 1ps
`default_nettype none


module cpu_bus(clk, rst,
               bus_stb, bus_we, bus_addr,
               bus_din, bus_dout, bus_ack,
               cpu_stb, cpu_we, cpu_ben, cpu_addr,
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
    input cpu_ben;
    input [23:0] cpu_addr;
    output reg [31:0] cpu_din;
    input [31:0] cpu_dout;
    output reg cpu_ack;

  reg state;
  reg next_state;
  reg [31:0] wbuf;
  reg wbuf_we;
  reg [31:0] wbuf_in;

  // ctrl
  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
    end else begin
      state <= next_state;
    end
  end

  // output
  always @(*) begin
    case (state)
      1'b0:
        if (~cpu_stb) begin
          // no bus activity from cpu
          bus_stb = 1'b0;
          bus_we = 1'bx;
          bus_addr[23:2] = 22'hxxxxxx;
          bus_dout[31:0] = 32'hxxxxxxxx;
          cpu_din[31:0] = 32'hxxxxxxxx;
          cpu_ack = 1'b0;
          next_state = 1'b0;
          wbuf_we = 1'b0;
          wbuf_in[31:0] = 32'hxxxxxxxx;
        end else begin
          // bus activated by cpu
          if (~cpu_we) begin
            // cpu read cycle
            if (cpu_ben) begin
              // cpu read byte
              bus_stb = 1'b1;
              bus_we = 1'b0;
              bus_addr[23:2] = cpu_addr[23:2];
              bus_dout[31:0] = 32'hxxxxxxxx;
              if (~cpu_addr[1]) begin
                if (~cpu_addr[0]) begin
                  cpu_din[31:0] = { 24'h0, bus_din[ 7: 0] };
                end else begin
                  cpu_din[31:0] = { 24'h0, bus_din[15: 8] };
                end
              end else begin
                if (~cpu_addr[0]) begin
                  cpu_din[31:0] = { 24'h0, bus_din[23:16] };
                end else begin
                  cpu_din[31:0] = { 24'h0, bus_din[31:24] };
                end
              end
              cpu_ack = bus_ack;
              next_state = 1'b0;
              wbuf_we = 1'b0;
              wbuf_in[31:0] = 32'hxxxxxxxx;
            end else begin
              // cpu read word
              bus_stb = 1'b1;
              bus_we = 1'b0;
              bus_addr[23:2] = cpu_addr[23:2];
              bus_dout[31:0] = 32'hxxxxxxxx;
              cpu_din[31:0] = bus_din[31:0];
              cpu_ack = bus_ack;
              next_state = 1'b0;
              wbuf_we = 1'b0;
              wbuf_in[31:0] = 32'hxxxxxxxx;
            end
          end else begin
            // cpu write cycle
            if (cpu_ben) begin
              // cpu write byte
              // part 1: read word into word buffer
              bus_stb = 1'b1;
              bus_we = 1'b0;
              bus_addr[23:2] = cpu_addr[23:2];
              bus_dout[31:0] = 32'hxxxxxxxx;
              cpu_din[31:0] = 32'hxxxxxxxx;
              cpu_ack = 1'b0;
              if (~bus_ack) begin
                next_state = 1'b0;
              end else begin
                next_state = 1'b1;
              end
              wbuf_we = 1'b1;
              if (~cpu_addr[1]) begin
                if (~cpu_addr[0]) begin
                  wbuf_in[31:0] = { bus_din[31:24], bus_din[23:16],
                                    bus_din[15:8], cpu_dout[7:0] };
                end else begin
                  wbuf_in[31:0] = { bus_din[31:24], bus_din[23:16],
                                    cpu_dout[7:0], bus_din[7:0] };
                end
              end else begin
                if (~cpu_addr[0]) begin
                  wbuf_in[31:0] = { bus_din[31:24], cpu_dout[7:0],
                                    bus_din[15:8], bus_din[7:0] };
                end else begin
                  wbuf_in[31:0] = { cpu_dout[7:0], bus_din[23:16],
                                    bus_din[15:8], bus_din[7:0] };
                end
              end
            end else begin
              // cpu write word
              bus_stb = 1'b1;
              bus_we = 1'b1;
              bus_addr[23:2] = cpu_addr[23:2];
              bus_dout[31:0] = cpu_dout[31:0];
              cpu_din[31:0] = 32'hxxxxxxxx;
              cpu_ack = bus_ack;
              next_state = 1'b0;
              wbuf_we = 1'b0;
              wbuf_in[31:0] = 32'hxxxxxxxx;
            end
          end
        end
      1'b1:
        begin
          // cpu write halfword or byte
          // part 2: write word from word buffer
          bus_stb = 1'b1;
          bus_we = 1'b1;
          bus_addr[23:2] = cpu_addr[23:2];
          bus_dout[31:0] = wbuf[31:0];
          cpu_din[31:0] = 32'hxxxxxxxx;
          cpu_ack = bus_ack;
          if (~bus_ack) begin
            next_state = 1'b1;
          end else begin
            next_state = 1'b0;
          end
          wbuf_we = 1'b0;
          wbuf_in[31:0] = 32'hxxxxxxxx;
        end
    endcase
  end

  // word buffer
  always @(posedge clk) begin
    if (wbuf_we) begin
      wbuf[31:0] <= wbuf_in[31:0];
    end
  end

endmodule
