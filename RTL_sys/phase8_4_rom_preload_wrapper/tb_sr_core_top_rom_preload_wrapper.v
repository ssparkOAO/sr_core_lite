`timescale 1ns / 1ps

module tb_sr_core_top_rom_preload_wrapper;

    parameter integer IN_COUNT        = 64;
    parameter integer FINAL_COUNT     = 256;

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

    reg signed [7:0] input_mem [0:IN_COUNT-1];
    reg [7:0] golden_out_mem [0:FINAL_COUNT-1];

    integer fd_input;
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

    sr_core_top_rom_preload_wrapper dut (
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
    begin
        diff = rtl_value - golden_value;
        if (diff < 0)
            abs_diff = -diff;
        else
            abs_diff = diff;

        if (abs_diff > max_abs_diff)
            max_abs_diff = abs_diff;

        if (rtl_value !== golden_value) begin
            mismatch_count = mismatch_count + 1;
            $display("MISMATCH pixel=%0d rtl=%0d golden=%0d", pixel_index, rtl_value, golden_value);
            $fdisplay(fd_result, "MISMATCH pixel=%0d rtl=%0d golden=%0d", pixel_index, rtl_value, golden_value);
        end
    end
    endtask

    initial begin
        fd_input        = $fopen("../../generated/golden/input_int8_for_core.mem", "r");
        fd_golden       = $fopen("../../generated/golden/output_uint8.mem", "r");
        fd_result       = $fopen("tb_sr_core_top_rom_preload_wrapper_result.txt", "w");

        if (fd_input == 0) begin $display("ERROR: failed to open input_int8_for_core.mem"); $finish; end
        if (fd_golden == 0) begin $display("ERROR: failed to open output_uint8.mem"); $finish; end
        if (fd_result == 0) begin $display("ERROR: failed to open result txt"); $finish; end

        $fdisplay(fd_result, "Phase8.4b sr_core_top_rom_preload_wrapper verification result");
        $fdisplay(fd_result, "==============================================================");
        $fdisplay(fd_result, "Purpose : Vivado ROM IP -> preload FSM -> parameter register bank -> verified sr_core_top");
        $fdisplay(fd_result, "Sim ROM : existing Vivado BMG ROM IP simulation wrappers");
        $fdisplay(fd_result, "Golden  : output_uint8.mem");
        $fdisplay(fd_result, "");

        for (i = 0; i < IN_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_input, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read input index %0d", i); $finish; end
            input_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < FINAL_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read output golden index %0d", i); $finish; end
            golden_out_mem[i] = temp_value[7:0];
        end

        $fclose(fd_input);
        $fclose(fd_golden);

        rst = 1'b1;
        preload_start = 1'b0;
        core_start = 1'b0;
        in_valid = 1'b0;
        in_pixel = 8'sd0;
        input_index = 0;
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
            end else begin
                in_pixel = 8'sd0;
                in_valid = 1'b0;
            end
        end

        @(negedge clk);
        in_valid = 1'b0;

        fd_dump0 = $fopen("feature_mem0_dump.txt", "w");
        fd_dump1 = $fopen("feature_mem1_dump.txt", "w");
        fd_dump2 = $fopen("feature_mem2_dump.txt", "w");

        if (fd_dump0 == 0) begin $display("ERROR: failed to open feature_mem0_dump.txt"); $finish; end
        if (fd_dump1 == 0) begin $display("ERROR: failed to open feature_mem1_dump.txt"); $finish; end
        if (fd_dump2 == 0) begin $display("ERROR: failed to open feature_mem2_dump.txt"); $finish; end

        for (i = 0; i < 512; i = i + 1) begin
            $fdisplay(fd_dump0, "%0d", dut.core_u0.feature_mem0[i]);
        end
        for (i = 0; i < 256; i = i + 1) begin
            $fdisplay(fd_dump1, "%0d", dut.core_u0.feature_mem1[i]);
        end
        for (i = 0; i < 256; i = i + 1) begin
            $fdisplay(fd_dump2, "%0d", dut.core_u0.feature_mem2[i]);
        end

        $fclose(fd_dump0);
        $fclose(fd_dump1);
        $fclose(fd_dump2);

        for (i = 0; i < FINAL_COUNT; i = i + 1) begin
            compare_pixel(i, dut.core_u0.output_mem[i], golden_out_mem[i]);
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
