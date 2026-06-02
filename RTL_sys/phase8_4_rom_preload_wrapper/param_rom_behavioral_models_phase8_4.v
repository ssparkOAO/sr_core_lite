`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Phase8.4b local behavioral ROM models.
// -----------------------------------------------------------------------------
// These models match the Vivado BMG ROM module names and are used only for
// Phase8.4b simulation. The readmemh paths are relative to:
//   model_lite/sr_core/RTL_sys/phase8_4_rom_preload_wrapper
// -----------------------------------------------------------------------------

module conv1_weight_rom (
    input wire clka,
    input wire ena,
    input wire [6:0] addra,
    output reg [7:0] douta
);
    reg [7:0] mem [0:71];

    initial begin
        $readmemh("../../generated_vivado_hex/conv1_weight.memh", mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];
        end
    end
endmodule


module conv3_weight_rom (
    input wire clka,
    input wire ena,
    input wire [4:0] addra,
    output reg [7:0] douta
);
    reg [7:0] mem [0:31];

    initial begin
        $readmemh("../../generated_vivado_hex/conv3_weight.memh", mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];
        end
    end
endmodule


module conv1_m0_rom (
    input wire clka,
    input wire ena,
    input wire [2:0] addra,
    output reg [31:0] douta
);
    reg [31:0] mem [0:7];

    initial begin
        $readmemh("../../generated_vivado_hex/conv1_m0.memh", mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];
        end
    end
endmodule


module conv1_m1_rom (
    input wire clka,
    input wire ena,
    input wire [2:0] addra,
    output reg [63:0] douta
);
    reg [63:0] mem [0:7];

    initial begin
        $readmemh("../../generated_vivado_hex/conv1_m1.memh", mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];
        end
    end
endmodule


module conv3_m0_rom (
    input wire clka,
    input wire ena,
    input wire [1:0] addra,
    output reg [31:0] douta
);
    reg [31:0] mem [0:3];

    initial begin
        $readmemh("../../generated_vivado_hex/conv3_m0.memh", mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];
        end
    end
endmodule


module conv3_m1_rom (
    input wire clka,
    input wire ena,
    input wire [1:0] addra,
    output reg [63:0] douta
);
    reg [63:0] mem [0:3];

    initial begin
        $readmemh("../../generated_vivado_hex/conv3_m1.memh", mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];
        end
    end
endmodule
