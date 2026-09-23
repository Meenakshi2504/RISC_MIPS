`timescale 1ns / 1ps

module RISC_PROCESSOR (
    input clk1,
    input clk2,
    input reset
);

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
    // GLOBAL CONTROL
    // ==================================================

    reg HALTED;
    reg TAKEN_BRANCH;


    // ==================================================
    // IF / ID
    // ==================================================

    wire [31:0] PC;
    wire [31:0] IF_ID_IR;
    wire [31:0] IF_ID_NPC;


    // ==================================================
    // ID / EX
    // ==================================================

    wire [31:0] ID_EX_A;
    wire [31:0] ID_EX_B;
    wire [31:0] ID_EX_NPC;
    wire [31:0] ID_EX_IR;
    wire [31:0] ID_EX_Imm;
    wire [2:0]  ID_EX_type;


    // ==================================================
    // EX / MEM
    // ==================================================

    wire [31:0] EX_MEM_ALUOut;
    wire [31:0] EX_MEM_B;
    wire [31:0] EX_MEM_IR;
    wire [2:0]  EX_MEM_type;
    wire        EX_MEM_cond;


    // ==================================================
    // MEM / WB
    // ==================================================

    wire [31:0] MEM_WB_ALUOut;
    wire [31:0] MEM_WB_LMD;
    wire [31:0] MEM_WB_IR;
    wire [2:0]  MEM_WB_type;


    // ==================================================
    // HAZARD CONTROL
    // ==================================================

    reg PC_WRITE;
    reg IF_ID_WRITE;
    reg ID_EX_STALL;


    // ==================================================
    // HAZARD DETECTION SIGNALS
    // ==================================================

    reg [4:0] current_rs;
    reg [4:0] current_rt;

    reg uses_rs;
    reg uses_rt;

    reg [4:0] ID_EX_DEST;
    reg [4:0] EX_MEM_DEST;

    reg hazard;


    // ==================================================
    // BRANCH SIGNALS
    // ==================================================

    wire branch_taken;
    wire [31:0] branch_target;


    // ==================================================
    // WRITE BACK
    // ==================================================

    reg        wb_write;
    reg [4:0]  wb_addr;
    reg [31:0] wb_data;


    // ==================================================
    // EX INPUTS
    // 
    // When branch_taken = 1, the instruction currently
    // sitting in ID/EX is the wrong-path instruction.
    //
    // We convert it into a NOP before EX/MEM.
    // ==================================================

    wire [31:0] EX_A_IN;
    wire [31:0] EX_B_IN;
    wire [31:0] EX_NPC_IN;
    wire [31:0] EX_IR_IN;
    wire [31:0] EX_Imm_IN;
    wire [2:0]  EX_type_IN;

    assign EX_A_IN =
            branch_taken ? 32'd0 : ID_EX_A;

    assign EX_B_IN =
            branch_taken ? 32'd0 : ID_EX_B;

    assign EX_NPC_IN =
            branch_taken ? 32'd0 : ID_EX_NPC;

    assign EX_IR_IN =
            branch_taken ? 32'h00000000 : ID_EX_IR;

    assign EX_Imm_IN =
            branch_taken ? 32'd0 : ID_EX_Imm;

    assign EX_type_IN =
            branch_taken ? RR_ALU : ID_EX_type;


    // ==================================================
    // BRANCH DETECTION
    // ==================================================

    assign branch_taken =
           ((EX_MEM_IR[31:26] == BEQZ) &&
            (EX_MEM_cond == 1'b1))
        ||
           ((EX_MEM_IR[31:26] == BNEQZ) &&
            (EX_MEM_cond == 1'b0));

    assign branch_target = EX_MEM_ALUOut;


    // ==================================================
    // CURRENT INSTRUCTION SOURCE REGISTERS
    // ==================================================

    always @(*)
    begin
        current_rs = IF_ID_IR[25:21];
        current_rt = IF_ID_IR[20:16];

        uses_rs = 1'b0;
        uses_rt = 1'b0;

        case (IF_ID_IR[31:26])

            // R-type instructions
            ADD,
            SUB,
            AND,
            OR,
            SLT,
            MUL:
            begin
                uses_rs = 1'b1;
                uses_rt = 1'b1;
            end

            // Immediate ALU instructions
            ADDI,
            SUBI,
            SLTI:
            begin
                uses_rs = 1'b1;
                uses_rt = 1'b0;
            end

            // Load
            LW:
            begin
                uses_rs = 1'b1;
                uses_rt = 1'b0;
            end

            // Store
            SW:
            begin
                uses_rs = 1'b1;
                uses_rt = 1'b1;
            end

            // Branch
            BEQZ,
            BNEQZ:
            begin
                uses_rs = 1'b1;
                uses_rt = 1'b0;
            end

            default:
            begin
                uses_rs = 1'b0;
                uses_rt = 1'b0;
            end

        endcase
    end


    // ==================================================
    // ID/EX DESTINATION REGISTER
    // ==================================================

    always @(*)
    begin
        ID_EX_DEST = 5'd0;

        case (ID_EX_type)

            RR_ALU:
                ID_EX_DEST = ID_EX_IR[15:11];

            RM_ALU,
            LOAD:
                ID_EX_DEST = ID_EX_IR[20:16];

            default:
                ID_EX_DEST = 5'd0;

        endcase
    end


    // ==================================================
    // EX/MEM DESTINATION REGISTER
    // ==================================================

    always @(*)
    begin
        EX_MEM_DEST = 5'd0;

        case (EX_MEM_type)

            RR_ALU:
                EX_MEM_DEST = EX_MEM_IR[15:11];

            RM_ALU,
            LOAD:
                EX_MEM_DEST = EX_MEM_IR[20:16];

            default:
                EX_MEM_DEST = 5'd0;

        endcase
    end


    // ==================================================
    // HAZARD DETECTION
    // ==================================================

    always @(*)
    begin
        hazard = 1'b0;

        // ----------------------------------------------
        // Check rs
        // ----------------------------------------------

        if (uses_rs && (current_rs != 5'd0))
        begin
            if ((ID_EX_DEST != 5'd0) &&
                (ID_EX_DEST == current_rs))
            begin
                hazard = 1'b1;
            end

            if ((EX_MEM_DEST != 5'd0) &&
                (EX_MEM_DEST == current_rs))
            begin
                hazard = 1'b1;
            end
        end


        // ----------------------------------------------
        // Check rt
        // ----------------------------------------------

        if (uses_rt && (current_rt != 5'd0))
        begin
            if ((ID_EX_DEST != 5'd0) &&
                (ID_EX_DEST == current_rt))
            begin
                hazard = 1'b1;
            end

            if ((EX_MEM_DEST != 5'd0) &&
                (EX_MEM_DEST == current_rt))
            begin
                hazard = 1'b1;
            end
        end


        // ----------------------------------------------
        // Stall controls
        // ----------------------------------------------

        if (hazard)
        begin
            PC_WRITE    = 1'b0;
            IF_ID_WRITE = 1'b0;
            ID_EX_STALL = 1'b1;
        end
        else
        begin
            PC_WRITE    = 1'b1;
            IF_ID_WRITE = 1'b1;
            ID_EX_STALL = 1'b0;
        end

    end


    // ==================================================
    // WRITE BACK CONTROL
    // ==================================================

    always @(*)
    begin
        wb_write = 1'b0;
        wb_addr  = 5'd0;
        wb_data  = 32'd0;

        // A taken branch suppresses writes from the
        // branch-resolution cycle. The wrong-path
        // instruction itself is already killed at EX.
        if (TAKEN_BRANCH == 1'b0)
        begin
            case (MEM_WB_type)

                RR_ALU:
                begin
                    wb_write = 1'b1;
                    wb_addr  = MEM_WB_IR[15:11];
                    wb_data  = MEM_WB_ALUOut;
                end

                RM_ALU:
                begin
                    wb_write = 1'b1;
                    wb_addr  = MEM_WB_IR[20:16];
                    wb_data  = MEM_WB_ALUOut;
                end

                LOAD:
                begin
                    wb_write = 1'b1;
                    wb_addr  = MEM_WB_IR[20:16];
                    wb_data  = MEM_WB_LMD;
                end

                default:
                begin
                    wb_write = 1'b0;
                    wb_addr  = 5'd0;
                    wb_data  = 32'd0;
                end

            endcase
        end
    end


    // ==================================================
    // HALT + TAKEN_BRANCH
    // ==================================================

    always @(posedge clk1)
    begin
        if (reset)
        begin
            HALTED       <= 1'b0;
            TAKEN_BRANCH <= 1'b0;
        end
        else
        begin

            // ------------------------------------------
            // Branch suppression lasts for one clk1
            // interval so the MEM stage sees it.
            // ------------------------------------------

            if (branch_taken)
                TAKEN_BRANCH <= 1'b1;
            else
                TAKEN_BRANCH <= 1'b0;


            // ------------------------------------------
            // HALT
            // ------------------------------------------

            if ((MEM_WB_type == HALT) &&
                (TAKEN_BRANCH == 1'b0))
            begin
                HALTED <= 1'b1;
            end

        end
    end


    // ==================================================
    // IF STAGE
    // ==================================================

    IF_IFID if_stage
    (
        .clk1(clk1),
        .reset(reset),
        .HALTED(HALTED),

        .pc_write(PC_WRITE),
        .ifid_write(IF_ID_WRITE),

        .branch_taken(branch_taken),
        .branch_target(branch_target),

        .pc(PC),
        .IF_ID_IR(IF_ID_IR),
        .IF_ID_NPC(IF_ID_NPC)
    );


    // ==================================================
    // ID STAGE
    // ==================================================

    ID_IDEX id_stage
    (
        .clk1(clk1),
        .clk2(clk2),
        .reset(reset),
        .HALTED(HALTED),

        .stall(ID_EX_STALL),

        .wb_write(wb_write),
        .wb_addr(wb_addr),
        .wb_data(wb_data),

        .IF_ID_IR(IF_ID_IR),
        .IF_ID_NPC(IF_ID_NPC),

        .ID_EX_A(ID_EX_A),
        .ID_EX_B(ID_EX_B),
        .ID_EX_NPC(ID_EX_NPC),
        .ID_EX_IR(ID_EX_IR),
        .ID_EX_Imm(ID_EX_Imm),
        .ID_EX_type(ID_EX_type)
    );


    // ==================================================
    // EX STAGE
    // ==================================================

    EX_EXMEM ex_stage
    (
        .clk1(clk1),
        .HALTED(HALTED),

        // IMPORTANT:
        // Use the gated EX inputs here.
        // When branch_taken=1, the wrong-path
        // instruction becomes a NOP.

        .ID_EX_A(EX_A_IN),
        .ID_EX_B(EX_B_IN),
        .ID_EX_Imm(EX_Imm_IN),
        .ID_EX_NPC(EX_NPC_IN),
        .ID_EX_IR(EX_IR_IN),
        .ID_EX_type(EX_type_IN),

        .EX_MEM_ALUOut(EX_MEM_ALUOut),
        .EX_MEM_B(EX_MEM_B),
        .EX_MEM_IR(EX_MEM_IR),
        .EX_MEM_type(EX_MEM_type),
        .EX_MEM_cond(EX_MEM_cond)
    );


    // ==================================================
    // MEM STAGE
    // ==================================================

    MEM_MEMWB mem_stage
    (
        .clk2(clk2),
        .HALTED(HALTED),
        .TAKEN_BRANCH(TAKEN_BRANCH),

        .EX_MEM_ALUOut(EX_MEM_ALUOut),
        .EX_MEM_B(EX_MEM_B),
        .EX_MEM_IR(EX_MEM_IR),
        .EX_MEM_type(EX_MEM_type),

        .MEM_WB_ALUOut(MEM_WB_ALUOut),
        .MEM_WB_LMD(MEM_WB_LMD),
        .MEM_WB_IR(MEM_WB_IR),
        .MEM_WB_type(MEM_WB_type)
    );

endmodule