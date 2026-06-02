`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_core_top_mem_wrapper
// -----------------------------------------------------------------------------
// Phase8.2 memory-oriented wrapper.
//
// This wrapper keeps weight and quant parameters inside memory-style arrays, then
// connects those arrays to the already verified sr_core_top module.
//
// The verified RTL under model_lite/sr_core/RTL is not modified.
// -----------------------------------------------------------------------------

module sr_core_top_mem_wrapper (
    input wire clk,
    input wire rst,
    input wire start,

    input wire in_valid,
    input signed [7:0] in_pixel,
    output wire in_ready,

    output wire busy,
    output wire done
);

    // Conv1 weight shape: [8][3][3][1], flattened to 72 signed int8 values.
    reg signed [7:0] conv1_weight_mem [0:71];

    // Conv3 layer uses 1x1 kernel. Weight shape: [4][1][1][8].
    reg signed [7:0] conv3_weight_mem [0:31];

    // Per-output-channel requant parameters.
    reg signed [31:0] conv1_m0_mem [0:7];
    reg signed [63:0] conv1_m1_mem [0:7];
    reg signed [31:0] conv3_m0_mem [0:3];
    reg signed [63:0] conv3_m1_mem [0:3];

    sr_core_top core_u0 (
        .clk(clk),
        .rst(rst),
        .start(start),
        .in_valid(in_valid),
        .in_pixel(in_pixel),
        .in_ready(in_ready),

        .conv1_w000(conv1_weight_mem[0]),  .conv1_w001(conv1_weight_mem[1]),  .conv1_w002(conv1_weight_mem[2]),
        .conv1_w003(conv1_weight_mem[3]),  .conv1_w004(conv1_weight_mem[4]),  .conv1_w005(conv1_weight_mem[5]),
        .conv1_w006(conv1_weight_mem[6]),  .conv1_w007(conv1_weight_mem[7]),  .conv1_w008(conv1_weight_mem[8]),

        .conv1_w100(conv1_weight_mem[9]),  .conv1_w101(conv1_weight_mem[10]), .conv1_w102(conv1_weight_mem[11]),
        .conv1_w103(conv1_weight_mem[12]), .conv1_w104(conv1_weight_mem[13]), .conv1_w105(conv1_weight_mem[14]),
        .conv1_w106(conv1_weight_mem[15]), .conv1_w107(conv1_weight_mem[16]), .conv1_w108(conv1_weight_mem[17]),

        .conv1_w200(conv1_weight_mem[18]), .conv1_w201(conv1_weight_mem[19]), .conv1_w202(conv1_weight_mem[20]),
        .conv1_w203(conv1_weight_mem[21]), .conv1_w204(conv1_weight_mem[22]), .conv1_w205(conv1_weight_mem[23]),
        .conv1_w206(conv1_weight_mem[24]), .conv1_w207(conv1_weight_mem[25]), .conv1_w208(conv1_weight_mem[26]),

        .conv1_w300(conv1_weight_mem[27]), .conv1_w301(conv1_weight_mem[28]), .conv1_w302(conv1_weight_mem[29]),
        .conv1_w303(conv1_weight_mem[30]), .conv1_w304(conv1_weight_mem[31]), .conv1_w305(conv1_weight_mem[32]),
        .conv1_w306(conv1_weight_mem[33]), .conv1_w307(conv1_weight_mem[34]), .conv1_w308(conv1_weight_mem[35]),

        .conv1_w400(conv1_weight_mem[36]), .conv1_w401(conv1_weight_mem[37]), .conv1_w402(conv1_weight_mem[38]),
        .conv1_w403(conv1_weight_mem[39]), .conv1_w404(conv1_weight_mem[40]), .conv1_w405(conv1_weight_mem[41]),
        .conv1_w406(conv1_weight_mem[42]), .conv1_w407(conv1_weight_mem[43]), .conv1_w408(conv1_weight_mem[44]),

        .conv1_w500(conv1_weight_mem[45]), .conv1_w501(conv1_weight_mem[46]), .conv1_w502(conv1_weight_mem[47]),
        .conv1_w503(conv1_weight_mem[48]), .conv1_w504(conv1_weight_mem[49]), .conv1_w505(conv1_weight_mem[50]),
        .conv1_w506(conv1_weight_mem[51]), .conv1_w507(conv1_weight_mem[52]), .conv1_w508(conv1_weight_mem[53]),

        .conv1_w600(conv1_weight_mem[54]), .conv1_w601(conv1_weight_mem[55]), .conv1_w602(conv1_weight_mem[56]),
        .conv1_w603(conv1_weight_mem[57]), .conv1_w604(conv1_weight_mem[58]), .conv1_w605(conv1_weight_mem[59]),
        .conv1_w606(conv1_weight_mem[60]), .conv1_w607(conv1_weight_mem[61]), .conv1_w608(conv1_weight_mem[62]),

        .conv1_w700(conv1_weight_mem[63]), .conv1_w701(conv1_weight_mem[64]), .conv1_w702(conv1_weight_mem[65]),
        .conv1_w703(conv1_weight_mem[66]), .conv1_w704(conv1_weight_mem[67]), .conv1_w705(conv1_weight_mem[68]),
        .conv1_w706(conv1_weight_mem[69]), .conv1_w707(conv1_weight_mem[70]), .conv1_w708(conv1_weight_mem[71]),

        .conv1_m0_0(conv1_m0_mem[0]), .conv1_m0_1(conv1_m0_mem[1]),
        .conv1_m0_2(conv1_m0_mem[2]), .conv1_m0_3(conv1_m0_mem[3]),
        .conv1_m0_4(conv1_m0_mem[4]), .conv1_m0_5(conv1_m0_mem[5]),
        .conv1_m0_6(conv1_m0_mem[6]), .conv1_m0_7(conv1_m0_mem[7]),

        .conv1_m1_0(conv1_m1_mem[0]), .conv1_m1_1(conv1_m1_mem[1]),
        .conv1_m1_2(conv1_m1_mem[2]), .conv1_m1_3(conv1_m1_mem[3]),
        .conv1_m1_4(conv1_m1_mem[4]), .conv1_m1_5(conv1_m1_mem[5]),
        .conv1_m1_6(conv1_m1_mem[6]), .conv1_m1_7(conv1_m1_mem[7]),

        .conv3_w00(conv3_weight_mem[0]),  .conv3_w01(conv3_weight_mem[1]),
        .conv3_w02(conv3_weight_mem[2]),  .conv3_w03(conv3_weight_mem[3]),
        .conv3_w04(conv3_weight_mem[4]),  .conv3_w05(conv3_weight_mem[5]),
        .conv3_w06(conv3_weight_mem[6]),  .conv3_w07(conv3_weight_mem[7]),

        .conv3_w10(conv3_weight_mem[8]),  .conv3_w11(conv3_weight_mem[9]),
        .conv3_w12(conv3_weight_mem[10]), .conv3_w13(conv3_weight_mem[11]),
        .conv3_w14(conv3_weight_mem[12]), .conv3_w15(conv3_weight_mem[13]),
        .conv3_w16(conv3_weight_mem[14]), .conv3_w17(conv3_weight_mem[15]),

        .conv3_w20(conv3_weight_mem[16]), .conv3_w21(conv3_weight_mem[17]),
        .conv3_w22(conv3_weight_mem[18]), .conv3_w23(conv3_weight_mem[19]),
        .conv3_w24(conv3_weight_mem[20]), .conv3_w25(conv3_weight_mem[21]),
        .conv3_w26(conv3_weight_mem[22]), .conv3_w27(conv3_weight_mem[23]),

        .conv3_w30(conv3_weight_mem[24]), .conv3_w31(conv3_weight_mem[25]),
        .conv3_w32(conv3_weight_mem[26]), .conv3_w33(conv3_weight_mem[27]),
        .conv3_w34(conv3_weight_mem[28]), .conv3_w35(conv3_weight_mem[29]),
        .conv3_w36(conv3_weight_mem[30]), .conv3_w37(conv3_weight_mem[31]),

        .conv3_m0_0(conv3_m0_mem[0]), .conv3_m0_1(conv3_m0_mem[1]),
        .conv3_m0_2(conv3_m0_mem[2]), .conv3_m0_3(conv3_m0_mem[3]),

        .conv3_m1_0(conv3_m1_mem[0]), .conv3_m1_1(conv3_m1_mem[1]),
        .conv3_m1_2(conv3_m1_mem[2]), .conv3_m1_3(conv3_m1_mem[3]),

        .busy(busy),
        .done(done)
    );

endmodule
