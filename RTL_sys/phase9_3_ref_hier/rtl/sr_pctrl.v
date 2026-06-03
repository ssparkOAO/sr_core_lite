`timescale 1ns / 1ps

// Parameter preload controller.
// ROM IPs are instantiated in sr_nn_top, not hidden here.

module sr_pctrl (
    input wire clk,
    input wire rst,
    input wire preload_start,

    output reg preload_busy,
    output reg preload_done,

    output reg conv1_weight_en,
    output reg [6:0] conv1_weight_addr,
    input signed [7:0] conv1_weight_data,

    output reg conv3_weight_en,
    output reg [4:0] conv3_weight_addr,
    input signed [7:0] conv3_weight_data,

    output reg conv1_m0_en,
    output reg [2:0] conv1_m0_addr,
    input signed [31:0] conv1_m0_data,

    output reg conv1_m1_en,
    output reg [2:0] conv1_m1_addr,
    input signed [63:0] conv1_m1_data,

    output reg conv3_m0_en,
    output reg [1:0] conv3_m0_addr,
    input signed [31:0] conv3_m0_data,

    output reg conv3_m1_en,
    output reg [1:0] conv3_m1_addr,
    input signed [63:0] conv3_m1_data,

    output reg [575:0] conv1_weight_flat,
    output reg [255:0] conv3_weight_flat,
    output reg [255:0] conv1_m0_flat,
    output reg [511:0] conv1_m1_flat,
    output reg [127:0] conv3_m0_flat,
    output reg [255:0] conv3_m1_flat
);

    localparam PRE_IDLE        = 5'd0;
    localparam PRE_C1W_SEND    = 5'd1;
    localparam PRE_C1W_WAIT    = 5'd2;
    localparam PRE_C1W_CAPTURE = 5'd3;
    localparam PRE_C3W_SEND    = 5'd4;
    localparam PRE_C3W_WAIT    = 5'd5;
    localparam PRE_C3W_CAPTURE = 5'd6;
    localparam PRE_C1M_SEND    = 5'd7;
    localparam PRE_C1M_WAIT    = 5'd8;
    localparam PRE_C1M_CAPTURE = 5'd9;
    localparam PRE_C3M_SEND    = 5'd10;
    localparam PRE_C3M_WAIT    = 5'd11;
    localparam PRE_C3M_CAPTURE = 5'd12;
    localparam PRE_DONE        = 5'd13;

    reg [4:0] preload_state;
    reg [6:0] preload_index;

    always @(posedge clk) begin
        if (rst) begin
            preload_state <= PRE_IDLE;
            preload_index <= 7'd0;
            preload_busy <= 1'b0;
            preload_done <= 1'b0;
            conv1_weight_en <= 1'b0;
            conv1_weight_addr <= 7'd0;
            conv3_weight_en <= 1'b0;
            conv3_weight_addr <= 5'd0;
            conv1_m0_en <= 1'b0;
            conv1_m0_addr <= 3'd0;
            conv1_m1_en <= 1'b0;
            conv1_m1_addr <= 3'd0;
            conv3_m0_en <= 1'b0;
            conv3_m0_addr <= 2'd0;
            conv3_m1_en <= 1'b0;
            conv3_m1_addr <= 2'd0;
            conv1_weight_flat <= 576'd0;
            conv3_weight_flat <= 256'd0;
            conv1_m0_flat <= 256'd0;
            conv1_m1_flat <= 512'd0;
            conv3_m0_flat <= 128'd0;
            conv3_m1_flat <= 256'd0;
        end else begin
            case (preload_state)
                PRE_IDLE: begin
                    preload_busy <= 1'b0;
                    conv1_weight_en <= 1'b0;
                    conv3_weight_en <= 1'b0;
                    conv1_m0_en <= 1'b0;
                    conv1_m1_en <= 1'b0;
                    conv3_m0_en <= 1'b0;
                    conv3_m1_en <= 1'b0;
                    if (preload_start) begin
                        preload_busy <= 1'b1;
                        preload_done <= 1'b0;
                        preload_index <= 7'd0;
                        preload_state <= PRE_C1W_SEND;
                    end
                end

                PRE_C1W_SEND: begin
                    conv1_weight_en <= 1'b1;
                    conv1_weight_addr <= preload_index;
                    preload_state <= PRE_C1W_WAIT;
                end

                PRE_C1W_WAIT: begin
                    conv1_weight_en <= 1'b0;
                    preload_state <= PRE_C1W_CAPTURE;
                end

                PRE_C1W_CAPTURE: begin
                    conv1_weight_flat[preload_index * 8 +: 8] <= conv1_weight_data;
                    if (preload_index == 7'd71) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_C3W_SEND;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C1W_SEND;
                    end
                end

                PRE_C3W_SEND: begin
                    conv3_weight_en <= 1'b1;
                    conv3_weight_addr <= preload_index[4:0];
                    preload_state <= PRE_C3W_WAIT;
                end

                PRE_C3W_WAIT: begin
                    conv3_weight_en <= 1'b0;
                    preload_state <= PRE_C3W_CAPTURE;
                end

                PRE_C3W_CAPTURE: begin
                    conv3_weight_flat[preload_index * 8 +: 8] <= conv3_weight_data;
                    if (preload_index == 7'd31) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_C1M_SEND;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C3W_SEND;
                    end
                end

                PRE_C1M_SEND: begin
                    conv1_m0_en <= 1'b1;
                    conv1_m1_en <= 1'b1;
                    conv1_m0_addr <= preload_index[2:0];
                    conv1_m1_addr <= preload_index[2:0];
                    preload_state <= PRE_C1M_WAIT;
                end

                PRE_C1M_WAIT: begin
                    conv1_m0_en <= 1'b0;
                    conv1_m1_en <= 1'b0;
                    preload_state <= PRE_C1M_CAPTURE;
                end

                PRE_C1M_CAPTURE: begin
                    conv1_m0_flat[preload_index * 32 +: 32] <= conv1_m0_data;
                    conv1_m1_flat[preload_index * 64 +: 64] <= conv1_m1_data;
                    if (preload_index == 7'd7) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_C3M_SEND;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C1M_SEND;
                    end
                end

                PRE_C3M_SEND: begin
                    conv3_m0_en <= 1'b1;
                    conv3_m1_en <= 1'b1;
                    conv3_m0_addr <= preload_index[1:0];
                    conv3_m1_addr <= preload_index[1:0];
                    preload_state <= PRE_C3M_WAIT;
                end

                PRE_C3M_WAIT: begin
                    conv3_m0_en <= 1'b0;
                    conv3_m1_en <= 1'b0;
                    preload_state <= PRE_C3M_CAPTURE;
                end

                PRE_C3M_CAPTURE: begin
                    conv3_m0_flat[preload_index * 32 +: 32] <= conv3_m0_data;
                    conv3_m1_flat[preload_index * 64 +: 64] <= conv3_m1_data;
                    if (preload_index == 7'd3) begin
                        preload_index <= 7'd0;
                        preload_state <= PRE_DONE;
                    end else begin
                        preload_index <= preload_index + 7'd1;
                        preload_state <= PRE_C3M_SEND;
                    end
                end

                PRE_DONE: begin
                    preload_busy <= 1'b0;
                    preload_done <= 1'b1;
                    conv1_weight_en <= 1'b0;
                    conv3_weight_en <= 1'b0;
                    conv1_m0_en <= 1'b0;
                    conv1_m1_en <= 1'b0;
                    conv3_m0_en <= 1'b0;
                    conv3_m1_en <= 1'b0;
                    if (preload_start) begin
                        preload_busy <= 1'b1;
                        preload_done <= 1'b0;
                        preload_index <= 7'd0;
                        preload_state <= PRE_C1W_SEND;
                    end
                end

                default: begin
                    preload_state <= PRE_IDLE;
                end
            endcase
        end
    end

endmodule
