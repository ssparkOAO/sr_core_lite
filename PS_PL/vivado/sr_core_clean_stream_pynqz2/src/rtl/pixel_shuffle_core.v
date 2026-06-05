`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// pixel_shuffle_core
// -----------------------------------------------------------------------------
// Purpose:
//   PixelShuffle x2 write-transaction core.
//
// This module performs the PixelShuffle mapping, HR address generation, and
// write request generation. It does not instantiate BRAM/IP.
//
// Packing:
//   wr_data_a = {c1, c0} for even HR row: [c0][c1]
//   wr_data_b = {c3, c2} for odd  HR row: [c2][c3]
// -----------------------------------------------------------------------------

module pixel_shuffle_core #(
    parameter LR_WIDTH   = 8,
    parameter LR_HEIGHT  = 8,
    parameter ADDR_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  in_valid,

    input  signed [7:0]          in_c0,
    input  signed [7:0]          in_c1,
    input  signed [7:0]          in_c2,
    input  signed [7:0]          in_c3,

    // even HR row write port
    output wire                  wr_en_a,
    output wire [ADDR_WIDTH-1:0] wr_addr_a,
    output wire [15:0]           wr_data_a,

    // odd HR row write port
    output wire                  wr_en_b,
    output wire [ADDR_WIDTH-1:0] wr_addr_b,
    output wire [15:0]           wr_data_b,

    output wire                  frame_done
);

// One write address stores two horizontally adjacent HR pixels.
localparam HR_LINE_ADDRS = LR_WIDTH;

reg [15:0] x_cnt;
reg [15:0] y_cnt;

wire line_end;
wire frame_end;

wire [ADDR_WIDTH-1:0] even_row_base;
wire [ADDR_WIDTH-1:0] odd_row_base;

assign line_end  = (x_cnt == LR_WIDTH  - 1);
assign frame_end = (y_cnt == LR_HEIGHT - 1);

// ------------------------------------------------------------
// x/y counter for the incoming LR pixel coordinate.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (rst) begin
        x_cnt <= 16'd0;
        y_cnt <= 16'd0;
    end else if (in_valid) begin
        if (line_end) begin
            x_cnt <= 16'd0;
        end else begin
            x_cnt <= x_cnt + 16'd1;
        end

        if (line_end && frame_end) begin
            y_cnt <= 16'd0;
        end else if (line_end) begin
            y_cnt <= y_cnt + 16'd1;
        end
    end
end

// ------------------------------------------------------------
// Data packing.
// ------------------------------------------------------------
// PixelShuffle block:
//
//   c0 c1
//   c2 c3
//
// Each write word stores {right_pixel, left_pixel}.
assign wr_data_a = {in_c1, in_c0};
assign wr_data_b = {in_c3, in_c2};

// ------------------------------------------------------------
// HR write address generation.
// ------------------------------------------------------------
// even row address = (2*y  ) * HR_LINE_ADDRS + x
// odd  row address = (2*y+1) * HR_LINE_ADDRS + x
assign even_row_base = (y_cnt << 1) * HR_LINE_ADDRS;
assign odd_row_base  = even_row_base + HR_LINE_ADDRS;

assign wr_addr_a = even_row_base + x_cnt[ADDR_WIDTH-1:0];
assign wr_addr_b = odd_row_base  + x_cnt[ADDR_WIDTH-1:0];

assign wr_en_a = in_valid;
assign wr_en_b = in_valid;

assign frame_done = in_valid && line_end && frame_end;

endmodule
