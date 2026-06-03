`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// sr_ctrl_clean_stream_img
// -----------------------------------------------------------------------------
// Controller for clean streaming image-level SR.
// Conv3 output streams directly into PixelShuffle; no Conv3 feature RAM exists.
// -----------------------------------------------------------------------------

module sr_ctrl_clean_stream_img (
    input wire clk,
    input wire rst,

    input wire preload_done,
    input wire core_start,

    input wire in_valid,
    output wire in_ready,

    input wire conv1_in_ready,
    output wire conv1_in_valid,

    input wire slice_valid,
    input wire ps_frame_done,

    output wire ps_rst,
    output wire ps_in_valid,

    output reg busy,
    output reg done
);

    localparam CORE_IDLE = 2'd0;
    localparam CORE_RUN  = 2'd1;
    localparam CORE_DONE = 2'd2;

    reg [1:0] core_state;
    wire gated_core_start;

    assign gated_core_start = core_start & preload_done;
    assign conv1_in_valid = (core_state == CORE_RUN) && in_valid;
    assign in_ready = (core_state == CORE_RUN) && conv1_in_ready;
    assign ps_rst = rst || (core_state != CORE_RUN);
    assign ps_in_valid = (core_state == CORE_RUN) && slice_valid;

    always @(posedge clk) begin
        if (rst) begin
            core_state <= CORE_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            case (core_state)
                CORE_IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    if (gated_core_start) begin
                        busy <= 1'b1;
                        core_state <= CORE_RUN;
                    end
                end

                CORE_RUN: begin
                    busy <= 1'b1;
                    done <= 1'b0;
                    if (ps_frame_done) begin
                        core_state <= CORE_DONE;
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
