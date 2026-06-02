`timescale 1ns / 1ps

module tb_sr_output_stage;

    parameter integer TOTAL_COUNT = 256;

    reg signed [7:0] in_pixel;
    wire [7:0] out_pixel_uint8;

    reg signed [7:0] input_mem [0:TOTAL_COUNT-1];
    reg [7:0] golden_mem [0:TOTAL_COUNT-1];

    integer fd_input;
    integer fd_golden;
    integer fd_result;
    integer read_ok;
    integer temp_value;
    integer i;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;
    integer clipped_value;

    sr_output_stage dut (
        .in_pixel(in_pixel),
        .out_pixel_uint8(out_pixel_uint8)
    );

    initial begin
        fd_input  = $fopen("model_lite/sr_core/generated/golden/pixel_shuffle_out_int8.mem", "r");
        fd_golden = $fopen("model_lite/sr_core/generated/golden/output_uint8.mem", "r");
        fd_result = $fopen("model_lite/sr_core/RTL/sr_output_stage/tb_sr_output_stage_result.txt", "w");

        if (fd_input == 0) begin
            $display("ERROR: failed to open pixel_shuffle_out_int8.mem");
            $finish;
        end

        if (fd_golden == 0) begin
            $display("ERROR: failed to open output_uint8.mem");
            $finish;
        end

        if (fd_result == 0) begin
            $display("ERROR: failed to open result txt");
            $finish;
        end

        $fdisplay(fd_result, "sr_output_stage verification result");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Purpose : signed int8 output clip + uint8 conversion");
        $fdisplay(fd_result, "Input   : pixel_shuffle_out_int8.mem, shape (16,16,1)");
        $fdisplay(fd_result, "Golden  : output_uint8.mem, shape (16,16,1)");
        $fdisplay(fd_result, "Formula : output_uint8 = clipped_int8 + 128");
        $fdisplay(fd_result, "");

        for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read input index %0d", i);
                $finish;
            end
            input_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read golden index %0d", i);
                $finish;
            end
            golden_mem[i] = temp_value[7:0];
        end

        $fclose(fd_input);
        $fclose(fd_golden);

        mismatch_count = 0;
        max_abs_diff = 0;

        for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
            in_pixel = input_mem[i];
            #1;

            if (in_pixel > 8'sd127)
                clipped_value = 127;
            else if (in_pixel < -8'sd128)
                clipped_value = -128;
            else
                clipped_value = in_pixel;

            diff = out_pixel_uint8 - golden_mem[i];
            if (diff < 0)
                abs_diff = -diff;
            else
                abs_diff = diff;

            if (abs_diff > max_abs_diff)
                max_abs_diff = abs_diff;

            if (out_pixel_uint8 !== golden_mem[i]) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH pixel=%0d input_int8=%0d clipped=%0d rtl_uint8=%0d golden_uint8=%0d",
                         i, in_pixel, clipped_value, out_pixel_uint8, golden_mem[i]);
                $fdisplay(fd_result, "MISMATCH pixel=%0d input_int8=%0d clipped=%0d rtl_uint8=%0d golden_uint8=%0d",
                          i, in_pixel, clipped_value, out_pixel_uint8, golden_mem[i]);
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
