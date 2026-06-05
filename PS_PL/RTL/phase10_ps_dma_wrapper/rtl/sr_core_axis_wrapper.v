`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_core_axis_wrapper
// -----------------------------------------------------------------------------
// Phase10.1 AXI4-Stream shell for the Phase9.6 clean-stream SR core.
//
// This wrapper does not add input RAM, AXI DMA, or AXI-Lite control.  It starts
// the verified clean-stream core after parameter preload and directly maps each
// accepted S_AXIS byte to the core signed int8 input pixel.
// -----------------------------------------------------------------------------

module sr_core_axis_wrapper #(
    parameter integer IN_COUNT       = 16384,
    parameter integer OUT_WORD_COUNT = 32768,
    parameter integer OUT_BYTE_COUNT = 65536
) (
    input  wire        clk,
    input  wire        rst,

    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,

    output reg  [7:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast,

    output wire        preload_done,
    output wire        core_done,
    output reg         frame_done,
    output reg         error,
    output reg  [15:0] input_count,
    output reg  [16:0] output_count
);

    localparam [15:0] IN_COUNT_W       = IN_COUNT;
    localparam [14:0] OUT_WORD_COUNT_W = OUT_WORD_COUNT;
    localparam [16:0] OUT_BYTE_COUNT_W = OUT_BYTE_COUNT;

    localparam ST_PRELOAD         = 4'd0;
    localparam ST_START_CORE      = 4'd1;
    localparam ST_WAIT_CORE_READY = 4'd2;
    localparam ST_INPUT           = 4'd3;
    localparam ST_WAIT_DONE       = 4'd4;
    localparam ST_READ_ISSUE      = 4'd5;
    localparam ST_READ_WAIT       = 4'd6;
    localparam ST_READ_CAPTURE    = 4'd7;
    localparam ST_SEND_LOW        = 4'd8;
    localparam ST_SEND_HIGH       = 4'd9;
    localparam ST_DONE            = 4'd10;

    reg [3:0] state;
    reg core_ready_seen;

    reg preload_start;
    reg core_start;
    wire core_in_valid;
    wire signed [7:0] core_in_pixel;
    wire core_in_ready;
    wire preload_busy;
    wire core_busy;
    reg out_rd_en;
    reg [14:0] out_rd_addr;
    wire [15:0] out_rd_data;

    reg [14:0] read_word_index;
    reg [15:0] read_word_data;

    assign s_axis_tready = (state == ST_INPUT) &&
                           core_ready_seen &&
                           core_in_ready &&
                           (input_count < IN_COUNT_W);
    assign core_in_valid = s_axis_tvalid && s_axis_tready;
    assign core_in_pixel = s_axis_tdata;

    sr_top_clean_stream_img core_u0 (
        .clk(clk),
        .rst(rst),
        .preload_start(preload_start),
        .core_start(core_start),
        .in_valid(core_in_valid),
        .in_pixel(core_in_pixel),
        .in_ready(core_in_ready),
        .preload_busy(preload_busy),
        .preload_done(preload_done),
        .busy(core_busy),
        .done(core_done),
        .out_rd_en(out_rd_en),
        .out_rd_addr(out_rd_addr),
        .out_rd_data(out_rd_data)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_PRELOAD;
            preload_start <= 1'b0;
            core_start <= 1'b0;
            out_rd_en <= 1'b0;
            out_rd_addr <= 15'd0;
            read_word_index <= 15'd0;
            read_word_data <= 16'd0;
            m_axis_tdata <= 8'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            frame_done <= 1'b0;
            error <= 1'b0;
            input_count <= 16'd0;
            output_count <= 17'd0;
            core_ready_seen <= 1'b0;
        end else begin
            preload_start <= 1'b0;
            core_start <= 1'b0;
            out_rd_en <= 1'b0;
            frame_done <= 1'b0;

            case (state)
                ST_PRELOAD: begin
                    input_count <= 16'd0;
                    output_count <= 17'd0;
                    read_word_index <= 15'd0;
                    core_ready_seen <= 1'b0;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    if (!preload_done && !preload_busy) begin
                        preload_start <= 1'b1;
                    end
                    if (preload_done) begin
                        state <= ST_START_CORE;
                    end
                end

                ST_START_CORE: begin
                    core_start <= 1'b1;
                    state <= ST_WAIT_CORE_READY;
                end

                ST_WAIT_CORE_READY: begin
                    if (core_in_ready) begin
                        core_ready_seen <= 1'b1;
                        state <= ST_INPUT;
                    end
                end

                ST_INPUT: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        if ((input_count == IN_COUNT_W - 16'd1) && !s_axis_tlast) begin
                            error <= 1'b1;
                        end
                        if ((input_count != IN_COUNT_W - 16'd1) && s_axis_tlast) begin
                            error <= 1'b1;
                        end

                        input_count <= input_count + 16'd1;
                        if (input_count == IN_COUNT_W - 16'd1) begin
                            state <= ST_WAIT_DONE;
                        end
                    end
                end

                ST_WAIT_DONE: begin
                    if (core_done) begin
                        read_word_index <= 15'd0;
                        state <= ST_READ_ISSUE;
                    end
                end

                ST_READ_ISSUE: begin
                    out_rd_en <= 1'b1;
                    out_rd_addr <= read_word_index;
                    state <= ST_READ_WAIT;
                end

                ST_READ_WAIT: begin
                    state <= ST_READ_CAPTURE;
                end

                ST_READ_CAPTURE: begin
                    read_word_data <= out_rd_data;
                    state <= ST_SEND_LOW;
                end

                ST_SEND_LOW: begin
                    if (!m_axis_tvalid) begin
                        m_axis_tdata <= read_word_data[7:0];
                        m_axis_tlast <= (output_count == OUT_BYTE_COUNT_W - 17'd1);
                        m_axis_tvalid <= 1'b1;
                    end else if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        output_count <= output_count + 17'd1;
                        state <= ST_SEND_HIGH;
                    end
                end

                ST_SEND_HIGH: begin
                    if (!m_axis_tvalid) begin
                        m_axis_tdata <= read_word_data[15:8];
                        m_axis_tlast <= (output_count == OUT_BYTE_COUNT_W - 17'd1);
                        m_axis_tvalid <= 1'b1;
                    end else if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        output_count <= output_count + 17'd1;
                        if (read_word_index == OUT_WORD_COUNT_W - 15'd1) begin
                            state <= ST_DONE;
                        end else begin
                            read_word_index <= read_word_index + 15'd1;
                            state <= ST_READ_ISSUE;
                        end
                    end
                end

                ST_DONE: begin
                    frame_done <= 1'b1;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                end

                default: begin
                    state <= ST_PRELOAD;
                end
            endcase
        end
    end

endmodule
