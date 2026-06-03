`timescale 1ns / 1ps

module tb_sr_top_clean_stream_img;

    parameter integer IN_COUNT = 16384;
    parameter integer OUT_WORD_COUNT = 32768;
    parameter integer OUT_PIXEL_COUNT = 65536;

    reg clk;
    reg rst;
    reg preload_start;
    reg core_start;
    reg in_valid;
    reg signed [7:0] in_pixel;

    wire in_ready;
    wire preload_busy;
    wire preload_done;
    wire busy;
    wire done;

    reg out_rd_en;
    reg [14:0] out_rd_addr;
    wire [15:0] out_rd_data;

    reg signed [7:0] input_mem [0:IN_COUNT-1];
    reg [7:0] golden_mem [0:OUT_PIXEL_COUNT-1];

    integer fd_input;
    integer fd_golden;
    integer fd_result;
    integer fd_output;
    integer read_ok;
    integer temp_value;
    integer i;
    integer input_index;
    integer sent_count;
    integer out_index;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;

    reg [7:0] out_left;
    reg [7:0] out_right;

    sr_top_clean_stream_img dut (
        .clk(clk),
        .rst(rst),
        .preload_start(preload_start),
        .core_start(core_start),
        .in_valid(in_valid),
        .in_pixel(in_pixel),
        .in_ready(in_ready),
        .preload_busy(preload_busy),
        .preload_done(preload_done),
        .busy(busy),
        .done(done),
        .out_rd_en(out_rd_en),
        .out_rd_addr(out_rd_addr),
        .out_rd_data(out_rd_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        fd_input = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/butterflyx2_Y.txt", "r");
        fd_golden = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/result/sr_output_uint8.txt", "r");
        fd_result = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase9_6_clean_stream/results/tb_sr_top_clean_stream_img_result.txt", "w");
        fd_output = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/result/sr_output_uint8_clean_stream.txt", "w");

        if (fd_input == 0) begin
            $display("ERROR: failed to open butterflyx2_Y.txt");
            $finish;
        end
        if (fd_golden == 0) begin
            $display("ERROR: failed to open Phase9.5 sr_output_uint8.txt");
            $finish;
        end
        if (fd_result == 0) begin
            $display("ERROR: failed to open result txt");
            $finish;
        end
        if (fd_output == 0) begin
            $display("ERROR: failed to open clean stream output txt");
            $finish;
        end

        for (i = 0; i < IN_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%h\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read input index %0d", i);
                $finish;
            end
            input_mem[i] = temp_value - 128;
        end
        $fclose(fd_input);

        for (i = 0; i < OUT_PIXEL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read golden index %0d", i);
                $finish;
            end
            golden_mem[i] = temp_value[7:0];
        end
        $fclose(fd_golden);

        $fdisplay(fd_result, "Phase9.6 clean streaming image-level SR TB");
        $fdisplay(fd_result, "Input    : butterflyx2_Y.txt");
        $fdisplay(fd_result, "Golden   : Phase9.5 sr_output_uint8.txt");
        $fdisplay(fd_result, "Output   : sr_output_uint8_clean_stream.txt");
        $fdisplay(fd_result, "");

        rst = 1'b1;
        preload_start = 1'b0;
        core_start = 1'b0;
        in_valid = 1'b0;
        in_pixel = 8'sd0;
        out_rd_en = 1'b0;
        out_rd_addr = 15'd0;
        input_index = 0;
        sent_count = 0;
        out_index = 0;
        mismatch_count = 0;
        max_abs_diff = 0;

        repeat (3) @(posedge clk);
        rst = 1'b0;

        @(negedge clk);
        preload_start = 1'b1;
        @(negedge clk);
        preload_start = 1'b0;

        wait (preload_done == 1'b1);
        $display("preload_done asserted");
        $fdisplay(fd_result, "preload_done asserted");

        @(negedge clk);
        core_start = 1'b1;
        @(negedge clk);
        core_start = 1'b0;

        while (done == 1'b0) begin
            @(negedge clk);
            if (in_ready && (input_index < IN_COUNT)) begin
                in_pixel = input_mem[input_index];
                in_valid = 1'b1;
                input_index = input_index + 1;
                sent_count = sent_count + 1;
            end else begin
                in_pixel = 8'sd0;
                in_valid = 1'b0;
            end
        end

        @(negedge clk);
        in_valid = 1'b0;

        $display("core done asserted");
        $display("input sent count = %0d", sent_count);
        $fdisplay(fd_result, "core done asserted");
        $fdisplay(fd_result, "input sent count = %0d", sent_count);

        out_index = 0;
        for (i = 0; i < OUT_WORD_COUNT; i = i + 1) begin
            @(negedge clk);
            out_rd_en = 1'b1;
            out_rd_addr = i[14:0];
            @(posedge clk);
            @(negedge clk);
            out_rd_en = 1'b0;

            out_left = out_rd_data[7:0];
            out_right = out_rd_data[15:8];

            $fdisplay(fd_output, "%0d", out_left);
            diff = out_left - golden_mem[out_index];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;
            if (out_left !== golden_mem[out_index]) begin
                mismatch_count = mismatch_count + 1;
                if (mismatch_count <= 20) begin
                    $display("Mismatch index=%0d rtl=%0d golden=%0d", out_index, out_left, golden_mem[out_index]);
                    $fdisplay(fd_result, "Mismatch index=%0d rtl=%0d golden=%0d", out_index, out_left, golden_mem[out_index]);
                end
            end
            out_index = out_index + 1;

            $fdisplay(fd_output, "%0d", out_right);
            diff = out_right - golden_mem[out_index];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;
            if (out_right !== golden_mem[out_index]) begin
                mismatch_count = mismatch_count + 1;
                if (mismatch_count <= 20) begin
                    $display("Mismatch index=%0d rtl=%0d golden=%0d", out_index, out_right, golden_mem[out_index]);
                    $fdisplay(fd_result, "Mismatch index=%0d rtl=%0d golden=%0d", out_index, out_right, golden_mem[out_index]);
                end
            end
            out_index = out_index + 1;
        end

        $display("output pixel count = %0d", out_index);
        $display("mismatch count = %0d", mismatch_count);
        $display("max abs diff = %0d", max_abs_diff);
        $fdisplay(fd_result, "output pixel count = %0d", out_index);
        $fdisplay(fd_result, "mismatch count = %0d", mismatch_count);
        $fdisplay(fd_result, "max abs diff = %0d", max_abs_diff);

        if ((sent_count == IN_COUNT) && (out_index == OUT_PIXEL_COUNT) &&
            (mismatch_count == 0) && (max_abs_diff == 0)) begin
            $display("PASS");
            $fdisplay(fd_result, "PASS");
        end else begin
            $display("FAIL");
            $fdisplay(fd_result, "FAIL");
        end

        $fclose(fd_output);
        $fclose(fd_result);
        $finish;
    end

endmodule
