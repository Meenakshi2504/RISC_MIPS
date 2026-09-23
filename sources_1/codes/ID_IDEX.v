`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 12:38:27
// Design Name: 
// Module Name: ID_IDEX
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


module ID_IDEX (
    input clk1,
    input clk2,
    input reset,
    input HALTED,

    input stall,

    input wb_write,
    input [4:0] wb_addr,
    input [31:0] wb_data,

    input [31:0] IF_ID_IR,
    input [31:0] IF_ID_NPC,

    output reg [31:0] ID_EX_A,
    output reg [31:0] ID_EX_B,
    output reg [31:0] ID_EX_NPC,
    output reg [31:0] ID_EX_IR,
    output reg [31:0] ID_EX_Imm,
    output reg [2:0] ID_EX_type
);

reg [31:0] Reg [0:31];

integer i;

// ==================================================
// OPCODES
// ==================================================

parameter ADD   = 6'b000000;
parameter SUB   = 6'b000001;
parameter AND   = 6'b000010;
parameter OR    = 6'b000011;
parameter SLT   = 6'b000100;
parameter MUL   = 6'b000101;

parameter LW    = 6'b001000;
parameter SW    = 6'b001001;

parameter ADDI  = 6'b001010;
parameter SUBI  = 6'b001011;
parameter SLTI  = 6'b001100;

parameter BNEQZ = 6'b001101;
parameter BEQZ  = 6'b001110;

parameter HLT   = 6'b111111;

// ==================================================
// INSTRUCTION TYPES
// ==================================================

parameter RR_ALU = 3'b000;
parameter RM_ALU = 3'b001;
parameter LOAD   = 3'b010;
parameter STORE  = 3'b011;
parameter BRANCH = 3'b100;
parameter HALT   = 3'b101;


// ==================================================
// WRITE BACK
// ==================================================

always @(posedge clk1)
begin
    if (reset)
    begin
        for (i = 0; i < 32; i = i + 1)
            Reg[i] <= 32'd0;
    end

    else
    begin
        Reg[0] <= 32'd0;

        if (wb_write && (wb_addr != 5'd0))
            Reg[wb_addr] <= wb_data;
    end
end


// ==================================================
// INSTRUCTION DECODE
// ==================================================

always @(posedge clk2)
begin
    if (reset)
    begin
        ID_EX_A <= 32'd0;
        ID_EX_B <= 32'd0;
        ID_EX_NPC <= 32'd0;
        ID_EX_IR <= 32'd0;
        ID_EX_Imm <= 32'd0;
        ID_EX_type <= RR_ALU;
    end

    else if (HALTED == 0)
    begin

        // ==========================================
        // HAZARD STALL → INSERT NOP/BUBBLE
        // ==========================================

        if (stall)
        begin
            ID_EX_A <= 32'd0;
            ID_EX_B <= 32'd0;
            ID_EX_NPC <= 32'd0;
            ID_EX_IR <= 32'h00000000;
            ID_EX_Imm <= 32'd0;
            ID_EX_type <= RR_ALU;
        end

        // ==========================================
        // NORMAL DECODE
        // ==========================================

        else
        begin

            // Read rs
            if (IF_ID_IR[25:21] == 5'b00000)
                ID_EX_A <= 32'd0;
            else
                ID_EX_A <= Reg[IF_ID_IR[25:21]];

            // Read rt
            if (IF_ID_IR[20:16] == 5'b00000)
                ID_EX_B <= 32'd0;
            else
                ID_EX_B <= Reg[IF_ID_IR[20:16]];

            ID_EX_NPC <= IF_ID_NPC;
            ID_EX_IR <= IF_ID_IR;

            // Sign extend immediate
            ID_EX_Imm <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

            // Decode instruction type
            case (IF_ID_IR[31:26])

                ADD, SUB, AND, OR, SLT, MUL:
                    ID_EX_type <= RR_ALU;

                ADDI, SUBI, SLTI:
                    ID_EX_type <= RM_ALU;

                LW:
                    ID_EX_type <= LOAD;

                SW:
                    ID_EX_type <= STORE;

                BNEQZ, BEQZ:
                    ID_EX_type <= BRANCH;

                HLT:
                    ID_EX_type <= HALT;

                default:
                    ID_EX_type <= HALT;

            endcase
        end
    end
end

endmodule
