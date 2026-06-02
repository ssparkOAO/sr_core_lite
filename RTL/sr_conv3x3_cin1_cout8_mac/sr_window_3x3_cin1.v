`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_window_3x3_cin1
// -----------------------------------------------------------------------------
// Purpose:
//   Streaming line-buffer 3x3 window generator for Conv1, Cin=1.
//
// Architecture:
//   The core walks over a padded raster of size (IMG_H+2) x (IMG_W+2).
//   Border positions inject PAD_VALUE internally.
//   Inner positions request one real input pixel with in_ready.
//
// Window timing:
//   When window_valid=1, win00~win22 correspond to output coordinate out_x/out_y.
// -----------------------------------------------------------------------------

module sr_window_3x3_cin1 #(
    parameter IMG_W      = 8,
    parameter IMG_H      = 8,
    parameter DATA_WIDTH = 8,
    parameter signed [DATA_WIDTH-1:0] PAD_VALUE = -128
) (
    input  wire clk,
    input  wire rst,
    input  wire in_valid,
    input  signed [DATA_WIDTH-1:0] in_pixel,

    output wire in_ready,
    output reg window_valid,
    output reg signed [DATA_WIDTH-1:0] win00,
    output reg signed [DATA_WIDTH-1:0] win01,
    output reg signed [DATA_WIDTH-1:0] win02,
    output reg signed [DATA_WIDTH-1:0] win10,
    output reg signed [DATA_WIDTH-1:0] win11,
    output reg signed [DATA_WIDTH-1:0] win12,
    output reg signed [DATA_WIDTH-1:0] win20,
    output reg signed [DATA_WIDTH-1:0] win21,
    output reg signed [DATA_WIDTH-1:0] win22,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);

localparam PAD_W = IMG_W + 2;
localparam PAD_H = IMG_H + 2;

reg [15:0] pad_x;
reg [15:0] pad_y;
reg frame_active;
reg frame_done;

wire is_left_pad;
wire is_right_pad;
wire is_top_pad;
wire is_bottom_pad;
wire is_padding;
wire need_input_pixel;
wire can_step;
wire emit_window;

wire signed [DATA_WIDTH-1:0] current_pixel;
wire signed [DATA_WIDTH-1:0] two_rows_up_pixel;
wire signed [DATA_WIDTH-1:0] previous_row_pixel;

reg signed [DATA_WIDTH-1:0] line0_mem [0:PAD_W-1];
reg signed [DATA_WIDTH-1:0] line1_mem [0:PAD_W-1];

reg signed [DATA_WIDTH-1:0] r0c0;
reg signed [DATA_WIDTH-1:0] r0c1;
reg signed [DATA_WIDTH-1:0] r0c2;
reg signed [DATA_WIDTH-1:0] r1c0;
reg signed [DATA_WIDTH-1:0] r1c1;
reg signed [DATA_WIDTH-1:0] r1c2;
reg signed [DATA_WIDTH-1:0] r2c0;
reg signed [DATA_WIDTH-1:0] r2c1;
reg signed [DATA_WIDTH-1:0] r2c2;

wire signed [DATA_WIDTH-1:0] next_r0c0;
wire signed [DATA_WIDTH-1:0] next_r0c1;
wire signed [DATA_WIDTH-1:0] next_r0c2;
wire signed [DATA_WIDTH-1:0] next_r1c0;
wire signed [DATA_WIDTH-1:0] next_r1c1;
wire signed [DATA_WIDTH-1:0] next_r1c2;
wire signed [DATA_WIDTH-1:0] next_r2c0;
wire signed [DATA_WIDTH-1:0] next_r2c1;
wire signed [DATA_WIDTH-1:0] next_r2c2;

integer reset_i;
/*  x:
	0 1 2 3 4 5 6 7 8 9
	^                 ^
	左pad (x=0)       右pad (x = PAD_W - 1)*/
	
assign is_left_pad     = (pad_x == 16'd0);
assign is_right_pad    = (pad_x == PAD_W - 1);
assign is_top_pad      = (pad_y == 16'd0);
assign is_bottom_pad   = (pad_y == PAD_H - 1);
assign is_padding      = is_left_pad || is_right_pad || is_top_pad || is_bottom_pad;
assign need_input_pixel = frame_active && !frame_done && !is_padding;
assign in_ready        = need_input_pixel;
assign can_step        = frame_active && !frame_done && (is_padding || in_valid);
assign emit_window     = can_step && (pad_y >= 16'd2) && (pad_x >= 16'd2);

assign current_pixel      = is_padding ? PAD_VALUE : in_pixel;
assign previous_row_pixel = line0_mem[pad_x];
assign two_rows_up_pixel  = line1_mem[pad_x];

assign next_r0c0 = r0c1;
assign next_r0c1 = r0c2;
assign next_r0c2 = two_rows_up_pixel;

assign next_r1c0 = r1c1;
assign next_r1c1 = r1c2;
assign next_r1c2 = previous_row_pixel;

assign next_r2c0 = r2c1;
assign next_r2c1 = r2c2;
assign next_r2c2 = current_pixel;

always @(posedge clk) begin
    if (rst) begin
        pad_x        <= 16'd0;
        pad_y        <= 16'd0;
        frame_active <= 1'b1;
        frame_done   <= 1'b0;
        window_valid <= 1'b0;
        out_x        <= 16'd0;
        out_y        <= 16'd0;

        r0c0 <= PAD_VALUE;
        r0c1 <= PAD_VALUE;
        r0c2 <= PAD_VALUE;
        r1c0 <= PAD_VALUE;
        r1c1 <= PAD_VALUE;
        r1c2 <= PAD_VALUE;
        r2c0 <= PAD_VALUE;
        r2c1 <= PAD_VALUE;
        r2c2 <= PAD_VALUE;

        win00 <= PAD_VALUE;
        win01 <= PAD_VALUE;
        win02 <= PAD_VALUE;
        win10 <= PAD_VALUE;
        win11 <= PAD_VALUE;
        win12 <= PAD_VALUE;
        win20 <= PAD_VALUE;
        win21 <= PAD_VALUE;
        win22 <= PAD_VALUE;

       // for (reset_i = 0; reset_i < PAD_W; reset_i = reset_i + 1) begin
            //line0_mem[reset_i] <= PAD_VALUE;
            //line1_mem[reset_i] <= PAD_VALUE;
       // end
    end else begin
        window_valid <= 1'b0;

        if (can_step) begin
            // Shift the visible 3x3 window left and append the new padded-stream column.
            r0c0 <= next_r0c0;
            r0c1 <= next_r0c1;
            r0c2 <= next_r0c2;
            r1c0 <= next_r1c0;
            r1c1 <= next_r1c1;
            r1c2 <= next_r1c2;
            r2c0 <= next_r2c0;
            r2c1 <= next_r2c1;
            r2c2 <= next_r2c2;

            // Move the row-delay memories forward at the current padded column.
            line0_mem[pad_x] <= current_pixel;
            line1_mem[pad_x] <= previous_row_pixel;

            if (emit_window) begin
                window_valid <= 1'b1;
                out_x <= pad_x - 16'd2;
                out_y <= pad_y - 16'd2;

                win00 <= next_r0c0;
                win01 <= next_r0c1;
                win02 <= next_r0c2;
                win10 <= next_r1c0;
                win11 <= next_r1c1;
                win12 <= next_r1c2;
                win20 <= next_r2c0;
                win21 <= next_r2c1;
                win22 <= next_r2c2;
            end

            // Advance padded raster coordinate.
            if ((pad_x == PAD_W - 1) && (pad_y == PAD_H - 1)) begin
                frame_done <= 1'b1;
            end else if (pad_x == PAD_W - 1) begin
                pad_x <= 16'd0;
                pad_y <= pad_y + 16'd1;
            end else begin
                pad_x <= pad_x + 16'd1;
            end
        end
    end
end

endmodule
