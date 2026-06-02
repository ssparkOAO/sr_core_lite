`timescale 1ns / 1ps

module tb_pixel_shuffle_core;

    parameter integer LR_W        = 8;
    parameter integer LR_H        = 8;
    parameter integer HR_W        = 16;
    parameter integer HR_H        = 16;
    parameter integer COUT        = 4;
    parameter integer LR_PIXELS   = 64;
    parameter integer TOTAL_COUNT = 256;
    parameter integer WORD_COUNT  = 128;
    parameter integer ADDR_WIDTH  = 8;

    reg clk;
    reg rst;
    reg in_valid;

    reg signed [7:0] in_c0;
    reg signed [7:0] in_c1;
    reg signed [7:0] in_c2;
    reg signed [7:0] in_c3;

    wire                  wr_en_a;
    wire [ADDR_WIDTH-1:0] wr_addr_a;
    wire [15:0]           wr_data_a;

    wire                  wr_en_b;
    wire [ADDR_WIDTH-1:0] wr_addr_b;
    wire [15:0]           wr_data_b;

    wire frame_done;

    reg signed [7:0] conv3_mem  [0:TOTAL_COUNT-1];
    reg signed [7:0] golden_mem [0:TOTAL_COUNT-1];
    reg [15:0] fake_mem [0:WORD_COUNT-1];

    integer fd_conv3;
    integer fd_golden;
    integer fd_result;
    integer read_ok;
    integer temp_value;
    integer i;
    integer x;
    integer y;
    integer pixel;
    integer addr;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;

    reg signed [7:0] rtl_value;
    reg signed [7:0] expected_value;
    reg [15:0] packed_word;

    pixel_shuffle_core #(
        .LR_WIDTH(LR_W),
        .LR_HEIGHT(LR_H),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_c0(in_c0),
        .in_c1(in_c1),
        .in_c2(in_c2),
        .in_c3(in_c3),
        .wr_en_a(wr_en_a),
        .wr_addr_a(wr_addr_a),
        .wr_data_a(wr_data_a),
        .wr_en_b(wr_en_b),
        .wr_addr_b(wr_addr_b),
        .wr_data_b(wr_data_b),
        .frame_done(frame_done)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        fd_conv3  = $fopen("model_lite/sr_core/generated/golden/conv3_out_int8.mem", "r");
        fd_golden = $fopen("model_lite/sr_core/generated/golden/pixel_shuffle_out_int8.mem", "r");
        fd_result = $fopen("model_lite/sr_core/RTL/sr_pixel_shuffle_x2/tb_pixel_shuffle_core_result.txt", "w");

        if (fd_conv3 == 0) begin
            $display("ERROR: failed to open conv3_out_int8.mem");
            $finish;
        end

        if (fd_golden == 0) begin
            $display("ERROR: failed to open pixel_shuffle_out_int8.mem");
            $finish;
        end

        if (fd_result == 0) begin
            $display("ERROR: failed to open result txt");
            $finish;
        end

        $fdisplay(fd_result, "pixel_shuffle_core transaction verification result");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Purpose : PixelShuffle x2 write transaction core");
        $fdisplay(fd_result, "Input   : conv3_out_int8.mem, shape (8,8,4), NHWC");
        $fdisplay(fd_result, "Golden  : pixel_shuffle_out_int8.mem, shape (16,16,1)");
        $fdisplay(fd_result, "Memory  : one fake dual-port memory sink in testbench");
        $fdisplay(fd_result, "");

        for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read conv3 index %0d", i);
                $finish;
            end
            conv3_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin
                $display("ERROR: failed to read golden index %0d", i);
                $finish;
            end
            golden_mem[i] = temp_value[7:0];
        end

        $fclose(fd_conv3);
        $fclose(fd_golden);

        for (i = 0; i < WORD_COUNT; i = i + 1) begin
            fake_mem[i] = 16'd0;
        end

        rst = 1'b1;
        in_valid = 1'b0;
        in_c0 = 8'sd0;
        in_c1 = 8'sd0;
        in_c2 = 8'sd0;
        in_c3 = 8'sd0;

        repeat (2) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // Feed one LR pixel per cycle.
        // Drive inputs on negedge, then sample write transactions at posedge.
        for (pixel = 0; pixel < LR_PIXELS; pixel = pixel + 1) begin
            @(negedge clk);
            in_c0 = conv3_mem[pixel*COUT + 0];
            in_c1 = conv3_mem[pixel*COUT + 1];
            in_c2 = conv3_mem[pixel*COUT + 2];
            in_c3 = conv3_mem[pixel*COUT + 3];
            in_valid = 1'b1;

            if (pixel == LR_PIXELS - 1) begin
                wait(frame_done);
            end

            @(posedge clk);
            if (wr_en_a) begin
                fake_mem[wr_addr_a] = wr_data_a;
            end
            if (wr_en_b) begin
                fake_mem[wr_addr_b] = wr_data_b;
            end
        end

        @(negedge clk);
        in_valid = 1'b0;
        @(posedge clk);

        mismatch_count = 0;
        max_abs_diff = 0;

        // Interpret the memory dump and compare against the HR golden image.
        for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
            y = i / HR_W;
            x = i - y*HR_W;
            addr = y*LR_W + (x / 2);
            packed_word = fake_mem[addr];

            if ((x % 2) == 0) begin
                rtl_value = packed_word[7:0];
            end else begin
                rtl_value = packed_word[15:8];
            end

            expected_value = golden_mem[i];
            diff = rtl_value - expected_value;
            if (diff < 0)
                abs_diff = -diff;
            else
                abs_diff = diff;

            if (abs_diff > max_abs_diff)
                max_abs_diff = abs_diff;

            if (rtl_value !== expected_value) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH y=%0d x=%0d expected=%0d rtl=%0d packed=0x%04h address=%0d",
                         y, x, expected_value, rtl_value, packed_word, addr);
                $fdisplay(fd_result, "MISMATCH y=%0d x=%0d expected=%0d rtl=%0d packed=0x%04h address=%0d",
                          y, x, expected_value, rtl_value, packed_word, addr);
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
