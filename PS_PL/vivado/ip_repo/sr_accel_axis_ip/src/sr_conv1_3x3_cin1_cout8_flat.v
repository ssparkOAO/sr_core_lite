`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_conv1_3x3_cin1_cout8_flat
// -----------------------------------------------------------------------------
// Conv1 3x3, Cin=1, Cout=8 full quantized block with flat parameter buses.
//
// The flat buses reduce top-level wiring noise. Internally the datapath is still
// fully parallel: 8 output channels, each with 9 signed int8 weights.
// -----------------------------------------------------------------------------

module sr_conv1_3x3_cin1_cout8_flat #(
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

    input [575:0] conv1_weight_flat,
    input [255:0] conv1_m0_flat,
    input [511:0] conv1_m1_flat,

    output wire out_valid,

    output signed [7:0] q0,
    output signed [7:0] q1,
    output signed [7:0] q2,
    output signed [7:0] q3,
    output signed [7:0] q4,
    output signed [7:0] q5,
    output signed [7:0] q6,
    output signed [7:0] q7
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

wire signed [31:0] acc0;
wire signed [31:0] acc1;
wire signed [31:0] acc2;
wire signed [31:0] acc3;
wire signed [31:0] acc4;
wire signed [31:0] acc5;
wire signed [31:0] acc6;
wire signed [31:0] acc7;

wire signed [7:0] w000; wire signed [7:0] w001; wire signed [7:0] w002;
wire signed [7:0] w003; wire signed [7:0] w004; wire signed [7:0] w005;
wire signed [7:0] w006; wire signed [7:0] w007; wire signed [7:0] w008;
wire signed [7:0] w100; wire signed [7:0] w101; wire signed [7:0] w102;
wire signed [7:0] w103; wire signed [7:0] w104; wire signed [7:0] w105;
wire signed [7:0] w106; wire signed [7:0] w107; wire signed [7:0] w108;
wire signed [7:0] w200; wire signed [7:0] w201; wire signed [7:0] w202;
wire signed [7:0] w203; wire signed [7:0] w204; wire signed [7:0] w205;
wire signed [7:0] w206; wire signed [7:0] w207; wire signed [7:0] w208;
wire signed [7:0] w300; wire signed [7:0] w301; wire signed [7:0] w302;
wire signed [7:0] w303; wire signed [7:0] w304; wire signed [7:0] w305;
wire signed [7:0] w306; wire signed [7:0] w307; wire signed [7:0] w308;
wire signed [7:0] w400; wire signed [7:0] w401; wire signed [7:0] w402;
wire signed [7:0] w403; wire signed [7:0] w404; wire signed [7:0] w405;
wire signed [7:0] w406; wire signed [7:0] w407; wire signed [7:0] w408;
wire signed [7:0] w500; wire signed [7:0] w501; wire signed [7:0] w502;
wire signed [7:0] w503; wire signed [7:0] w504; wire signed [7:0] w505;
wire signed [7:0] w506; wire signed [7:0] w507; wire signed [7:0] w508;
wire signed [7:0] w600; wire signed [7:0] w601; wire signed [7:0] w602;
wire signed [7:0] w603; wire signed [7:0] w604; wire signed [7:0] w605;
wire signed [7:0] w606; wire signed [7:0] w607; wire signed [7:0] w608;
wire signed [7:0] w700; wire signed [7:0] w701; wire signed [7:0] w702;
wire signed [7:0] w703; wire signed [7:0] w704; wire signed [7:0] w705;
wire signed [7:0] w706; wire signed [7:0] w707; wire signed [7:0] w708;

wire signed [31:0] m0_0; wire signed [31:0] m0_1;
wire signed [31:0] m0_2; wire signed [31:0] m0_3;
wire signed [31:0] m0_4; wire signed [31:0] m0_5;
wire signed [31:0] m0_6; wire signed [31:0] m0_7;

wire signed [63:0] m1_0; wire signed [63:0] m1_1;
wire signed [63:0] m1_2; wire signed [63:0] m1_3;
wire signed [63:0] m1_4; wire signed [63:0] m1_5;
wire signed [63:0] m1_6; wire signed [63:0] m1_7;

assign w000 = conv1_weight_flat[7:0];
assign w001 = conv1_weight_flat[15:8];
assign w002 = conv1_weight_flat[23:16];
assign w003 = conv1_weight_flat[31:24];
assign w004 = conv1_weight_flat[39:32];
assign w005 = conv1_weight_flat[47:40];
assign w006 = conv1_weight_flat[55:48];
assign w007 = conv1_weight_flat[63:56];
assign w008 = conv1_weight_flat[71:64];
assign w100 = conv1_weight_flat[79:72];
assign w101 = conv1_weight_flat[87:80];
assign w102 = conv1_weight_flat[95:88];
assign w103 = conv1_weight_flat[103:96];
assign w104 = conv1_weight_flat[111:104];
assign w105 = conv1_weight_flat[119:112];
assign w106 = conv1_weight_flat[127:120];
assign w107 = conv1_weight_flat[135:128];
assign w108 = conv1_weight_flat[143:136];
assign w200 = conv1_weight_flat[151:144];
assign w201 = conv1_weight_flat[159:152];
assign w202 = conv1_weight_flat[167:160];
assign w203 = conv1_weight_flat[175:168];
assign w204 = conv1_weight_flat[183:176];
assign w205 = conv1_weight_flat[191:184];
assign w206 = conv1_weight_flat[199:192];
assign w207 = conv1_weight_flat[207:200];
assign w208 = conv1_weight_flat[215:208];
assign w300 = conv1_weight_flat[223:216];
assign w301 = conv1_weight_flat[231:224];
assign w302 = conv1_weight_flat[239:232];
assign w303 = conv1_weight_flat[247:240];
assign w304 = conv1_weight_flat[255:248];
assign w305 = conv1_weight_flat[263:256];
assign w306 = conv1_weight_flat[271:264];
assign w307 = conv1_weight_flat[279:272];
assign w308 = conv1_weight_flat[287:280];
assign w400 = conv1_weight_flat[295:288];
assign w401 = conv1_weight_flat[303:296];
assign w402 = conv1_weight_flat[311:304];
assign w403 = conv1_weight_flat[319:312];
assign w404 = conv1_weight_flat[327:320];
assign w405 = conv1_weight_flat[335:328];
assign w406 = conv1_weight_flat[343:336];
assign w407 = conv1_weight_flat[351:344];
assign w408 = conv1_weight_flat[359:352];
assign w500 = conv1_weight_flat[367:360];
assign w501 = conv1_weight_flat[375:368];
assign w502 = conv1_weight_flat[383:376];
assign w503 = conv1_weight_flat[391:384];
assign w504 = conv1_weight_flat[399:392];
assign w505 = conv1_weight_flat[407:400];
assign w506 = conv1_weight_flat[415:408];
assign w507 = conv1_weight_flat[423:416];
assign w508 = conv1_weight_flat[431:424];
assign w600 = conv1_weight_flat[439:432];
assign w601 = conv1_weight_flat[447:440];
assign w602 = conv1_weight_flat[455:448];
assign w603 = conv1_weight_flat[463:456];
assign w604 = conv1_weight_flat[471:464];
assign w605 = conv1_weight_flat[479:472];
assign w606 = conv1_weight_flat[487:480];
assign w607 = conv1_weight_flat[495:488];
assign w608 = conv1_weight_flat[503:496];
assign w700 = conv1_weight_flat[511:504];
assign w701 = conv1_weight_flat[519:512];
assign w702 = conv1_weight_flat[527:520];
assign w703 = conv1_weight_flat[535:528];
assign w704 = conv1_weight_flat[543:536];
assign w705 = conv1_weight_flat[551:544];
assign w706 = conv1_weight_flat[559:552];
assign w707 = conv1_weight_flat[567:560];
assign w708 = conv1_weight_flat[575:568];

assign m0_0 = conv1_m0_flat[31:0];
assign m0_1 = conv1_m0_flat[63:32];
assign m0_2 = conv1_m0_flat[95:64];
assign m0_3 = conv1_m0_flat[127:96];
assign m0_4 = conv1_m0_flat[159:128];
assign m0_5 = conv1_m0_flat[191:160];
assign m0_6 = conv1_m0_flat[223:192];
assign m0_7 = conv1_m0_flat[255:224];

assign m1_0 = conv1_m1_flat[63:0];
assign m1_1 = conv1_m1_flat[127:64];
assign m1_2 = conv1_m1_flat[191:128];
assign m1_3 = conv1_m1_flat[255:192];
assign m1_4 = conv1_m1_flat[319:256];
assign m1_5 = conv1_m1_flat[383:320];
assign m1_6 = conv1_m1_flat[447:384];
assign m1_7 = conv1_m1_flat[511:448];

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
    .win00(win00), .win01(win01), .win02(win02),
    .win10(win10), .win11(win11), .win12(win12),
    .win20(win20), .win21(win21), .win22(win22),
    .out_x(),
    .out_y()
);

sr_conv3x3_cin1_cout8_mac mac_u0 (
    .win00(win00), .win01(win01), .win02(win02),
    .win10(win10), .win11(win11), .win12(win12),
    .win20(win20), .win21(win21), .win22(win22),
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
    .acc0(acc0), .acc1(acc1), .acc2(acc2), .acc3(acc3),
    .acc4(acc4), .acc5(acc5), .acc6(acc6), .acc7(acc7)
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
