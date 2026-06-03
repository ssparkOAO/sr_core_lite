`timescale 1ns / 1ps

// Behavioral models with the same module names as Vivado BMG RAM IP.
// Use these only for Phase9.3 behavioral simulation.

module conv3_feature_ram (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [5:0] addra,
    input wire [31:0] dina,

    input wire clkb,
    input wire enb,
    input wire [5:0] addrb,
    output reg [31:0] doutb
);

    reg [31:0] mem [0:63];

    always @(posedge clka) begin
        if (ena && wea[0]) begin
            mem[addra] <= dina;
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            doutb <= mem[addrb];
        end
    end

endmodule


module output_image_ram (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [6:0] addra,
    input wire [15:0] dina,
    output reg [15:0] douta,

    input wire clkb,
    input wire enb,
    input wire [0:0] web,
    input wire [6:0] addrb,
    input wire [15:0] dinb,
    output reg [15:0] doutb
);

    reg [15:0] mem [0:127];

    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) begin
                mem[addra] <= dina;
            end
            douta <= mem[addra];
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            if (web[0]) begin
                mem[addrb] <= dinb;
            end
            doutb <= mem[addrb];
        end
    end

endmodule
