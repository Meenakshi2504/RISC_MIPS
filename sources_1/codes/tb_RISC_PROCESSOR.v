`timescale 1ns / 1ps

module tb_RISC_PROCESSOR;

reg clk1;
reg clk2;
reg reset;


// ==================================================
// DUT
// ==================================================

RISC_PROCESSOR dut (
    .clk1(clk1),
    .clk2(clk2),
    .reset(reset)
);


// ==================================================
// TB SIGNALS FOR WAVEFORM
// Only important pipeline/control signals
// ==================================================

// --------------------
// Processor control
// --------------------

wire HALTED;
wire TAKEN_BRANCH;

// --------------------
// Program counter
// --------------------

wire [31:0] PC;

// --------------------
// IF / ID
// --------------------

wire [31:0] IF_ID_IR;
wire [31:0] IF_ID_NPC;

// --------------------
// ID / EX
// --------------------

wire [31:0] ID_EX_IR;
wire [2:0]  ID_EX_type;

// --------------------
// EX / MEM
// --------------------

wire [31:0] EX_MEM_IR;
wire [2:0]  EX_MEM_type;

// --------------------
// MEM / WB
// --------------------

wire [31:0] MEM_WB_IR;
wire [2:0]  MEM_WB_type;

// --------------------
// Hazard control
// --------------------

wire hazard;
wire PC_WRITE;
wire IF_ID_WRITE;
wire ID_EX_STALL;

// --------------------
// Branch
// --------------------

wire branch_taken;
wire [31:0] branch_target;

// --------------------
// Writeback
// --------------------

wire wb_write;
wire [4:0]  wb_addr;
wire [31:0] wb_data;


// ==================================================
// CONNECT TB SIGNALS TO DUT INTERNAL SIGNALS
// ==================================================

assign HALTED       = dut.HALTED;
assign TAKEN_BRANCH = dut.TAKEN_BRANCH;

assign PC = dut.PC;

// IF/ID
assign IF_ID_IR  = dut.IF_ID_IR;
assign IF_ID_NPC = dut.IF_ID_NPC;

// ID/EX
assign ID_EX_IR   = dut.ID_EX_IR;
assign ID_EX_type = dut.ID_EX_type;

// EX/MEM
assign EX_MEM_IR   = dut.EX_MEM_IR;
assign EX_MEM_type = dut.EX_MEM_type;

// MEM/WB
assign MEM_WB_IR   = dut.MEM_WB_IR;
assign MEM_WB_type = dut.MEM_WB_type;

// Hazard
assign hazard      = dut.hazard;
assign PC_WRITE    = dut.PC_WRITE;
assign IF_ID_WRITE = dut.IF_ID_WRITE;
assign ID_EX_STALL = dut.ID_EX_STALL;

// Branch
assign branch_taken  = dut.branch_taken;
assign branch_target = dut.branch_target;

// Writeback
assign wb_write = dut.wb_write;
assign wb_addr  = dut.wb_addr;
assign wb_data  = dut.wb_data;


// ==================================================
// CLOCK 1
// ==================================================

initial begin
    clk1 = 0;
    forever #5 clk1 = ~clk1;
end


// ==================================================
// CLOCK 2
// ==================================================

initial begin
    clk2 = 1;
    forever #5 clk2 = ~clk2;
end


// ==================================================
// PROGRAM
// ==================================================

initial begin

    // ------------------------------------------------
    // 0: ADDI R1,R0,10
    // ------------------------------------------------
    dut.if_stage.IMEM[0] = 32'h2801000A;


    // ------------------------------------------------
    // 1: ADDI R2,R1,5
    //
    // R1 hazard
    // ------------------------------------------------
    dut.if_stage.IMEM[1] = 32'h28220005;


    // ------------------------------------------------
    // 2: ADD R3,R1,R2
    //
    // R1 + R2 hazards
    // ------------------------------------------------
    dut.if_stage.IMEM[2] = 32'h00221800;


    // ------------------------------------------------
    // 3: SUB R4,R3,R1
    //
    // R3 hazard
    // ------------------------------------------------
    dut.if_stage.IMEM[3] = 32'h04612000;


    // ------------------------------------------------
    // 4: AND R5,R1,R4
    //
    // R4 hazard
    // ------------------------------------------------
    dut.if_stage.IMEM[4] = 32'h08242800;


    // ------------------------------------------------
    // 5: OR R6,R5,R3
    //
    // R5 hazard
    // ------------------------------------------------
    dut.if_stage.IMEM[5] = 32'h0CA33000;


    // ------------------------------------------------
    // 6: SLT R7,R6,R3
    //
    // R6 hazard
    // ------------------------------------------------
    dut.if_stage.IMEM[6] = 32'h10C33800;


    // ------------------------------------------------
    // 7: MUL R8,R7,R1
    //
    // R7 hazard
    // ------------------------------------------------
    dut.if_stage.IMEM[7] = 32'h14E14000;


    // ------------------------------------------------
    // 8: BEQZ R8,+2
    //
    // R8 hazard
    //
    // NPC = 9
    // Target = 11
    // ------------------------------------------------
    dut.if_stage.IMEM[8] = 32'h39000002;


    // ------------------------------------------------
    // 9: WRONG PATH
    // ADDI R9,R0,111
    // ------------------------------------------------
    dut.if_stage.IMEM[9] = 32'h2809006F;


    // ------------------------------------------------
    // 10: WRONG PATH
    // ADDI R9,R0,222
    // ------------------------------------------------
    dut.if_stage.IMEM[10] = 32'h280900DE;


    // ------------------------------------------------
    // 11: BRANCH TARGET
    // ADDI R10,R0,99
    // ------------------------------------------------
    dut.if_stage.IMEM[11] = 32'h280A0063;


    // ------------------------------------------------
    // 12: HLT
    // ------------------------------------------------
    dut.if_stage.IMEM[12] = 32'hFC000000;


    // ------------------------------------------------
    // Fill
    // ------------------------------------------------
    dut.if_stage.IMEM[13] = 32'h00000000;
    dut.if_stage.IMEM[14] = 32'h00000000;
    dut.if_stage.IMEM[15] = 32'h00000000;

end


// ==================================================
// RESET
// ==================================================

initial begin

    reset = 1;

    // Reset across both clock phases
    #12;

    reset = 0;

end


// ==================================================
// RUN + CHECK
// ==================================================

initial begin

    #450;

    $display("");
    $display("");
    $display("================================================");
    $display("             FINAL PROCESSOR RESULTS");
    $display("================================================");

    $display("HALTED = %b", HALTED);
    $display("PC     = %d", PC);

    $display("");
    $display("HAZARD SIGNALS");

    $display("hazard      = %b", hazard);
    $display("PC_WRITE    = %b", PC_WRITE);
    $display("IF_ID_WRITE = %b", IF_ID_WRITE);
    $display("ID_EX_STALL = %b", ID_EX_STALL);

    $display("");
    $display("BRANCH SIGNALS");

    $display("branch_taken  = %b", branch_taken);
    $display("branch_target = %d", branch_target);
    $display("TAKEN_BRANCH  = %b", TAKEN_BRANCH);

    $display("");
    $display("PIPELINE");

    $display("IF_ID_IR  = %h", IF_ID_IR);
    $display("ID_EX_IR  = %h", ID_EX_IR);
    $display("EX_MEM_IR = %h", EX_MEM_IR);
    $display("MEM_WB_IR = %h", MEM_WB_IR);


    // ==================================================
    // CHECK
    // ==================================================

    $display("");
    $display("================================================");
    $display("                 CHECK RESULTS");
    $display("================================================");


    if (dut.id_stage.Reg[1] == 32'd10)
        $display("R1  = 10       PASS");
    else
        $display("R1  = %d       FAIL", dut.id_stage.Reg[1]);


    if (dut.id_stage.Reg[2] == 32'd15)
        $display("R2  = 15       PASS");
    else
        $display("R2  = %d       FAIL", dut.id_stage.Reg[2]);


    if (dut.id_stage.Reg[3] == 32'd25)
        $display("R3  = 25       PASS");
    else
        $display("R3  = %d       FAIL", dut.id_stage.Reg[3]);


    if (dut.id_stage.Reg[4] == 32'd15)
        $display("R4  = 15       PASS");
    else
        $display("R4  = %d       FAIL", dut.id_stage.Reg[4]);


    if (dut.id_stage.Reg[5] == 32'd10)
        $display("R5  = 10       PASS");
    else
        $display("R5  = %d       FAIL", dut.id_stage.Reg[5]);


    if (dut.id_stage.Reg[6] == 32'd27)
        $display("R6  = 27       PASS");
    else
        $display("R6  = %d       FAIL", dut.id_stage.Reg[6]);


    if (dut.id_stage.Reg[7] == 32'd0)
        $display("R7  = 0        PASS");
    else
        $display("R7  = %d       FAIL", dut.id_stage.Reg[7]);


    if (dut.id_stage.Reg[8] == 32'd0)
        $display("R8  = 0        PASS");
    else
        $display("R8  = %d       FAIL", dut.id_stage.Reg[8]);


    // Wrong-path instructions must NOT execute
    if (dut.id_stage.Reg[9] == 32'd0)
        $display("R9  = 0        PASS  (branch flush)");
    else
        $display("R9  = %d       FAIL  (branch flush)",
                 dut.id_stage.Reg[9]);


    // Branch target must execute
    if (dut.id_stage.Reg[10] == 32'd99)
        $display("R10 = 99       PASS  (branch target)");
    else
        $display("R10 = %d       FAIL  (branch target)",
                 dut.id_stage.Reg[10]);


    if (dut.id_stage.Reg[0] == 32'd0)
        $display("R0  = 0        PASS");
    else
        $display("R0  = %d       FAIL", dut.id_stage.Reg[0]);


    if (HALTED == 1'b1)
        $display("HALTED = 1    PASS");
    else
        $display("HALTED = 0    FAIL");


    $display("");
    $display("================================================");
    $display("             TEST COMPLETE");
    $display("================================================");

    $finish;

end

endmodule