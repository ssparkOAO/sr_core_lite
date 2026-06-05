`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_conv1x1_cin8_cout4_flat
// -----------------------------------------------------------------------------
// Conv3 layer 1x1, Cin=8, Cout=4 block with flat parameter buses.
//
// The layer name is Conv3, but the kernel is 1x1. This module keeps the
// functional name in the filename while reducing top-level parameter ports.
// -----------------------------------------------------------------------------

module sr_conv1x1_cin8_cout4_flat (
    input  signed [7:0] in_c0,
    input  signed [7:0] in_c1,
    input  signed [7:0] in_c2,
    input  signed [7:0] in_c3,
    input  signed [7:0] in_c4,
    input  signed [7:0] in_c5,
    input  signed [7:0] in_c6,
    input  signed [7:0] in_c7,

    input [255:0] conv3_weight_flat,
    input [127:0] conv3_m0_flat,
    input [255:0] conv3_m1_flat,

    output signed [7:0] q0,
    output signed [7:0] q1,
    output signed [7:0] q2,
    output signed [7:0] q3
);

wire signed [7:0] w00; wire signed [7:0] w01;
wire signed [7:0] w02; wire signed [7:0] w03;
wire signed [7:0] w04; wire signed [7:0] w05;
wire signed [7:0] w06; wire signed [7:0] w07;
wire signed [7:0] w10; wire signed [7:0] w11;
wire signed [7:0] w12; wire signed [7:0] w13;
wire signed [7:0] w14; wire signed [7:0] w15;
wire signed [7:0] w16; wire signed [7:0] w17;
wire signed [7:0] w20; wire signed [7:0] w21;
wire signed [7:0] w22; wire signed [7:0] w23;
wire signed [7:0] w24; wire signed [7:0] w25;
wire signed [7:0] w26; wire signed [7:0] w27;
wire signed [7:0] w30; wire signed [7:0] w31;
wire signed [7:0] w32; wire signed [7:0] w33;
wire signed [7:0] w34; wire signed [7:0] w35;
wire signed [7:0] w36; wire signed [7:0] w37;

wire signed [31:0] m0_0; wire signed [31:0] m0_1;
wire signed [31:0] m0_2; wire signed [31:0] m0_3;
wire signed [63:0] m1_0; wire signed [63:0] m1_1;
wire signed [63:0] m1_2; wire signed [63:0] m1_3;

wire signed [31:0] acc0;
wire signed [31:0] acc1;
wire signed [31:0] acc2;
wire signed [31:0] acc3;

assign w00 = conv3_weight_flat[7:0];
assign w01 = conv3_weight_flat[15:8];
assign w02 = conv3_weight_flat[23:16];
assign w03 = conv3_weight_flat[31:24];
assign w04 = conv3_weight_flat[39:32];
assign w05 = conv3_weight_flat[47:40];
assign w06 = conv3_weight_flat[55:48];
assign w07 = conv3_weight_flat[63:56];
assign w10 = conv3_weight_flat[71:64];
assign w11 = conv3_weight_flat[79:72];
assign w12 = conv3_weight_flat[87:80];
assign w13 = conv3_weight_flat[95:88];
assign w14 = conv3_weight_flat[103:96];
assign w15 = conv3_weight_flat[111:104];
assign w16 = conv3_weight_flat[119:112];
assign w17 = conv3_weight_flat[127:120];
assign w20 = conv3_weight_flat[135:128];
assign w21 = conv3_weight_flat[143:136];
assign w22 = conv3_weight_flat[151:144];
assign w23 = conv3_weight_flat[159:152];
assign w24 = conv3_weight_flat[167:160];
assign w25 = conv3_weight_flat[175:168];
assign w26 = conv3_weight_flat[183:176];
assign w27 = conv3_weight_flat[191:184];
assign w30 = conv3_weight_flat[199:192];
assign w31 = conv3_weight_flat[207:200];
assign w32 = conv3_weight_flat[215:208];
assign w33 = conv3_weight_flat[223:216];
assign w34 = conv3_weight_flat[231:224];
assign w35 = conv3_weight_flat[239:232];
assign w36 = conv3_weight_flat[247:240];
assign w37 = conv3_weight_flat[255:248];

assign m0_0 = conv3_m0_flat[31:0];
assign m0_1 = conv3_m0_flat[63:32];
assign m0_2 = conv3_m0_flat[95:64];
assign m0_3 = conv3_m0_flat[127:96];

assign m1_0 = conv3_m1_flat[63:0];
assign m1_1 = conv3_m1_flat[127:64];
assign m1_2 = conv3_m1_flat[191:128];
assign m1_3 = conv3_m1_flat[255:192];

sr_conv1x1_cin8_cout4_mac mac_u0 (
    .in_c0(in_c0), .in_c1(in_c1), .in_c2(in_c2), .in_c3(in_c3),
    .in_c4(in_c4), .in_c5(in_c5), .in_c6(in_c6), .in_c7(in_c7),
    .w00(w00), .w01(w01), .w02(w02), .w03(w03),
    .w04(w04), .w05(w05), .w06(w06), .w07(w07),
    .w10(w10), .w11(w11), .w12(w12), .w13(w13),
    .w14(w14), .w15(w15), .w16(w16), .w17(w17),
    .w20(w20), .w21(w21), .w22(w22), .w23(w23),
    .w24(w24), .w25(w25), .w26(w26), .w27(w27),
    .w30(w30), .w31(w31), .w32(w32), .w33(w33),
    .w34(w34), .w35(w35), .w36(w36), .w37(w37),
    .acc0(acc0), .acc1(acc1), .acc2(acc2), .acc3(acc3)
);

sr_requantize requant_ch0 (.acc(acc0), .m0(m0_0), .m1(m1_0), .q_out(q0));
sr_requantize requant_ch1 (.acc(acc1), .m0(m0_1), .m1(m1_1), .q_out(q1));
sr_requantize requant_ch2 (.acc(acc2), .m0(m0_2), .m1(m1_2), .q_out(q2));
sr_requantize requant_ch3 (.acc(acc3), .m0(m0_3), .m1(m1_3), .q_out(q3));

endmodule
