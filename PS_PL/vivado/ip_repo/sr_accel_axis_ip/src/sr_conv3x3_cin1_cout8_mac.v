`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_conv3x3_cin1_cout8_mac
// -----------------------------------------------------------------------------
// Purpose:
//   Conv1 3x3 MAC only. Cin=1, Cout=8.
//   No bias, no requant, no clamp, no ReLU.
// -----------------------------------------------------------------------------

module sr_conv3x3_cin1_cout8_mac (
    input signed [7:0] win00,
    input signed [7:0] win01,
    input signed [7:0] win02,
    input signed [7:0] win10,
    input signed [7:0] win11,
    input signed [7:0] win12,
    input signed [7:0] win20,
    input signed [7:0] win21,
    input signed [7:0] win22,

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

    output signed [31:0] acc0,
    output signed [31:0] acc1,
    output signed [31:0] acc2,
    output signed [31:0] acc3,
    output signed [31:0] acc4,
    output signed [31:0] acc5,
    output signed [31:0] acc6,
    output signed [31:0] acc7
);

wire signed [15:0] win00_s;
wire signed [15:0] win01_s;
wire signed [15:0] win02_s;
wire signed [15:0] win10_s;
wire signed [15:0] win11_s;
wire signed [15:0] win12_s;
wire signed [15:0] win20_s;
wire signed [15:0] win21_s;
wire signed [15:0] win22_s;

assign win00_s = win00;
assign win01_s = win01;
assign win02_s = win02;
assign win10_s = win10;
assign win11_s = win11;
assign win12_s = win12;
assign win20_s = win20;
assign win21_s = win21;
assign win22_s = win22;

// Stage 1/2: row partial sums for each output channel.
wire signed [31:0] psum0_r0;
wire signed [31:0] psum0_r1;
wire signed [31:0] psum0_r2;
wire signed [31:0] psum1_r0;
wire signed [31:0] psum1_r1;
wire signed [31:0] psum1_r2;
wire signed [31:0] psum2_r0;
wire signed [31:0] psum2_r1;
wire signed [31:0] psum2_r2;
wire signed [31:0] psum3_r0;
wire signed [31:0] psum3_r1;
wire signed [31:0] psum3_r2;
wire signed [31:0] psum4_r0;
wire signed [31:0] psum4_r1;
wire signed [31:0] psum4_r2;
wire signed [31:0] psum5_r0;
wire signed [31:0] psum5_r1;
wire signed [31:0] psum5_r2;
wire signed [31:0] psum6_r0;
wire signed [31:0] psum6_r1;
wire signed [31:0] psum6_r2;
wire signed [31:0] psum7_r0;
wire signed [31:0] psum7_r1;
wire signed [31:0] psum7_r2;

assign psum0_r0 = (win00_s * w000) + (win01_s * w001) + (win02_s * w002);
assign psum0_r1 = (win10_s * w003) + (win11_s * w004) + (win12_s * w005);
assign psum0_r2 = (win20_s * w006) + (win21_s * w007) + (win22_s * w008);

assign psum1_r0 = (win00_s * w100) + (win01_s * w101) + (win02_s * w102);
assign psum1_r1 = (win10_s * w103) + (win11_s * w104) + (win12_s * w105);
assign psum1_r2 = (win20_s * w106) + (win21_s * w107) + (win22_s * w108);

assign psum2_r0 = (win00_s * w200) + (win01_s * w201) + (win02_s * w202);
assign psum2_r1 = (win10_s * w203) + (win11_s * w204) + (win12_s * w205);
assign psum2_r2 = (win20_s * w206) + (win21_s * w207) + (win22_s * w208);

assign psum3_r0 = (win00_s * w300) + (win01_s * w301) + (win02_s * w302);
assign psum3_r1 = (win10_s * w303) + (win11_s * w304) + (win12_s * w305);
assign psum3_r2 = (win20_s * w306) + (win21_s * w307) + (win22_s * w308);

assign psum4_r0 = (win00_s * w400) + (win01_s * w401) + (win02_s * w402);
assign psum4_r1 = (win10_s * w403) + (win11_s * w404) + (win12_s * w405);
assign psum4_r2 = (win20_s * w406) + (win21_s * w407) + (win22_s * w408);

assign psum5_r0 = (win00_s * w500) + (win01_s * w501) + (win02_s * w502);
assign psum5_r1 = (win10_s * w503) + (win11_s * w504) + (win12_s * w505);
assign psum5_r2 = (win20_s * w506) + (win21_s * w507) + (win22_s * w508);

assign psum6_r0 = (win00_s * w600) + (win01_s * w601) + (win02_s * w602);
assign psum6_r1 = (win10_s * w603) + (win11_s * w604) + (win12_s * w605);
assign psum6_r2 = (win20_s * w606) + (win21_s * w607) + (win22_s * w608);

assign psum7_r0 = (win00_s * w700) + (win01_s * w701) + (win02_s * w702);
assign psum7_r1 = (win10_s * w703) + (win11_s * w704) + (win12_s * w705);
assign psum7_r2 = (win20_s * w706) + (win21_s * w707) + (win22_s * w708);

// Stage 3: final accumulation for each output channel.
assign acc0 = psum0_r0 + psum0_r1 + psum0_r2;
assign acc1 = psum1_r0 + psum1_r1 + psum1_r2;
assign acc2 = psum2_r0 + psum2_r1 + psum2_r2;
assign acc3 = psum3_r0 + psum3_r1 + psum3_r2;
assign acc4 = psum4_r0 + psum4_r1 + psum4_r2;
assign acc5 = psum5_r0 + psum5_r1 + psum5_r2;
assign acc6 = psum6_r0 + psum6_r1 + psum6_r2;
assign acc7 = psum7_r0 + psum7_r1 + psum7_r2;

endmodule
