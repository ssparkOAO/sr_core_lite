`timescale 1ns / 1ps

module tb_sr_nn_top_img;

    parameter integer LR_W = 128;
    parameter integer LR_H = 128;
    parameter integer HR_W = 256;
    parameter integer HR_H = 256;
    parameter integer IN_COUNT = 16384;
    parameter integer OUT_WORD_COUNT = 32768;

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

    reg dbg_c3_rd_en;
    reg [13:0] dbg_c3_rd_addr;
    wire [31:0] dbg_c3_rd_data;
    reg dbg_out_rd_en;
    reg [14:0] dbg_out_rd_addr;
    wire [15:0] dbg_out_rd_data;

    reg signed [7:0] input_mem [0:IN_COUNT-1];

    integer fd_input;
    integer fd_result;
    integer fd_output;
    integer read_ok;
    integer temp_value;
    integer i;
    integer input_index;
    integer out_index;
    integer sent_count;

    reg [7:0] out_left;
    reg [7:0] out_right;

    sr_nn_top_img dut (
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
        .dbg_c3_rd_en(dbg_c3_rd_en),
        .dbg_c3_rd_addr(dbg_c3_rd_addr),
        .dbg_c3_rd_data(dbg_c3_rd_data),
        .dbg_out_rd_en(dbg_out_rd_en),
        .dbg_out_rd_addr(dbg_out_rd_addr),
        .dbg_out_rd_data(dbg_out_rd_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        fd_input = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/butterflyx2_Y.txt", "r");
        fd_result = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase9_5_image_test/results/tb_sr_nn_top_img_result.txt", "w");
        fd_output = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/result/sr_output_uint8_test2.txt", "w");

        if (fd_input == 0) begin
            $display("ERROR: failed to open butterflyx2_Y.txt");
            $finish;
        end
        if (fd_result == 0) begin
            $display("ERROR: failed to open tb result file");
            $finish;
        end
        if (fd_output == 0) begin
            $display("ERROR: failed to open sr_output_uint8.txt");
            $finish;
        end

        $fdisplay(fd_result, "Phase9.5 image-level SR inference TB");
        $fdisplay(fd_result, "Input  : butterflyx2_Y.txt, 128x128 uint8 hex");
        $fdisplay(fd_result, "Output : sr_output_uint8.txt, 256x256 uint8 decimal");
        $fdisplay(fd_result, "");

        for (i = 0; i < IN_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%h\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read input index %0d", i);
                $fdisplay(fd_result, "ERROR: failed to read input index %0d", i);
                $finish;
            end
            input_mem[i] = temp_value - 128;
        end
        $fclose(fd_input);

        rst = 1'b1;
        preload_start = 1'b0;
        core_start = 1'b0;
        in_valid = 1'b0;
        in_pixel = 8'sd0;
        dbg_c3_rd_en = 1'b0;
        dbg_c3_rd_addr = 14'd0;
        dbg_out_rd_en = 1'b0;
        dbg_out_rd_addr = 15'd0;
        input_index = 0;
        sent_count = 0;

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
            dbg_out_rd_en = 1'b1;
            dbg_out_rd_addr = i[14:0];
            @(posedge clk);
            @(negedge clk);
            dbg_out_rd_en = 1'b0;

            out_left = dbg_out_rd_data[7:0];
            out_right = dbg_out_rd_data[15:8];

            $fdisplay(fd_output, "%0d", out_left);
            $fdisplay(fd_output, "%0d", out_right);
            out_index = out_index + 2;
        end

        $display("output pixel count = %0d", out_index);
        $fdisplay(fd_result, "output pixel count = %0d", out_index);

        if ((sent_count == IN_COUNT) && (out_index == HR_W * HR_H)) begin
            $display("TB_CAPTURE_PASS");
            $fdisplay(fd_result, "TB_CAPTURE_PASS");
        end else begin
            $display("TB_CAPTURE_FAIL");
            $fdisplay(fd_result, "TB_CAPTURE_FAIL");
        end

        $fclose(fd_output);
        $fclose(fd_result);
        $finish;
    end

endmodule
