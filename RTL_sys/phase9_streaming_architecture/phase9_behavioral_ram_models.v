`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Phase9 behavioral RAM models
// -----------------------------------------------------------------------------
// These modules model the raw RAM ports used by the Phase9 reference-like
// architecture. They are intentionally simple simulation models. The matching
// Vivado BMG RAM IP will be created in the new streaming Vivado project later.
// -----------------------------------------------------------------------------

module conv3_feature_ram_model (
    input wire clk,

    // Port A: write Conv3 output feature word.
    input wire wr_en,
    input wire [5:0] wr_addr,
    input wire [31:0] wr_data,

    // Port B: read one LR pixel's 4-channel Conv3 output.
    input wire rd_en,
    input wire [5:0] rd_addr,
    output reg [31:0] rd_data
);

    reg [31:0] mem [0:63];

    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end

        if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule


module output_image_ram_model (
    input wire clk,

    // Port A: even HR row write.
    input wire wr_en_a,
    input wire [7:0] wr_addr_a,
    input wire [15:0] wr_data_a,

    // Port B: odd HR row write.
    input wire wr_en_b,
    input wire [7:0] wr_addr_b,
    input wire [15:0] wr_data_b
);

    reg [15:0] mem [0:127];

    always @(posedge clk) begin
        if (wr_en_a) begin
            mem[wr_addr_a] <= wr_data_a;
        end

        if (wr_en_b) begin
            mem[wr_addr_b] <= wr_data_b;
        end
    end

endmodule
