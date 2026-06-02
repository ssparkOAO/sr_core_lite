`timescale 1ns / 1ps

module tb_sr_output_clip;

    reg signed [15:0] in_pixel;
    wire signed [7:0] out_pixel;

    integer fd_result;
    integer mismatch_count;

    sr_output_clip dut (
        .in_pixel(in_pixel),
        .out_pixel(out_pixel)
    );

    task run_case;
        input signed [15:0] test_input;
        input signed [7:0] expected;
    begin
        in_pixel = test_input;
        #1;

        $display("input=%0d output=%0d expected=%0d", test_input, out_pixel, expected);
        $fdisplay(fd_result, "input=%0d output=%0d expected=%0d", test_input, out_pixel, expected);

        if (out_pixel !== expected) begin
            mismatch_count = mismatch_count + 1;
            $display("MISMATCH input=%0d output=%0d expected=%0d", test_input, out_pixel, expected);
            $fdisplay(fd_result, "MISMATCH input=%0d output=%0d expected=%0d", test_input, out_pixel, expected);
        end
    end
    endtask

    initial begin
        fd_result = $fopen("model_lite/sr_core/RTL/sr_output_clip/tb_sr_output_clip_result.txt", "w");
        if (fd_result == 0) begin
            $display("ERROR: failed to open result txt");
            $finish;
        end

        mismatch_count = 0;

        $fdisplay(fd_result, "sr_output_clip verification result");
        $fdisplay(fd_result, "==================================================");
        $fdisplay(fd_result, "Purpose : output range constraint, not standalone ReLU");
        $fdisplay(fd_result, "Clamp   : signed int8 range [-128, 127]");
        $fdisplay(fd_result, "");

        run_case(-16'sd128, -8'sd128);
        run_case(-16'sd64,  -8'sd64);
        run_case( 16'sd0,    8'sd0);
        run_case( 16'sd64,   8'sd64);
        run_case( 16'sd127,  8'sd127);

        run_case( 16'sd200,  8'sd127);
        run_case(-16'sd200, -8'sd128);

        $display("mismatch count = %0d", mismatch_count);
        $fdisplay(fd_result, "");
        $fdisplay(fd_result, "mismatch count = %0d", mismatch_count);

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
