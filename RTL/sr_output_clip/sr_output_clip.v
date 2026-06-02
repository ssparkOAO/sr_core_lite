`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_output_clip
// -----------------------------------------------------------------------------
// Purpose:
//   Output range constraint block after PixelShuffle.
//   This is not a standalone CNN ReLU layer.
//
// Note:
//   Input is wider than int8 so overflow / underflow can be represented and
//   verified. Output is signed int8 range [-128, 127].
// -----------------------------------------------------------------------------

module sr_output_clip (
    input  signed [15:0] in_pixel,
    output reg signed [7:0] out_pixel
);

always @* begin
    if (in_pixel > 16'sd127) begin
        out_pixel = 8'sd127;
    end else if (in_pixel < -16'sd128) begin
        out_pixel = -8'sd128;
    end else begin
        out_pixel = in_pixel[7:0];
    end
end

endmodule
