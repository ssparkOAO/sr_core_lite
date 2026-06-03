`timescale 1ns / 1ps

// Controller for 128x128 image-level SR inference.
// It coordinates Conv1 input, Conv3 feature RAM, and PixelShuffle read phase.

module sr_ctrl_img #(
    parameter LR_PIXELS = 16384,
    parameter C3_ADDR_WIDTH = 14
) (
    input wire clk,
    input wire rst,

    input wire preload_done,
    input wire core_start,

    input wire in_valid,
    output wire in_ready,

    input wire conv1_in_ready,
    output wire conv1_in_valid,

    input wire slice_valid,
    input wire slice_last,
    input wire [C3_ADDR_WIDTH-1:0] slice_addr,

    input signed [7:0] conv3_q0,
    input signed [7:0] conv3_q1,
    input signed [7:0] conv3_q2,
    input signed [7:0] conv3_q3,

    output reg conv3_feature_wr_en,
    output reg [C3_ADDR_WIDTH-1:0] conv3_feature_wr_addr,
    output reg [31:0] conv3_feature_wr_data,

    output reg conv3_feature_rd_en,
    output reg [C3_ADDR_WIDTH-1:0] conv3_feature_rd_addr,

    output wire ps_rst,
    output reg ps_in_valid,

    output reg busy,
    output reg done
);

    localparam CORE_IDLE    = 3'd0;
    localparam CORE_CONV    = 3'd1;
    localparam CORE_PS_SEND = 3'd2;
    localparam CORE_PS_WAIT = 3'd3;
    localparam CORE_PS_USE  = 3'd4;
    localparam CORE_DONE    = 3'd5;

    reg [2:0] core_state;
    reg [C3_ADDR_WIDTH-1:0] ps_pixel_index;

    wire gated_core_start;
    wire ps_last_pixel;

    assign gated_core_start = core_start & preload_done;
    assign conv1_in_valid = (core_state == CORE_CONV) && in_valid;
    assign in_ready = (core_state == CORE_CONV) && conv1_in_ready;
    assign ps_last_pixel = (ps_pixel_index == LR_PIXELS - 1);

    assign ps_rst = rst || (core_state != CORE_PS_SEND &&
                            core_state != CORE_PS_WAIT &&
                            core_state != CORE_PS_USE);

    always @(posedge clk) begin
        if (rst) begin
            core_state <= CORE_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            ps_pixel_index <= {C3_ADDR_WIDTH{1'b0}};
            conv3_feature_wr_en <= 1'b0;
            conv3_feature_wr_addr <= {C3_ADDR_WIDTH{1'b0}};
            conv3_feature_wr_data <= 32'd0;
            conv3_feature_rd_en <= 1'b0;
            conv3_feature_rd_addr <= {C3_ADDR_WIDTH{1'b0}};
            ps_in_valid <= 1'b0;
        end else begin
            conv3_feature_wr_en <= 1'b0;
            conv3_feature_rd_en <= 1'b0;
            ps_in_valid <= 1'b0;

            case (core_state)
                CORE_IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    ps_pixel_index <= {C3_ADDR_WIDTH{1'b0}};
                    if (gated_core_start) begin
                        busy <= 1'b1;
                        core_state <= CORE_CONV;
                    end
                end

                CORE_CONV: begin
                    busy <= 1'b1;
                    if (slice_valid) begin
                        conv3_feature_wr_en <= 1'b1;
                        conv3_feature_wr_addr <= slice_addr;
                        conv3_feature_wr_data <= {conv3_q3, conv3_q2, conv3_q1, conv3_q0};
                    end
                    if (slice_valid && slice_last) begin
                        ps_pixel_index <= {C3_ADDR_WIDTH{1'b0}};
                        core_state <= CORE_PS_SEND;
                    end
                end

                CORE_PS_SEND: begin
                    conv3_feature_rd_en <= 1'b1;
                    conv3_feature_rd_addr <= ps_pixel_index;
                    core_state <= CORE_PS_WAIT;
                end

                CORE_PS_WAIT: begin
                    core_state <= CORE_PS_USE;
                end

                CORE_PS_USE: begin
                    ps_in_valid <= 1'b1;
                    if (ps_last_pixel) begin
                        core_state <= CORE_DONE;
                    end else begin
                        ps_pixel_index <= ps_pixel_index + 1'b1;
                        core_state <= CORE_PS_SEND;
                    end
                end

                CORE_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    core_state <= CORE_DONE;
                end

                default: begin
                    core_state <= CORE_IDLE;
                end
            endcase
        end
    end

endmodule
