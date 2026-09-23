`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 12:37:32
// Design Name: 
// Module Name: IF_IFID
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module IF_IFID (
    input clk1,
    input reset,
    input HALTED,

    input pc_write,
    input ifid_write,

    input branch_taken,
    input [31:0] branch_target,

    output reg [31:0] pc,
    output reg [31:0] IF_ID_IR,
    output reg [31:0] IF_ID_NPC
);

reg [31:0] IMEM [0:1023];

wire [31:0] instruction;
wire [31:0] npc;

assign instruction = IMEM[pc];
assign npc = pc + 32'd1;


always @(posedge clk1)
begin
    if (reset)
    begin
        pc <= 32'd0;
        IF_ID_IR <= 32'd0;
        IF_ID_NPC <= 32'd0;
    end

    else if (HALTED == 0)
    begin

        // Branch has priority over stall
        if (branch_taken)
        begin
            IF_ID_IR <= IMEM[branch_target];
            IF_ID_NPC <= branch_target + 32'd1;
            pc <= branch_target + 32'd1;
        end

        else
        begin
            // Update PC only when allowed
            if (pc_write)
                pc <= npc;

            // Update IF/ID only when allowed
            if (ifid_write)
            begin
                IF_ID_IR <= instruction;
                IF_ID_NPC <= npc;
            end
        end
    end
end

endmodule
