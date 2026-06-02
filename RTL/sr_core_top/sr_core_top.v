`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_core_top
// -----------------------------------------------------------------------------
// Verification-oriented top for the quantized SR core.
//
// This is not the deployment version.  It intentionally uses simple behavioral
// stage memories between verified RTL blocks so each stage can be debugged
// independently:
//
//   input stream
//     -> Conv1 block
//     -> feature_mem0
//     -> Conv3 block
//     -> feature_mem1
//     -> PixelShuffle write transaction core
//     -> feature_mem2
//     -> OutputStage
//     -> output_mem
// -----------------------------------------------------------------------------

module sr_core_top (
    input wire clk,
    input wire rst,
    input wire start,

    input wire in_valid,
    input signed [7:0] in_pixel,
    output wire in_ready,

    input signed [7:0] conv1_w000,
    input signed [7:0] conv1_w001,
    input signed [7:0] conv1_w002,
    input signed [7:0] conv1_w003,
    input signed [7:0] conv1_w004,
    input signed [7:0] conv1_w005,
    input signed [7:0] conv1_w006,
    input signed [7:0] conv1_w007,
    input signed [7:0] conv1_w008,

    input signed [7:0] conv1_w100,
    input signed [7:0] conv1_w101,
    input signed [7:0] conv1_w102,
    input signed [7:0] conv1_w103,
    input signed [7:0] conv1_w104,
    input signed [7:0] conv1_w105,
    input signed [7:0] conv1_w106,
    input signed [7:0] conv1_w107,
    input signed [7:0] conv1_w108,

    input signed [7:0] conv1_w200,
    input signed [7:0] conv1_w201,
    input signed [7:0] conv1_w202,
    input signed [7:0] conv1_w203,
    input signed [7:0] conv1_w204,
    input signed [7:0] conv1_w205,
    input signed [7:0] conv1_w206,
    input signed [7:0] conv1_w207,
    input signed [7:0] conv1_w208,

    input signed [7:0] conv1_w300,
    input signed [7:0] conv1_w301,
    input signed [7:0] conv1_w302,
    input signed [7:0] conv1_w303,
    input signed [7:0] conv1_w304,
    input signed [7:0] conv1_w305,
    input signed [7:0] conv1_w306,
    input signed [7:0] conv1_w307,
    input signed [7:0] conv1_w308,

    input signed [7:0] conv1_w400,
    input signed [7:0] conv1_w401,
    input signed [7:0] conv1_w402,
    input signed [7:0] conv1_w403,
    input signed [7:0] conv1_w404,
    input signed [7:0] conv1_w405,
    input signed [7:0] conv1_w406,
    input signed [7:0] conv1_w407,
    input signed [7:0] conv1_w408,

    input signed [7:0] conv1_w500,
    input signed [7:0] conv1_w501,
    input signed [7:0] conv1_w502,
    input signed [7:0] conv1_w503,
    input signed [7:0] conv1_w504,
    input signed [7:0] conv1_w505,
    input signed [7:0] conv1_w506,
    input signed [7:0] conv1_w507,
    input signed [7:0] conv1_w508,

    input signed [7:0] conv1_w600,
    input signed [7:0] conv1_w601,
    input signed [7:0] conv1_w602,
    input signed [7:0] conv1_w603,
    input signed [7:0] conv1_w604,
    input signed [7:0] conv1_w605,
    input signed [7:0] conv1_w606,
    input signed [7:0] conv1_w607,
    input signed [7:0] conv1_w608,

    input signed [7:0] conv1_w700,
    input signed [7:0] conv1_w701,
    input signed [7:0] conv1_w702,
    input signed [7:0] conv1_w703,
    input signed [7:0] conv1_w704,
    input signed [7:0] conv1_w705,
    input signed [7:0] conv1_w706,
    input signed [7:0] conv1_w707,
    input signed [7:0] conv1_w708,

    input signed [31:0] conv1_m0_0,
    input signed [31:0] conv1_m0_1,
    input signed [31:0] conv1_m0_2,
    input signed [31:0] conv1_m0_3,
    input signed [31:0] conv1_m0_4,
    input signed [31:0] conv1_m0_5,
    input signed [31:0] conv1_m0_6,
    input signed [31:0] conv1_m0_7,

    input signed [63:0] conv1_m1_0,
    input signed [63:0] conv1_m1_1,
    input signed [63:0] conv1_m1_2,
    input signed [63:0] conv1_m1_3,
    input signed [63:0] conv1_m1_4,
    input signed [63:0] conv1_m1_5,
    input signed [63:0] conv1_m1_6,
    input signed [63:0] conv1_m1_7,

    input signed [7:0] conv3_w00,
    input signed [7:0] conv3_w01,
    input signed [7:0] conv3_w02,
    input signed [7:0] conv3_w03,
    input signed [7:0] conv3_w04,
    input signed [7:0] conv3_w05,
    input signed [7:0] conv3_w06,
    input signed [7:0] conv3_w07,

    input signed [7:0] conv3_w10,
    input signed [7:0] conv3_w11,
    input signed [7:0] conv3_w12,
    input signed [7:0] conv3_w13,
    input signed [7:0] conv3_w14,
    input signed [7:0] conv3_w15,
    input signed [7:0] conv3_w16,
    input signed [7:0] conv3_w17,

    input signed [7:0] conv3_w20,
    input signed [7:0] conv3_w21,
    input signed [7:0] conv3_w22,
    input signed [7:0] conv3_w23,
    input signed [7:0] conv3_w24,
    input signed [7:0] conv3_w25,
    input signed [7:0] conv3_w26,
    input signed [7:0] conv3_w27,

    input signed [7:0] conv3_w30,
    input signed [7:0] conv3_w31,
    input signed [7:0] conv3_w32,
    input signed [7:0] conv3_w33,
    input signed [7:0] conv3_w34,
    input signed [7:0] conv3_w35,
    input signed [7:0] conv3_w36,
    input signed [7:0] conv3_w37,

    input signed [31:0] conv3_m0_0,
    input signed [31:0] conv3_m0_1,
    input signed [31:0] conv3_m0_2,
    input signed [31:0] conv3_m0_3,

    input signed [63:0] conv3_m1_0,
    input signed [63:0] conv3_m1_1,
    input signed [63:0] conv3_m1_2,
    input signed [63:0] conv3_m1_3,

    output reg busy,
    output reg done
);

localparam ST_IDLE  = 3'd0;
localparam ST_CONV1 = 3'd1;
localparam ST_CONV3 = 3'd2;
localparam ST_PS    = 3'd3;
localparam ST_OUT   = 3'd4;
localparam ST_DONE  = 3'd5;

reg [2:0] state;

reg signed [7:0] feature_mem0 [0:511];
reg signed [7:0] feature_mem1 [0:255];
reg signed [7:0] feature_mem2 [0:255];
reg [7:0] output_mem [0:255];

reg [15:0] conv3_pixel_index;
reg [15:0] ps_pixel_index;
reg [15:0] out_pixel_index;

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

wire signed [7:0] conv3_in_c0;
wire signed [7:0] conv3_in_c1;
wire signed [7:0] conv3_in_c2;
wire signed [7:0] conv3_in_c3;
wire signed [7:0] conv3_in_c4;
wire signed [7:0] conv3_in_c5;
wire signed [7:0] conv3_in_c6;
wire signed [7:0] conv3_in_c7;
wire signed [7:0] conv3_q0;
wire signed [7:0] conv3_q1;
wire signed [7:0] conv3_q2;
wire signed [7:0] conv3_q3;

wire ps_in_valid;
wire ps_rst;
wire                  ps_wr_en_a;
wire [7:0]            ps_wr_addr_a;
wire [15:0]           ps_wr_data_a;
wire                  ps_wr_en_b;
wire [7:0]            ps_wr_addr_b;
wire [15:0]           ps_wr_data_b;
wire                  ps_frame_done;

wire [7:0] output_stage_uint8;

assign conv1_in_valid = (state == ST_CONV1) && in_valid;
assign in_ready = (state == ST_CONV1) && conv1_in_ready;

assign conv3_in_c0 = feature_mem0[conv3_pixel_index*8 + 0];
assign conv3_in_c1 = feature_mem0[conv3_pixel_index*8 + 1];
assign conv3_in_c2 = feature_mem0[conv3_pixel_index*8 + 2];
assign conv3_in_c3 = feature_mem0[conv3_pixel_index*8 + 3];
assign conv3_in_c4 = feature_mem0[conv3_pixel_index*8 + 4];
assign conv3_in_c5 = feature_mem0[conv3_pixel_index*8 + 5];
assign conv3_in_c6 = feature_mem0[conv3_pixel_index*8 + 6];
assign conv3_in_c7 = feature_mem0[conv3_pixel_index*8 + 7];

assign ps_in_valid = (state == ST_PS);
assign ps_rst = rst || (state != ST_PS);

sr_conv1_3x3_cin1_cout8_block conv1_block (
    .clk(clk),
    .rst(rst),
    .in_valid(conv1_in_valid),
    .in_pixel(in_pixel),
    .in_ready(conv1_in_ready),

    .w000(conv1_w000), .w001(conv1_w001), .w002(conv1_w002),
    .w003(conv1_w003), .w004(conv1_w004), .w005(conv1_w005),
    .w006(conv1_w006), .w007(conv1_w007), .w008(conv1_w008),

    .w100(conv1_w100), .w101(conv1_w101), .w102(conv1_w102),
    .w103(conv1_w103), .w104(conv1_w104), .w105(conv1_w105),
    .w106(conv1_w106), .w107(conv1_w107), .w108(conv1_w108),

    .w200(conv1_w200), .w201(conv1_w201), .w202(conv1_w202),
    .w203(conv1_w203), .w204(conv1_w204), .w205(conv1_w205),
    .w206(conv1_w206), .w207(conv1_w207), .w208(conv1_w208),

    .w300(conv1_w300), .w301(conv1_w301), .w302(conv1_w302),
    .w303(conv1_w303), .w304(conv1_w304), .w305(conv1_w305),
    .w306(conv1_w306), .w307(conv1_w307), .w308(conv1_w308),

    .w400(conv1_w400), .w401(conv1_w401), .w402(conv1_w402),
    .w403(conv1_w403), .w404(conv1_w404), .w405(conv1_w405),
    .w406(conv1_w406), .w407(conv1_w407), .w408(conv1_w408),

    .w500(conv1_w500), .w501(conv1_w501), .w502(conv1_w502),
    .w503(conv1_w503), .w504(conv1_w504), .w505(conv1_w505),
    .w506(conv1_w506), .w507(conv1_w507), .w508(conv1_w508),

    .w600(conv1_w600), .w601(conv1_w601), .w602(conv1_w602),
    .w603(conv1_w603), .w604(conv1_w604), .w605(conv1_w605),
    .w606(conv1_w606), .w607(conv1_w607), .w608(conv1_w608),

    .w700(conv1_w700), .w701(conv1_w701), .w702(conv1_w702),
    .w703(conv1_w703), .w704(conv1_w704), .w705(conv1_w705),
    .w706(conv1_w706), .w707(conv1_w707), .w708(conv1_w708),

    .m0_0(conv1_m0_0), .m0_1(conv1_m0_1), .m0_2(conv1_m0_2), .m0_3(conv1_m0_3),
    .m0_4(conv1_m0_4), .m0_5(conv1_m0_5), .m0_6(conv1_m0_6), .m0_7(conv1_m0_7),

    .m1_0(conv1_m1_0), .m1_1(conv1_m1_1), .m1_2(conv1_m1_2), .m1_3(conv1_m1_3),
    .m1_4(conv1_m1_4), .m1_5(conv1_m1_5), .m1_6(conv1_m1_6), .m1_7(conv1_m1_7),

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

sr_conv1x1_cin8_cout4_block conv3_block (
    .in_c0(conv3_in_c0), .in_c1(conv3_in_c1), .in_c2(conv3_in_c2), .in_c3(conv3_in_c3),
    .in_c4(conv3_in_c4), .in_c5(conv3_in_c5), .in_c6(conv3_in_c6), .in_c7(conv3_in_c7),

    .w00(conv3_w00), .w01(conv3_w01), .w02(conv3_w02), .w03(conv3_w03),
    .w04(conv3_w04), .w05(conv3_w05), .w06(conv3_w06), .w07(conv3_w07),

    .w10(conv3_w10), .w11(conv3_w11), .w12(conv3_w12), .w13(conv3_w13),
    .w14(conv3_w14), .w15(conv3_w15), .w16(conv3_w16), .w17(conv3_w17),

    .w20(conv3_w20), .w21(conv3_w21), .w22(conv3_w22), .w23(conv3_w23),
    .w24(conv3_w24), .w25(conv3_w25), .w26(conv3_w26), .w27(conv3_w27),

    .w30(conv3_w30), .w31(conv3_w31), .w32(conv3_w32), .w33(conv3_w33),
    .w34(conv3_w34), .w35(conv3_w35), .w36(conv3_w36), .w37(conv3_w37),

    .m0_0(conv3_m0_0), .m0_1(conv3_m0_1), .m0_2(conv3_m0_2), .m0_3(conv3_m0_3),
    .m1_0(conv3_m1_0), .m1_1(conv3_m1_1), .m1_2(conv3_m1_2), .m1_3(conv3_m1_3),

    .q0(conv3_q0),
    .q1(conv3_q1),
    .q2(conv3_q2),
    .q3(conv3_q3)
);

pixel_shuffle_core #(
    .LR_WIDTH(8),
    .LR_HEIGHT(8),
    .ADDR_WIDTH(8)
) pixel_shuffle (
    .clk(clk),
    .rst(ps_rst),
    .in_valid(ps_in_valid),
    .in_c0(feature_mem1[ps_pixel_index*4 + 0]),
    .in_c1(feature_mem1[ps_pixel_index*4 + 1]),
    .in_c2(feature_mem1[ps_pixel_index*4 + 2]),
    .in_c3(feature_mem1[ps_pixel_index*4 + 3]),
    .wr_en_a(ps_wr_en_a),
    .wr_addr_a(ps_wr_addr_a),
    .wr_data_a(ps_wr_data_a),
    .wr_en_b(ps_wr_en_b),
    .wr_addr_b(ps_wr_addr_b),
    .wr_data_b(ps_wr_data_b),
    .frame_done(ps_frame_done)
);

sr_output_stage output_stage (
    .in_pixel(feature_mem2[out_pixel_index]),
    .out_pixel_uint8(output_stage_uint8)
);

always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
        busy <= 1'b0;
        done <= 1'b0;
        conv3_pixel_index <= 16'd0;
        ps_pixel_index <= 16'd0;
        out_pixel_index <= 16'd0;
    end else begin
        case (state)
            ST_IDLE: begin
                busy <= 1'b0;
                done <= 1'b0;
                conv3_pixel_index <= 16'd0;
                ps_pixel_index <= 16'd0;
                out_pixel_index <= 16'd0;
                if (start) begin
                    busy <= 1'b1;
                    state <= ST_CONV1;
                end
            end

            ST_CONV1: begin
                busy <= 1'b1;
                if (conv1_out_valid) begin
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 0] <= conv1_q0;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 1] <= conv1_q1;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 2] <= conv1_q2;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 3] <= conv1_q3;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 4] <= conv1_q4;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 5] <= conv1_q5;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 6] <= conv1_q6;
                    feature_mem0[(conv1_out_y*8 + conv1_out_x)*8 + 7] <= conv1_q7;

                    if ((conv1_out_x == 16'd7) && (conv1_out_y == 16'd7)) begin
                        conv3_pixel_index <= 16'd0;
                        state <= ST_CONV3;
                    end
                end
            end

            ST_CONV3: begin
                feature_mem1[conv3_pixel_index*4 + 0] <= conv3_q0;
                feature_mem1[conv3_pixel_index*4 + 1] <= conv3_q1;
                feature_mem1[conv3_pixel_index*4 + 2] <= conv3_q2;
                feature_mem1[conv3_pixel_index*4 + 3] <= conv3_q3;

                if (conv3_pixel_index == 16'd63) begin
                    ps_pixel_index <= 16'd0;
                    state <= ST_PS;
                end else begin
                    conv3_pixel_index <= conv3_pixel_index + 16'd1;
                end
            end

            ST_PS: begin
                if (ps_wr_en_a) begin
                    feature_mem2[ps_wr_addr_a*2 + 0] <= ps_wr_data_a[7:0];
                    feature_mem2[ps_wr_addr_a*2 + 1] <= ps_wr_data_a[15:8];
                end

                if (ps_wr_en_b) begin
                    feature_mem2[ps_wr_addr_b*2 + 0] <= ps_wr_data_b[7:0];
                    feature_mem2[ps_wr_addr_b*2 + 1] <= ps_wr_data_b[15:8];
                end

                if (ps_pixel_index == 16'd63) begin
                    out_pixel_index <= 16'd0;
                    state <= ST_OUT;
                end else begin
                    ps_pixel_index <= ps_pixel_index + 16'd1;
                end
            end

            ST_OUT: begin
                output_mem[out_pixel_index] <= output_stage_uint8;

                if (out_pixel_index == 16'd255) begin
                    state <= ST_DONE;
                end else begin
                    out_pixel_index <= out_pixel_index + 16'd1;
                end
            end

            ST_DONE: begin
                busy <= 1'b0;
                done <= 1'b1;
                state <= ST_DONE;
            end

            default: begin
                state <= ST_IDLE;
            end
        endcase
    end
end

endmodule
