`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_output_stage
// -----------------------------------------------------------------------------
// Purpose:
//   Final output formatting stage:
//     signed int8 -> output clip -> uint8 image domain
//
// This is not a CNN layer. It is the final output format conversion stage.
// -----------------------------------------------------------------------------

module sr_output_stage (
    input  signed [7:0] in_pixel,
    output reg [7:0] out_pixel_uint8
);

reg signed [7:0] clipped_pixel;
reg signed [8:0] recovered_pixel;

always @* begin
    // The input is already signed int8, but keep explicit clamp logic here
    // so this stage clearly owns the final output range constraint.
    if (in_pixel > 8'sd127) begin
        clipped_pixel = 8'sd127;
    end else if (in_pixel < -8'sd128) begin
        clipped_pixel = -8'sd128;
    end else begin
        clipped_pixel = in_pixel;
    end

    // zero_point = -128, so uint8 image value = signed_int8_value + 128.
    recovered_pixel = clipped_pixel + 9'sd128;
    out_pixel_uint8 = recovered_pixel[7:0];
end

endmodule
