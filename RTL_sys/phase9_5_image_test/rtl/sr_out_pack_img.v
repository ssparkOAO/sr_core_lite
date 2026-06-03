`timescale 1ns / 1ps

// Convert PixelShuffle signed int8 pairs to uint8 and repack for image RAM.

module sr_out_pack_img #(
    parameter ADDR_WIDTH = 15
) (
    input wire ps_wr_en_a,
    input wire [ADDR_WIDTH-1:0] ps_wr_addr_a,
    input wire [15:0] ps_wr_data_a,

    input wire ps_wr_en_b,
    input wire [ADDR_WIDTH-1:0] ps_wr_addr_b,
    input wire [15:0] ps_wr_data_b,

    output wire output_ram_wr_en_a,
    output wire [ADDR_WIDTH-1:0] output_ram_wr_addr_a,
    output wire [15:0] output_ram_wr_data_a,

    output wire output_ram_wr_en_b,
    output wire [ADDR_WIDTH-1:0] output_ram_wr_addr_b,
    output wire [15:0] output_ram_wr_data_b
);

    wire [7:0] out_a_left;
    wire [7:0] out_a_right;
    wire [7:0] out_b_left;
    wire [7:0] out_b_right;

    assign output_ram_wr_en_a = ps_wr_en_a;
    assign output_ram_wr_addr_a = ps_wr_addr_a;
    assign output_ram_wr_data_a = {out_a_right, out_a_left};

    assign output_ram_wr_en_b = ps_wr_en_b;
    assign output_ram_wr_addr_b = ps_wr_addr_b;
    assign output_ram_wr_data_b = {out_b_right, out_b_left};

    sr_output_stage out_a_l (.in_pixel(ps_wr_data_a[7:0]),  .out_pixel_uint8(out_a_left));
    sr_output_stage out_a_r (.in_pixel(ps_wr_data_a[15:8]), .out_pixel_uint8(out_a_right));
    sr_output_stage out_b_l (.in_pixel(ps_wr_data_b[7:0]),  .out_pixel_uint8(out_b_left));
    sr_output_stage out_b_r (.in_pixel(ps_wr_data_b[15:8]), .out_pixel_uint8(out_b_right));

endmodule
