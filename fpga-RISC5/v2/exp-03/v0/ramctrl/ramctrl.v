//
// ramctrl.v -- RAM controller for simulated RAM
//


`timescale 1ns/1ps
`default_nettype none


module ramctrl(clk, rst,
               inst_stb, inst_addr,
               inst_dout, inst_ack,
               data_stb, data_we,
               data_addr, data_din,
               data_dout, data_ack);
    input clk;
    input rst;
    input inst_stb;
    input [23:2] inst_addr;
    output [31:0] inst_dout;
    output inst_ack;
    input data_stb;
    input data_we;
    input [23:2] data_addr;
    input [31:0] data_din;
    output [31:0] data_dout;
    output data_ack;

  reg inst;
  reg ram_stb;
  reg ram_we;
  wire [23:2] ram_addr;
  wire [31:0] ram_din;
  wire [31:0] ram_dout;
  wire ram_ack;

  ram ram_0(
    .clk(clk),
    .rst(rst),
    .stb(ram_stb),
    .we(ram_we),
    .addr(ram_addr[23:2]),
    .data_in(ram_din[31:0]),
    .data_out(ram_dout[31:0]),
    .ack(ram_ack)
  );

  reg [2:0] state;
  reg [2:0] next_state;

  always @(posedge clk) begin
    if (rst) begin
      state[2:0] <= 3'h0;
    end else begin
      state[2:0] <= next_state[2:0];
    end
  end

  always @(*) begin
    case (state[2:0])
      3'h0:  // idle: request arbitration
        begin
          if (data_stb) begin
            if (data_we) begin
              next_state[2:0] = 3'h5;
              inst = 1'b0;
              ram_stb = 1'b1;
              ram_we = 1'b1;
            end else begin
              next_state[2:0] = 3'h3;
              inst = 1'b0;
              ram_stb = 1'b1;
              ram_we = 1'b0;
            end
          end else begin
            if (inst_stb) begin
              next_state[2:0] = 3'h1;
              inst = 1'b1;
              ram_stb = 1'b1;
              ram_we = 1'b0;
            end else begin
              next_state[2:0] = 3'h0;
              inst = 1'b0;
              ram_stb = 1'b0;
              ram_we = 1'b0;
            end
          end
        end
      3'h1:  // inst rd: wait for ack
        begin
          if (ram_ack) begin
            next_state[2:0] = 3'h2;
            inst = 1'b1;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end else begin
            next_state[2:0] = 3'h1;
            inst = 1'b1;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end
        end
      3'h2:  // inst rd: data transfer
        begin
          if (~ram_ack) begin
            next_state[2:0] = 3'h0;
            inst = 1'b1;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end else begin
            next_state[2:0] = 3'h2;
            inst = 1'b1;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end
        end
      3'h3:  // data rd: wait for ack
        begin
          if (ram_ack) begin
            next_state[2:0] = 3'h4;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end else begin
            next_state[2:0] = 3'h3;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end
        end
      3'h4:  // data rd: data transfer
        begin
          if (~ram_ack) begin
            next_state[2:0] = 3'h0;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end else begin
            next_state[2:0] = 3'h4;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end
        end
      3'h5:  // data wr: wait for ack
        begin
          if (ram_ack) begin
            next_state[2:0] = 3'h6;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end else begin
            next_state[2:0] = 3'h5;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end
        end
      3'h6:  // data wr: data transfer
        begin
          if (~ram_ack) begin
            next_state[2:0] = 3'h0;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end else begin
            next_state[2:0] = 3'h6;
            inst = 1'b0;
            ram_stb = 1'b0;
            ram_we = 1'b0;
          end
        end
      default:
        begin
          next_state[2:0] = 3'h0;
          inst = 1'b0;
          ram_stb = 1'b0;
          ram_we = 1'b0;
        end
    endcase
  end

  assign ram_addr[23:2] = inst ? inst_addr[23:2] : data_addr[23:2];

  assign ram_din[31:0] = data_din[31:0];

  assign inst_dout[31:0] = ram_dout[31:0];
  assign data_dout[31:0] = ram_dout[31:0];

  assign inst_ack = inst ? ram_ack : 1'b0;
  assign data_ack = inst ? 1'b0 : ram_ack;

endmodule
