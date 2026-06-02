`timescale 1ns / 1ps

module tb_sr_weight_memory_arch_proposal;

    parameter integer CONV1_WEIGHT_COUNT = 72;
    parameter integer CONV3_WEIGHT_COUNT = 32;
    parameter integer CONV1_COUT         = 8;
    parameter integer CONV3_COUT         = 4;

    reg clk;

    reg [6:0] conv1_weight_addr;
    wire signed [7:0] conv1_weight_data;

    reg [4:0] conv3_weight_addr;
    wire signed [7:0] conv3_weight_data;

    reg [2:0] conv1_ch_addr;
    wire signed [31:0] conv1_m0_data;
    wire signed [63:0] conv1_m1_data;

    reg [1:0] conv3_ch_addr;
    wire signed [31:0] conv3_m0_data;
    wire signed [63:0] conv3_m1_data;

    reg signed [7:0]  golden_conv1_weight [0:CONV1_WEIGHT_COUNT-1];
    reg signed [7:0]  golden_conv3_weight [0:CONV3_WEIGHT_COUNT-1];
    reg signed [31:0] golden_conv1_m0     [0:CONV1_COUT-1];
    reg signed [63:0] golden_conv1_m1     [0:CONV1_COUT-1];
    reg signed [31:0] golden_conv3_m0     [0:CONV3_COUT-1];
    reg signed [63:0] golden_conv3_m1     [0:CONV3_COUT-1];

    integer fd_conv1_weight;
    integer fd_conv3_weight;
    integer fd_conv1_m0;
    integer fd_conv1_m1;
    integer fd_conv3_m0;
    integer fd_conv3_m1;
    integer fd_result;

    integer read_ok;
    integer temp_value;
    integer i;

    integer conv1_weight_mismatch;
    integer conv3_weight_mismatch;
    integer conv1_m0_mismatch;
    integer conv1_m1_mismatch;
    integer conv3_m0_mismatch;
    integer conv3_m1_mismatch;
    integer total_mismatch;

    sr_conv1_weight_mem_arch dut_conv1_weight (
        .clk(clk),
        .addr(conv1_weight_addr),
        .data(conv1_weight_data)
    );

    sr_conv3_weight_mem_arch dut_conv3_weight (
        .clk(clk),
        .addr(conv3_weight_addr),
        .data(conv3_weight_data)
    );

    sr_quant_param_mem_arch dut_quant (
        .clk(clk),
        .conv1_ch_addr(conv1_ch_addr),
        .conv1_m0_data(conv1_m0_data),
        .conv1_m1_data(conv1_m1_data),
        .conv3_ch_addr(conv3_ch_addr),
        .conv3_m0_data(conv3_m0_data),
        .conv3_m1_data(conv3_m1_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        fd_conv1_weight = $fopen("model_lite/sr_core/generated/conv1_weight.mem", "r");
        fd_conv3_weight = $fopen("model_lite/sr_core/generated/conv3_weight.mem", "r");
        fd_conv1_m0     = $fopen("model_lite/sr_core/generated/conv1_m0.mem", "r");
        fd_conv1_m1     = $fopen("model_lite/sr_core/generated/conv1_m1.mem", "r");
        fd_conv3_m0     = $fopen("model_lite/sr_core/generated/conv3_m0.mem", "r");
        fd_conv3_m1     = $fopen("model_lite/sr_core/generated/conv3_m1.mem", "r");
        fd_result       = $fopen("model_lite/sr_core/RTL_sys/phase8_weight_memory/tb_sr_weight_memory_arch_proposal_result.txt", "w");

        if (fd_conv1_weight == 0) begin $display("ERROR: failed to open conv1_weight.mem"); $finish; end
        if (fd_conv3_weight == 0) begin $display("ERROR: failed to open conv3_weight.mem"); $finish; end
        if (fd_conv1_m0 == 0) begin $display("ERROR: failed to open conv1_m0.mem"); $finish; end
        if (fd_conv1_m1 == 0) begin $display("ERROR: failed to open conv1_m1.mem"); $finish; end
        if (fd_conv3_m0 == 0) begin $display("ERROR: failed to open conv3_m0.mem"); $finish; end
        if (fd_conv3_m1 == 0) begin $display("ERROR: failed to open conv3_m1.mem"); $finish; end
        if (fd_result == 0) begin $display("ERROR: failed to open result txt"); $finish; end

        $fdisplay(fd_result, "Phase8.1 Weight Memory Self-Check");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Purpose : verify memory-style weight/M0/M1 mapping");
        $fdisplay(fd_result, "Scope   : mapping readback only, not connected to sr_core_top");
        $fdisplay(fd_result, "");

        for (i = 0; i < CONV1_WEIGHT_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_conv1_weight, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read conv1 weight %0d", i); $finish; end
            golden_conv1_weight[i] = temp_value[7:0];
            dut_conv1_weight.conv1_weight_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < CONV3_WEIGHT_COUNT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3_weight, "%d\n", temp_value);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 weight %0d", i); $finish; end
            golden_conv3_weight[i] = temp_value[7:0];
            dut_conv3_weight.conv3_weight_mem[i] = temp_value[7:0];
        end

        for (i = 0; i < CONV1_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv1_m0, "%d\n", golden_conv1_m0[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv1 m0 %0d", i); $finish; end
            dut_quant.conv1_m0_mem[i] = golden_conv1_m0[i];
        end

        for (i = 0; i < CONV1_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv1_m1, "%d\n", golden_conv1_m1[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv1 m1 %0d", i); $finish; end
            dut_quant.conv1_m1_mem[i] = golden_conv1_m1[i];
        end

        for (i = 0; i < CONV3_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3_m0, "%d\n", golden_conv3_m0[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 m0 %0d", i); $finish; end
            dut_quant.conv3_m0_mem[i] = golden_conv3_m0[i];
        end

        for (i = 0; i < CONV3_COUT; i = i + 1) begin
            read_ok = $fscanf(fd_conv3_m1, "%d\n", golden_conv3_m1[i]);
            if (read_ok != 1) begin $display("ERROR: failed to read conv3 m1 %0d", i); $finish; end
            dut_quant.conv3_m1_mem[i] = golden_conv3_m1[i];
        end

        $fclose(fd_conv1_weight);
        $fclose(fd_conv3_weight);
        $fclose(fd_conv1_m0);
        $fclose(fd_conv1_m1);
        $fclose(fd_conv3_m0);
        $fclose(fd_conv3_m1);

        conv1_weight_mismatch = 0;
        conv3_weight_mismatch = 0;
        conv1_m0_mismatch = 0;
        conv1_m1_mismatch = 0;
        conv3_m0_mismatch = 0;
        conv3_m1_mismatch = 0;

        conv1_weight_addr = 7'd0;
        conv3_weight_addr = 5'd0;
        conv1_ch_addr = 3'd0;
        conv3_ch_addr = 2'd0;
        repeat (2) @(posedge clk);

        for (i = 0; i < CONV1_WEIGHT_COUNT; i = i + 1) begin
            conv1_weight_addr = i[6:0];
            @(posedge clk);
            #1;
            if (conv1_weight_data !== golden_conv1_weight[i]) begin
                conv1_weight_mismatch = conv1_weight_mismatch + 1;
                $display("MISMATCH conv1_weight addr=%0d expected=%0d rtl=%0d", i, golden_conv1_weight[i], conv1_weight_data);
                $fdisplay(fd_result, "MISMATCH conv1_weight addr=%0d expected=%0d rtl=%0d", i, golden_conv1_weight[i], conv1_weight_data);
            end
        end

        for (i = 0; i < CONV3_WEIGHT_COUNT; i = i + 1) begin
            conv3_weight_addr = i[4:0];
            @(posedge clk);
            #1;
            if (conv3_weight_data !== golden_conv3_weight[i]) begin
                conv3_weight_mismatch = conv3_weight_mismatch + 1;
                $display("MISMATCH conv3_weight addr=%0d expected=%0d rtl=%0d", i, golden_conv3_weight[i], conv3_weight_data);
                $fdisplay(fd_result, "MISMATCH conv3_weight addr=%0d expected=%0d rtl=%0d", i, golden_conv3_weight[i], conv3_weight_data);
            end
        end

        for (i = 0; i < CONV1_COUT; i = i + 1) begin
            conv1_ch_addr = i[2:0];
            @(posedge clk);
            #1;
            if (conv1_m0_data !== golden_conv1_m0[i]) begin
                conv1_m0_mismatch = conv1_m0_mismatch + 1;
                $display("MISMATCH conv1_m0 addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m0[i], conv1_m0_data);
                $fdisplay(fd_result, "MISMATCH conv1_m0 addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m0[i], conv1_m0_data);
            end
            if (conv1_m1_data !== golden_conv1_m1[i]) begin
                conv1_m1_mismatch = conv1_m1_mismatch + 1;
                $display("MISMATCH conv1_m1 addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m1[i], conv1_m1_data);
                $fdisplay(fd_result, "MISMATCH conv1_m1 addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m1[i], conv1_m1_data);
            end
        end

        for (i = 0; i < CONV3_COUT; i = i + 1) begin
            conv3_ch_addr = i[1:0];
            @(posedge clk);
            #1;
            if (conv3_m0_data !== golden_conv3_m0[i]) begin
                conv3_m0_mismatch = conv3_m0_mismatch + 1;
                $display("MISMATCH conv3_m0 addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m0[i], conv3_m0_data);
                $fdisplay(fd_result, "MISMATCH conv3_m0 addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m0[i], conv3_m0_data);
            end
            if (conv3_m1_data !== golden_conv3_m1[i]) begin
                conv3_m1_mismatch = conv3_m1_mismatch + 1;
                $display("MISMATCH conv3_m1 addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m1[i], conv3_m1_data);
                $fdisplay(fd_result, "MISMATCH conv3_m1 addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m1[i], conv3_m1_data);
            end
        end

        total_mismatch = conv1_weight_mismatch + conv3_weight_mismatch
                       + conv1_m0_mismatch + conv1_m1_mismatch
                       + conv3_m0_mismatch + conv3_m1_mismatch;

        $display("conv1_weight mismatch count = %0d", conv1_weight_mismatch);
        $display("conv3_weight mismatch count = %0d", conv3_weight_mismatch);
        $display("conv1_m0 mismatch count     = %0d", conv1_m0_mismatch);
        $display("conv1_m1 mismatch count     = %0d", conv1_m1_mismatch);
        $display("conv3_m0 mismatch count     = %0d", conv3_m0_mismatch);
        $display("conv3_m1 mismatch count     = %0d", conv3_m1_mismatch);
        $display("total mismatch count        = %0d", total_mismatch);

        $fdisplay(fd_result, "conv1_weight mismatch count = %0d", conv1_weight_mismatch);
        $fdisplay(fd_result, "conv3_weight mismatch count = %0d", conv3_weight_mismatch);
        $fdisplay(fd_result, "conv1_m0 mismatch count     = %0d", conv1_m0_mismatch);
        $fdisplay(fd_result, "conv1_m1 mismatch count     = %0d", conv1_m1_mismatch);
        $fdisplay(fd_result, "conv3_m0 mismatch count     = %0d", conv3_m0_mismatch);
        $fdisplay(fd_result, "conv3_m1 mismatch count     = %0d", conv3_m1_mismatch);
        $fdisplay(fd_result, "total mismatch count        = %0d", total_mismatch);

        if (total_mismatch == 0) begin
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
