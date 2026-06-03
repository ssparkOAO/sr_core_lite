`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_core_top_stream_ram_wrapper
// -----------------------------------------------------------------------------
// Phase9.2 reference-like RAM/IP architecture.
//
// This top does not instantiate the old verification-oriented sr_core_top.
// Instead, it places the verified CNN datapath blocks beside raw RAM ports:
//
//   Conv1 -> register slice -> Conv3 -> conv3_feature_ram port
//          conv3_feature_ram port -> PixelShuffle -> OutputStage -> output RAM
//
// The parameter path keeps the Phase8.4b idea:
//   Vivado parameter ROMs -> preload FSM -> parameter register bank.
//
// The verified RTL library under model_lite/sr_core/RTL is not modified.
// -----------------------------------------------------------------------------

module sr_core_top_stream_ram_wrapper (
    input wire clk,
    input wire rst,
    input wire preload_start,
    input wire core_start,

    input wire in_valid,
    input signed [7:0] in_pixel,
    output wire in_ready,

    output reg preload_busy,
    output reg preload_done,
    output reg busy,
    output reg done,

    // Conv3 feature RAM raw port.
    output reg conv3_feature_wr_en,
    output reg [5:0] conv3_feature_wr_addr,
    output reg [31:0] conv3_feature_wr_data,
    output reg conv3_feature_rd_en,
    output reg [5:0] conv3_feature_rd_addr,
    input wire [31:0] conv3_feature_rd_data,

    // Output image RAM raw write ports.
    output wire output_ram_wr_en_a,
    output wire [7:0] output_ram_wr_addr_a,
    output wire [15:0] output_ram_wr_data_a,
    output wire output_ram_wr_en_b,
    output wire [7:0] output_ram_wr_addr_b,
    output wire [15:0] output_ram_wr_data_b
);

    // -------------------------------------------------------------------------
    // Parameter register bank
    // -------------------------------------------------------------------------
    reg signed [7:0] conv1_weight_mem [0:71];
    reg signed [7:0] conv3_weight_mem [0:31];
    reg signed [31:0] conv1_m0_mem [0:7];
    reg signed [63:0] conv1_m1_mem [0:7];
    reg signed [31:0] conv3_m0_mem [0:3];
    reg signed [63:0] conv3_m1_mem [0:3];

    localparam PRE_IDLE        = 5'd0;
    localparam PRE_C1W_SEND    = 5'd1;
    localparam PRE_C1W_WAIT    = 5'd2;
    localparam PRE_C1W_CAPTURE = 5'd3;
    localparam PRE_C3W_SEND    = 5'd4;
    localparam PRE_C3W_WAIT    = 5'd5;
    localparam PRE_C3W_CAPTURE = 5'd6;
    localparam PRE_C1M_SEND    = 5'd7;
    localparam PRE_C1M_WAIT    = 5'd8;
    localparam PRE_C1M_CAPTURE = 5'd9;
    localparam PRE_C3M_SEND    = 5'd10;
    localparam PRE_C3M_WAIT    = 5'd11;
    localparam PRE_C3M_CAPTURE = 5'd12;
    localparam PRE_DONE        = 5'd13;

    reg [4:0] preload_state;
    reg [6:0] preload_index;

    reg conv1_weight_en;
    reg [6:0] conv1_weight_addr;
    wire signed [7:0] conv1_weight_data;

    reg conv3_weight_en;
    reg [4:0] conv3_weight_addr;
    wire signed [7:0] conv3_weight_data;

    reg conv1_m0_en;
    reg [2:0] conv1_m0_addr;
    wire signed [31:0] conv1_m0_data;

    reg conv1_m1_en;
    reg [2:0] conv1_m1_addr;
    wire signed [63:0] conv1_m1_data;

    reg conv3_m0_en;
    reg [1:0] conv3_m0_addr;
    wire signed [31:0] conv3_m0_data;

    reg conv3_m1_en;
    reg [1:0] conv3_m1_addr;
    wire signed [63:0] conv3_m1_data;

    sr_param_rom_bank param_rom_bank_u0 (
        .clk(clk),
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
        .conv3_m1_data(conv3_m1_data)
    );

    always @(posedge clk) begin
        if (rst) begin
            preload_state <= PRE_IDLE;
            preload_index <= 7'd0;
            preload_busy <= 1'b0;
            preload_done <= 1'b0;
            conv1_weight_en <= 1'b0;
            conv1_weight_addr <= 7'd0;
            conv3_weight_en <= 1'b0;
            conv3_weight_addr <= 5'd0;
            conv1_m0_en <= 1'b0;
            conv1_m0_addr <= 3'd0;
            conv1_m1_en <= 1'b0;
            conv1_m1_addr <= 3'd0;
            conv3_m0_en <= 1'b0;
            conv3_m0_addr <= 2'd0;
            conv3_m1_en <= 1'b0;
            conv3_m1_addr <= 2'd0;
        end else begin
            case (preload_state)
                PRE_IDLE: begin
                    preload_busy <= 1'b0;
                    conv1_weight_en <= 1'b0;
                    conv3_weight_en <= 1'b0;
                    conv1_m0_en <= 1'b0;
                    conv1_m1_en <= 1'b0;
                    conv3_m0_en <= 1'b0;
                    conv3_m1_en <= 1'b0;
                    if (preload_start) begin
                        preload_busy <= 1'b1;
                        preload_done <= 1'b0;
                        preload_index <= 7'd0;
                        preload_state <= PRE_C1W_SEND;
                    end
                end

                PRE_C1W_SEND: begin
                    conv1_weight_en <= 1'b1;
                    conv1_weight_addr <= preload_index;
                    preload_state <= PRE_C1W_WAIT;
                end

                PRE_C1W_WAIT: begin
                    conv1_weight_en <= 1'b0;
                    preload_state <= PRE_C1W_CAPTURE;
                end

                PRE_C1W_CAPTURE: begin
                    conv1_weight_mem[preload_index] <= conv1_weight_data;
                    if (preload_index == 7'd71) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_C3W_SEND;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C1W_SEND;
                    end
                end

                PRE_C3W_SEND: begin
                    conv3_weight_en <= 1'b1;
                    conv3_weight_addr <= preload_index[4:0];
                    preload_state <= PRE_C3W_WAIT;
                end

                PRE_C3W_WAIT: begin
                    conv3_weight_en <= 1'b0;
                    preload_state <= PRE_C3W_CAPTURE;
                end

                PRE_C3W_CAPTURE: begin
                    conv3_weight_mem[preload_index[4:0]] <= conv3_weight_data;
                    if (preload_index == 7'd31) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_C1M_SEND;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C3W_SEND;
                    end
                end

                PRE_C1M_SEND: begin
                    conv1_m0_en <= 1'b1;
                    conv1_m1_en <= 1'b1;
                    conv1_m0_addr <= preload_index[2:0];
                    conv1_m1_addr <= preload_index[2:0];
                    preload_state <= PRE_C1M_WAIT;
                end

                PRE_C1M_WAIT: begin
                    conv1_m0_en <= 1'b0;
                    conv1_m1_en <= 1'b0;
                    preload_state <= PRE_C1M_CAPTURE;
                end

                PRE_C1M_CAPTURE: begin
                    conv1_m0_mem[preload_index[2:0]] <= conv1_m0_data;
                    conv1_m1_mem[preload_index[2:0]] <= conv1_m1_data;
                    if (preload_index == 7'd7) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_C3M_SEND;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C1M_SEND;
                    end
                end

                PRE_C3M_SEND: begin
                    conv3_m0_en <= 1'b1;
                    conv3_m1_en <= 1'b1;
                    conv3_m0_addr <= preload_index[1:0];
                    conv3_m1_addr <= preload_index[1:0];
                    preload_state <= PRE_C3M_WAIT;
                end

                PRE_C3M_WAIT: begin
                    conv3_m0_en <= 1'b0;
                    conv3_m1_en <= 1'b0;
                    preload_state <= PRE_C3M_CAPTURE;
                end

                PRE_C3M_CAPTURE: begin
                    conv3_m0_mem[preload_index[1:0]] <= conv3_m0_data;
                    conv3_m1_mem[preload_index[1:0]] <= conv3_m1_data;
                    if (preload_index == 7'd3) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_DONE;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C3M_SEND;
                    end
                end

                PRE_DONE: begin
                    preload_busy <= 1'b0;
                    preload_done <= 1'b1;
                    conv1_weight_en <= 1'b0;
                    conv3_weight_en <= 1'b0;
                    conv1_m0_en <= 1'b0;
                    conv1_m1_en <= 1'b0;
                    conv3_m0_en <= 1'b0;
                    conv3_m1_en <= 1'b0;
                    if (preload_start) begin
                        preload_busy <= 1'b1;
                        preload_done <= 1'b0;
                        preload_index <= 7'd0;
                        preload_state <= PRE_C1W_SEND;
                    end
                end

                default: begin
                    preload_state <= PRE_IDLE;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // CNN datapath
    // -------------------------------------------------------------------------
    localparam CORE_IDLE       = 3'd0;
    localparam CORE_CONV       = 3'd1;
    localparam CORE_PS_SEND    = 3'd2;
    localparam CORE_PS_WAIT    = 3'd3;
    localparam CORE_PS_USE     = 3'd4;
    localparam CORE_DONE       = 3'd5;

    reg [2:0] core_state;
    reg [5:0] ps_pixel_index;

    wire gated_core_start;
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

    reg conv1_to_conv3_valid;
    reg conv1_to_conv3_last;
    reg [5:0] conv1_to_conv3_addr;
    reg signed [7:0] conv3_in_c0;
    reg signed [7:0] conv3_in_c1;
    reg signed [7:0] conv3_in_c2;
    reg signed [7:0] conv3_in_c3;
    reg signed [7:0] conv3_in_c4;
    reg signed [7:0] conv3_in_c5;
    reg signed [7:0] conv3_in_c6;
    reg signed [7:0] conv3_in_c7;

    wire signed [7:0] conv3_q0;
    wire signed [7:0] conv3_q1;
    wire signed [7:0] conv3_q2;
    wire signed [7:0] conv3_q3;

    wire ps_rst;
    reg ps_in_valid_reg;
    wire ps_wr_en_a;
    wire [7:0] ps_wr_addr_a;
    wire [15:0] ps_wr_data_a;
    wire ps_wr_en_b;
    wire [7:0] ps_wr_addr_b;
    wire [15:0] ps_wr_data_b;
    wire ps_frame_done;

    wire signed [7:0] ps_c0;
    wire signed [7:0] ps_c1;
    wire signed [7:0] ps_c2;
    wire signed [7:0] ps_c3;

    wire [7:0] out_a_left;
    wire [7:0] out_a_right;
    wire [7:0] out_b_left;
    wire [7:0] out_b_right;

    assign gated_core_start = core_start & preload_done;
    assign conv1_in_valid = (core_state == CORE_CONV) && in_valid;
    assign in_ready = (core_state == CORE_CONV) && conv1_in_ready;

    assign ps_rst = rst || (core_state != CORE_PS_SEND &&
                            core_state != CORE_PS_WAIT &&
                            core_state != CORE_PS_USE);

    assign ps_c0 = conv3_feature_rd_data[7:0];
    assign ps_c1 = conv3_feature_rd_data[15:8];
    assign ps_c2 = conv3_feature_rd_data[23:16];
    assign ps_c3 = conv3_feature_rd_data[31:24];

    assign output_ram_wr_en_a = ps_wr_en_a;
    assign output_ram_wr_addr_a = ps_wr_addr_a;
    assign output_ram_wr_data_a = {out_a_right, out_a_left};

    assign output_ram_wr_en_b = ps_wr_en_b;
    assign output_ram_wr_addr_b = ps_wr_addr_b;
    assign output_ram_wr_data_b = {out_b_right, out_b_left};

    sr_conv1_3x3_cin1_cout8_block conv1_block (
        .clk(clk),
        .rst(rst),
        .in_valid(conv1_in_valid),
        .in_pixel(in_pixel),
        .in_ready(conv1_in_ready),

        .w000(conv1_weight_mem[0]),  .w001(conv1_weight_mem[1]),  .w002(conv1_weight_mem[2]),
        .w003(conv1_weight_mem[3]),  .w004(conv1_weight_mem[4]),  .w005(conv1_weight_mem[5]),
        .w006(conv1_weight_mem[6]),  .w007(conv1_weight_mem[7]),  .w008(conv1_weight_mem[8]),
        .w100(conv1_weight_mem[9]),  .w101(conv1_weight_mem[10]), .w102(conv1_weight_mem[11]),
        .w103(conv1_weight_mem[12]), .w104(conv1_weight_mem[13]), .w105(conv1_weight_mem[14]),
        .w106(conv1_weight_mem[15]), .w107(conv1_weight_mem[16]), .w108(conv1_weight_mem[17]),
        .w200(conv1_weight_mem[18]), .w201(conv1_weight_mem[19]), .w202(conv1_weight_mem[20]),
        .w203(conv1_weight_mem[21]), .w204(conv1_weight_mem[22]), .w205(conv1_weight_mem[23]),
        .w206(conv1_weight_mem[24]), .w207(conv1_weight_mem[25]), .w208(conv1_weight_mem[26]),
        .w300(conv1_weight_mem[27]), .w301(conv1_weight_mem[28]), .w302(conv1_weight_mem[29]),
        .w303(conv1_weight_mem[30]), .w304(conv1_weight_mem[31]), .w305(conv1_weight_mem[32]),
        .w306(conv1_weight_mem[33]), .w307(conv1_weight_mem[34]), .w308(conv1_weight_mem[35]),
        .w400(conv1_weight_mem[36]), .w401(conv1_weight_mem[37]), .w402(conv1_weight_mem[38]),
        .w403(conv1_weight_mem[39]), .w404(conv1_weight_mem[40]), .w405(conv1_weight_mem[41]),
        .w406(conv1_weight_mem[42]), .w407(conv1_weight_mem[43]), .w408(conv1_weight_mem[44]),
        .w500(conv1_weight_mem[45]), .w501(conv1_weight_mem[46]), .w502(conv1_weight_mem[47]),
        .w503(conv1_weight_mem[48]), .w504(conv1_weight_mem[49]), .w505(conv1_weight_mem[50]),
        .w506(conv1_weight_mem[51]), .w507(conv1_weight_mem[52]), .w508(conv1_weight_mem[53]),
        .w600(conv1_weight_mem[54]), .w601(conv1_weight_mem[55]), .w602(conv1_weight_mem[56]),
        .w603(conv1_weight_mem[57]), .w604(conv1_weight_mem[58]), .w605(conv1_weight_mem[59]),
        .w606(conv1_weight_mem[60]), .w607(conv1_weight_mem[61]), .w608(conv1_weight_mem[62]),
        .w700(conv1_weight_mem[63]), .w701(conv1_weight_mem[64]), .w702(conv1_weight_mem[65]),
        .w703(conv1_weight_mem[66]), .w704(conv1_weight_mem[67]), .w705(conv1_weight_mem[68]),
        .w706(conv1_weight_mem[69]), .w707(conv1_weight_mem[70]), .w708(conv1_weight_mem[71]),

        .m0_0(conv1_m0_mem[0]), .m0_1(conv1_m0_mem[1]),
        .m0_2(conv1_m0_mem[2]), .m0_3(conv1_m0_mem[3]),
        .m0_4(conv1_m0_mem[4]), .m0_5(conv1_m0_mem[5]),
        .m0_6(conv1_m0_mem[6]), .m0_7(conv1_m0_mem[7]),
        .m1_0(conv1_m1_mem[0]), .m1_1(conv1_m1_mem[1]),
        .m1_2(conv1_m1_mem[2]), .m1_3(conv1_m1_mem[3]),
        .m1_4(conv1_m1_mem[4]), .m1_5(conv1_m1_mem[5]),
        .m1_6(conv1_m1_mem[6]), .m1_7(conv1_m1_mem[7]),

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
        .w00(conv3_weight_mem[0]),  .w01(conv3_weight_mem[1]),
        .w02(conv3_weight_mem[2]),  .w03(conv3_weight_mem[3]),
        .w04(conv3_weight_mem[4]),  .w05(conv3_weight_mem[5]),
        .w06(conv3_weight_mem[6]),  .w07(conv3_weight_mem[7]),
        .w10(conv3_weight_mem[8]),  .w11(conv3_weight_mem[9]),
        .w12(conv3_weight_mem[10]), .w13(conv3_weight_mem[11]),
        .w14(conv3_weight_mem[12]), .w15(conv3_weight_mem[13]),
        .w16(conv3_weight_mem[14]), .w17(conv3_weight_mem[15]),
        .w20(conv3_weight_mem[16]), .w21(conv3_weight_mem[17]),
        .w22(conv3_weight_mem[18]), .w23(conv3_weight_mem[19]),
        .w24(conv3_weight_mem[20]), .w25(conv3_weight_mem[21]),
        .w26(conv3_weight_mem[22]), .w27(conv3_weight_mem[23]),
        .w30(conv3_weight_mem[24]), .w31(conv3_weight_mem[25]),
        .w32(conv3_weight_mem[26]), .w33(conv3_weight_mem[27]),
        .w34(conv3_weight_mem[28]), .w35(conv3_weight_mem[29]),
        .w36(conv3_weight_mem[30]), .w37(conv3_weight_mem[31]),
        .m0_0(conv3_m0_mem[0]), .m0_1(conv3_m0_mem[1]),
        .m0_2(conv3_m0_mem[2]), .m0_3(conv3_m0_mem[3]),
        .m1_0(conv3_m1_mem[0]), .m1_1(conv3_m1_mem[1]),
        .m1_2(conv3_m1_mem[2]), .m1_3(conv3_m1_mem[3]),
        .q0(conv3_q0), .q1(conv3_q1), .q2(conv3_q2), .q3(conv3_q3)
    );

    pixel_shuffle_core #(
        .LR_WIDTH(8),
        .LR_HEIGHT(8),
        .ADDR_WIDTH(8)
    ) pixel_shuffle_u0 (
        .clk(clk),
        .rst(ps_rst),
        .in_valid(ps_in_valid_reg),
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

    sr_output_stage out_a_l (.in_pixel(ps_wr_data_a[7:0]),  .out_pixel_uint8(out_a_left));
    sr_output_stage out_a_r (.in_pixel(ps_wr_data_a[15:8]), .out_pixel_uint8(out_a_right));
    sr_output_stage out_b_l (.in_pixel(ps_wr_data_b[7:0]),  .out_pixel_uint8(out_b_left));
    sr_output_stage out_b_r (.in_pixel(ps_wr_data_b[15:8]), .out_pixel_uint8(out_b_right));

    always @(posedge clk) begin
        if (rst) begin
            core_state <= CORE_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            ps_pixel_index <= 6'd0;
            conv1_to_conv3_valid <= 1'b0;
            conv1_to_conv3_last <= 1'b0;
            conv1_to_conv3_addr <= 6'd0;
            conv3_in_c0 <= 8'sd0;
            conv3_in_c1 <= 8'sd0;
            conv3_in_c2 <= 8'sd0;
            conv3_in_c3 <= 8'sd0;
            conv3_in_c4 <= 8'sd0;
            conv3_in_c5 <= 8'sd0;
            conv3_in_c6 <= 8'sd0;
            conv3_in_c7 <= 8'sd0;
            conv3_feature_wr_en <= 1'b0;
            conv3_feature_wr_addr <= 6'd0;
            conv3_feature_wr_data <= 32'd0;
            conv3_feature_rd_en <= 1'b0;
            conv3_feature_rd_addr <= 6'd0;
            ps_in_valid_reg <= 1'b0;
        end else begin
            conv3_feature_wr_en <= 1'b0;
            conv3_feature_rd_en <= 1'b0;
            ps_in_valid_reg <= 1'b0;

            case (core_state)
                CORE_IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    ps_pixel_index <= 6'd0;
                    conv1_to_conv3_valid <= 1'b0;
                    conv1_to_conv3_last <= 1'b0;
                    if (gated_core_start) begin
                        busy <= 1'b1;
                        core_state <= CORE_CONV;
                    end
                end

                CORE_CONV: begin
                    busy <= 1'b1;

                    if (conv1_to_conv3_valid) begin
                        conv3_feature_wr_en <= 1'b1;
                        conv3_feature_wr_addr <= conv1_to_conv3_addr;
                        conv3_feature_wr_data <= {conv3_q3, conv3_q2, conv3_q1, conv3_q0};
                    end

                    if (conv1_out_valid) begin
                        conv3_in_c0 <= conv1_q0;
                        conv3_in_c1 <= conv1_q1;
                        conv3_in_c2 <= conv1_q2;
                        conv3_in_c3 <= conv1_q3;
                        conv3_in_c4 <= conv1_q4;
                        conv3_in_c5 <= conv1_q5;
                        conv3_in_c6 <= conv1_q6;
                        conv3_in_c7 <= conv1_q7;
                        conv1_to_conv3_addr <= conv1_out_y[2:0] * 6'd8 + conv1_out_x[2:0];
                        conv1_to_conv3_last <= (conv1_out_x == 16'd7) && (conv1_out_y == 16'd7);
                        conv1_to_conv3_valid <= 1'b1;
                    end else begin
                        conv1_to_conv3_valid <= 1'b0;
                        conv1_to_conv3_last <= 1'b0;
                    end

                    if (conv1_to_conv3_valid && conv1_to_conv3_last) begin
                        ps_pixel_index <= 6'd0;
                        core_state <= CORE_PS_SEND;
                    end
                end

                CORE_PS_SEND: begin
                    conv3_feature_rd_en <= 1'b1;
                    conv3_feature_rd_addr <= ps_pixel_index;
                    core_state <= CORE_PS_WAIT;
                end

                CORE_PS_WAIT: begin
                    core_state <= CORE_PS_USE;
                end

                CORE_PS_USE: begin
                    ps_in_valid_reg <= 1'b1;
                    if (ps_pixel_index == 6'd63) begin
                        core_state <= CORE_DONE;
                    end else begin
                        ps_pixel_index <= ps_pixel_index + 6'd1;
                        core_state <= CORE_PS_SEND;
                    end
                end

                CORE_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    core_state <= CORE_DONE;
                end

                default: begin
                    core_state <= CORE_IDLE;
                end
            endcase
        end
    end

endmodule
