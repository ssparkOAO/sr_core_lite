`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Phase8.3 Parameter ROM Bank Self-Check
// -----------------------------------------------------------------------------
// Goal:
//   Verify that the ROM-style parameter bank returns the same values as the
//   generated parameter .mem files.
//
// Scope:
//   - Conv1 weight ROM
//   - Conv3 weight ROM
//   - Conv1 M0/M1 ROM
//   - Conv3 M0/M1 ROM
// -----------------------------------------------------------------------------

module tb_sr_param_rom_bank;

    reg clk;

    reg conv1_weight_en;
    reg [6:0] conv1_weight_addr;
    wire signed [7:0] conv1_weight_data;

    reg conv3_weight_en;
    reg [4:0] conv3_weight_addr;
    wire signed [7:0] conv3_weight_data;

    reg conv1_m0_en;
    reg [2:0] conv1_m0_addr;
    wire signed [31:0] conv1_m0_data;

    reg conv1_m1_en;
    reg [2:0] conv1_m1_addr;
    wire signed [63:0] conv1_m1_data;

    reg conv3_m0_en;
    reg [1:0] conv3_m0_addr;
    wire signed [31:0] conv3_m0_data;

    reg conv3_m1_en;
    reg [1:0] conv3_m1_addr;
    wire signed [63:0] conv3_m1_data;

    reg signed [7:0] golden_conv1_weight [0:71];
    reg signed [7:0] golden_conv3_weight [0:31];
    reg signed [31:0] golden_conv1_m0 [0:7];
    reg signed [63:0] golden_conv1_m1 [0:7];
    reg signed [31:0] golden_conv3_m0 [0:3];
    reg signed [63:0] golden_conv3_m1 [0:3];

    integer i;
    integer fd;
    integer code;
    integer result_fd;

    integer conv1_weight_mismatch;
    integer conv3_weight_mismatch;
    integer conv1_m0_mismatch;
    integer conv1_m1_mismatch;
    integer conv3_m0_mismatch;
    integer conv3_m1_mismatch;
    integer total_mismatch;

    sr_param_rom_bank dut (
        .clk(clk),

        .conv1_weight_en(conv1_weight_en),
        .conv1_weight_addr(conv1_weight_addr),
        .conv1_weight_data(conv1_weight_data),

        .conv3_weight_en(conv3_weight_en),
        .conv3_weight_addr(conv3_weight_addr),
        .conv3_weight_data(conv3_weight_data),

        .conv1_m0_en(conv1_m0_en),
        .conv1_m0_addr(conv1_m0_addr),
        .conv1_m0_data(conv1_m0_data),

        .conv1_m1_en(conv1_m1_en),
        .conv1_m1_addr(conv1_m1_addr),
        .conv1_m1_data(conv1_m1_data),

        .conv3_m0_en(conv3_m0_en),
        .conv3_m0_addr(conv3_m0_addr),
        .conv3_m0_data(conv3_m0_data),

        .conv3_m1_en(conv3_m1_en),
        .conv3_m1_addr(conv3_m1_addr),
        .conv3_m1_data(conv3_m1_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        result_fd = $fopen("tb_sr_param_rom_bank_result.txt", "w");

        conv1_weight_en = 1'b0;
        conv1_weight_addr = 7'd0;
        conv3_weight_en = 1'b0;
        conv3_weight_addr = 5'd0;
        conv1_m0_en = 1'b0;
        conv1_m0_addr = 3'd0;
        conv1_m1_en = 1'b0;
        conv1_m1_addr = 3'd0;
        conv3_m0_en = 1'b0;
        conv3_m0_addr = 2'd0;
        conv3_m1_en = 1'b0;
        conv3_m1_addr = 2'd0;

        conv1_weight_mismatch = 0;
        conv3_weight_mismatch = 0;
        conv1_m0_mismatch = 0;
        conv1_m1_mismatch = 0;
        conv3_m0_mismatch = 0;
        conv3_m1_mismatch = 0;
        total_mismatch = 0;

        load_conv1_weight;
        load_conv3_weight;
        load_conv1_m0;
        load_conv1_m1;
        load_conv3_m0;
        load_conv3_m1;

        repeat (2) @(posedge clk);

        check_conv1_weight;
        check_conv3_weight;
        check_conv1_m0;
        check_conv1_m1;
        check_conv3_m0;
        check_conv3_m1;

        total_mismatch = conv1_weight_mismatch + conv3_weight_mismatch
                       + conv1_m0_mismatch + conv1_m1_mismatch
                       + conv3_m0_mismatch + conv3_m1_mismatch;

        print_both("");
        print_both("==============================================");
        print_both("Phase8.3 Parameter ROM Bank Self-Check Result");
        print_both("==============================================");
        print_count("conv1_weight mismatch count", conv1_weight_mismatch);
        print_count("conv3_weight mismatch count", conv3_weight_mismatch);
        print_count("conv1_m0 mismatch count", conv1_m0_mismatch);
        print_count("conv1_m1 mismatch count", conv1_m1_mismatch);
        print_count("conv3_m0 mismatch count", conv3_m0_mismatch);
        print_count("conv3_m1 mismatch count", conv3_m1_mismatch);
        print_count("total mismatch count", total_mismatch);

        if (total_mismatch == 0) begin
            print_both("PASS");
        end else begin
            print_both("FAIL");
        end

        $fclose(result_fd);
        $finish;
    end

    task print_both;
        input [1023:0] msg;
        begin
            $display("%0s", msg);
            $fdisplay(result_fd, "%0s", msg);
        end
    endtask

    task print_count;
        input [1023:0] name;
        input integer value;
        begin
            $display("%0s = %0d", name, value);
            $fdisplay(result_fd, "%0s = %0d", name, value);
        end
    endtask

    task load_conv1_weight;
        begin
            fd = $fopen("../../../generated/conv1_weight.mem", "r");
            if (fd == 0) begin
                print_both("ERROR: cannot open generated/conv1_weight.mem");
                $finish;
            end
            for (i = 0; i < 72; i = i + 1) begin
                code = $fscanf(fd, "%d\n", golden_conv1_weight[i]);
            end
            $fclose(fd);
        end
    endtask

    task load_conv3_weight;
        begin
            fd = $fopen("../../../generated/conv3_weight.mem", "r");
            if (fd == 0) begin
                print_both("ERROR: cannot open generated/conv3_weight.mem");
                $finish;
            end
            for (i = 0; i < 32; i = i + 1) begin
                code = $fscanf(fd, "%d\n", golden_conv3_weight[i]);
            end
            $fclose(fd);
        end
    endtask

    task load_conv1_m0;
        begin
            fd = $fopen("../../../generated/conv1_m0.mem", "r");
            if (fd == 0) begin
                print_both("ERROR: cannot open generated/conv1_m0.mem");
                $finish;
            end
            for (i = 0; i < 8; i = i + 1) begin
                code = $fscanf(fd, "%d\n", golden_conv1_m0[i]);
            end
            $fclose(fd);
        end
    endtask

    task load_conv1_m1;
        begin
            fd = $fopen("../../../generated/conv1_m1.mem", "r");
            if (fd == 0) begin
                print_both("ERROR: cannot open generated/conv1_m1.mem");
                $finish;
            end
            for (i = 0; i < 8; i = i + 1) begin
                code = $fscanf(fd, "%d\n", golden_conv1_m1[i]);
            end
            $fclose(fd);
        end
    endtask

    task load_conv3_m0;
        begin
            fd = $fopen("../../../generated/conv3_m0.mem", "r");
            if (fd == 0) begin
                print_both("ERROR: cannot open generated/conv3_m0.mem");
                $finish;
            end
            for (i = 0; i < 4; i = i + 1) begin
                code = $fscanf(fd, "%d\n", golden_conv3_m0[i]);
            end
            $fclose(fd);
        end
    endtask

    task load_conv3_m1;
        begin
            fd = $fopen("../../../generated/conv3_m1.mem", "r");
            if (fd == 0) begin
                print_both("ERROR: cannot open generated/conv3_m1.mem");
                $finish;
            end
            for (i = 0; i < 4; i = i + 1) begin
                code = $fscanf(fd, "%d\n", golden_conv3_m1[i]);
            end
            $fclose(fd);
        end
    endtask

    task check_conv1_weight;
        begin
            conv1_weight_en = 1'b1;
            for (i = 0; i < 72; i = i + 1) begin
                @(negedge clk);
                conv1_weight_addr = i[6:0];
                @(posedge clk);
                @(negedge clk);
                if (conv1_weight_data !== golden_conv1_weight[i]) begin
                    conv1_weight_mismatch = conv1_weight_mismatch + 1;
                    $display("conv1_weight mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv1_weight[i], conv1_weight_data);
                    $fdisplay(result_fd, "conv1_weight mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv1_weight[i], conv1_weight_data);
                end
            end
            conv1_weight_en = 1'b0;
        end
    endtask

    task check_conv3_weight;
        begin
            conv3_weight_en = 1'b1;
            for (i = 0; i < 32; i = i + 1) begin
                @(negedge clk);
                conv3_weight_addr = i[4:0];
                @(posedge clk);
                @(negedge clk);
                if (conv3_weight_data !== golden_conv3_weight[i]) begin
                    conv3_weight_mismatch = conv3_weight_mismatch + 1;
                    $display("conv3_weight mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv3_weight[i], conv3_weight_data);
                    $fdisplay(result_fd, "conv3_weight mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv3_weight[i], conv3_weight_data);
                end
            end
            conv3_weight_en = 1'b0;
        end
    endtask

    task check_conv1_m0;
        begin
            conv1_m0_en = 1'b1;
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge clk);
                conv1_m0_addr = i[2:0];
                @(posedge clk);
                @(negedge clk);
                if (conv1_m0_data !== golden_conv1_m0[i]) begin
                    conv1_m0_mismatch = conv1_m0_mismatch + 1;
                    $display("conv1_m0 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m0[i], conv1_m0_data);
                    $fdisplay(result_fd, "conv1_m0 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m0[i], conv1_m0_data);
                end
            end
            conv1_m0_en = 1'b0;
        end
    endtask

    task check_conv1_m1;
        begin
            conv1_m1_en = 1'b1;
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge clk);
                conv1_m1_addr = i[2:0];
                @(posedge clk);
                @(negedge clk);
                if (conv1_m1_data !== golden_conv1_m1[i]) begin
                    conv1_m1_mismatch = conv1_m1_mismatch + 1;
                    $display("conv1_m1 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m1[i], conv1_m1_data);
                    $fdisplay(result_fd, "conv1_m1 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv1_m1[i], conv1_m1_data);
                end
            end
            conv1_m1_en = 1'b0;
        end
    endtask

    task check_conv3_m0;
        begin
            conv3_m0_en = 1'b1;
            for (i = 0; i < 4; i = i + 1) begin
                @(negedge clk);
                conv3_m0_addr = i[1:0];
                @(posedge clk);
                @(negedge clk);
                if (conv3_m0_data !== golden_conv3_m0[i]) begin
                    conv3_m0_mismatch = conv3_m0_mismatch + 1;
                    $display("conv3_m0 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m0[i], conv3_m0_data);
                    $fdisplay(result_fd, "conv3_m0 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m0[i], conv3_m0_data);
                end
            end
            conv3_m0_en = 1'b0;
        end
    endtask

    task check_conv3_m1;
        begin
            conv3_m1_en = 1'b1;
            for (i = 0; i < 4; i = i + 1) begin
                @(negedge clk);
                conv3_m1_addr = i[1:0];
                @(posedge clk);
                @(negedge clk);
                if (conv3_m1_data !== golden_conv3_m1[i]) begin
                    conv3_m1_mismatch = conv3_m1_mismatch + 1;
                    $display("conv3_m1 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m1[i], conv3_m1_data);
                    $fdisplay(result_fd, "conv3_m1 mismatch addr=%0d expected=%0d rtl=%0d", i, golden_conv3_m1[i], conv3_m1_data);
                end
            end
            conv3_m1_en = 1'b0;
        end
    endtask

endmodule
