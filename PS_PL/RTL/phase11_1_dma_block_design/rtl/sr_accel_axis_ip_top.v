`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_accel_axis_ip_top
// -----------------------------------------------------------------------------
// Vivado IP packaging shell for the verified Phase10 AXI-Stream SR wrapper.
//
// External interface:
//   - active-low reset for Vivado/BD convention
//   - AXI4-Stream slave input from AXI DMA MM2S
//   - AXI4-Stream master output to AXI DMA S2MM
//
// Internal interface:
//   - sr_core_axis_wrapper keeps its verified active-high rst port
//   - TKEEP is kept at this IP boundary for AXI DMA compatibility
// -----------------------------------------------------------------------------

module sr_accel_axis_ip_top #(
    parameter integer IN_COUNT       = 16384,
    parameter integer OUT_WORD_COUNT = 32768,
    parameter integer OUT_BYTE_COUNT = 65536
) (
    input  wire       aclk,
    input  wire       aresetn,

    input  wire [7:0] s_axis_tdata,
    input  wire [0:0] s_axis_tkeep,
    input  wire       s_axis_tvalid,
    output wire       s_axis_tready,
    input  wire       s_axis_tlast,

    output wire [7:0] m_axis_tdata,
    output wire [0:0] m_axis_tkeep,
    output wire       m_axis_tvalid,
    input  wire       m_axis_tready,
    output wire       m_axis_tlast
);

    wire rst;

    wire preload_done_unused;
    wire core_done_unused;
    wire frame_done_unused;
    wire error_unused;
    wire [15:0] input_count_unused;
    wire [16:0] output_count_unused;

    assign rst = ~aresetn;

    // Width is 8-bit, so every valid output beat contains one valid byte.
    assign m_axis_tkeep = 1'b1;

    sr_core_axis_wrapper #(
        .IN_COUNT(IN_COUNT),
        .OUT_WORD_COUNT(OUT_WORD_COUNT),
        .OUT_BYTE_COUNT(OUT_BYTE_COUNT)
    ) sr_core_axis_wrapper_u0 (
        .clk(aclk),
        .rst(rst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),

        .preload_done(preload_done_unused),
        .core_done(core_done_unused),
        .frame_done(frame_done_unused),
        .error(error_unused),
        .input_count(input_count_unused),
        .output_count(output_count_unused)
    );

    // S_AXIS TKEEP is intentionally not consumed by the verified wrapper.
    // AXI DMA is expected to drive it high for every 8-bit pixel beat.
    wire s_axis_tkeep_unused;
    assign s_axis_tkeep_unused = s_axis_tkeep[0];

endmodule
