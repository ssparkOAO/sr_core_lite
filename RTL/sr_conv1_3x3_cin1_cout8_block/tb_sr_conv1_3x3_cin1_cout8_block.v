`timescale 1ns / 1ps

module tb_sr_conv1_3x3_cin1_cout8_block;

    parameter integer IMG_W        = 8;
    parameter integer IMG_H        = 8;
    parameter integer IN_COUNT     = 64;
    parameter integer WEIGHT_COUNT = 72;
    parameter integer COUT         = 8;
    parameter integer OUT_COUNT    = 512;

    reg clk;
    reg rst;
    reg in_valid;
    reg signed [7:0] in_pixel;
    wire in_ready;
    wire out_valid;
    wire [15:0] out_x;
    wire [15:0] out_y;

    wire signed [7:0] q0;
    wire signed [7:0] q1;
    wire signed [7:0] q2;
    wire signed [7:0] q3;
    wire signed [7:0] q4;
    wire signed [7:0] q5;
    wire signed [7:0] q6;
    wire signed [7:0] q7;

    wire signed [31:0] acc0;
    wire signed [31:0] acc1;
    wire signed [31:0] acc2;
    wire signed [31:0] acc3;
    wire signed [31:0] acc4;
    wire signed [31:0] acc5;
    wire signed [31:0] acc6;
    wire signed [31:0] acc7;

    wire signed [7:0] win00;
    wire signed [7:0] win01;
    wire signed [7:0] win02;
    wire signed [7:0] win10;
    wire signed [7:0] win11;
    wire signed [7:0] win12;
    wire signed [7:0] win20;
    wire signed [7:0] win21;
    wire signed [7:0] win22;

    reg signed [7:0]  input_mem  [0:IN_COUNT-1];
    reg signed [7:0]  weight_mem [0:WEIGHT_COUNT-1];
    reg signed [31:0] m0_mem     [0:COUT-1];
    reg signed [63:0] m1_mem     [0:COUT-1];
    reg signed [7:0]  golden_mem [0:OUT_COUNT-1];

    integer fd_input;
    integer fd_weight;
    integer fd_m0;
    integer fd_m1;
    integer fd_golden;
    integer fd_result;
    integer read_ok;
    integer temp_value;
    integer i;
    integer input_index;
    integer out_index;
    integer golden_index;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;

    sr_conv1_3x3_cin1_cout8_block dut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_pixel(in_pixel),
        .in_ready(in_ready),

        .w000(weight_mem[0]),  .w001(weight_mem[1]),  .w002(weight_mem[2]),
        .w003(weight_mem[3]),  .w004(weight_mem[4]),  .w005(weight_mem[5]),
        .w006(weight_mem[6]),  .w007(weight_mem[7]),  .w008(weight_mem[8]),

        .w100(weight_mem[9]),  .w101(weight_mem[10]), .w102(weight_mem[11]),
        .w103(weight_mem[12]), .w104(weight_mem[13]), .w105(weight_mem[14]),
        .w106(weight_mem[15]), .w107(weight_mem[16]), .w108(weight_mem[17]),

        .w200(weight_mem[18]), .w201(weight_mem[19]), .w202(weight_mem[20]),
        .w203(weight_mem[21]), .w204(weight_mem[22]), .w205(weight_mem[23]),
        .w206(weight_mem[24]), .w207(weight_mem[25]), .w208(weight_mem[26]),

        .w300(weight_mem[27]), .w301(weight_mem[28]), .w302(weight_mem[29]),
        .w303(weight_mem[30]), .w304(weight_mem[31]), .w305(weight_mem[32]),
        .w306(weight_mem[33]), .w307(weight_mem[34]), .w308(weight_mem[35]),

        .w400(weight_mem[36]), .w401(weight_mem[37]), .w402(weight_mem[38]),
        .w403(weight_mem[39]), .w404(weight_mem[40]), .w405(weight_mem[41]),
        .w406(weight_mem[42]), .w407(weight_mem[43]), .w408(weight_mem[44]),

        .w500(weight_mem[45]), .w501(weight_mem[46]), .w502(weight_mem[47]),
        .w503(weight_mem[48]), .w504(weight_mem[49]), .w505(weight_mem[50]),
        .w506(weight_mem[51]), .w507(weight_mem[52]), .w508(weight_mem[53]),

        .w600(weight_mem[54]), .w601(weight_mem[55]), .w602(weight_mem[56]),
        .w603(weight_mem[57]), .w604(weight_mem[58]), .w605(weight_mem[59]),
        .w606(weight_mem[60]), .w607(weight_mem[61]), .w608(weight_mem[62]),

        .w700(weight_mem[63]), .w701(weight_mem[64]), .w702(weight_mem[65]),
        .w703(weight_mem[66]), .w704(weight_mem[67]), .w705(weight_mem[68]),
        .w706(weight_mem[69]), .w707(weight_mem[70]), .w708(weight_mem[71]),

        .m0_0(m0_mem[0]), .m0_1(m0_mem[1]), .m0_2(m0_mem[2]), .m0_3(m0_mem[3]),
        .m0_4(m0_mem[4]), .m0_5(m0_mem[5]), .m0_6(m0_mem[6]), .m0_7(m0_mem[7]),

        .m1_0(m1_mem[0]), .m1_1(m1_mem[1]), .m1_2(m1_mem[2]), .m1_3(m1_mem[3]),
        .m1_4(m1_mem[4]), .m1_5(m1_mem[5]), .m1_6(m1_mem[6]), .m1_7(m1_mem[7]),

        .out_valid(out_valid),
        .out_x(out_x),
        .out_y(out_y),

        .q0(q0), .q1(q1), .q2(q2), .q3(q3),
        .q4(q4), .q5(q5), .q6(q6), .q7(q7),

        .acc0(acc0), .acc1(acc1), .acc2(acc2), .acc3(acc3),
        .acc4(acc4), .acc5(acc5), .acc6(acc6), .acc7(acc7),

        .win00_dbg(win00), .win01_dbg(win01), .win02_dbg(win02),
        .win10_dbg(win10), .win11_dbg(win11), .win12_dbg(win12),
        .win20_dbg(win20), .win21_dbg(win21), .win22_dbg(win22)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_channel;
        input integer channel;
        input signed [7:0] rtl_q;
        input signed [7:0] golden_q;
        input signed [31:0] acc_value;
        input signed [31:0] m0_value;
        input signed [63:0] m1_value;
    begin
        diff = rtl_q - golden_q;
        if (diff < 0)
            abs_diff = -diff;
        else
            abs_diff = diff;

        if (abs_diff > max_abs_diff)
            max_abs_diff = abs_diff;

        if (rtl_q !== golden_q) begin
            mismatch_count = mismatch_count + 1;
            $display("MISMATCH pixel=%0d x=%0d y=%0d channel=%0d rtl_q=%0d golden_q=%0d acc=%0d m0=%0d m1=%0d",
                     out_index, out_x, out_y, channel, rtl_q, golden_q, acc_value, m0_value, m1_value);
            $display("window: [%0d %0d %0d] [%0d %0d %0d] [%0d %0d %0d]",
                     win00, win01, win02, win10, win11, win12, win20, win21, win22);
            $fdisplay(fd_result, "MISMATCH pixel=%0d x=%0d y=%0d channel=%0d rtl_q=%0d golden_q=%0d acc=%0d m0=%0d m1=%0d",
                      out_index, out_x, out_y, channel, rtl_q, golden_q, acc_value, m0_value, m1_value);
            $fdisplay(fd_result, "window: [%0d %0d %0d] [%0d %0d %0d] [%0d %0d %0d]",
                      win00, win01, win02, win10, win11, win12, win20, win21, win22);
        end
    end
    endtask

    initial begin
        fd_input  = $fopen("model_lite/sr_core/generated/golden/input_int8_for_core.mem", "r");
        fd_weight = $fopen("model_lite/sr_core/generated/conv1_weight.mem", "r");
        fd_m0     = $fopen("model_lite/sr_core/generated/conv1_m0.mem", "r");
        fd_m1     = $fopen("model_lite/sr_core/generated/conv1_m1.mem", "r");
        fd_golden = $fopen("model_lite/sr_core/generated/golden/conv1_out_int8.mem", "r");
        fd_result = $fopen("model_lite/sr_core/RTL/sr_conv1_3x3_cin1_cout8_block/tb_sr_conv1_3x3_cin1_cout8_block_result.txt", "w");

        if (fd_input == 0) begin $display("ERROR: failed to open input_int8_for_core.mem"); $finish; end
        if (fd_weight == 0) begin $display("ERROR: failed to open conv1_weight.mem"); $finish; end
        if (fd_m0 == 0) begin $display("ERROR: failed to open conv1_m0.mem"); $finish; end
        if (fd_m1 == 0) begin $display("ERROR: failed to open conv1_m1.mem"); $finish; end
        if (fd_golden == 0) begin $display("ERROR: failed to open conv1_out_int8.mem"); $finish; end
        if (fd_result == 0) begin $display("ERROR: failed to open result txt"); $finish; end

        $fdisplay(fd_result, "sr_conv1_3x3_cin1_cout8_block verification result");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Purpose : Conv1 3x3 window + MAC + 8x requant");
        $fdisplay(fd_result, "Input   : input_int8_for_core.mem, shape (8,8,1)");
        $fdisplay(fd_result, "Weight  : conv1_weight.mem, shape [8,3,3,1]");
        $fdisplay(fd_result, "M0/M1   : conv1_m0.mem / conv1_m1.mem, 8 channels");
        $fdisplay(fd_result, "Golden  : conv1_out_int8.mem, shape (8,8,8)");
        $fdisplay(fd_result, "No separate ReLU block; Conv1 fused ReLU has output zero_point = -128");
        $fdisplay(fd_result, "");

        for (i = 0; i < IN_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read input index %0d", i); $finish; end
            input_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < WEIGHT_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_weight, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read weight index %0d", i); $finish; end
            weight_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < COUT; i = i + 1) begin
            read_ok = $fscanf(fd_m0, "%d\n", m0_mem[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read m0 channel %0d", i); $finish; end
        end

        for (i = 0; i < COUT; i = i + 1) begin
            read_ok = $fscanf(fd_m1, "%d\n", m1_mem[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read m1 channel %0d", i); $finish; end
        end

        for (i = 0; i < OUT_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read golden index %0d", i); $finish; end
            golden_mem[i] = temp_value[7:0];
        end

        $fclose(fd_input);
        $fclose(fd_weight);
        $fclose(fd_m0);
        $fclose(fd_m1);
        $fclose(fd_golden);

        rst = 1'b1;
        in_valid = 1'b0;
        in_pixel = 8'sd0;
        mismatch_count = 0;
        max_abs_diff = 0;
        out_index = 0;
        input_index = 0;

        repeat (2) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        while (out_index < IMG_W*IMG_H) begin
            @(negedge clk);
            if (in_ready && (input_index < IN_COUNT)) begin
                in_pixel = input_mem[input_index];
                in_valid = 1'b1;
                input_index = input_index + 1;
            end else begin
                in_pixel = 8'sd0;
                in_valid = 1'b0;
            end

            if (out_valid) begin
                golden_index = (out_y*IMG_W + out_x) * COUT;
                check_channel(0, q0, golden_mem[golden_index + 0], acc0, m0_mem[0], m1_mem[0]);
                check_channel(1, q1, golden_mem[golden_index + 1], acc1, m0_mem[1], m1_mem[1]);
                check_channel(2, q2, golden_mem[golden_index + 2], acc2, m0_mem[2], m1_mem[2]);
                check_channel(3, q3, golden_mem[golden_index + 3], acc3, m0_mem[3], m1_mem[3]);
                check_channel(4, q4, golden_mem[golden_index + 4], acc4, m0_mem[4], m1_mem[4]);
                check_channel(5, q5, golden_mem[golden_index + 5], acc5, m0_mem[5], m1_mem[5]);
                check_channel(6, q6, golden_mem[golden_index + 6], acc6, m0_mem[6], m1_mem[6]);
                check_channel(7, q7, golden_mem[golden_index + 7], acc7, m0_mem[7], m1_mem[7]);
                out_index = out_index + 1;
            end
        end

        @(negedge clk);
        in_valid = 1'b0;

        $display("mismatch count = %0d", mismatch_count);
        $display("max abs diff   = %0d", max_abs_diff);
        $fdisplay(fd_result, "mismatch count = %0d", mismatch_count);
        $fdisplay(fd_result, "max abs diff   = %0d", max_abs_diff);

        if (mismatch_count == 0) begin
            $display("PASS");
            $fdisplay(fd_result, "PASS");
        end else begin
            $display("FAIL");
            $fdisplay(fd_result, "FAIL");
        end

        $fclose(fd_result);
        $finish;
    end

endmodule
