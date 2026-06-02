`timescale 1ns/1ps

module tb_sr_requantize;

    parameter integer NUM_SAMPLES = 256;
    parameter integer COUT        = 4;

    reg signed [31:0] acc;
    reg signed [31:0] m0;
    reg signed [63:0] m1;
    wire signed [7:0] q_out;

    reg signed [31:0] acc_mem    [0:NUM_SAMPLES-1];
    reg signed [31:0] m0_mem     [0:COUT-1];
    reg signed [63:0] m1_mem     [0:COUT-1];
    reg signed [7:0]  golden_mem [0:NUM_SAMPLES-1];

    integer i;
    integer ch;
    integer mismatch_count;
    integer max_abs_diff;
    integer diff;
    integer abs_diff;
    integer fd_acc;
    integer fd_m0;
    integer fd_m1;
    integer fd_golden;
    integer read_ok;
    integer value_i8;

    sr_requantize dut (
        .acc(acc),
        .m0(m0),
        .m1(m1),
        .q_out(q_out)
    );

    initial begin
        /* Open decimal .mem files generated from the runtime-verified golden.
           These files are signed decimal text, so this testbench uses fscanf,
           not readmemh. */
        fd_acc    = $fopen("model_lite/sr_core/generated/golden/conv3_acc_int32.mem", "r");
        fd_m0     = $fopen("model_lite/sr_core/generated/conv3_m0.mem", "r");
        fd_m1     = $fopen("model_lite/sr_core/generated/conv3_m1.mem", "r");
        fd_golden = $fopen("model_lite/sr_core/generated/golden/conv3_out_int8.mem", "r");

        if (fd_acc == 0) begin
            $display("ERROR: failed to open conv3_acc_int32.mem");
            $finish;
        end

        if (fd_m0 == 0) begin
            $display("ERROR: failed to open conv3_m0.mem");
            $finish;
        end

        if (fd_m1 == 0) begin
            $display("ERROR: failed to open conv3_m1.mem");
            $finish;
        end

        if (fd_golden == 0) begin
            $display("ERROR: failed to open conv3_out_int8.mem");
            $finish;
        end

        /* conv3_acc_int32.mem has one accumulator per output value. */
        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            read_ok = $fscanf(fd_acc, "%d\n", acc_mem[i]);
            if (read_ok != 1) begin
                $display("ERROR: failed to read acc index %0d", i);
                $finish;
            end
        end

        /* Conv3 has Cout = 4, so m0 and m1 each contain 4 values. */
        for (i = 0; i < COUT; i = i + 1) begin
            read_ok = $fscanf(fd_m0, "%d\n", m0_mem[i]);
            if (read_ok != 1) begin
                $display("ERROR: failed to read m0 channel %0d", i);
                $finish;
            end
        end

        for (i = 0; i < COUT; i = i + 1) begin
            read_ok = $fscanf(fd_m1, "%d\n", m1_mem[i]);
            if (read_ok != 1) begin
                $display("ERROR: failed to read m1 channel %0d", i);
                $finish;
            end
        end

        /* Golden output is int8, also stored as signed decimal text. */
        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            read_ok = $fscanf(fd_golden, "%d\n", value_i8);
            if (read_ok != 1) begin
                $display("ERROR: failed to read golden index %0d", i);
                $finish;
            end

            golden_mem[i] = value_i8[7:0];
        end

        $fclose(fd_acc);
        $fclose(fd_m0);
        $fclose(fd_m1);
        $fclose(fd_golden);

        mismatch_count = 0;
        max_abs_diff = 0;

        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            /* Output order is spatial-major with channel 0,1,2,3 repeating. */
            ch = i % COUT;

            acc = acc_mem[i];
            m0  = m0_mem[ch];
            m1  = m1_mem[ch];
            #1;

            /* Track max abs diff even though the PASS condition is exact match. */
            diff = $signed(q_out) - $signed(golden_mem[i]);
            if (diff < 0)
                abs_diff = -diff;
            else
                abs_diff = diff;

            if (abs_diff > max_abs_diff)
                max_abs_diff = abs_diff;

            if (q_out !== golden_mem[i]) begin
                mismatch_count = mismatch_count + 1;
                $display("MISMATCH index=%0d acc=%0d m0=%0d m1=%0d golden=%0d rtl_out=%0d",
                         i, acc, m0, m1, golden_mem[i], q_out);
            end
        end

        $display("mismatch count = %0d", mismatch_count);
        $display("max abs diff   = %0d", max_abs_diff);

        if (mismatch_count == 0)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

endmodule
