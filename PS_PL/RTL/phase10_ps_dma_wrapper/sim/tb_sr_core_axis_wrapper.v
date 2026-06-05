`timescale 1ns / 1ps

module tb_sr_core_axis_wrapper;

    localparam integer IN_COUNT = 16384;
    localparam integer OUT_PIXEL_COUNT = 65536;
    localparam integer TIMEOUT_CYCLES = 2000000;

    reg clk;
    reg rst;

    reg [7:0] s_axis_tdata;
    reg s_axis_tvalid;
    wire s_axis_tready;
    reg s_axis_tlast;

    wire [7:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire m_axis_tlast;

    wire preload_done;
    wire core_done;
    wire frame_done;
    wire error;
    wire [15:0] input_count;
    wire [16:0] output_count;

    reg signed [7:0] input_mem [0:IN_COUNT-1];
    reg [7:0] golden_mem [0:OUT_PIXEL_COUNT-1];

    integer fd_input;
    integer fd_golden;
    integer fd_result;
    integer fd_output;
    integer read_ok;
    integer temp_value;
    integer i;
    integer sent_count;
    integer recv_count;
    integer input_tlast_index;
    integer output_tlast_index;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;
    integer timeout_count;
    integer input_handshake_pass;
    integer core_done_pass;
    integer output_handshake_pass;
    integer value_compare_pass;

    sr_core_axis_wrapper dut (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .preload_done(preload_done),
        .core_done(core_done),
        .frame_done(frame_done),
        .error(error),
        .input_count(input_count),
        .output_count(output_count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        fd_input = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/butterflyx2_Y.txt", "r");
        fd_golden = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/result/sr_output_uint8_clean_stream.txt", "r");
        fd_result = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/RTL_sys/phase10_ps_dma_wrapper/results/tb_sr_core_axis_wrapper_result.txt", "w");
        fd_output = $fopen("C:/M11413047/codex/final_proj/model_lite/sr_core/pic/test_pic/result/sr_output_uint8_axis_wrapper.txt", "w");

        if (fd_input == 0) begin
            $display("ERROR: failed to open butterflyx2_Y.txt");
            $finish;
        end
        if (fd_golden == 0) begin
            $display("ERROR: failed to open sr_output_uint8_clean_stream.txt");
            $finish;
        end
        if (fd_result == 0) begin
            $display("ERROR: failed to open Phase10 result txt");
            $finish;
        end
        if (fd_output == 0) begin
            $display("ERROR: failed to open axis wrapper output txt");
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

        $fdisplay(fd_result, "Phase10.1 AXI-Stream wrapper TB");
        $fdisplay(fd_result, "Input  : butterflyx2_Y.txt, TB quantize uint8 - 128");
        $fdisplay(fd_result, "Golden : sr_output_uint8_clean_stream.txt");
        $fdisplay(fd_result, "Output : sr_output_uint8_axis_wrapper.txt");
        $fdisplay(fd_result, "");

        rst = 1'b1;
        s_axis_tdata = 8'd0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast = 1'b0;
        m_axis_tready = 1'b1;
        sent_count = 0;
        recv_count = 0;
        input_tlast_index = -1;
        output_tlast_index = -1;
        mismatch_count = 0;
        max_abs_diff = 0;
        timeout_count = 0;
        input_handshake_pass = 0;
        core_done_pass = 0;
        output_handshake_pass = 0;
        value_compare_pass = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        wait (rst == 1'b0);
        for (i = 0; i < IN_COUNT; i = i + 1) begin
            @(negedge clk);
            s_axis_tdata = input_mem[i];
            s_axis_tvalid = 1'b1;
            s_axis_tlast = (i == IN_COUNT - 1);
            while (!s_axis_tready) begin
                @(negedge clk);
            end
            @(posedge clk);
            sent_count = sent_count + 1;
            if (s_axis_tlast) begin
                input_tlast_index = sent_count - 1;
            end
        end

        @(negedge clk);
        s_axis_tdata = 8'd0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast = 1'b0;
    end

    always @(posedge clk) begin
        if (!rst && m_axis_tvalid && m_axis_tready) begin
            $fdisplay(fd_output, "%0d", m_axis_tdata);

            diff = m_axis_tdata - golden_mem[recv_count];
            if (diff < 0) abs_diff = -diff; else abs_diff = diff;
            if (abs_diff > max_abs_diff) max_abs_diff = abs_diff;

            if (m_axis_tdata !== golden_mem[recv_count]) begin
                mismatch_count = mismatch_count + 1;
                if (mismatch_count <= 20) begin
                    $display("Mismatch index=%0d rtl=%0d golden=%0d",
                             recv_count, m_axis_tdata, golden_mem[recv_count]);
                    $fdisplay(fd_result, "Mismatch index=%0d rtl=%0d golden=%0d",
                              recv_count, m_axis_tdata, golden_mem[recv_count]);
                end
            end

            if (m_axis_tlast) begin
                output_tlast_index = recv_count;
            end
            recv_count = recv_count + 1;
        end
    end

    initial begin
        wait (rst == 1'b0);
        while (!frame_done && (timeout_count < TIMEOUT_CYCLES)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (timeout_count >= TIMEOUT_CYCLES) begin
            $display("FAIL: timeout");
            $fdisplay(fd_result, "FAIL: timeout");
        end

        repeat (10) @(posedge clk);

        $display("preload_done = %0d", preload_done);
        $display("core_done = %0d", core_done);
        $display("wrapper error = %0d", error);
        $display("input count = %0d", input_count);
        $display("output count = %0d", output_count);
        $display("sent count = %0d", sent_count);
        $display("recv count = %0d", recv_count);
        $display("input tlast index = %0d", input_tlast_index);
        $display("output tlast index = %0d", output_tlast_index);
        $display("mismatch count = %0d", mismatch_count);
        $display("max abs diff = %0d", max_abs_diff);

        input_handshake_pass =
            (input_count == IN_COUNT) &&
            (sent_count == IN_COUNT) &&
            (input_tlast_index == IN_COUNT - 1) &&
            (error == 1'b0);

        core_done_pass = (core_done == 1'b1);

        output_handshake_pass =
            (output_count == OUT_PIXEL_COUNT) &&
            (recv_count == OUT_PIXEL_COUNT) &&
            (output_tlast_index == OUT_PIXEL_COUNT - 1);

        value_compare_pass =
            output_handshake_pass &&
            (mismatch_count == 0) &&
            (max_abs_diff == 0);

        $fdisplay(fd_result, "preload_done = %0d", preload_done);
        $fdisplay(fd_result, "core_done = %0d", core_done);
        $fdisplay(fd_result, "wrapper error = %0d", error);
        $fdisplay(fd_result, "input count = %0d", input_count);
        $fdisplay(fd_result, "output count = %0d", output_count);
        $fdisplay(fd_result, "sent count = %0d", sent_count);
        $fdisplay(fd_result, "recv count = %0d", recv_count);
        $fdisplay(fd_result, "input tlast index = %0d", input_tlast_index);
        $fdisplay(fd_result, "output tlast index = %0d", output_tlast_index);
        $fdisplay(fd_result, "mismatch count = %0d", mismatch_count);
        $fdisplay(fd_result, "max abs diff = %0d", max_abs_diff);
        $fdisplay(fd_result, "");
        $fdisplay(fd_result, "input handshake pass = %0d", input_handshake_pass);
        $fdisplay(fd_result, "core done pass = %0d", core_done_pass);
        $fdisplay(fd_result, "output handshake pass = %0d", output_handshake_pass);
        $fdisplay(fd_result, "value compare pass = %0d", value_compare_pass);

        if (!core_done_pass) begin
            $fdisplay(fd_result, "Diagnosis: control/timing failure before output compare; core_done did not assert.");
        end else if (!output_handshake_pass) begin
            $fdisplay(fd_result, "Diagnosis: output stream failure; wrapper did not emit a complete frame.");
        end else if (!value_compare_pass) begin
            $fdisplay(fd_result, "Diagnosis: value mismatch after complete output frame.");
        end

        if (input_handshake_pass &&
            core_done_pass &&
            output_handshake_pass &&
            value_compare_pass) begin
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
