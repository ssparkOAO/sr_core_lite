`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_conv1_3x3_cin1_cout8_block
// -----------------------------------------------------------------------------
// Purpose:
//   Conv1 full quantized block:
//     streaming 3x3 window -> Conv1 3x3 MAC -> 8x requantize
//
// Note:
//   No standalone ReLU module is inserted here. Conv1 uses fused ReLU semantics
//   and output zero point is -128, so sr_requantize's signed int8 clamp is enough
//   for this verified TFLite flow.
// -----------------------------------------------------------------------------

module sr_conv1_3x3_cin1_cout8_block #(
    parameter IMG_W      = 8,
    parameter IMG_H      = 8,
    parameter DATA_WIDTH = 8,
    parameter signed [DATA_WIDTH-1:0] PAD_VALUE = -128
) (
    input wire clk,
    input wire rst,
    input wire in_valid,
    input signed [7:0] in_pixel,
    output wire in_ready,

    input signed [7:0] w000,
    input signed [7:0] w001,
    input signed [7:0] w002,
    input signed [7:0] w003,
    input signed [7:0] w004,
    input signed [7:0] w005,
    input signed [7:0] w006,
    input signed [7:0] w007,
    input signed [7:0] w008,

    input signed [7:0] w100,
    input signed [7:0] w101,
    input signed [7:0] w102,
    input signed [7:0] w103,
    input signed [7:0] w104,
    input signed [7:0] w105,
    input signed [7:0] w106,
    input signed [7:0] w107,
    input signed [7:0] w108,

    input signed [7:0] w200,
    input signed [7:0] w201,
    input signed [7:0] w202,
    input signed [7:0] w203,
    input signed [7:0] w204,
    input signed [7:0] w205,
    input signed [7:0] w206,
    input signed [7:0] w207,
    input signed [7:0] w208,

    input signed [7:0] w300,
    input signed [7:0] w301,
    input signed [7:0] w302,
    input signed [7:0] w303,
    input signed [7:0] w304,
    input signed [7:0] w305,
    input signed [7:0] w306,
    input signed [7:0] w307,
    input signed [7:0] w308,

    input signed [7:0] w400,
    input signed [7:0] w401,
    input signed [7:0] w402,
    input signed [7:0] w403,
    input signed [7:0] w404,
    input signed [7:0] w405,
    input signed [7:0] w406,
    input signed [7:0] w407,
    input signed [7:0] w408,

    input signed [7:0] w500,
    input signed [7:0] w501,
    input signed [7:0] w502,
    input signed [7:0] w503,
    input signed [7:0] w504,
    input signed [7:0] w505,
    input signed [7:0] w506,
    input signed [7:0] w507,
    input signed [7:0] w508,

    input signed [7:0] w600,
    input signed [7:0] w601,
    input signed [7:0] w602,
    input signed [7:0] w603,
    input signed [7:0] w604,
    input signed [7:0] w605,
    input signed [7:0] w606,
    input signed [7:0] w607,
    input signed [7:0] w608,

    input signed [7:0] w700,
    input signed [7:0] w701,
    input signed [7:0] w702,
    input signed [7:0] w703,
    input signed [7:0] w704,
    input signed [7:0] w705,
    input signed [7:0] w706,
    input signed [7:0] w707,
    input signed [7:0] w708,

    input signed [31:0] m0_0,
    input signed [31:0] m0_1,
    input signed [31:0] m0_2,
    input signed [31:0] m0_3,
    input signed [31:0] m0_4,
    input signed [31:0] m0_5,
    input signed [31:0] m0_6,
    input signed [31:0] m0_7,

    input signed [63:0] m1_0,
    input signed [63:0] m1_1,
    input signed [63:0] m1_2,
    input signed [63:0] m1_3,
    input signed [63:0] m1_4,
    input signed [63:0] m1_5,
    input signed [63:0] m1_6,
    input signed [63:0] m1_7,

    output wire out_valid,
    output wire [15:0] out_x,
    output wire [15:0] out_y,

    output signed [7:0] q0,
    output signed [7:0] q1,
    output signed [7:0] q2,
    output signed [7:0] q3,
    output signed [7:0] q4,
    output signed [7:0] q5,
    output signed [7:0] q6,
    output signed [7:0] q7,

    output signed [31:0] acc0,
    output signed [31:0] acc1,
    output signed [31:0] acc2,
    output signed [31:0] acc3,
    output signed [31:0] acc4,
    output signed [31:0] acc5,
    output signed [31:0] acc6,
    output signed [31:0] acc7,

    output signed [7:0] win00_dbg,
    output signed [7:0] win01_dbg,
    output signed [7:0] win02_dbg,
    output signed [7:0] win10_dbg,
    output signed [7:0] win11_dbg,
    output signed [7:0] win12_dbg,
    output signed [7:0] win20_dbg,
    output signed [7:0] win21_dbg,
    output signed [7:0] win22_dbg
);

wire signed [7:0] win00;
wire signed [7:0] win01;
wire signed [7:0] win02;
wire signed [7:0] win10;
wire signed [7:0] win11;
wire signed [7:0] win12;
wire signed [7:0] win20;
wire signed [7:0] win21;
wire signed [7:0] win22;

assign win00_dbg = win00;
assign win01_dbg = win01;
assign win02_dbg = win02;
assign win10_dbg = win10;
assign win11_dbg = win11;
assign win12_dbg = win12;
assign win20_dbg = win20;
assign win21_dbg = win21;
assign win22_dbg = win22;

sr_window_3x3_cin1 #(
    .IMG_W(IMG_W),
    .IMG_H(IMG_H),
    .DATA_WIDTH(DATA_WIDTH),
    .PAD_VALUE(PAD_VALUE)
) window_u0 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in_pixel(in_pixel),
    .in_ready(in_ready),
    .window_valid(out_valid),
    .win00(win00),
    .win01(win01),
    .win02(win02),
    .win10(win10),
    .win11(win11),
    .win12(win12),
    .win20(win20),
    .win21(win21),
    .win22(win22),
    .out_x(out_x),
    .out_y(out_y)
);

sr_conv3x3_cin1_cout8_mac mac_u0 (
    .win00(win00),
    .win01(win01),
    .win02(win02),
    .win10(win10),
    .win11(win11),
    .win12(win12),
    .win20(win20),
    .win21(win21),
    .win22(win22),

    .w000(w000), .w001(w001), .w002(w002),
    .w003(w003), .w004(w004), .w005(w005),
    .w006(w006), .w007(w007), .w008(w008),

    .w100(w100), .w101(w101), .w102(w102),
    .w103(w103), .w104(w104), .w105(w105),
    .w106(w106), .w107(w107), .w108(w108),

    .w200(w200), .w201(w201), .w202(w202),
    .w203(w203), .w204(w204), .w205(w205),
    .w206(w206), .w207(w207), .w208(w208),

    .w300(w300), .w301(w301), .w302(w302),
    .w303(w303), .w304(w304), .w305(w305),
    .w306(w306), .w307(w307), .w308(w308),

    .w400(w400), .w401(w401), .w402(w402),
    .w403(w403), .w404(w404), .w405(w405),
    .w406(w406), .w407(w407), .w408(w408),

    .w500(w500), .w501(w501), .w502(w502),
    .w503(w503), .w504(w504), .w505(w505),
    .w506(w506), .w507(w507), .w508(w508),

    .w600(w600), .w601(w601), .w602(w602),
    .w603(w603), .w604(w604), .w605(w605),
    .w606(w606), .w607(w607), .w608(w608),

    .w700(w700), .w701(w701), .w702(w702),
    .w703(w703), .w704(w704), .w705(w705),
    .w706(w706), .w707(w707), .w708(w708),

    .acc0(acc0),
    .acc1(acc1),
    .acc2(acc2),
    .acc3(acc3),
    .acc4(acc4),
    .acc5(acc5),
    .acc6(acc6),
    .acc7(acc7)
);

sr_requantize req0 (.acc(acc0), .m0(m0_0), .m1(m1_0), .q_out(q0));
sr_requantize req1 (.acc(acc1), .m0(m0_1), .m1(m1_1), .q_out(q1));
sr_requantize req2 (.acc(acc2), .m0(m0_2), .m1(m1_2), .q_out(q2));
sr_requantize req3 (.acc(acc3), .m0(m0_3), .m1(m1_3), .q_out(q3));
sr_requantize req4 (.acc(acc4), .m0(m0_4), .m1(m1_4), .q_out(q4));
sr_requantize req5 (.acc(acc5), .m0(m0_5), .m1(m1_5), .q_out(q5));
sr_requantize req6 (.acc(acc6), .m0(m0_6), .m1(m1_6), .q_out(q6));
sr_requantize req7 (.acc(acc7), .m0(m0_7), .m1(m1_7), .q_out(q7));

endmodule
