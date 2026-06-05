`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_conv1x1_cin8_cout4_mac
// -----------------------------------------------------------------------------
// Purpose:
//   Conv3 layer 1x1 MAC only.
//   Cin=8, Cout=4, signed int8 activation, signed int8 weight,
//   signed int32 accumulator output.
//
// Mapping:
//   in_c0 ~ in_c7 are one NHWC pixel's 8 channels.
//   w00 ~ w07 belong to output channel 0.
//   w10 ~ w17 belong to output channel 1.
//   w20 ~ w27 belong to output channel 2.
//   w30 ~ w37 belong to output channel 3.
// -----------------------------------------------------------------------------

module sr_conv1x1_cin8_cout4_mac (
    input  signed [7:0] in_c0,
    input  signed [7:0] in_c1,
    input  signed [7:0] in_c2,
    input  signed [7:0] in_c3,
    input  signed [7:0] in_c4,
    input  signed [7:0] in_c5,
    input  signed [7:0] in_c6,
    input  signed [7:0] in_c7,

    input  signed [7:0] w00, //w(out_c,in_c)
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

    output signed [31:0] acc0, //acc of out_ch
    output signed [31:0] acc1,
    output signed [31:0] acc2,
    output signed [31:0] acc3
);

// Stage 0: sign-extend int8 activation and weight to a wider signed datapath.
wire signed [15:0] in0_s;
wire signed [15:0] in1_s;
wire signed [15:0] in2_s;
wire signed [15:0] in3_s;
wire signed [15:0] in4_s;
wire signed [15:0] in5_s;
wire signed [15:0] in6_s;
wire signed [15:0] in7_s;

assign in0_s = {{8{in_c0[7]}}, in_c0};
assign in1_s = {{8{in_c1[7]}}, in_c1};
assign in2_s = {{8{in_c2[7]}}, in_c2};
assign in3_s = {{8{in_c3[7]}}, in_c3};
assign in4_s = {{8{in_c4[7]}}, in_c4};
assign in5_s = {{8{in_c5[7]}}, in_c5};
assign in6_s = {{8{in_c6[7]}}, in_c6};
assign in7_s = {{8{in_c7[7]}}, in_c7};

wire signed [15:0] w00_s;
wire signed [15:0] w01_s;
wire signed [15:0] w02_s;
wire signed [15:0] w03_s;
wire signed [15:0] w04_s;
wire signed [15:0] w05_s;
wire signed [15:0] w06_s;
wire signed [15:0] w07_s;

wire signed [15:0] w10_s;
wire signed [15:0] w11_s;
wire signed [15:0] w12_s;
wire signed [15:0] w13_s;
wire signed [15:0] w14_s;
wire signed [15:0] w15_s;
wire signed [15:0] w16_s;
wire signed [15:0] w17_s;

wire signed [15:0] w20_s;
wire signed [15:0] w21_s;
wire signed [15:0] w22_s;
wire signed [15:0] w23_s;
wire signed [15:0] w24_s;
wire signed [15:0] w25_s;
wire signed [15:0] w26_s;
wire signed [15:0] w27_s;

wire signed [15:0] w30_s;
wire signed [15:0] w31_s;
wire signed [15:0] w32_s;
wire signed [15:0] w33_s;
wire signed [15:0] w34_s;
wire signed [15:0] w35_s;
wire signed [15:0] w36_s;
wire signed [15:0] w37_s;

assign w00_s = {{8{w00[7]}}, w00};
assign w01_s = {{8{w01[7]}}, w01};
assign w02_s = {{8{w02[7]}}, w02};
assign w03_s = {{8{w03[7]}}, w03};
assign w04_s = {{8{w04[7]}}, w04};
assign w05_s = {{8{w05[7]}}, w05};
assign w06_s = {{8{w06[7]}}, w06};
assign w07_s = {{8{w07[7]}}, w07};

assign w10_s = {{8{w10[7]}}, w10};
assign w11_s = {{8{w11[7]}}, w11};
assign w12_s = {{8{w12[7]}}, w12};
assign w13_s = {{8{w13[7]}}, w13};
assign w14_s = {{8{w14[7]}}, w14};
assign w15_s = {{8{w15[7]}}, w15};
assign w16_s = {{8{w16[7]}}, w16};
assign w17_s = {{8{w17[7]}}, w17};

assign w20_s = {{8{w20[7]}}, w20};
assign w21_s = {{8{w21[7]}}, w21};
assign w22_s = {{8{w22[7]}}, w22};
assign w23_s = {{8{w23[7]}}, w23};
assign w24_s = {{8{w24[7]}}, w24};
assign w25_s = {{8{w25[7]}}, w25};
assign w26_s = {{8{w26[7]}}, w26};
assign w27_s = {{8{w27[7]}}, w27};

assign w30_s = {{8{w30[7]}}, w30};
assign w31_s = {{8{w31[7]}}, w31};
assign w32_s = {{8{w32[7]}}, w32};
assign w33_s = {{8{w33[7]}}, w33};
assign w34_s = {{8{w34[7]}}, w34};
assign w35_s = {{8{w35[7]}}, w35};
assign w36_s = {{8{w36[7]}}, w36};
assign w37_s = {{8{w37[7]}}, w37};

// Stage 1: signed int8 x int8 multipliers for output channel 0.
wire signed [31:0] mul00;
wire signed [31:0] mul01;
wire signed [31:0] mul02;
wire signed [31:0] mul03;
wire signed [31:0] mul04;
wire signed [31:0] mul05;
wire signed [31:0] mul06;
wire signed [31:0] mul07;

assign mul00 = in0_s * w00_s;
assign mul01 = in1_s * w01_s;
assign mul02 = in2_s * w02_s;
assign mul03 = in3_s * w03_s;
assign mul04 = in4_s * w04_s;
assign mul05 = in5_s * w05_s;
assign mul06 = in6_s * w06_s;
assign mul07 = in7_s * w07_s;

// Stage 1: signed int8 x int8 multipliers for output channel 1.
wire signed [31:0] mul10;
wire signed [31:0] mul11;
wire signed [31:0] mul12;
wire signed [31:0] mul13;
wire signed [31:0] mul14;
wire signed [31:0] mul15;
wire signed [31:0] mul16;
wire signed [31:0] mul17;

assign mul10 = in0_s * w10_s;
assign mul11 = in1_s * w11_s;
assign mul12 = in2_s * w12_s;
assign mul13 = in3_s * w13_s;
assign mul14 = in4_s * w14_s;
assign mul15 = in5_s * w15_s;
assign mul16 = in6_s * w16_s;
assign mul17 = in7_s * w17_s;

// Stage 1: signed int8 x int8 multipliers for output channel 2.
wire signed [31:0] mul20;
wire signed [31:0] mul21;
wire signed [31:0] mul22;
wire signed [31:0] mul23;
wire signed [31:0] mul24;
wire signed [31:0] mul25;
wire signed [31:0] mul26;
wire signed [31:0] mul27;

assign mul20 = in0_s * w20_s;
assign mul21 = in1_s * w21_s;
assign mul22 = in2_s * w22_s;
assign mul23 = in3_s * w23_s;
assign mul24 = in4_s * w24_s;
assign mul25 = in5_s * w25_s;
assign mul26 = in6_s * w26_s;
assign mul27 = in7_s * w27_s;

// Stage 1: signed int8 x int8 multipliers for output channel 3.
wire signed [31:0] mul30;
wire signed [31:0] mul31;
wire signed [31:0] mul32;
wire signed [31:0] mul33;
wire signed [31:0] mul34;
wire signed [31:0] mul35;
wire signed [31:0] mul36;
wire signed [31:0] mul37;

assign mul30 = in0_s * w30_s;
assign mul31 = in1_s * w31_s;
assign mul32 = in2_s * w32_s;
assign mul33 = in3_s * w33_s;
assign mul34 = in4_s * w34_s;
assign mul35 = in5_s * w35_s;
assign mul36 = in6_s * w36_s;
assign mul37 = in7_s * w37_s;

// Stage 2: partial sums. Each psum adds two products.
wire signed [31:0] psum0a;
wire signed [31:0] psum0b;
wire signed [31:0] psum0c;
wire signed [31:0] psum0d;
wire signed [31:0] psum1a;
wire signed [31:0] psum1b;
wire signed [31:0] psum1c;
wire signed [31:0] psum1d;
wire signed [31:0] psum2a;
wire signed [31:0] psum2b;
wire signed [31:0] psum2c;
wire signed [31:0] psum2d;
wire signed [31:0] psum3a;
wire signed [31:0] psum3b;
wire signed [31:0] psum3c;
wire signed [31:0] psum3d;

assign psum0a = mul00 + mul01;
assign psum0b = mul02 + mul03;
assign psum0c = mul04 + mul05;
assign psum0d = mul06 + mul07;

assign psum1a = mul10 + mul11;
assign psum1b = mul12 + mul13;
assign psum1c = mul14 + mul15;
assign psum1d = mul16 + mul17;

assign psum2a = mul20 + mul21;
assign psum2b = mul22 + mul23;
assign psum2c = mul24 + mul25;
assign psum2d = mul26 + mul27;

assign psum3a = mul30 + mul31;
assign psum3b = mul32 + mul33;
assign psum3c = mul34 + mul35;
assign psum3d = mul36 + mul37;

// Stage 3: final accumulation for each output channel.
assign acc0 = psum0a + psum0b + psum0c + psum0d;
assign acc1 = psum1a + psum1b + psum1c + psum1d;
assign acc2 = psum2a + psum2b + psum2c + psum2d;
assign acc3 = psum3a + psum3b + psum3c + psum3d;

endmodule
