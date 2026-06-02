`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Phase8.3 Parameter ROM Bank Prototype
// -----------------------------------------------------------------------------
// This module groups the Vivado Block Memory Generator ROM IPs used for fixed
// SR accelerator parameters.
//
// Current scope:
//   - Conv1 weight ROM
//   - Conv3 weight ROM
//   - Conv1 M0/M1 ROM
//   - Conv3 M0/M1 ROM
//
// The generated IP modules are created by:
//   tcl/create_sr_core_bram_pynqz2.tcl
//
// This is still RTL_sys prototype work. The verified RTL library under RTL/
// remains untouched.
// -----------------------------------------------------------------------------

module sr_param_rom_bank (
    input wire clk,

    input wire conv1_weight_en,
    input wire [6:0] conv1_weight_addr,
    output wire signed [7:0] conv1_weight_data,

    input wire conv3_weight_en,
    input wire [4:0] conv3_weight_addr,
    output wire signed [7:0] conv3_weight_data,

    input wire conv1_m0_en,
    input wire [2:0] conv1_m0_addr,
    output wire signed [31:0] conv1_m0_data,

    input wire conv1_m1_en,
    input wire [2:0] conv1_m1_addr,
    output wire signed [63:0] conv1_m1_data,

    input wire conv3_m0_en,
    input wire [1:0] conv3_m0_addr,
    output wire signed [31:0] conv3_m0_data,

    input wire conv3_m1_en,
    input wire [1:0] conv3_m1_addr,
    output wire signed [63:0] conv3_m1_data
);

    // Note about enable:
    // Vivado Block Memory Generator can create ROMs with or without ENA.
    // Keeping ENA here makes read timing explicit for future controllers.
    // If the design wants "always read", each *_en can simply be tied to 1'b1.

    wire [7:0]  conv1_weight_raw;
    wire [7:0]  conv3_weight_raw;
    wire [31:0] conv1_m0_raw;
    wire [63:0] conv1_m1_raw;
    wire [31:0] conv3_m0_raw;
    wire [63:0] conv3_m1_raw;

    assign conv1_weight_data = conv1_weight_raw;
    assign conv3_weight_data = conv3_weight_raw;
    assign conv1_m0_data     = conv1_m0_raw;
    assign conv1_m1_data     = conv1_m1_raw;
    assign conv3_m0_data     = conv3_m0_raw;
    assign conv3_m1_data     = conv3_m1_raw;

    conv1_weight_rom u_conv1_weight_rom (
        .clka(clk),
        .ena(conv1_weight_en),
        .addra(conv1_weight_addr),
        .douta(conv1_weight_raw)
    );

    conv3_weight_rom u_conv3_weight_rom (
        .clka(clk),
        .ena(conv3_weight_en),
        .addra(conv3_weight_addr),
        .douta(conv3_weight_raw)
    );

    conv1_m0_rom u_conv1_m0_rom (
        .clka(clk),
        .ena(conv1_m0_en),
        .addra(conv1_m0_addr),
        .douta(conv1_m0_raw)
    );

    conv1_m1_rom u_conv1_m1_rom (
        .clka(clk),
        .ena(conv1_m1_en),
        .addra(conv1_m1_addr),
        .douta(conv1_m1_raw)
    );

    conv3_m0_rom u_conv3_m0_rom (
        .clka(clk),
        .ena(conv3_m0_en),
        .addra(conv3_m0_addr),
        .douta(conv3_m0_raw)
    );

    conv3_m1_rom u_conv3_m1_rom (
        .clka(clk),
        .ena(conv3_m1_en),
        .addra(conv3_m1_addr),
        .douta(conv3_m1_raw)
    );

endmodule
