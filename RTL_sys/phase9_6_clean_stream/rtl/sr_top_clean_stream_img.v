`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_top_clean_stream_img
// -----------------------------------------------------------------------------
// Phase9.6 clean streaming image-level SR top.
//
// Parameter ROM IP, Conv1, Conv3, PixelShuffle, output pack, and output RAM are
// visible at the same hierarchy level. Conv3 output streams directly into
// PixelShuffle; no Conv3 feature RAM is used.
// -----------------------------------------------------------------------------

module sr_top_clean_stream_img (
    input wire clk,
    input wire rst,
    input wire preload_start,
    input wire core_start,

    input wire in_valid,
    input signed [7:0] in_pixel,
    output wire in_ready,

    output wire preload_busy,
    output wire preload_done,
    output wire busy,
    output wire done,

    input wire out_rd_en,
    input wire [14:0] out_rd_addr,
    output wire [15:0] out_rd_data
);

    wire conv1_weight_en;
    wire [6:0] conv1_weight_addr;
    wire signed [7:0] conv1_weight_data;

    wire conv3_weight_en;
    wire [4:0] conv3_weight_addr;
    wire signed [7:0] conv3_weight_data;

    wire conv1_m0_en;
    wire [2:0] conv1_m0_addr;
    wire signed [31:0] conv1_m0_data;

    wire conv1_m1_en;
    wire [2:0] conv1_m1_addr;
    wire signed [63:0] conv1_m1_data;

    wire conv3_m0_en;
    wire [1:0] conv3_m0_addr;
    wire signed [31:0] conv3_m0_data;

    wire conv3_m1_en;
    wire [1:0] conv3_m1_addr;
    wire signed [63:0] conv3_m1_data;

    wire [575:0] conv1_weight_flat;
    wire [255:0] conv3_weight_flat;
    wire [255:0] conv1_m0_flat;
    wire [511:0] conv1_m1_flat;
    wire [127:0] conv3_m0_flat;
    wire [255:0] conv3_m1_flat;

    wire conv1_in_valid;
    wire conv1_in_ready;
    wire conv1_out_valid;

    wire signed [7:0] conv1_q0;
    wire signed [7:0] conv1_q1;
    wire signed [7:0] conv1_q2;
    wire signed [7:0] conv1_q3;
    wire signed [7:0] conv1_q4;
    wire signed [7:0] conv1_q5;
    wire signed [7:0] conv1_q6;
    wire signed [7:0] conv1_q7;

    wire slice_valid;
    wire signed [7:0] conv3_in0;
    wire signed [7:0] conv3_in1;
    wire signed [7:0] conv3_in2;
    wire signed [7:0] conv3_in3;
    wire signed [7:0] conv3_in4;
    wire signed [7:0] conv3_in5;
    wire signed [7:0] conv3_in6;
    wire signed [7:0] conv3_in7;

    wire signed [7:0] conv3_q0;
    wire signed [7:0] conv3_q1;
    wire signed [7:0] conv3_q2;
    wire signed [7:0] conv3_q3;

    wire ps_rst;
    wire ps_in_valid;
    wire ps_wr_en_a;
    wire [14:0] ps_wr_addr_a;
    wire [15:0] ps_wr_data_a;
    wire ps_wr_en_b;
    wire [14:0] ps_wr_addr_b;
    wire [15:0] ps_wr_data_b;
    wire ps_frame_done;

    wire output_ram_wr_en_a;
    wire [14:0] output_ram_wr_addr_a;
    wire [15:0] output_ram_wr_data_a;
    wire output_ram_wr_en_b;
    wire [14:0] output_ram_wr_addr_b;
    wire [15:0] output_ram_wr_data_b;
    wire [15:0] output_ram_dout_a;
    wire [15:0] output_ram_dout_b;

    assign out_rd_data = output_ram_dout_a;

    conv1_weight_rom u_conv1_weight_rom (
        .clka(clk),
        .ena(conv1_weight_en),
        .addra(conv1_weight_addr),
        .douta(conv1_weight_data)
    );

    conv3_weight_rom u_conv3_weight_rom (
        .clka(clk),
        .ena(conv3_weight_en),
        .addra(conv3_weight_addr),
        .douta(conv3_weight_data)
    );

    conv1_m0_rom u_conv1_m0_rom (
        .clka(clk),
        .ena(conv1_m0_en),
        .addra(conv1_m0_addr),
        .douta(conv1_m0_data)
    );

    conv1_m1_rom u_conv1_m1_rom (
        .clka(clk),
        .ena(conv1_m1_en),
        .addra(conv1_m1_addr),
        .douta(conv1_m1_data)
    );

    conv3_m0_rom u_conv3_m0_rom (
        .clka(clk),
        .ena(conv3_m0_en),
        .addra(conv3_m0_addr),
        .douta(conv3_m0_data)
    );

    conv3_m1_rom u_conv3_m1_rom (
        .clka(clk),
        .ena(conv3_m1_en),
        .addra(conv3_m1_addr),
        .douta(conv3_m1_data)
    );

    sr_pctrl pctrl_u0 (
        .clk(clk),
        .rst(rst),
        .preload_start(preload_start),
        .preload_busy(preload_busy),
        .preload_done(preload_done),
        .conv1_weight_en(conv1_weight_en),
        .conv1_weight_addr(conv1_weight_addr),
        .conv1_weight_data(conv1_weight_data),
        .conv3_weight_en(conv3_weight_en),
        .conv3_weight_addr(conv3_weight_addr),
        .conv3_weight_data(conv3_weight_data),
        .conv1_m0_en(conv1_m0_en),
        .conv1_m0_addr(conv1_m0_addr),
        .conv1_m0_data(conv1_m0_data),
        .conv1_m1_en(conv1_m1_en),
        .conv1_m1_addr(conv1_m1_addr),
        .conv1_m1_data(conv1_m1_data),
        .conv3_m0_en(conv3_m0_en),
        .conv3_m0_addr(conv3_m0_addr),
        .conv3_m0_data(conv3_m0_data),
        .conv3_m1_en(conv3_m1_en),
        .conv3_m1_addr(conv3_m1_addr),
        .conv3_m1_data(conv3_m1_data),
        .conv1_weight_flat(conv1_weight_flat),
        .conv3_weight_flat(conv3_weight_flat),
        .conv1_m0_flat(conv1_m0_flat),
        .conv1_m1_flat(conv1_m1_flat),
        .conv3_m0_flat(conv3_m0_flat),
        .conv3_m1_flat(conv3_m1_flat)
    );

    sr_ctrl_clean_stream_img ctrl_u0 (
        .clk(clk),
        .rst(rst),
        .preload_done(preload_done),
        .core_start(core_start),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .conv1_in_ready(conv1_in_ready),
        .conv1_in_valid(conv1_in_valid),
        .slice_valid(slice_valid),
        .ps_frame_done(ps_frame_done),
        .ps_rst(ps_rst),
        .ps_in_valid(ps_in_valid),
        .busy(busy),
        .done(done)
    );

    sr_conv1_3x3_cin1_cout8_flat #(
        .IMG_W(128),
        .IMG_H(128)
    ) conv1_block (
        .clk(clk),
        .rst(rst),
        .in_valid(conv1_in_valid),
        .in_pixel(in_pixel),
        .in_ready(conv1_in_ready),
        .conv1_weight_flat(conv1_weight_flat),
        .conv1_m0_flat(conv1_m0_flat),
        .conv1_m1_flat(conv1_m1_flat),
        .out_valid(conv1_out_valid),
        .q0(conv1_q0), .q1(conv1_q1), .q2(conv1_q2), .q3(conv1_q3),
        .q4(conv1_q4), .q5(conv1_q5), .q6(conv1_q6), .q7(conv1_q7)
    );

    sr_conv1_to_conv3_stream_slice #(
        .IMG_W(128),
        .IMG_H(128)
    ) conv1_to_conv3_slice_u0 (
        .clk(clk),
        .rst(rst),
        .in_valid(conv1_out_valid),
        .in_c0(conv1_q0), .in_c1(conv1_q1), .in_c2(conv1_q2), .in_c3(conv1_q3),
        .in_c4(conv1_q4), .in_c5(conv1_q5), .in_c6(conv1_q6), .in_c7(conv1_q7),
        .out_valid(slice_valid),
        .out_c0(conv3_in0), .out_c1(conv3_in1), .out_c2(conv3_in2), .out_c3(conv3_in3),
        .out_c4(conv3_in4), .out_c5(conv3_in5), .out_c6(conv3_in6), .out_c7(conv3_in7)
    );

    sr_conv1x1_cin8_cout4_flat conv3_block (
        .in_c0(conv3_in0), .in_c1(conv3_in1), .in_c2(conv3_in2), .in_c3(conv3_in3),
        .in_c4(conv3_in4), .in_c5(conv3_in5), .in_c6(conv3_in6), .in_c7(conv3_in7),
        .conv3_weight_flat(conv3_weight_flat),
        .conv3_m0_flat(conv3_m0_flat),
        .conv3_m1_flat(conv3_m1_flat),
        .q0(conv3_q0), .q1(conv3_q1), .q2(conv3_q2), .q3(conv3_q3)
    );

    pixel_shuffle_core #(
        .LR_WIDTH(128),
        .LR_HEIGHT(128),
        .ADDR_WIDTH(15)
    ) pixel_shuffle_u0 (
        .clk(clk),
        .rst(ps_rst),
        .in_valid(ps_in_valid),
        .in_c0(conv3_q0),
        .in_c1(conv3_q1),
        .in_c2(conv3_q2),
        .in_c3(conv3_q3),
        .wr_en_a(ps_wr_en_a),
        .wr_addr_a(ps_wr_addr_a),
        .wr_data_a(ps_wr_data_a),
        .wr_en_b(ps_wr_en_b),
        .wr_addr_b(ps_wr_addr_b),
        .wr_data_b(ps_wr_data_b),
        .frame_done(ps_frame_done)
    );

    sr_output_pack2x2_uint8 #(
        .ADDR_WIDTH(15)
    ) out_pack_u0 (
        .ps_wr_en_a(ps_wr_en_a),
        .ps_wr_addr_a(ps_wr_addr_a),
        .ps_wr_data_a(ps_wr_data_a),
        .ps_wr_en_b(ps_wr_en_b),
        .ps_wr_addr_b(ps_wr_addr_b),
        .ps_wr_data_b(ps_wr_data_b),
        .output_ram_wr_en_a(output_ram_wr_en_a),
        .output_ram_wr_addr_a(output_ram_wr_addr_a),
        .output_ram_wr_data_a(output_ram_wr_data_a),
        .output_ram_wr_en_b(output_ram_wr_en_b),
        .output_ram_wr_addr_b(output_ram_wr_addr_b),
        .output_ram_wr_data_b(output_ram_wr_data_b)
    );

    output_image_ram u_output_image_ram (
        .clka(clk),
        .ena(output_ram_wr_en_a | (done & out_rd_en)),
        .wea(done ? 1'b0 : output_ram_wr_en_a),
        .addra(done ? out_rd_addr : output_ram_wr_addr_a),
        .dina(output_ram_wr_data_a),
        .douta(output_ram_dout_a),
        .clkb(clk),
        .enb(output_ram_wr_en_b),
        .web(done ? 1'b0 : output_ram_wr_en_b),
        .addrb(output_ram_wr_addr_b),
        .dinb(output_ram_wr_data_b),
        .doutb(output_ram_dout_b)
    );

endmodule
