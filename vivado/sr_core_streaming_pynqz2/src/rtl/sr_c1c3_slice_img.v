`timescale 1ns / 1ps

// One-cycle register slice between Conv1 and Conv3 for image-size testing.
// Conv3 is 1x1, so Conv1 output can stream directly into Conv3.

module sr_c1c3_slice_img #(
    parameter IMG_W = 128,
    parameter IMG_H = 128,
    parameter ADDR_WIDTH = 14
) (
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
    output reg [ADDR_WIDTH-1:0] out_addr,
    output reg signed [7:0] out_c0,
    output reg signed [7:0] out_c1,
    output reg signed [7:0] out_c2,
    output reg signed [7:0] out_c3,
    output reg signed [7:0] out_c4,
    output reg signed [7:0] out_c5,
    output reg signed [7:0] out_c6,
    output reg signed [7:0] out_c7
);

    wire [31:0] addr_calc;

    assign addr_calc = in_y * IMG_W + in_x;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
            out_addr <= {ADDR_WIDTH{1'b0}};
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
                out_last <= (in_x == IMG_W - 1) && (in_y == IMG_H - 1);
                out_addr <= addr_calc[ADDR_WIDTH-1:0];
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
