`timescale 1ns / 1ps

module tb_sr_conv1x1_cin8_cout4_mac;

    parameter integer NUM_PIXELS  = 64;
    parameter integer CIN         = 8;
    parameter integer COUT        = 4;
    parameter integer ACT_COUNT   = 512;
    parameter integer WEIGHT_COUNT = 32;
    parameter integer GOLD_COUNT  = 256;

    reg signed [7:0] in_c0;
    reg signed [7:0] in_c1;
    reg signed [7:0] in_c2;
    reg signed [7:0] in_c3;
    reg signed [7:0] in_c4;
    reg signed [7:0] in_c5;
    reg signed [7:0] in_c6;
    reg signed [7:0] in_c7;

    reg signed [7:0] w00;
    reg signed [7:0] w01;
    reg signed [7:0] w02;
    reg signed [7:0] w03;
    reg signed [7:0] w04;
    reg signed [7:0] w05;
    reg signed [7:0] w06;
    reg signed [7:0] w07;

    reg signed [7:0] w10;
    reg signed [7:0] w11;
    reg signed [7:0] w12;
    reg signed [7:0] w13;
    reg signed [7:0] w14;
    reg signed [7:0] w15;
    reg signed [7:0] w16;
    reg signed [7:0] w17;

    reg signed [7:0] w20;
    reg signed [7:0] w21;
    reg signed [7:0] w22;
    reg signed [7:0] w23;
    reg signed [7:0] w24;
    reg signed [7:0] w25;
    reg signed [7:0] w26;
    reg signed [7:0] w27;

    reg signed [7:0] w30;
    reg signed [7:0] w31;
    reg signed [7:0] w32;
    reg signed [7:0] w33;
    reg signed [7:0] w34;
    reg signed [7:0] w35;
    reg signed [7:0] w36;
    reg signed [7:0] w37;

    wire signed [31:0] acc0;
    wire signed [31:0] acc1;
    wire signed [31:0] acc2;
    wire signed [31:0] acc3;

    reg signed [7:0]  act_mem    [0:ACT_COUNT-1];
    reg signed [7:0]  weight_mem [0:WEIGHT_COUNT-1];
    reg signed [31:0] golden_mem [0:GOLD_COUNT-1];

    integer fd_act;
    integer fd_weight;
    integer fd_golden;
    integer fd_result;
    integer read_ok;
    integer temp_value;
    integer pixel;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;

    sr_conv1x1_cin8_cout4_mac dut (
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

    initial begin
        fd_act    = $fopen("model_lite/sr_core/generated/golden/conv1_out_int8.mem", "r");
        fd_weight = $fopen("model_lite/sr_core/generated/conv3_weight.mem", "r");
        fd_golden = $fopen("model_lite/sr_core/generated/golden/conv3_acc_int32.mem", "r");
        fd_result = $fopen("model_lite/sr_core/RTL/sr_conv1x1_cin8_cout4_mac/tb_sr_conv1x1_cin8_cout4_mac_result.txt", "w");

        if (fd_act == 0) begin
            $display("ERROR: failed to open conv1_out_int8.mem");
            $finish;
        end

        if (fd_weight == 0) begin
            $display("ERROR: failed to open conv3_weight.mem");
            $finish;
        end

        if (fd_golden == 0) begin
            $display("ERROR: failed to open conv3_acc_int32.mem");
            $finish;
        end

        if (fd_result == 0) begin
            $display("ERROR: failed to open result txt");
            $finish;
        end

        $fdisplay(fd_result, "sr_conv1x1_cin8_cout4_mac verification result");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Purpose : Conv3 layer 1x1 MAC only");
        $fdisplay(fd_result, "Input   : conv1_out_int8.mem, shape (H,W,8), NHWC");
        $fdisplay(fd_result, "Weight  : conv3_weight.mem, shape [4,1,1,8], cout-major");
        $fdisplay(fd_result, "Golden  : conv3_acc_int32.mem, shape (H,W,4)");
        $fdisplay(fd_result, "No bias, no requant, no clamp, no ReLU");
        $fdisplay(fd_result, "");

        // Memory mapping: conv1_out_int8 is NHWC, 8 signed int8 values per pixel.
        for (pixel = 0; pixel < ACT_COUNT; pixel = pixel + 1) begin
            read_ok = $fscanf(fd_act, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read activation index %0d", pixel);
                $finish;
            end
            act_mem[pixel] = temp_value[7:0];
        end

        // Weight mapping: cout-major, 8 signed int8 weights per output channel.
        for (pixel = 0; pixel < WEIGHT_COUNT; pixel = pixel + 1) begin
            read_ok = $fscanf(fd_weight, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read weight index %0d", pixel);
                $finish;
            end
            weight_mem[pixel] = temp_value[7:0];
        end

        // Golden mapping: conv3_acc_int32 is NHWC, 4 signed int32 accumulators per pixel.
        for (pixel = 0; pixel < GOLD_COUNT; pixel = pixel + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", golden_mem[pixel]);
            if (read_ok != 1) begin
                $display("ERROR: failed to read golden index %0d", pixel);
                $finish;
            end
        end

        $fclose(fd_act);
        $fclose(fd_weight);
        $fclose(fd_golden);

        w00 = weight_mem[0];
        w01 = weight_mem[1];
        w02 = weight_mem[2];
        w03 = weight_mem[3];
        w04 = weight_mem[4];
        w05 = weight_mem[5];
        w06 = weight_mem[6];
        w07 = weight_mem[7];

        w10 = weight_mem[8];
        w11 = weight_mem[9];
        w12 = weight_mem[10];
        w13 = weight_mem[11];
        w14 = weight_mem[12];
        w15 = weight_mem[13];
        w16 = weight_mem[14];
        w17 = weight_mem[15];

        w20 = weight_mem[16];
        w21 = weight_mem[17];
        w22 = weight_mem[18];
        w23 = weight_mem[19];
        w24 = weight_mem[20];
        w25 = weight_mem[21];
        w26 = weight_mem[22];
        w27 = weight_mem[23];

        w30 = weight_mem[24];
        w31 = weight_mem[25];
        w32 = weight_mem[26];
        w33 = weight_mem[27];
        w34 = weight_mem[28];
        w35 = weight_mem[29];
        w36 = weight_mem[30];
        w37 = weight_mem[31];

        mismatch_count = 0;
        max_abs_diff = 0;

        for (pixel = 0; pixel < NUM_PIXELS; pixel = pixel + 1) begin
            in_c0 = act_mem[pixel*CIN + 0];
            in_c1 = act_mem[pixel*CIN + 1];
            in_c2 = act_mem[pixel*CIN + 2];
            in_c3 = act_mem[pixel*CIN + 3];
            in_c4 = act_mem[pixel*CIN + 4];
            in_c5 = act_mem[pixel*CIN + 5];
            in_c6 = act_mem[pixel*CIN + 6];
            in_c7 = act_mem[pixel*CIN + 7];
            #1;

            diff = acc0 - golden_mem[pixel*COUT + 0];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;
            if (acc0 !== golden_mem[pixel*COUT + 0]) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH pixel=%0d channel=0 rtl=%0d golden=%0d", pixel, acc0, golden_mem[pixel*COUT + 0]);
                $fdisplay(fd_result, "MISMATCH pixel=%0d channel=0 rtl=%0d golden=%0d", pixel, acc0, golden_mem[pixel*COUT + 0]);
            end

            diff = acc1 - golden_mem[pixel*COUT + 1];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;
            if (acc1 !== golden_mem[pixel*COUT + 1]) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH pixel=%0d channel=1 rtl=%0d golden=%0d", pixel, acc1, golden_mem[pixel*COUT + 1]);
                $fdisplay(fd_result, "MISMATCH pixel=%0d channel=1 rtl=%0d golden=%0d", pixel, acc1, golden_mem[pixel*COUT + 1]);
            end

            diff = acc2 - golden_mem[pixel*COUT + 2];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;
            if (acc2 !== golden_mem[pixel*COUT + 2]) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH pixel=%0d channel=2 rtl=%0d golden=%0d", pixel, acc2, golden_mem[pixel*COUT + 2]);
                $fdisplay(fd_result, "MISMATCH pixel=%0d channel=2 rtl=%0d golden=%0d", pixel, acc2, golden_mem[pixel*COUT + 2]);
            end

            diff = acc3 - golden_mem[pixel*COUT + 3];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;
            if (acc3 !== golden_mem[pixel*COUT + 3]) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH pixel=%0d channel=3 rtl=%0d golden=%0d", pixel, acc3, golden_mem[pixel*COUT + 3]);
                $fdisplay(fd_result, "MISMATCH pixel=%0d channel=3 rtl=%0d golden=%0d", pixel, acc3, golden_mem[pixel*COUT + 3]);
            end
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
