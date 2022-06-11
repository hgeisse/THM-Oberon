//
// icachetest.v -- test the instruction cache
//


`timescale 1ns/1ps
`default_nettype none


//
// define the time to pass before the first request takes place
// (in clock cycles, up to 255)
//
`define HOLDOFF		8'd80

//
// define the time to pass between two consecutive requests
// (in clock cycles, range: 0..15)
//
`define DISTANCE	4'd6
//`define DISTANCE	4'd1
//`define DISTANCE	4'd0

//
// define the total number of requests
//
`define NUM_TESTS	20'd1000

//
// define an address pattern for the optional LRU test
// (the tests are disabled if no pattern is defined)
//
// LRU_0: 0x010000, 0x020000, 0x010000, 0x020000, 0x010000, 0x050000
// LRU_1: 0x010000, 0x020000, 0x010000, 0x020000, 0x050000, 0x050000
//
//`define LRU_0
//`define LRU_1


module icachetest(clk, rst,
                  ready_in, valid_out, addr_out,
                  ready_out, valid_in, data_in,
                  test_ended, test_error);
    input clk;
    input rst;
    //----------------
    input ready_in;
    output reg valid_out;
    output reg [23:0] addr_out;
    //----------------
    output ready_out;
    input valid_in;
    input [31:0] data_in;
    //----------------
    output reg test_ended;
    output reg test_error;

  reg [7:0] holdoff;
  wire holdoff_counting;
  reg [3:0] distance;
  wire distance_restart;
  reg [19:0] gen_state;
  reg jump;
  reg [23:0] target;

  reg [23:0] addr;
  wire [31:0] data;
  wire data_error;
  reg [19:0] test_count;

  //--------------------------------------------

  always @(posedge clk) begin
    if (rst) begin
      holdoff[7:0] <= `HOLDOFF;
    end else begin
      if (holdoff_counting) begin
        holdoff[7:0] <= holdoff[7:0] - 8'd1;
      end
    end
  end

  assign holdoff_counting = (holdoff[7:0] != 8'd0);

  always @(posedge clk) begin
    if (holdoff_counting) begin
      distance[3:0] <= 4'd0;
    end else begin
      if (ready_in) begin
        if (distance_restart) begin
          distance[3:0] <= 4'd0;
        end else begin
          distance[3:0] <= distance[3:0] + 4'd1;
        end
      end
    end
  end

  assign distance_restart = (distance[3:0] == `DISTANCE);

  always @(posedge clk) begin
    if (rst) begin
      valid_out <= 1'b0;
    end else begin
      if (ready_in) begin
        valid_out <= distance_restart & ~holdoff_counting;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      gen_state[19:0] <= 20'h0;
      jump <= 1'b0;
      target[23:0] <= 24'hxxxxxx;
    end else begin
      if (ready_in & distance_restart & ~holdoff_counting) begin
        gen_state[19:0] <= gen_state[19:0] + 20'h1;
        case (gen_state[19:0])
`ifdef LRU_0
          20'h00005:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h010000;
            end
          20'h00006:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h020000;
            end
          20'h00007:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h010000;
            end
          20'h00008:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h020000;
            end
          20'h00009:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h010000;
            end
          20'h0000A:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h050000;
            end
`endif
`ifdef LRU_1
          20'h00005:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h010000;
            end
          20'h00006:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h020000;
            end
          20'h00007:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h010000;
            end
          20'h00008:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h020000;
            end
          20'h00009:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h050000;
            end
          20'h0000A:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h050000;
            end
`endif
          20'h0003F:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h000000;
            end
          20'h0007F:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h000000;
            end
          20'h000BF:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h000000;
            end
          20'h000FF:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h800000;
            end
          20'h0013F:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h800000;
            end
          20'h0017F:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h800000;
            end
          20'h001BF:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h800000;
            end
          20'h001FF:
            begin
              jump <= 1'b1;
              target[23:0] <= 24'h000000;
            end
          default:
            begin
              jump <= 1'b0;
              target[23:0] <= 24'hxxxxxx;
            end
        endcase
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      addr_out[23:0] <= 24'hFFFFFC;
    end else begin
      if (ready_in & distance_restart & ~holdoff_counting) begin
        if (jump) begin
          // jump to target address
          addr_out[23:0] <= target[23:0];
        end else begin
          // increment address
          addr_out[23:0] <= addr_out[23:0] + 24'h000004;
        end
      end
    end
  end

  //--------------------------------------------

  always @(posedge clk) begin
    if (ready_in) begin
      addr[23:0] <= addr_out[23:0];
    end
  end

  //--------------------------------------------

  assign ready_out = 1'b1;

  assign data[31:0] =
    { ~addr[18:14], addr[5:2], ~addr[9:7], addr[13:10],
      addr[8:6], ~addr[13:10], addr[23:19], ~addr[5:2] };

  assign data_error = (data_in[31:0] != data[31:0]);

  always @(posedge clk) begin
    if (rst) begin
      test_count[19:0] <= 20'd0;
      test_ended <= 1'b0;
      test_error <= 1'b0;
    end else begin
      if (test_count[19:0] != `NUM_TESTS) begin
        if (valid_in) begin
          test_count[19:0] <= test_count[19:0] + 20'd1;
          if (data_error) begin
            test_error <= 1'b1;
          end
        end
      end else begin
        test_ended <= 1'b1;
      end
    end
  end

endmodule
