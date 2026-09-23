`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 12:40:44
// Design Name: 
// Module Name: MEM_MEMWB
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

module MEM_MEMWB (
    clk2,
    HALTED,
    TAKEN_BRANCH,

    EX_MEM_ALUOut,
    EX_MEM_B,
    EX_MEM_IR,
    EX_MEM_type,

    MEM_WB_ALUOut,
    MEM_WB_LMD,
    MEM_WB_IR,
    MEM_WB_type
);

    input clk2;
    input HALTED;
    input TAKEN_BRANCH;

    input [31:0] EX_MEM_ALUOut;
    input [31:0] EX_MEM_B;
    input [31:0] EX_MEM_IR;
    input [2:0]  EX_MEM_type;

    output reg [31:0] MEM_WB_ALUOut;
    output reg [31:0] MEM_WB_LMD;
    output reg [31:0] MEM_WB_IR;
    output reg [2:0]  MEM_WB_type;


    // ==================================================
    // DATA MEMORY
    // ==================================================

    reg [31:0] Mem [0:1023];


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
    // MEMORY STAGE
    // ==================================================

    always @(posedge clk2)
    begin
        if (HALTED == 0)
        begin

            // ------------------------------------------
            // Pass information to MEM/WB
            // ------------------------------------------

            MEM_WB_type <= #2 EX_MEM_type;
            MEM_WB_IR   <= #2 EX_MEM_IR;


            case (EX_MEM_type)

                // --------------------------------------
                // ALU instructions
                // --------------------------------------

                RR_ALU,
                RM_ALU:
                begin
                    MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;
                end


                // --------------------------------------
                // LOAD
                // --------------------------------------

                LOAD:
                begin
                    MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];
                end


                // --------------------------------------
                // STORE
                // --------------------------------------

                STORE:
                begin
                    // A store from the wrong path must not
                    // modify data memory after a branch.
                    if (TAKEN_BRANCH == 1'b0)
                        Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
                end


                // --------------------------------------
                // BRANCH
                // --------------------------------------

                BRANCH:
                begin
                    // No memory operation.
                end


                // --------------------------------------
                // HALT
                // --------------------------------------

                HALT:
                begin
                    // No memory operation.
                end


                // --------------------------------------
                // Default
                // --------------------------------------

                default:
                begin
                    // No memory operation.
                end

            endcase

        end
    end

endmodule