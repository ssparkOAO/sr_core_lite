`timescale 1ns / 1ps

module tb_sr_nn_top_ip;

    parameter integer IN_COUNT    = 64;
    parameter integer CONV3_COUNT = 256;
    parameter integer FINAL_COUNT = 256;

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
    reg [5:0] dbg_c3_rd_addr;
    wire [31:0] dbg_c3_rd_data;
    reg dbg_out_rd_en;
    reg [6:0] dbg_out_rd_addr;
    wire [15:0] dbg_out_rd_data;

    reg signed [7:0] input_mem [0:IN_COUNT-1];
    reg signed [7:0] golden_conv3_mem [0:CONV3_COUNT-1];
    reg [7:0] golden_out_mem [0:FINAL_COUNT-1];

    integer fd_input;
    integer fd_conv3;
    integer fd_golden;
    integer fd_result;
    integer fd_stream_dump;
    integer fd_conv3_dump;
    integer fd_output_dump;

    integer read_ok;
    integer temp_value;
    integer i;
    integer input_index;
    integer mismatch_count;
    integer conv3_mismatch_count;
    integer output_mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;
    integer pixel_index;
    integer left_index;
    integer right_index;

    reg signed [7:0] conv3_byte0;
    reg signed [7:0] conv3_byte1;
    reg signed [7:0] conv3_byte2;
    reg signed [7:0] conv3_byte3;
    reg [7:0] out_left;
    reg [7:0] out_right;

    sr_nn_top dut (
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

    task update_diff;
        input integer rtl_value;
        input integer golden_value;
    begin
        diff = rtl_value - golden_value;
        if (diff < 0)
            abs_diff = -diff;
        else
            abs_diff = diff;

        if (abs_diff > max_abs_diff)
            max_abs_diff = abs_diff;
    end
    endtask

    initial begin
        fd_input  = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/generated/golden/input_int8_for_core.mem", "r");
        fd_conv3  = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/generated/golden/conv3_out_int8.mem", "r");
        fd_golden = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/generated/golden/output_uint8.mem", "r");
        fd_result = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase9_4_ip_verify/results/tb_sr_nn_top_ip_result.txt", "w");
        fd_stream_dump = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase9_4_ip_verify/results/conv1_to_conv3_stream_ip_dump.txt", "w");

        if (fd_input == 0) begin $display("ERROR: failed to open input_int8_for_core.mem"); $finish; end
        if (fd_conv3 == 0) begin $display("ERROR: failed to open conv3_out_int8.mem"); $finish; end
        if (fd_golden == 0) begin $display("ERROR: failed to open output_uint8.mem"); $finish; end
        if (fd_result == 0) begin $display("ERROR: failed to open result txt"); $finish; end
        if (fd_stream_dump == 0) begin $display("ERROR: failed to open stream dump"); $finish; end

        $fdisplay(fd_result, "Phase9.4 sr_nn_top BMG IP-backed verification result");
        $fdisplay(fd_result, "==============================================================");
        $fdisplay(fd_result, "Purpose : verify sr_nn_top with Vivado BMG ROM/RAM simulation wrappers");
        $fdisplay(fd_result, "Golden  : conv3_out_int8.mem and output_uint8.mem");
        $fdisplay(fd_result, "");
        $fdisplay(fd_stream_dump, "pixel_addr c0 c1 c2 c3 c4 c5 c6 c7");

        for (i = 0; i < IN_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read input index %0d", i); $finish; end
            input_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < CONV3_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 golden index %0d", i); $finish; end
            golden_conv3_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < FINAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read output golden index %0d", i); $finish; end
            golden_out_mem[i] = temp_value[7:0];
        end

        $fclose(fd_input);
        $fclose(fd_conv3);
        $fclose(fd_golden);

        rst = 1'b1;
        preload_start = 1'b0;
        core_start = 1'b0;
        in_valid = 1'b0;
        in_pixel = 8'sd0;
        dbg_c3_rd_en = 1'b0;
        dbg_c3_rd_addr = 6'd0;
        dbg_out_rd_en = 1'b0;
        dbg_out_rd_addr = 7'd0;
        input_index = 0;
        mismatch_count = 0;
        conv3_mismatch_count = 0;
        output_mismatch_count = 0;
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
            end else begin
                in_pixel = 8'sd0;
                in_valid = 1'b0;
            end

            if (dut.c1c3_slice_u0.out_valid) begin
                $fdisplay(fd_stream_dump, "%0d %0d %0d %0d %0d %0d %0d %0d %0d",
                    dut.c1c3_slice_u0.out_addr,
                    dut.c1c3_slice_u0.out_c0,
                    dut.c1c3_slice_u0.out_c1,
                    dut.c1c3_slice_u0.out_c2,
                    dut.c1c3_slice_u0.out_c3,
                    dut.c1c3_slice_u0.out_c4,
                    dut.c1c3_slice_u0.out_c5,
                    dut.c1c3_slice_u0.out_c6,
                    dut.c1c3_slice_u0.out_c7);
            end
        end

        @(negedge clk);
        in_valid = 1'b0;

        fd_conv3_dump  = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase9_4_ip_verify/results/conv3_feature_ram_ip_dump.txt", "w");
        fd_output_dump = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase9_4_ip_verify/results/output_image_ram_ip_dump.txt", "w");

        if (fd_conv3_dump == 0) begin $display("ERROR: failed to open conv3 dump"); $finish; end
        if (fd_output_dump == 0) begin $display("ERROR: failed to open output dump"); $finish; end

        for (i = 0; i < 64; i = i + 1) begin
            @(negedge clk);
            dbg_c3_rd_en = 1'b1;
            dbg_c3_rd_addr = i[5:0];
            @(posedge clk);
            @(negedge clk);
            dbg_c3_rd_en = 1'b0;

            conv3_byte0 = dbg_c3_rd_data[7:0];
            conv3_byte1 = dbg_c3_rd_data[15:8];
            conv3_byte2 = dbg_c3_rd_data[23:16];
            conv3_byte3 = dbg_c3_rd_data[31:24];

            $fdisplay(fd_conv3_dump, "%0d", conv3_byte0);
            $fdisplay(fd_conv3_dump, "%0d", conv3_byte1);
            $fdisplay(fd_conv3_dump, "%0d", conv3_byte2);
            $fdisplay(fd_conv3_dump, "%0d", conv3_byte3);

            pixel_index = i * 4;

            update_diff(conv3_byte0, golden_conv3_mem[pixel_index + 0]);
            if (conv3_byte0 !== golden_conv3_mem[pixel_index + 0]) begin
                conv3_mismatch_count = conv3_mismatch_count + 1;
                $fdisplay(fd_result, "CONV3 MISMATCH index=%0d rtl=%0d golden=%0d", pixel_index + 0, conv3_byte0, golden_conv3_mem[pixel_index + 0]);
            end

            update_diff(conv3_byte1, golden_conv3_mem[pixel_index + 1]);
            if (conv3_byte1 !== golden_conv3_mem[pixel_index + 1]) begin
                conv3_mismatch_count = conv3_mismatch_count + 1;
                $fdisplay(fd_result, "CONV3 MISMATCH index=%0d rtl=%0d golden=%0d", pixel_index + 1, conv3_byte1, golden_conv3_mem[pixel_index + 1]);
            end

            update_diff(conv3_byte2, golden_conv3_mem[pixel_index + 2]);
            if (conv3_byte2 !== golden_conv3_mem[pixel_index + 2]) begin
                conv3_mismatch_count = conv3_mismatch_count + 1;
                $fdisplay(fd_result, "CONV3 MISMATCH index=%0d rtl=%0d golden=%0d", pixel_index + 2, conv3_byte2, golden_conv3_mem[pixel_index + 2]);
            end

            update_diff(conv3_byte3, golden_conv3_mem[pixel_index + 3]);
            if (conv3_byte3 !== golden_conv3_mem[pixel_index + 3]) begin
                conv3_mismatch_count = conv3_mismatch_count + 1;
                $fdisplay(fd_result, "CONV3 MISMATCH index=%0d rtl=%0d golden=%0d", pixel_index + 3, conv3_byte3, golden_conv3_mem[pixel_index + 3]);
            end
        end

        for (i = 0; i < 128; i = i + 1) begin
            @(negedge clk);
            dbg_out_rd_en = 1'b1;
            dbg_out_rd_addr = i[6:0];
            @(posedge clk);
            @(negedge clk);
            dbg_out_rd_en = 1'b0;

            out_left = dbg_out_rd_data[7:0];
            out_right = dbg_out_rd_data[15:8];

            left_index = i * 2;
            right_index = i * 2 + 1;

            $fdisplay(fd_output_dump, "%0d", out_left);
            $fdisplay(fd_output_dump, "%0d", out_right);

            update_diff(out_left, golden_out_mem[left_index]);
            if (out_left !== golden_out_mem[left_index]) begin
                output_mismatch_count = output_mismatch_count + 1;
                $fdisplay(fd_result, "OUTPUT MISMATCH index=%0d rtl=%0d golden=%0d packed_word=%h ram_addr=%0d",
                    left_index, out_left, golden_out_mem[left_index], dbg_out_rd_data, i);
            end

            update_diff(out_right, golden_out_mem[right_index]);
            if (out_right !== golden_out_mem[right_index]) begin
                output_mismatch_count = output_mismatch_count + 1;
                $fdisplay(fd_result, "OUTPUT MISMATCH index=%0d rtl=%0d golden=%0d packed_word=%h ram_addr=%0d",
                    right_index, out_right, golden_out_mem[right_index], dbg_out_rd_data, i);
            end
        end

        mismatch_count = conv3_mismatch_count + output_mismatch_count;

        $display("conv3_feature_ram mismatch count = %0d", conv3_mismatch_count);
        $display("output_image_ram mismatch count = %0d", output_mismatch_count);
        $display("total mismatch count = %0d", mismatch_count);
        $display("max abs diff = %0d", max_abs_diff);

        $fdisplay(fd_result, "conv3_feature_ram mismatch count = %0d", conv3_mismatch_count);
        $fdisplay(fd_result, "output_image_ram mismatch count = %0d", output_mismatch_count);
        $fdisplay(fd_result, "total mismatch count = %0d", mismatch_count);
        $fdisplay(fd_result, "max abs diff = %0d", max_abs_diff);

        if (mismatch_count == 0) begin
            $display("PASS");
            $fdisplay(fd_result, "PASS");
        end else begin
            $display("FAIL");
            $fdisplay(fd_result, "FAIL");
        end

        $fclose(fd_stream_dump);
        $fclose(fd_conv3_dump);
        $fclose(fd_output_dump);
        $fclose(fd_result);
        $finish;
    end

endmodule
