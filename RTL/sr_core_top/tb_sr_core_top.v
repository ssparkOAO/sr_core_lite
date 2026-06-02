`timescale 1ns / 1ps

module tb_sr_core_top;

    parameter integer IN_COUNT        = 64;
    parameter integer CONV1_WEIGHT_N  = 72;
    parameter integer CONV1_COUT      = 8;
    parameter integer CONV3_WEIGHT_N  = 32;
    parameter integer CONV3_COUT      = 4;
    parameter integer FINAL_COUNT     = 256;

    reg clk;
    reg rst;
    reg start;
    reg in_valid;
    reg signed [7:0] in_pixel;

    wire in_ready;
    wire busy;
    wire done;

    reg signed [7:0]  input_mem        [0:IN_COUNT-1];
    reg signed [7:0]  conv1_weight_mem [0:CONV1_WEIGHT_N-1];
    reg signed [31:0] conv1_m0_mem     [0:CONV1_COUT-1];
    reg signed [63:0] conv1_m1_mem     [0:CONV1_COUT-1];
    reg signed [7:0]  conv3_weight_mem [0:CONV3_WEIGHT_N-1];
    reg signed [31:0] conv3_m0_mem     [0:CONV3_COUT-1];
    reg signed [63:0] conv3_m1_mem     [0:CONV3_COUT-1];
    reg [7:0]         golden_out_mem   [0:FINAL_COUNT-1];

    integer fd_input;
    integer fd_conv1_weight;
    integer fd_conv1_m0;
    integer fd_conv1_m1;
    integer fd_conv3_weight;
    integer fd_conv3_m0;
    integer fd_conv3_m1;
    integer fd_golden;
    integer fd_result;
    integer fd_dump0;
    integer fd_dump1;
    integer fd_dump2;

    integer read_ok;
    integer temp_value;
    integer i;
    integer input_index;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;

    sr_core_top dut (
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

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task compare_pixel;
        input integer pixel_index;
        input [7:0] rtl_value;
        input [7:0] golden_value;
        integer hr_x;
        integer hr_y;
        integer lr_x;
        integer lr_y;
        integer lr_pixel;
        integer sub_channel;
    begin
        hr_y = pixel_index / 16;
        hr_x = pixel_index - hr_y*16;
        lr_y = hr_y / 2;
        lr_x = hr_x / 2;
        lr_pixel = lr_y*8 + lr_x;
        sub_channel = (hr_y - lr_y*2)*2 + (hr_x - lr_x*2);

        diff = rtl_value - golden_value;
        if (diff < 0)
            abs_diff = -diff;
        else
            abs_diff = diff;

        if (abs_diff > max_abs_diff)
            max_abs_diff = abs_diff;

        if (rtl_value !== golden_value) begin
            mismatch_count = mismatch_count + 1;
            $display("MISMATCH pixel=%0d hr_y=%0d hr_x=%0d rtl=%0d golden=%0d conv3_sub=%0d pixel_shuffle=%0d",
                     pixel_index, hr_y, hr_x, rtl_value, golden_value,
                     dut.feature_mem1[lr_pixel*4 + sub_channel],
                     dut.feature_mem2[pixel_index]);
            $display("Conv1 feature at LR pixel %0d: c0=%0d c1=%0d c2=%0d c3=%0d c4=%0d c5=%0d c6=%0d c7=%0d",
                     lr_pixel,
                     dut.feature_mem0[lr_pixel*8 + 0], dut.feature_mem0[lr_pixel*8 + 1],
                     dut.feature_mem0[lr_pixel*8 + 2], dut.feature_mem0[lr_pixel*8 + 3],
                     dut.feature_mem0[lr_pixel*8 + 4], dut.feature_mem0[lr_pixel*8 + 5],
                     dut.feature_mem0[lr_pixel*8 + 6], dut.feature_mem0[lr_pixel*8 + 7]);
            $fdisplay(fd_result, "MISMATCH pixel=%0d hr_y=%0d hr_x=%0d rtl=%0d golden=%0d conv3_sub=%0d pixel_shuffle=%0d",
                      pixel_index, hr_y, hr_x, rtl_value, golden_value,
                      dut.feature_mem1[lr_pixel*4 + sub_channel],
                      dut.feature_mem2[pixel_index]);
            $fdisplay(fd_result, "Conv1 feature at LR pixel %0d: c0=%0d c1=%0d c2=%0d c3=%0d c4=%0d c5=%0d c6=%0d c7=%0d",
                      lr_pixel,
                      dut.feature_mem0[lr_pixel*8 + 0], dut.feature_mem0[lr_pixel*8 + 1],
                      dut.feature_mem0[lr_pixel*8 + 2], dut.feature_mem0[lr_pixel*8 + 3],
                      dut.feature_mem0[lr_pixel*8 + 4], dut.feature_mem0[lr_pixel*8 + 5],
                      dut.feature_mem0[lr_pixel*8 + 6], dut.feature_mem0[lr_pixel*8 + 7]);
        end
    end
    endtask

    initial begin
        fd_input        = $fopen("model_lite/sr_core/generated/golden/input_int8_for_core.mem", "r");
        fd_conv1_weight = $fopen("model_lite/sr_core/generated/conv1_weight.mem", "r");
        fd_conv1_m0     = $fopen("model_lite/sr_core/generated/conv1_m0.mem", "r");
        fd_conv1_m1     = $fopen("model_lite/sr_core/generated/conv1_m1.mem", "r");
        fd_conv3_weight = $fopen("model_lite/sr_core/generated/conv3_weight.mem", "r");
        fd_conv3_m0     = $fopen("model_lite/sr_core/generated/conv3_m0.mem", "r");
        fd_conv3_m1     = $fopen("model_lite/sr_core/generated/conv3_m1.mem", "r");
        fd_golden       = $fopen("model_lite/sr_core/generated/golden/output_uint8.mem", "r");
        fd_result       = $fopen("model_lite/sr_core/RTL/sr_core_top/tb_sr_core_top_result.txt", "w");

        if (fd_input == 0) begin $display("ERROR: failed to open input_int8_for_core.mem"); $finish; end
        if (fd_conv1_weight == 0) begin $display("ERROR: failed to open conv1_weight.mem"); $finish; end
        if (fd_conv1_m0 == 0) begin $display("ERROR: failed to open conv1_m0.mem"); $finish; end
        if (fd_conv1_m1 == 0) begin $display("ERROR: failed to open conv1_m1.mem"); $finish; end
        if (fd_conv3_weight == 0) begin $display("ERROR: failed to open conv3_weight.mem"); $finish; end
        if (fd_conv3_m0 == 0) begin $display("ERROR: failed to open conv3_m0.mem"); $finish; end
        if (fd_conv3_m1 == 0) begin $display("ERROR: failed to open conv3_m1.mem"); $finish; end
        if (fd_golden == 0) begin $display("ERROR: failed to open output_uint8.mem"); $finish; end
        if (fd_result == 0) begin $display("ERROR: failed to open result txt"); $finish; end

        $fdisplay(fd_result, "sr_core_top end-to-end verification result");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Flow:");
        $fdisplay(fd_result, "  input_int8_for_core");
        $fdisplay(fd_result, "    -> Conv1 block");
        $fdisplay(fd_result, "    -> feature_mem0");
        $fdisplay(fd_result, "    -> Conv3 block");
        $fdisplay(fd_result, "    -> feature_mem1");
        $fdisplay(fd_result, "    -> PixelShuffle core");
        $fdisplay(fd_result, "    -> feature_mem2");
        $fdisplay(fd_result, "    -> OutputStage");
        $fdisplay(fd_result, "    -> output_uint8");
        $fdisplay(fd_result, "");

        for (i = 0; i < IN_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read input index %0d", i); $finish; end
            input_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < CONV1_WEIGHT_N; i = i + 1) begin
            read_ok = $fscanf(fd_conv1_weight, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read conv1 weight index %0d", i); $finish; end
            conv1_weight_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < CONV1_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv1_m0, "%d\n", conv1_m0_mem[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv1 m0 index %0d", i); $finish; end
        end

        for (i = 0; i < CONV1_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv1_m1, "%d\n", conv1_m1_mem[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv1 m1 index %0d", i); $finish; end
        end

        for (i = 0; i < CONV3_WEIGHT_N; i = i + 1) begin
            read_ok = $fscanf(fd_conv3_weight, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 weight index %0d", i); $finish; end
            conv3_weight_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < CONV3_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3_m0, "%d\n", conv3_m0_mem[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 m0 index %0d", i); $finish; end
        end

        for (i = 0; i < CONV3_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3_m1, "%d\n", conv3_m1_mem[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 m1 index %0d", i); $finish; end
        end

        for (i = 0; i < FINAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read output golden index %0d", i); $finish; end
            golden_out_mem[i] = temp_value[7:0];
        end

        $fclose(fd_input);
        $fclose(fd_conv1_weight);
        $fclose(fd_conv1_m0);
        $fclose(fd_conv1_m1);
        $fclose(fd_conv3_weight);
        $fclose(fd_conv3_m0);
        $fclose(fd_conv3_m1);
        $fclose(fd_golden);

        rst = 1'b1;
        start = 1'b0;
        in_valid = 1'b0;
        in_pixel = 8'sd0;
        input_index = 0;
        mismatch_count = 0;
        max_abs_diff = 0;

        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        while (done == 1'b0) begin
            @(negedge clk);
            if (in_ready && (input_index < IN_COUNT)) begin
                in_pixel = input_mem[input_index];
                in_valid = 1'b1;
                input_index = input_index + 1;
            end else begin
                in_pixel = 8'sd0;
                in_valid = 1'b0;
            end
        end

        @(negedge clk);
        in_valid = 1'b0;

        fd_dump0 = $fopen("model_lite/sr_core/RTL/sr_core_top/feature_mem0_dump.txt", "w");
        fd_dump1 = $fopen("model_lite/sr_core/RTL/sr_core_top/feature_mem1_dump.txt", "w");
        fd_dump2 = $fopen("model_lite/sr_core/RTL/sr_core_top/feature_mem2_dump.txt", "w");

        if (fd_dump0 == 0) begin $display("ERROR: failed to open feature_mem0_dump.txt"); $finish; end
        if (fd_dump1 == 0) begin $display("ERROR: failed to open feature_mem1_dump.txt"); $finish; end
        if (fd_dump2 == 0) begin $display("ERROR: failed to open feature_mem2_dump.txt"); $finish; end

        for (i = 0; i < 512; i = i + 1) begin
            $fdisplay(fd_dump0, "%0d", dut.feature_mem0[i]);
        end
        for (i = 0; i < 256; i = i + 1) begin
            $fdisplay(fd_dump1, "%0d", dut.feature_mem1[i]);
        end
        for (i = 0; i < 256; i = i + 1) begin
            $fdisplay(fd_dump2, "%0d", dut.feature_mem2[i]);
        end

        $fclose(fd_dump0);
        $fclose(fd_dump1);
        $fclose(fd_dump2);

        for (i = 0; i < FINAL_COUNT; i = i + 1) begin
            compare_pixel(i, dut.output_mem[i], golden_out_mem[i]);
        end

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
