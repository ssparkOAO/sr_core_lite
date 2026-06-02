`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Phase8 Weight Memory Architecture Proposal
// -----------------------------------------------------------------------------
// This file is an architecture draft for RTL_sys.
//
// It is not connected to the verified RTL library yet.
// The current verified modules under model_lite/sr_core/RTL must remain untouched.
//
// Goal:
//   Replace large top-level weight/M0/M1 port lists with memory-style interfaces.
//   These small memory-bank modules are intended as the first step toward future
//   BRAM or ROM migration.
// -----------------------------------------------------------------------------

module sr_conv1_weight_mem_arch (
    input wire clk,
    input wire [6:0] addr,
    output reg signed [7:0] data
);

    // Conv1 weight shape: [8][3][3][1]
    // Flatten layout used by current generated/conv1_weight.mem:
    //   output channel major, then kernel tap 0..8
    //
    // Address:
    //   co0 tap0..tap8 -> addr 0..8
    //   co1 tap0..tap8 -> addr 9..17
    //   ...
    //   co7 tap0..tap8 -> addr 63..71
    reg signed [7:0] conv1_weight_mem [0:71];

    always @(posedge clk) begin
        data <= conv1_weight_mem[addr];
    end

endmodule


module sr_conv3_weight_mem_arch (
    input wire clk,
    input wire [4:0] addr,
    output reg signed [7:0] data
);

    // Conv3 layer uses a 1x1 kernel.
    // Weight shape: [4][1][1][8]
    // Flatten layout:
    //   output channel major, then input channel 0..7
    //
    // Address:
    //   co0 ci0..ci7 -> addr 0..7
    //   co1 ci0..ci7 -> addr 8..15
    //   co2 ci0..ci7 -> addr 16..23
    //   co3 ci0..ci7 -> addr 24..31
    reg signed [7:0] conv3_weight_mem [0:31];

    always @(posedge clk) begin
        data <= conv3_weight_mem[addr];
    end

endmodule


module sr_quant_param_mem_arch (
    input wire clk,

    input wire [2:0] conv1_ch_addr,
    output reg signed [31:0] conv1_m0_data,
    output reg signed [63:0] conv1_m1_data,

    input wire [1:0] conv3_ch_addr,
    output reg signed [31:0] conv3_m0_data,
    output reg signed [63:0] conv3_m1_data
);

    // Conv1 has 8 output channels.
    reg signed [31:0] conv1_m0_mem [0:7];
    reg signed [63:0] conv1_m1_mem [0:7];

    // Conv3 has 4 output channels.
    reg signed [31:0] conv3_m0_mem [0:3];
    reg signed [63:0] conv3_m1_mem [0:3];

    always @(posedge clk) begin
        conv1_m0_data <= conv1_m0_mem[conv1_ch_addr];
        conv1_m1_data <= conv1_m1_mem[conv1_ch_addr];

        conv3_m0_data <= conv3_m0_mem[conv3_ch_addr];
        conv3_m1_data <= conv3_m1_mem[conv3_ch_addr];
    end

endmodule
