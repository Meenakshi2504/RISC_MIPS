`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 12:39:17
// Design Name: 
// Module Name: EX_EXMEM
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

module EX_EXMEM (
    clk1,
    HALTED,

    ID_EX_A,
    ID_EX_B,
    ID_EX_Imm,
    ID_EX_NPC,
    ID_EX_IR,
    ID_EX_type,

    EX_MEM_ALUOut,
    EX_MEM_B,
    EX_MEM_IR,
    EX_MEM_type,
    EX_MEM_cond
);

    input clk1;
    input HALTED;

    input [31:0] ID_EX_A;
    input [31:0] ID_EX_B;
    input [31:0] ID_EX_Imm;
    input [31:0] ID_EX_NPC;
    input [31:0] ID_EX_IR;
    input [2:0]  ID_EX_type;

    output reg [31:0] EX_MEM_ALUOut;
    output reg [31:0] EX_MEM_B;
    output reg [31:0] EX_MEM_IR;
    output reg [2:0]  EX_MEM_type;
    output reg        EX_MEM_cond;


    // Instruction types
    parameter RR_ALU = 3'b000;
    parameter RM_ALU = 3'b001;
    parameter LOAD   = 3'b010;
    parameter STORE  = 3'b011;
    parameter BRANCH = 3'b100;
    parameter HALT   = 3'b101;


    // Opcodes
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
    // EXECUTE STAGE
    // ==================================================

    always @(posedge clk1)
    begin
        if (HALTED == 0)
        begin

            // Pass these through to EX/MEM
            EX_MEM_type <= #2 ID_EX_type;
            EX_MEM_IR   <= #2 ID_EX_IR;

            case (ID_EX_type)

                // --------------------------------------
                // REGISTER-REGISTER ALU
                // --------------------------------------
                RR_ALU:
                begin
                    case (ID_EX_IR[31:26])

                        ADD:
                            EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;

                        SUB:
                            EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;

                        AND:
                            EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;

                        OR:
                            EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;

                        SLT:
                            EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_B);

                        MUL:
                            EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;

                        default:
                            EX_MEM_ALUOut <= #2 32'hxxxxxxxx;

                    endcase
                end


                // --------------------------------------
                // REGISTER-IMMEDIATE ALU
                // --------------------------------------
                RM_ALU:
                begin
                    case (ID_EX_IR[31:26])

                        ADDI:
                            EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;

                        SUBI:
                            EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;

                        SLTI:
                            EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_Imm);

                        default:
                            EX_MEM_ALUOut <= #2 32'hxxxxxxxx;

                    endcase
                end


                // --------------------------------------
                // LOAD / STORE
                // --------------------------------------
                LOAD,
                STORE:
                begin
                    // Effective address
                    EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;

                    // Store data
                    EX_MEM_B <= #2 ID_EX_B;
                end


                // --------------------------------------
                // BRANCH
                // --------------------------------------
                BRANCH:
                begin
                    // Branch target
                    EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;

                    // BEQZ: condition = 1 when A == 0
                    // BNEQZ: condition = 0 when A != 0
                    EX_MEM_cond <= #2 (ID_EX_A == 0);
                end

            endcase

        end
    end

endmodule
