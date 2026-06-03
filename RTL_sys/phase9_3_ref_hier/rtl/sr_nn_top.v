`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_nn_top
// -----------------------------------------------------------------------------
// Phase9.3 reference-like CNN hierarchy top.
//
// Goal for Vivado schematic:
//   controller + ROM IP + Conv1 + slice + Conv3 + RAM IP + PixelShuffle
//   should be visible at the same level.
// -----------------------------------------------------------------------------

module sr_nn_top (
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

    input wire dbg_c3_rd_en,
    input wire [5:0] dbg_c3_rd_addr,
    output wire [31:0] dbg_c3_rd_data,

    input wire dbg_out_rd_en,
    input wire [6:0] dbg_out_rd_addr,
    output wire [15:0] dbg_out_rd_data
);

    // -------------------------------------------------------------------------
    // Parameter ROM wires
    // -------------------------------------------------------------------------
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

    // ROM IPs stay at this top level for readable Vivado hierarchy.
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

    // -------------------------------------------------------------------------
    // CNN datapath wires
    // -------------------------------------------------------------------------
    wire conv1_in_valid;
    wire conv1_in_ready;
    wire conv1_out_valid;
    wire [15:0] conv1_out_x;
    wire [15:0] conv1_out_y;

    wire signed [7:0] conv1_q0;
    wire signed [7:0] conv1_q1;
    wire signed [7:0] conv1_q2;
    wire signed [7:0] conv1_q3;
    wire signed [7:0] conv1_q4;
    wire signed [7:0] conv1_q5;
    wire signed [7:0] conv1_q6;
    wire signed [7:0] conv1_q7;

    wire signed [31:0] conv1_acc0;
    wire signed [31:0] conv1_acc1;
    wire signed [31:0] conv1_acc2;
    wire signed [31:0] conv1_acc3;
    wire signed [31:0] conv1_acc4;
    wire signed [31:0] conv1_acc5;
    wire signed [31:0] conv1_acc6;
    wire signed [31:0] conv1_acc7;

    wire signed [7:0] win00_dbg;
    wire signed [7:0] win01_dbg;
    wire signed [7:0] win02_dbg;
    wire signed [7:0] win10_dbg;
    wire signed [7:0] win11_dbg;
    wire signed [7:0] win12_dbg;
    wire signed [7:0] win20_dbg;
    wire signed [7:0] win21_dbg;
    wire signed [7:0] win22_dbg;

    wire slice_valid;
    wire slice_last;
    wire [5:0] slice_addr;
    wire signed [7:0] c3_in0;
    wire signed [7:0] c3_in1;
    wire signed [7:0] c3_in2;
    wire signed [7:0] c3_in3;
    wire signed [7:0] c3_in4;
    wire signed [7:0] c3_in5;
    wire signed [7:0] c3_in6;
    wire signed [7:0] c3_in7;

    wire signed [7:0] conv3_q0;
    wire signed [7:0] conv3_q1;
    wire signed [7:0] conv3_q2;
    wire signed [7:0] conv3_q3;

    wire ps_rst;
    wire ps_in_valid;
    wire ps_wr_en_a;
    wire [7:0] ps_wr_addr_a;
    wire [15:0] ps_wr_data_a;
    wire ps_wr_en_b;
    wire [7:0] ps_wr_addr_b;
    wire [15:0] ps_wr_data_b;
    wire ps_frame_done;

    wire conv3_feature_wr_en;
    wire [5:0] conv3_feature_wr_addr;
    wire [31:0] conv3_feature_wr_data;
    wire conv3_feature_rd_en;
    wire [5:0] conv3_feature_rd_addr;
    wire [31:0] conv3_feature_rd_data;
    wire conv3_feature_ram_rd_en;
    wire [5:0] conv3_feature_ram_rd_addr;

    wire output_ram_wr_en_a;
    wire [7:0] output_ram_wr_addr_a;
    wire [15:0] output_ram_wr_data_a;
    wire output_ram_wr_en_b;
    wire [7:0] output_ram_wr_addr_b;
    wire [15:0] output_ram_wr_data_b;
    wire [15:0] output_ram_dout_a;
    wire [15:0] output_ram_dout_b;
    wire output_ram_dbg_en;
    wire [6:0] output_ram_dbg_addr;

    wire signed [7:0] ps_c0;
    wire signed [7:0] ps_c1;
    wire signed [7:0] ps_c2;
    wire signed [7:0] ps_c3;

    assign ps_c0 = conv3_feature_rd_data[7:0];
    assign ps_c1 = conv3_feature_rd_data[15:8];
    assign ps_c2 = conv3_feature_rd_data[23:16];
    assign ps_c3 = conv3_feature_rd_data[31:24];

    assign conv3_feature_ram_rd_en = done ? dbg_c3_rd_en : conv3_feature_rd_en;
    assign conv3_feature_ram_rd_addr = done ? dbg_c3_rd_addr : conv3_feature_rd_addr;
    assign dbg_c3_rd_data = conv3_feature_rd_data;

    assign output_ram_dbg_en = done ? dbg_out_rd_en : 1'b0;
    assign output_ram_dbg_addr = dbg_out_rd_addr;
    assign dbg_out_rd_data = output_ram_dout_a;

    sr_ctrl ctrl_u0 (
        .clk(clk),
        .rst(rst),
        .preload_done(preload_done),
        .core_start(core_start),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .conv1_in_ready(conv1_in_ready),
        .conv1_in_valid(conv1_in_valid),
        .slice_valid(slice_valid),
        .slice_last(slice_last),
        .slice_addr(slice_addr),
        .conv3_q0(conv3_q0),
        .conv3_q1(conv3_q1),
        .conv3_q2(conv3_q2),
        .conv3_q3(conv3_q3),
        .conv3_feature_wr_en(conv3_feature_wr_en),
        .conv3_feature_wr_addr(conv3_feature_wr_addr),
        .conv3_feature_wr_data(conv3_feature_wr_data),
        .conv3_feature_rd_en(conv3_feature_rd_en),
        .conv3_feature_rd_addr(conv3_feature_rd_addr),
        .ps_rst(ps_rst),
        .ps_in_valid(ps_in_valid),
        .busy(busy),
        .done(done)
    );

    sr_conv1_3x3_cin1_cout8_block conv1_block (
        .clk(clk),
        .rst(rst),
        .in_valid(conv1_in_valid),
        .in_pixel(in_pixel),
        .in_ready(conv1_in_ready),

        .w000(conv1_weight_flat[7:0]),     .w001(conv1_weight_flat[15:8]),    .w002(conv1_weight_flat[23:16]),
        .w003(conv1_weight_flat[31:24]),   .w004(conv1_weight_flat[39:32]),   .w005(conv1_weight_flat[47:40]),
        .w006(conv1_weight_flat[55:48]),   .w007(conv1_weight_flat[63:56]),   .w008(conv1_weight_flat[71:64]),
        .w100(conv1_weight_flat[79:72]),   .w101(conv1_weight_flat[87:80]),   .w102(conv1_weight_flat[95:88]),
        .w103(conv1_weight_flat[103:96]),  .w104(conv1_weight_flat[111:104]), .w105(conv1_weight_flat[119:112]),
        .w106(conv1_weight_flat[127:120]), .w107(conv1_weight_flat[135:128]), .w108(conv1_weight_flat[143:136]),
        .w200(conv1_weight_flat[151:144]), .w201(conv1_weight_flat[159:152]), .w202(conv1_weight_flat[167:160]),
        .w203(conv1_weight_flat[175:168]), .w204(conv1_weight_flat[183:176]), .w205(conv1_weight_flat[191:184]),
        .w206(conv1_weight_flat[199:192]), .w207(conv1_weight_flat[207:200]), .w208(conv1_weight_flat[215:208]),
        .w300(conv1_weight_flat[223:216]), .w301(conv1_weight_flat[231:224]), .w302(conv1_weight_flat[239:232]),
        .w303(conv1_weight_flat[247:240]), .w304(conv1_weight_flat[255:248]), .w305(conv1_weight_flat[263:256]),
        .w306(conv1_weight_flat[271:264]), .w307(conv1_weight_flat[279:272]), .w308(conv1_weight_flat[287:280]),
        .w400(conv1_weight_flat[295:288]), .w401(conv1_weight_flat[303:296]), .w402(conv1_weight_flat[311:304]),
        .w403(conv1_weight_flat[319:312]), .w404(conv1_weight_flat[327:320]), .w405(conv1_weight_flat[335:328]),
        .w406(conv1_weight_flat[343:336]), .w407(conv1_weight_flat[351:344]), .w408(conv1_weight_flat[359:352]),
        .w500(conv1_weight_flat[367:360]), .w501(conv1_weight_flat[375:368]), .w502(conv1_weight_flat[383:376]),
        .w503(conv1_weight_flat[391:384]), .w504(conv1_weight_flat[399:392]), .w505(conv1_weight_flat[407:400]),
        .w506(conv1_weight_flat[415:408]), .w507(conv1_weight_flat[423:416]), .w508(conv1_weight_flat[431:424]),
        .w600(conv1_weight_flat[439:432]), .w601(conv1_weight_flat[447:440]), .w602(conv1_weight_flat[455:448]),
        .w603(conv1_weight_flat[463:456]), .w604(conv1_weight_flat[471:464]), .w605(conv1_weight_flat[479:472]),
        .w606(conv1_weight_flat[487:480]), .w607(conv1_weight_flat[495:488]), .w608(conv1_weight_flat[503:496]),
        .w700(conv1_weight_flat[511:504]), .w701(conv1_weight_flat[519:512]), .w702(conv1_weight_flat[527:520]),
        .w703(conv1_weight_flat[535:528]), .w704(conv1_weight_flat[543:536]), .w705(conv1_weight_flat[551:544]),
        .w706(conv1_weight_flat[559:552]), .w707(conv1_weight_flat[567:560]), .w708(conv1_weight_flat[575:568]),

        .m0_0(conv1_m0_flat[31:0]),    .m0_1(conv1_m0_flat[63:32]),
        .m0_2(conv1_m0_flat[95:64]),   .m0_3(conv1_m0_flat[127:96]),
        .m0_4(conv1_m0_flat[159:128]), .m0_5(conv1_m0_flat[191:160]),
        .m0_6(conv1_m0_flat[223:192]), .m0_7(conv1_m0_flat[255:224]),
        .m1_0(conv1_m1_flat[63:0]),    .m1_1(conv1_m1_flat[127:64]),
        .m1_2(conv1_m1_flat[191:128]), .m1_3(conv1_m1_flat[255:192]),
        .m1_4(conv1_m1_flat[319:256]), .m1_5(conv1_m1_flat[383:320]),
        .m1_6(conv1_m1_flat[447:384]), .m1_7(conv1_m1_flat[511:448]),

        .out_valid(conv1_out_valid),
        .out_x(conv1_out_x),
        .out_y(conv1_out_y),
        .q0(conv1_q0), .q1(conv1_q1), .q2(conv1_q2), .q3(conv1_q3),
        .q4(conv1_q4), .q5(conv1_q5), .q6(conv1_q6), .q7(conv1_q7),
        .acc0(conv1_acc0), .acc1(conv1_acc1), .acc2(conv1_acc2), .acc3(conv1_acc3),
        .acc4(conv1_acc4), .acc5(conv1_acc5), .acc6(conv1_acc6), .acc7(conv1_acc7),
        .win00_dbg(win00_dbg), .win01_dbg(win01_dbg), .win02_dbg(win02_dbg),
        .win10_dbg(win10_dbg), .win11_dbg(win11_dbg), .win12_dbg(win12_dbg),
        .win20_dbg(win20_dbg), .win21_dbg(win21_dbg), .win22_dbg(win22_dbg)
    );

    sr_c1c3_slice c1c3_slice_u0 (
        .clk(clk),
        .rst(rst),
        .in_valid(conv1_out_valid),
        .in_x(conv1_out_x),
        .in_y(conv1_out_y),
        .in_c0(conv1_q0), .in_c1(conv1_q1), .in_c2(conv1_q2), .in_c3(conv1_q3),
        .in_c4(conv1_q4), .in_c5(conv1_q5), .in_c6(conv1_q6), .in_c7(conv1_q7),
        .out_valid(slice_valid),
        .out_last(slice_last),
        .out_addr(slice_addr),
        .out_c0(c3_in0), .out_c1(c3_in1), .out_c2(c3_in2), .out_c3(c3_in3),
        .out_c4(c3_in4), .out_c5(c3_in5), .out_c6(c3_in6), .out_c7(c3_in7)
    );

    sr_conv1x1_cin8_cout4_block conv3_block (
        .in_c0(c3_in0), .in_c1(c3_in1), .in_c2(c3_in2), .in_c3(c3_in3),
        .in_c4(c3_in4), .in_c5(c3_in5), .in_c6(c3_in6), .in_c7(c3_in7),
        .w00(conv3_weight_flat[7:0]),     .w01(conv3_weight_flat[15:8]),
        .w02(conv3_weight_flat[23:16]),   .w03(conv3_weight_flat[31:24]),
        .w04(conv3_weight_flat[39:32]),   .w05(conv3_weight_flat[47:40]),
        .w06(conv3_weight_flat[55:48]),   .w07(conv3_weight_flat[63:56]),
        .w10(conv3_weight_flat[71:64]),   .w11(conv3_weight_flat[79:72]),
        .w12(conv3_weight_flat[87:80]),   .w13(conv3_weight_flat[95:88]),
        .w14(conv3_weight_flat[103:96]),  .w15(conv3_weight_flat[111:104]),
        .w16(conv3_weight_flat[119:112]), .w17(conv3_weight_flat[127:120]),
        .w20(conv3_weight_flat[135:128]), .w21(conv3_weight_flat[143:136]),
        .w22(conv3_weight_flat[151:144]), .w23(conv3_weight_flat[159:152]),
        .w24(conv3_weight_flat[167:160]), .w25(conv3_weight_flat[175:168]),
        .w26(conv3_weight_flat[183:176]), .w27(conv3_weight_flat[191:184]),
        .w30(conv3_weight_flat[199:192]), .w31(conv3_weight_flat[207:200]),
        .w32(conv3_weight_flat[215:208]), .w33(conv3_weight_flat[223:216]),
        .w34(conv3_weight_flat[231:224]), .w35(conv3_weight_flat[239:232]),
        .w36(conv3_weight_flat[247:240]), .w37(conv3_weight_flat[255:248]),
        .m0_0(conv3_m0_flat[31:0]),   .m0_1(conv3_m0_flat[63:32]),
        .m0_2(conv3_m0_flat[95:64]),  .m0_3(conv3_m0_flat[127:96]),
        .m1_0(conv3_m1_flat[63:0]),   .m1_1(conv3_m1_flat[127:64]),
        .m1_2(conv3_m1_flat[191:128]),.m1_3(conv3_m1_flat[255:192]),
        .q0(conv3_q0), .q1(conv3_q1), .q2(conv3_q2), .q3(conv3_q3)
    );

    pixel_shuffle_core #(
        .LR_WIDTH(8),
        .LR_HEIGHT(8),
        .ADDR_WIDTH(8)
    ) pixel_shuffle_u0 (
        .clk(clk),
        .rst(ps_rst),
        .in_valid(ps_in_valid),
        .in_c0(ps_c0),
        .in_c1(ps_c1),
        .in_c2(ps_c2),
        .in_c3(ps_c3),
        .wr_en_a(ps_wr_en_a),
        .wr_addr_a(ps_wr_addr_a),
        .wr_data_a(ps_wr_data_a),
        .wr_en_b(ps_wr_en_b),
        .wr_addr_b(ps_wr_addr_b),
        .wr_data_b(ps_wr_data_b),
        .frame_done(ps_frame_done)
    );

    sr_out_pack out_pack_u0 (
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

    // RAM IPs stay at this top level for readable Vivado hierarchy.
    conv3_feature_ram u_conv3_feature_ram (
        .clka(clk),
        .ena(conv3_feature_wr_en),
        .wea(conv3_feature_wr_en),
        .addra(conv3_feature_wr_addr),
        .dina(conv3_feature_wr_data),
        .clkb(clk),
        .enb(conv3_feature_ram_rd_en),
        .addrb(conv3_feature_ram_rd_addr),
        .doutb(conv3_feature_rd_data)
    );

    output_image_ram u_output_image_ram (
        .clka(clk),
        .ena(output_ram_wr_en_a | output_ram_dbg_en),
        .wea(output_ram_wr_en_a),
        .addra(output_ram_dbg_en ? output_ram_dbg_addr : output_ram_wr_addr_a[6:0]),
        .dina(output_ram_wr_data_a),
        .douta(output_ram_dout_a),
        .clkb(clk),
        .enb(output_ram_wr_en_b),
        .web(output_ram_wr_en_b),
        .addrb(output_ram_wr_addr_b[6:0]),
        .dinb(output_ram_wr_data_b),
        .doutb(output_ram_dout_b)
    );

endmodule
