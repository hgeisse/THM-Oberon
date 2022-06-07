//
// ram.v -- simulate external RAM
//          4M x 32 bit = 16 MB
//


`timescale 1ns/1ps
`default_nettype none


`define RD_LATENCY	4'd5	// # cycles read latency, min = 3
`define WR_LATENCY	4'd5	// # cycles write latency, min = 3


module ram(clk, rst,
           stb, we, addr,
           data_in, data_out, ack);
    input clk;
    input rst;
    input stb;
    input we;
    input [21:0] addr;
    input [31:0] data_in;
    output reg [31:0] data_out;
    output ack;

  reg we_buf;
  reg [21:0] addr_buf;
  reg [31:0] mem[0:4194303];
  reg [3:0] latency_cnt;
  wire xfer_start;
  reg [3:0] address_cnt;
  wire xfer_stop;
  reg rd_ack;
  wire [2:0] ram_addr_lo;
  wire [21:0] ram_addr;

  always @(posedge clk) begin
    if (rst) begin
      latency_cnt[3:0] <= 4'h0;
    end else begin
      if (latency_cnt[3:0] == 4'h0) begin
        if (xfer_stop & stb) begin
          // handle request
          if (we) begin
            latency_cnt[3:0] <= `WR_LATENCY - 2;
            we_buf <= 1'b1;
          end else begin
            latency_cnt[3:0] <= `RD_LATENCY - 2;
            we_buf <= 1'b0;
          end
          addr_buf[21:0] <= addr[21:0];
        end
      end else begin
        latency_cnt[3:0] <= latency_cnt[3:0] - 4'h1;
      end
    end
  end

  assign xfer_start = (latency_cnt[3:0] == 4'h1);

  always @(posedge clk) begin
    if (rst) begin
      address_cnt[3:0] <= 4'h8;
    end else begin
      if (xfer_start) begin
        address_cnt[3:0] <= 4'h0;
      end else begin
        if (~xfer_stop) begin
          address_cnt[3:0] <= address_cnt[3:0] + 4'h1;
        end
      end
    end
  end

  assign xfer_stop = address_cnt[3];

  always @(posedge clk) begin
    if (rst) begin
      rd_ack <= 1'b0;
    end else begin
      rd_ack <= ~xfer_stop;
    end
  end

  assign ack = we_buf ? ~xfer_stop : rd_ack;

  assign ram_addr_lo[2:0] = addr_buf[2:0] + address_cnt[2:0];
  assign ram_addr = { addr_buf[21:3], ram_addr_lo[2:0] };

  always @(posedge clk) begin
    if (~xfer_stop) begin
      if (we_buf) begin
        mem[ram_addr] <= data_in;
      end else begin
        data_out <= mem[ram_addr];
      end
    end
  end

  initial begin
    mem[22'h0FFC] = 32'hFFFF;
    mem[22'h0FFD] = 32'hFFFF;
    mem[22'h0FFE] = 32'hFFFF;
    mem[22'h0FFF] = 32'hFFFF;

    mem[22'h1000] = 32'h0101;
    mem[22'h1001] = 32'h1101;
    mem[22'h1002] = 32'h2101;
    mem[22'h1003] = 32'h3101;
    mem[22'h1004] = 32'h4101;
    mem[22'h1005] = 32'h5101;
    mem[22'h1006] = 32'h6101;
    mem[22'h1007] = 32'h7101;
    mem[22'h1008] = 32'h8101;
    mem[22'h1009] = 32'h9101;
    mem[22'h100A] = 32'hA101;
    mem[22'h100B] = 32'hB101;
    mem[22'h100C] = 32'hC101;
    mem[22'h100D] = 32'hD101;
    mem[22'h100E] = 32'hE101;
    mem[22'h100F] = 32'hF101;

    mem[22'h1010] = 32'h0201;
    mem[22'h1011] = 32'h1201;
    mem[22'h1012] = 32'h2201;
    mem[22'h1013] = 32'h3201;
    mem[22'h1014] = 32'h4201;
    mem[22'h1015] = 32'h5201;
    mem[22'h1016] = 32'h6201;
    mem[22'h1017] = 32'h7201;
    mem[22'h1018] = 32'h8201;
    mem[22'h1019] = 32'h9201;
    mem[22'h101A] = 32'hA201;
    mem[22'h101B] = 32'hB201;
    mem[22'h101C] = 32'hC201;
    mem[22'h101D] = 32'hD201;
    mem[22'h101E] = 32'hE201;
    mem[22'h101F] = 32'hF201;

    mem[22'h1020] = 32'hFFFF;
    mem[22'h1021] = 32'hFFFF;
    mem[22'h1022] = 32'hFFFF;
    mem[22'h1023] = 32'hFFFF;
  end

endmodule
