`timescale 1ns/1ps

module sr_requantize (
    input  signed [31:0] acc,
    input  signed [31:0] m0,
    input  signed [63:0] m1,
    output reg signed [7:0] q_out
);

    /* ------------------------------------------------------------
       Requantization formula used by the Python/TFLite golden:

           q_out_tmp = acc * m0 + m1
           rounded   = q_out_tmp >>> 32
           if q_out_tmp[31] == 1, rounded = rounded + 1

       acc and m0 are both signed 32-bit values.
       A 32-bit x 32-bit multiply produces a signed 64-bit result.
       ------------------------------------------------------------ */
    wire signed [63:0] mult;
    wire signed [63:0] q_out_tmp;
    wire signed [63:0] shifted;
    wire signed [63:0] rounded;

    assign mult      = acc * m0;
	/* NOTE:
   q_out_tmp uses signed 64-bit accumulation
   to match current TFLite/Python golden behavior.

   In theory:
       signed 64-bit + signed 64-bit
   may require 65-bit to avoid overflow.

   However:
       current SR model dynamic range
   does not approach this limit,
   and keeping 64-bit ensures exact
   runtime alignment with golden outputs.
*/
    assign q_out_tmp = mult + m1;

    /* Arithmetic shift keeps the sign bit for negative numbers.
       This is important because q_out_tmp is signed fixed-point data. 因為m0 m1 組成含左移32位，所以要除回去 */
    assign shifted = q_out_tmp >>> 32;

    /* q_out_tmp[31] is the first dropped fractional bit.
       If it is 1, add one after shifting to match the golden rounding.  */
    assign rounded = shifted + (q_out_tmp[31] ? 64'sd1 : 64'sd0); //捨棄的最高位

    always @* begin
        /* Clamp final result into signed int8 range: [-128, 127]. */
        if (rounded > 64'sd127)
            q_out = 8'sd127;
        else if (rounded < -64'sd128)
            q_out = -8'sd128;
        else
            q_out = rounded[7:0];
    end

endmodule
