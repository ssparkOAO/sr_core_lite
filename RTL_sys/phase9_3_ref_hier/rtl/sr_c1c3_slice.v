`timescale 1ns / 1ps

// One-cycle register slice between Conv1 and Conv3.
// Conv3 is 1x1, so feature_mem0 is not needed.

module sr_c1c3_slice (
    input wire clk,
    input wire rst,

    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input signed [7:0] in_c0,
    input signed [7:0] in_c1,
    input signed [7:0] in_c2,
    input signed [7:0] in_c3,
    input signed [7:0] in_c4,
    input signed [7:0] in_c5,
    input signed [7:0] in_c6,
    input signed [7:0] in_c7,

    output reg out_valid,
    output reg out_last,
    output reg [5:0] out_addr,
    output reg signed [7:0] out_c0,
    output reg signed [7:0] out_c1,
    output reg signed [7:0] out_c2,
    output reg signed [7:0] out_c3,
    output reg signed [7:0] out_c4,
    output reg signed [7:0] out_c5,
    output reg signed [7:0] out_c6,
    output reg signed [7:0] out_c7
);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
            out_addr <= 6'd0;
            out_c0 <= 8'sd0;
            out_c1 <= 8'sd0;
            out_c2 <= 8'sd0;
            out_c3 <= 8'sd0;
            out_c4 <= 8'sd0;
            out_c5 <= 8'sd0;
            out_c6 <= 8'sd0;
            out_c7 <= 8'sd0;
        end else begin
            if (in_valid) begin
                out_valid <= 1'b1;
                out_last <= (in_x == 16'd7) && (in_y == 16'd7);
                out_addr <= in_y[2:0] * 6'd8 + in_x[2:0];
                out_c0 <= in_c0;
                out_c1 <= in_c1;
                out_c2 <= in_c2;
                out_c3 <= in_c3;
                out_c4 <= in_c4;
                out_c5 <= in_c5;
                out_c6 <= in_c6;
                out_c7 <= in_c7;
            end else begin
                out_valid <= 1'b0;
                out_last <= 1'b0;
            end
        end
    end

endmodule
