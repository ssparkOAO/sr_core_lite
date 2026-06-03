`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_conv1x1_cin8_cout4_block
// -----------------------------------------------------------------------------
// Purpose:
//   Conv3 layer 1x1 block: signed int8 MAC followed by per-channel requant.
//
// Datapath:
//   in_c0~in_c7
//     -> sr_conv1x1_cin8_cout4_mac
//     -> acc0~acc3
//     -> 4x sr_requantize
//     -> q0~q3
//
// Note:
//   Conv3 is the layer name. Its kernel is 1x1.
// -----------------------------------------------------------------------------

module sr_conv1x1_cin8_cout4_block (
    input  signed [7:0] in_c0,
    input  signed [7:0] in_c1,
    input  signed [7:0] in_c2,
    input  signed [7:0] in_c3,
    input  signed [7:0] in_c4,
    input  signed [7:0] in_c5,
    input  signed [7:0] in_c6,
    input  signed [7:0] in_c7,

    input  signed [7:0] w00,
    input  signed [7:0] w01,
    input  signed [7:0] w02,
    input  signed [7:0] w03,
    input  signed [7:0] w04,
    input  signed [7:0] w05,
    input  signed [7:0] w06,
    input  signed [7:0] w07,

    input  signed [7:0] w10,
    input  signed [7:0] w11,
    input  signed [7:0] w12,
    input  signed [7:0] w13,
    input  signed [7:0] w14,
    input  signed [7:0] w15,
    input  signed [7:0] w16,
    input  signed [7:0] w17,

    input  signed [7:0] w20,
    input  signed [7:0] w21,
    input  signed [7:0] w22,
    input  signed [7:0] w23,
    input  signed [7:0] w24,
    input  signed [7:0] w25,
    input  signed [7:0] w26,
    input  signed [7:0] w27,

    input  signed [7:0] w30,
    input  signed [7:0] w31,
    input  signed [7:0] w32,
    input  signed [7:0] w33,
    input  signed [7:0] w34,
    input  signed [7:0] w35,
    input  signed [7:0] w36,
    input  signed [7:0] w37,

    input  signed [31:0] m0_0,
    input  signed [31:0] m0_1,
    input  signed [31:0] m0_2,
    input  signed [31:0] m0_3,

    input  signed [63:0] m1_0,
    input  signed [63:0] m1_1,
    input  signed [63:0] m1_2,
    input  signed [63:0] m1_3,

    output signed [7:0] q0,
    output signed [7:0] q1,
    output signed [7:0] q2,
    output signed [7:0] q3
);

wire signed [31:0] acc0;
wire signed [31:0] acc1;
wire signed [31:0] acc2;
wire signed [31:0] acc3;

// Stage 1: Conv3 layer 1x1 MAC. No bias, no requant here.
sr_conv1x1_cin8_cout4_mac mac_u0 (
    .in_c0(in_c0),
    .in_c1(in_c1),
    .in_c2(in_c2),
    .in_c3(in_c3),
    .in_c4(in_c4),
    .in_c5(in_c5),
    .in_c6(in_c6),
    .in_c7(in_c7),

    .w00(w00),
    .w01(w01),
    .w02(w02),
    .w03(w03),
    .w04(w04),
    .w05(w05),
    .w06(w06),
    .w07(w07),

    .w10(w10),
    .w11(w11),
    .w12(w12),
    .w13(w13),
    .w14(w14),
    .w15(w15),
    .w16(w16),
    .w17(w17),

    .w20(w20),
    .w21(w21),
    .w22(w22),
    .w23(w23),
    .w24(w24),
    .w25(w25),
    .w26(w26),
    .w27(w27),

    .w30(w30),
    .w31(w31),
    .w32(w32),
    .w33(w33),
    .w34(w34),
    .w35(w35),
    .w36(w36),
    .w37(w37),

    .acc0(acc0),
    .acc1(acc1),
    .acc2(acc2),
    .acc3(acc3)
);

// Stage 2: one requantizer per output channel.
sr_requantize requant_ch0 (
    .acc(acc0),
    .m0(m0_0),
    .m1(m1_0),
    .q_out(q0)
);

sr_requantize requant_ch1 (
    .acc(acc1),
    .m0(m0_1),
    .m1(m1_1),
    .q_out(q1)
);

sr_requantize requant_ch2 (
    .acc(acc2),
    .m0(m0_2),
    .m1(m1_2),
    .q_out(q2)
);

sr_requantize requant_ch3 (
    .acc(acc3),
    .m0(m0_3),
    .m1(m1_3),
    .q_out(q3)
);

endmodule
