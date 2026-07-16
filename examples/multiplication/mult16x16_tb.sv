//See multiplication16.md for explanation

`timescale 1ns/1ps

module MUL16_tb;

    logic clk = 0;
    logic rst;

    TOP dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    //program counter
    logic [15:0] PC_dbg;
    assign PC_dbg = dut.controlpath.PC;

    //flags in current cycle, set by previous instruction
    logic FLAGN_dbg, FLAGZ_dbg, FLAGC_dbg, FLAGV_dbg;
    assign FLAGN_dbg = dut.controlpath.NQ;
    assign FLAGZ_dbg = dut.controlpath.ZQ;
    assign FLAGC_dbg = dut.controlpath.CQ;
    assign FLAGV_dbg = dut.controlpath.VQ;

    //registers
    logic [15:0] R0_dbg, R1_dbg, R2_dbg, R3_dbg, R4_dbg, R5_dbg, R6_dbg, R7_dbg;
    assign R0_dbg = dut.datapath.reg16x8.REG[0];
    assign R1_dbg = dut.datapath.reg16x8.REG[1];
    assign R2_dbg = dut.datapath.reg16x8.REG[2];
    assign R3_dbg = dut.datapath.reg16x8.REG[3];
    assign R4_dbg = dut.datapath.reg16x8.REG[4];
    assign R5_dbg = dut.datapath.reg16x8.REG[5];
    assign R6_dbg = dut.datapath.reg16x8.REG[6];
    assign R7_dbg = dut.datapath.reg16x8.REG[7];

    //decode/write debug taps
    logic [15:0] INS_dbg;
    logic [2:0]  A_dbg, B_dbg, C_dbg, AD1_dbg;
    logic        WEN1_dbg, AD1SELC_dbg, PCWRITE_dbg, OP2SEL_dbg;
    logic [15:0] DIN1_dbg, IMMEXT_dbg, ALUOUT_dbg, DOUT2_dbg, DOUT3_dbg;
    assign INS_dbg     = dut.controlpath.INS;
    assign A_dbg        = dut.datapath.A;
    assign B_dbg        = dut.datapath.B;
    assign C_dbg        = dut.datapath.C;
    assign AD1_dbg      = dut.datapath.AD1;
    assign WEN1_dbg     = dut.datapath.WEN1;
    assign AD1SELC_dbg  = dut.datapath.AD1SELC;
    assign PCWRITE_dbg  = dut.datapath.PCWRITE;
    assign OP2SEL_dbg   = dut.datapath.OP2SEL;
    assign DIN1_dbg     = dut.datapath.DIN1;
    assign IMMEXT_dbg   = dut.datapath.IMMEXT;
    assign ALUOUT_dbg   = dut.datapath.ALUOUT;
    assign DOUT2_dbg    = dut.datapath.DOUT2;
    assign DOUT3_dbg    = dut.datapath.DOUT3;

    // Program: 16x16 -> 32-bit multiply, op1=op2=0x80FF (33023*33023)
    // Result: R6:R5 = 0x40FFFE01 (1,090,518,529)
    localparam int PROG_LEN = 20;
    logic [15:0] PROGRAM [0:PROG_LEN-1];

    initial begin
        PROGRAM[0]  = 16'hd080; // EXT #128
        PROGRAM[1]  = 16'h01ff; // MOV R0,#255
        PROGRAM[2]  = 16'hd080; // EXT #128
        PROGRAM[3]  = 16'h03ff; // MOV R1,#255
        PROGRAM[4]  = 16'h0620; // MOV R3,R1
        PROGRAM[5]  = 16'h0900; // MOV R4,#0
        PROGRAM[6]  = 16'h0b00; // MOV R5,#0
        PROGRAM[7]  = 16'h0d00; // MOV R6,#0
        PROGRAM[8]  = 16'h6100; // CMP R0,#0
        PROGRAM[9]  = 16'hc20b; // JEQ 11
        PROGRAM[10] = 16'h0e00; // MOV R7,R0
        PROGRAM[11] = 16'h5f01; // AND R7,#1
        PROGRAM[12] = 16'hc203; // JEQ 3
        PROGRAM[13] = 16'h1a74; // ADD R5,R3
        PROGRAM[14] = 16'h3c98; // ADC R6,R4
        PROGRAM[15] = 16'h7881; // LSL R4,R4,#1
        PROGRAM[16] = 16'h7661; // LSL R3,R3,#1
        PROGRAM[17] = 16'h3900; // ADC R4,#0
        PROGRAM[18] = 16'h7011; // LSR R0,R0,#1
        PROGRAM[19] = 16'hc0f5; // JMP -11
    end


    int pass_count = 0;
    int fail_count = 0;
    int cyc = 0;

    localparam int NUM_CYCLES = 188;

    int    exp_pc [0:NUM_CYCLES-1];
    int    exp_r0 [0:NUM_CYCLES-1];
    int    exp_r1 [0:NUM_CYCLES-1];
    int    exp_r2 [0:NUM_CYCLES-1];
    int    exp_r3 [0:NUM_CYCLES-1];
    int    exp_r4 [0:NUM_CYCLES-1];
    int    exp_r5 [0:NUM_CYCLES-1];
    int    exp_r6 [0:NUM_CYCLES-1];
    int    exp_r7 [0:NUM_CYCLES-1];
    int    exp_z  [0:NUM_CYCLES-1];
    string exp_label [0:NUM_CYCLES-1];

    task automatic check(
        input logic [15:0] act_pc, act_r0, act_r1, act_r2, act_r3, act_r4, act_r5, act_r6, act_r7,
        input logic act_z,
        input int cycle_num
    );
        bit ok = 1;
        string msg = "";

        if (act_pc !== exp_pc[cycle_num][15:0])
            begin ok = 0; msg = {msg, " PC"}; end
        if (act_r0 !== exp_r0[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R0"}; end
        if (act_r1 !== exp_r1[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R1"}; end
        if (act_r2 !== exp_r2[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R2"}; end
        if (act_r3 !== exp_r3[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R3"}; end
        if (act_r4 !== exp_r4[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R4"}; end
        if (act_r5 !== exp_r5[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R5"}; end
        if (act_r6 !== exp_r6[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R6"}; end
        if (act_r7 !== exp_r7[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R7"}; end
        if (act_z  !== exp_z[cycle_num][0])
            begin ok = 0; msg = {msg, " Z"}; end

        if (ok) begin
            $display("PASS | cyc %3d | %-14s | PC=%0d R0=%0d R1=%0d R3=%0d R4=%0d R5=%0d R6=%0d R7=%0d",
                      cycle_num, exp_label[cycle_num], act_pc, act_r0, act_r1, act_r3, act_r4, act_r5, act_r6, act_r7);
            pass_count++;
        end else begin
            $display("FAIL | cyc %3d | %-14s | mismatch:%s", cycle_num, exp_label[cycle_num], msg);
            $display("       actual:   PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d R5=%0d R6=%0d R7=%0d Z=%0b",
                      act_pc, act_r0, act_r1, act_r2, act_r3, act_r4, act_r5, act_r6, act_r7, act_z);
            $display("       expected: PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d R5=%0d R6=%0d R7=%0d",
                      exp_pc[cycle_num], exp_r0[cycle_num], exp_r1[cycle_num], exp_r2[cycle_num],
                      exp_r3[cycle_num], exp_r4[cycle_num], exp_r5[cycle_num], exp_r6[cycle_num], exp_r7[cycle_num]);
            fail_count++;
        end
    endtask

    initial begin

        exp_pc[0]=1; exp_r0[0]=0; exp_r1[0]=0; exp_r2[0]=0; exp_r3[0]=0; exp_r4[0]=0; exp_r5[0]=0; exp_r6[0]=0; exp_r7[0]=0; exp_z[0]=0; exp_label[0]="EXT #128";
        exp_pc[1]=2; exp_r0[1]=33023; exp_r1[1]=0; exp_r2[1]=0; exp_r3[1]=0; exp_r4[1]=0; exp_r5[1]=0; exp_r6[1]=0; exp_r7[1]=0; exp_z[1]=0; exp_label[1]="MOV R0,#255";
        exp_pc[2]=3; exp_r0[2]=33023; exp_r1[2]=0; exp_r2[2]=0; exp_r3[2]=0; exp_r4[2]=0; exp_r5[2]=0; exp_r6[2]=0; exp_r7[2]=0; exp_z[2]=0; exp_label[2]="EXT #128";
        exp_pc[3]=4; exp_r0[3]=33023; exp_r1[3]=33023; exp_r2[3]=0; exp_r3[3]=0; exp_r4[3]=0; exp_r5[3]=0; exp_r6[3]=0; exp_r7[3]=0; exp_z[3]=0; exp_label[3]="MOV R1,#255";
        exp_pc[4]=5; exp_r0[4]=33023; exp_r1[4]=33023; exp_r2[4]=0; exp_r3[4]=33023; exp_r4[4]=0; exp_r5[4]=0; exp_r6[4]=0; exp_r7[4]=0; exp_z[4]=0; exp_label[4]="MOV R3,R1";
        exp_pc[5]=6; exp_r0[5]=33023; exp_r1[5]=33023; exp_r2[5]=0; exp_r3[5]=33023; exp_r4[5]=0; exp_r5[5]=0; exp_r6[5]=0; exp_r7[5]=0; exp_z[5]=1; exp_label[5]="MOV R4,#0";
        exp_pc[6]=7; exp_r0[6]=33023; exp_r1[6]=33023; exp_r2[6]=0; exp_r3[6]=33023; exp_r4[6]=0; exp_r5[6]=0; exp_r6[6]=0; exp_r7[6]=0; exp_z[6]=1; exp_label[6]="MOV R5,#0";
        exp_pc[7]=8; exp_r0[7]=33023; exp_r1[7]=33023; exp_r2[7]=0; exp_r3[7]=33023; exp_r4[7]=0; exp_r5[7]=0; exp_r6[7]=0; exp_r7[7]=0; exp_z[7]=1; exp_label[7]="MOV R6,#0";
        exp_pc[8]=9; exp_r0[8]=33023; exp_r1[8]=33023; exp_r2[8]=0; exp_r3[8]=33023; exp_r4[8]=0; exp_r5[8]=0; exp_r6[8]=0; exp_r7[8]=0; exp_z[8]=0; exp_label[8]="CMP R0,#0";
        exp_pc[9]=10; exp_r0[9]=33023; exp_r1[9]=33023; exp_r2[9]=0; exp_r3[9]=33023; exp_r4[9]=0; exp_r5[9]=0; exp_r6[9]=0; exp_r7[9]=0; exp_z[9]=0; exp_label[9]="JEQ 11";
        exp_pc[10]=11; exp_r0[10]=33023; exp_r1[10]=33023; exp_r2[10]=0; exp_r3[10]=33023; exp_r4[10]=0; exp_r5[10]=0; exp_r6[10]=0; exp_r7[10]=33023; exp_z[10]=0; exp_label[10]="MOV R7,R0";
        exp_pc[11]=12; exp_r0[11]=33023; exp_r1[11]=33023; exp_r2[11]=0; exp_r3[11]=33023; exp_r4[11]=0; exp_r5[11]=0; exp_r6[11]=0; exp_r7[11]=1; exp_z[11]=0; exp_label[11]="AND R7,#1";
        exp_pc[12]=13; exp_r0[12]=33023; exp_r1[12]=33023; exp_r2[12]=0; exp_r3[12]=33023; exp_r4[12]=0; exp_r5[12]=0; exp_r6[12]=0; exp_r7[12]=1; exp_z[12]=0; exp_label[12]="JEQ 3";
        exp_pc[13]=14; exp_r0[13]=33023; exp_r1[13]=33023; exp_r2[13]=0; exp_r3[13]=33023; exp_r4[13]=0; exp_r5[13]=33023; exp_r6[13]=0; exp_r7[13]=1; exp_z[13]=0; exp_label[13]="ADD R5,R3";
        exp_pc[14]=15; exp_r0[14]=33023; exp_r1[14]=33023; exp_r2[14]=0; exp_r3[14]=33023; exp_r4[14]=0; exp_r5[14]=33023; exp_r6[14]=0; exp_r7[14]=1; exp_z[14]=1; exp_label[14]="ADC R6,R4";
        exp_pc[15]=16; exp_r0[15]=33023; exp_r1[15]=33023; exp_r2[15]=0; exp_r3[15]=33023; exp_r4[15]=0; exp_r5[15]=33023; exp_r6[15]=0; exp_r7[15]=1; exp_z[15]=1; exp_label[15]="LSL R4,#1";
        exp_pc[16]=17; exp_r0[16]=33023; exp_r1[16]=33023; exp_r2[16]=0; exp_r3[16]=510; exp_r4[16]=0; exp_r5[16]=33023; exp_r6[16]=0; exp_r7[16]=1; exp_z[16]=0; exp_label[16]="LSL R3,#1";
        exp_pc[17]=18; exp_r0[17]=33023; exp_r1[17]=33023; exp_r2[17]=0; exp_r3[17]=510; exp_r4[17]=1; exp_r5[17]=33023; exp_r6[17]=0; exp_r7[17]=1; exp_z[17]=0; exp_label[17]="ADC R4,#0";
        exp_pc[18]=19; exp_r0[18]=16511; exp_r1[18]=33023; exp_r2[18]=0; exp_r3[18]=510; exp_r4[18]=1; exp_r5[18]=33023; exp_r6[18]=0; exp_r7[18]=1; exp_z[18]=0; exp_label[18]="LSR R0,#1";
        exp_pc[19]=8; exp_r0[19]=16511; exp_r1[19]=33023; exp_r2[19]=0; exp_r3[19]=510; exp_r4[19]=1; exp_r5[19]=33023; exp_r6[19]=0; exp_r7[19]=1; exp_z[19]=0; exp_label[19]="JMP -11";
        exp_pc[20]=9; exp_r0[20]=16511; exp_r1[20]=33023; exp_r2[20]=0; exp_r3[20]=510; exp_r4[20]=1; exp_r5[20]=33023; exp_r6[20]=0; exp_r7[20]=1; exp_z[20]=0; exp_label[20]="CMP R0,#0";
        exp_pc[21]=10; exp_r0[21]=16511; exp_r1[21]=33023; exp_r2[21]=0; exp_r3[21]=510; exp_r4[21]=1; exp_r5[21]=33023; exp_r6[21]=0; exp_r7[21]=1; exp_z[21]=0; exp_label[21]="JEQ 11";
        exp_pc[22]=11; exp_r0[22]=16511; exp_r1[22]=33023; exp_r2[22]=0; exp_r3[22]=510; exp_r4[22]=1; exp_r5[22]=33023; exp_r6[22]=0; exp_r7[22]=16511; exp_z[22]=0; exp_label[22]="MOV R7,R0";
        exp_pc[23]=12; exp_r0[23]=16511; exp_r1[23]=33023; exp_r2[23]=0; exp_r3[23]=510; exp_r4[23]=1; exp_r5[23]=33023; exp_r6[23]=0; exp_r7[23]=1; exp_z[23]=0; exp_label[23]="AND R7,#1";
        exp_pc[24]=13; exp_r0[24]=16511; exp_r1[24]=33023; exp_r2[24]=0; exp_r3[24]=510; exp_r4[24]=1; exp_r5[24]=33023; exp_r6[24]=0; exp_r7[24]=1; exp_z[24]=0; exp_label[24]="JEQ 3";
        exp_pc[25]=14; exp_r0[25]=16511; exp_r1[25]=33023; exp_r2[25]=0; exp_r3[25]=510; exp_r4[25]=1; exp_r5[25]=33533; exp_r6[25]=0; exp_r7[25]=1; exp_z[25]=0; exp_label[25]="ADD R5,R3";
        exp_pc[26]=15; exp_r0[26]=16511; exp_r1[26]=33023; exp_r2[26]=0; exp_r3[26]=510; exp_r4[26]=1; exp_r5[26]=33533; exp_r6[26]=1; exp_r7[26]=1; exp_z[26]=0; exp_label[26]="ADC R6,R4";
        exp_pc[27]=16; exp_r0[27]=16511; exp_r1[27]=33023; exp_r2[27]=0; exp_r3[27]=510; exp_r4[27]=2; exp_r5[27]=33533; exp_r6[27]=1; exp_r7[27]=1; exp_z[27]=0; exp_label[27]="LSL R4,#1";
        exp_pc[28]=17; exp_r0[28]=16511; exp_r1[28]=33023; exp_r2[28]=0; exp_r3[28]=1020; exp_r4[28]=2; exp_r5[28]=33533; exp_r6[28]=1; exp_r7[28]=1; exp_z[28]=0; exp_label[28]="LSL R3,#1";
        exp_pc[29]=18; exp_r0[29]=16511; exp_r1[29]=33023; exp_r2[29]=0; exp_r3[29]=1020; exp_r4[29]=2; exp_r5[29]=33533; exp_r6[29]=1; exp_r7[29]=1; exp_z[29]=0; exp_label[29]="ADC R4,#0";
        exp_pc[30]=19; exp_r0[30]=8255; exp_r1[30]=33023; exp_r2[30]=0; exp_r3[30]=1020; exp_r4[30]=2; exp_r5[30]=33533; exp_r6[30]=1; exp_r7[30]=1; exp_z[30]=0; exp_label[30]="LSR R0,#1";
        exp_pc[31]=8; exp_r0[31]=8255; exp_r1[31]=33023; exp_r2[31]=0; exp_r3[31]=1020; exp_r4[31]=2; exp_r5[31]=33533; exp_r6[31]=1; exp_r7[31]=1; exp_z[31]=0; exp_label[31]="JMP -11";
        exp_pc[32]=9; exp_r0[32]=8255; exp_r1[32]=33023; exp_r2[32]=0; exp_r3[32]=1020; exp_r4[32]=2; exp_r5[32]=33533; exp_r6[32]=1; exp_r7[32]=1; exp_z[32]=0; exp_label[32]="CMP R0,#0";
        exp_pc[33]=10; exp_r0[33]=8255; exp_r1[33]=33023; exp_r2[33]=0; exp_r3[33]=1020; exp_r4[33]=2; exp_r5[33]=33533; exp_r6[33]=1; exp_r7[33]=1; exp_z[33]=0; exp_label[33]="JEQ 11";
        exp_pc[34]=11; exp_r0[34]=8255; exp_r1[34]=33023; exp_r2[34]=0; exp_r3[34]=1020; exp_r4[34]=2; exp_r5[34]=33533; exp_r6[34]=1; exp_r7[34]=8255; exp_z[34]=0; exp_label[34]="MOV R7,R0";
        exp_pc[35]=12; exp_r0[35]=8255; exp_r1[35]=33023; exp_r2[35]=0; exp_r3[35]=1020; exp_r4[35]=2; exp_r5[35]=33533; exp_r6[35]=1; exp_r7[35]=1; exp_z[35]=0; exp_label[35]="AND R7,#1";
        exp_pc[36]=13; exp_r0[36]=8255; exp_r1[36]=33023; exp_r2[36]=0; exp_r3[36]=1020; exp_r4[36]=2; exp_r5[36]=33533; exp_r6[36]=1; exp_r7[36]=1; exp_z[36]=0; exp_label[36]="JEQ 3";
        exp_pc[37]=14; exp_r0[37]=8255; exp_r1[37]=33023; exp_r2[37]=0; exp_r3[37]=1020; exp_r4[37]=2; exp_r5[37]=34553; exp_r6[37]=1; exp_r7[37]=1; exp_z[37]=0; exp_label[37]="ADD R5,R3";
        exp_pc[38]=15; exp_r0[38]=8255; exp_r1[38]=33023; exp_r2[38]=0; exp_r3[38]=1020; exp_r4[38]=2; exp_r5[38]=34553; exp_r6[38]=3; exp_r7[38]=1; exp_z[38]=0; exp_label[38]="ADC R6,R4";
        exp_pc[39]=16; exp_r0[39]=8255; exp_r1[39]=33023; exp_r2[39]=0; exp_r3[39]=1020; exp_r4[39]=4; exp_r5[39]=34553; exp_r6[39]=3; exp_r7[39]=1; exp_z[39]=0; exp_label[39]="LSL R4,#1";
        exp_pc[40]=17; exp_r0[40]=8255; exp_r1[40]=33023; exp_r2[40]=0; exp_r3[40]=2040; exp_r4[40]=4; exp_r5[40]=34553; exp_r6[40]=3; exp_r7[40]=1; exp_z[40]=0; exp_label[40]="LSL R3,#1";
        exp_pc[41]=18; exp_r0[41]=8255; exp_r1[41]=33023; exp_r2[41]=0; exp_r3[41]=2040; exp_r4[41]=4; exp_r5[41]=34553; exp_r6[41]=3; exp_r7[41]=1; exp_z[41]=0; exp_label[41]="ADC R4,#0";
        exp_pc[42]=19; exp_r0[42]=4127; exp_r1[42]=33023; exp_r2[42]=0; exp_r3[42]=2040; exp_r4[42]=4; exp_r5[42]=34553; exp_r6[42]=3; exp_r7[42]=1; exp_z[42]=0; exp_label[42]="LSR R0,#1";
        exp_pc[43]=8; exp_r0[43]=4127; exp_r1[43]=33023; exp_r2[43]=0; exp_r3[43]=2040; exp_r4[43]=4; exp_r5[43]=34553; exp_r6[43]=3; exp_r7[43]=1; exp_z[43]=0; exp_label[43]="JMP -11";
        exp_pc[44]=9; exp_r0[44]=4127; exp_r1[44]=33023; exp_r2[44]=0; exp_r3[44]=2040; exp_r4[44]=4; exp_r5[44]=34553; exp_r6[44]=3; exp_r7[44]=1; exp_z[44]=0; exp_label[44]="CMP R0,#0";
        exp_pc[45]=10; exp_r0[45]=4127; exp_r1[45]=33023; exp_r2[45]=0; exp_r3[45]=2040; exp_r4[45]=4; exp_r5[45]=34553; exp_r6[45]=3; exp_r7[45]=1; exp_z[45]=0; exp_label[45]="JEQ 11";
        exp_pc[46]=11; exp_r0[46]=4127; exp_r1[46]=33023; exp_r2[46]=0; exp_r3[46]=2040; exp_r4[46]=4; exp_r5[46]=34553; exp_r6[46]=3; exp_r7[46]=4127; exp_z[46]=0; exp_label[46]="MOV R7,R0";
        exp_pc[47]=12; exp_r0[47]=4127; exp_r1[47]=33023; exp_r2[47]=0; exp_r3[47]=2040; exp_r4[47]=4; exp_r5[47]=34553; exp_r6[47]=3; exp_r7[47]=1; exp_z[47]=0; exp_label[47]="AND R7,#1";
        exp_pc[48]=13; exp_r0[48]=4127; exp_r1[48]=33023; exp_r2[48]=0; exp_r3[48]=2040; exp_r4[48]=4; exp_r5[48]=34553; exp_r6[48]=3; exp_r7[48]=1; exp_z[48]=0; exp_label[48]="JEQ 3";
        exp_pc[49]=14; exp_r0[49]=4127; exp_r1[49]=33023; exp_r2[49]=0; exp_r3[49]=2040; exp_r4[49]=4; exp_r5[49]=36593; exp_r6[49]=3; exp_r7[49]=1; exp_z[49]=0; exp_label[49]="ADD R5,R3";
        exp_pc[50]=15; exp_r0[50]=4127; exp_r1[50]=33023; exp_r2[50]=0; exp_r3[50]=2040; exp_r4[50]=4; exp_r5[50]=36593; exp_r6[50]=7; exp_r7[50]=1; exp_z[50]=0; exp_label[50]="ADC R6,R4";
        exp_pc[51]=16; exp_r0[51]=4127; exp_r1[51]=33023; exp_r2[51]=0; exp_r3[51]=2040; exp_r4[51]=8; exp_r5[51]=36593; exp_r6[51]=7; exp_r7[51]=1; exp_z[51]=0; exp_label[51]="LSL R4,#1";
        exp_pc[52]=17; exp_r0[52]=4127; exp_r1[52]=33023; exp_r2[52]=0; exp_r3[52]=4080; exp_r4[52]=8; exp_r5[52]=36593; exp_r6[52]=7; exp_r7[52]=1; exp_z[52]=0; exp_label[52]="LSL R3,#1";
        exp_pc[53]=18; exp_r0[53]=4127; exp_r1[53]=33023; exp_r2[53]=0; exp_r3[53]=4080; exp_r4[53]=8; exp_r5[53]=36593; exp_r6[53]=7; exp_r7[53]=1; exp_z[53]=0; exp_label[53]="ADC R4,#0";
        exp_pc[54]=19; exp_r0[54]=2063; exp_r1[54]=33023; exp_r2[54]=0; exp_r3[54]=4080; exp_r4[54]=8; exp_r5[54]=36593; exp_r6[54]=7; exp_r7[54]=1; exp_z[54]=0; exp_label[54]="LSR R0,#1";
        exp_pc[55]=8; exp_r0[55]=2063; exp_r1[55]=33023; exp_r2[55]=0; exp_r3[55]=4080; exp_r4[55]=8; exp_r5[55]=36593; exp_r6[55]=7; exp_r7[55]=1; exp_z[55]=0; exp_label[55]="JMP -11";
        exp_pc[56]=9; exp_r0[56]=2063; exp_r1[56]=33023; exp_r2[56]=0; exp_r3[56]=4080; exp_r4[56]=8; exp_r5[56]=36593; exp_r6[56]=7; exp_r7[56]=1; exp_z[56]=0; exp_label[56]="CMP R0,#0";
        exp_pc[57]=10; exp_r0[57]=2063; exp_r1[57]=33023; exp_r2[57]=0; exp_r3[57]=4080; exp_r4[57]=8; exp_r5[57]=36593; exp_r6[57]=7; exp_r7[57]=1; exp_z[57]=0; exp_label[57]="JEQ 11";
        exp_pc[58]=11; exp_r0[58]=2063; exp_r1[58]=33023; exp_r2[58]=0; exp_r3[58]=4080; exp_r4[58]=8; exp_r5[58]=36593; exp_r6[58]=7; exp_r7[58]=2063; exp_z[58]=0; exp_label[58]="MOV R7,R0";
        exp_pc[59]=12; exp_r0[59]=2063; exp_r1[59]=33023; exp_r2[59]=0; exp_r3[59]=4080; exp_r4[59]=8; exp_r5[59]=36593; exp_r6[59]=7; exp_r7[59]=1; exp_z[59]=0; exp_label[59]="AND R7,#1";
        exp_pc[60]=13; exp_r0[60]=2063; exp_r1[60]=33023; exp_r2[60]=0; exp_r3[60]=4080; exp_r4[60]=8; exp_r5[60]=36593; exp_r6[60]=7; exp_r7[60]=1; exp_z[60]=0; exp_label[60]="JEQ 3";
        exp_pc[61]=14; exp_r0[61]=2063; exp_r1[61]=33023; exp_r2[61]=0; exp_r3[61]=4080; exp_r4[61]=8; exp_r5[61]=40673; exp_r6[61]=7; exp_r7[61]=1; exp_z[61]=0; exp_label[61]="ADD R5,R3";
        exp_pc[62]=15; exp_r0[62]=2063; exp_r1[62]=33023; exp_r2[62]=0; exp_r3[62]=4080; exp_r4[62]=8; exp_r5[62]=40673; exp_r6[62]=15; exp_r7[62]=1; exp_z[62]=0; exp_label[62]="ADC R6,R4";
        exp_pc[63]=16; exp_r0[63]=2063; exp_r1[63]=33023; exp_r2[63]=0; exp_r3[63]=4080; exp_r4[63]=16; exp_r5[63]=40673; exp_r6[63]=15; exp_r7[63]=1; exp_z[63]=0; exp_label[63]="LSL R4,#1";
        exp_pc[64]=17; exp_r0[64]=2063; exp_r1[64]=33023; exp_r2[64]=0; exp_r3[64]=8160; exp_r4[64]=16; exp_r5[64]=40673; exp_r6[64]=15; exp_r7[64]=1; exp_z[64]=0; exp_label[64]="LSL R3,#1";
        exp_pc[65]=18; exp_r0[65]=2063; exp_r1[65]=33023; exp_r2[65]=0; exp_r3[65]=8160; exp_r4[65]=16; exp_r5[65]=40673; exp_r6[65]=15; exp_r7[65]=1; exp_z[65]=0; exp_label[65]="ADC R4,#0";
        exp_pc[66]=19; exp_r0[66]=1031; exp_r1[66]=33023; exp_r2[66]=0; exp_r3[66]=8160; exp_r4[66]=16; exp_r5[66]=40673; exp_r6[66]=15; exp_r7[66]=1; exp_z[66]=0; exp_label[66]="LSR R0,#1";
        exp_pc[67]=8; exp_r0[67]=1031; exp_r1[67]=33023; exp_r2[67]=0; exp_r3[67]=8160; exp_r4[67]=16; exp_r5[67]=40673; exp_r6[67]=15; exp_r7[67]=1; exp_z[67]=0; exp_label[67]="JMP -11";
        exp_pc[68]=9; exp_r0[68]=1031; exp_r1[68]=33023; exp_r2[68]=0; exp_r3[68]=8160; exp_r4[68]=16; exp_r5[68]=40673; exp_r6[68]=15; exp_r7[68]=1; exp_z[68]=0; exp_label[68]="CMP R0,#0";
        exp_pc[69]=10; exp_r0[69]=1031; exp_r1[69]=33023; exp_r2[69]=0; exp_r3[69]=8160; exp_r4[69]=16; exp_r5[69]=40673; exp_r6[69]=15; exp_r7[69]=1; exp_z[69]=0; exp_label[69]="JEQ 11";
        exp_pc[70]=11; exp_r0[70]=1031; exp_r1[70]=33023; exp_r2[70]=0; exp_r3[70]=8160; exp_r4[70]=16; exp_r5[70]=40673; exp_r6[70]=15; exp_r7[70]=1031; exp_z[70]=0; exp_label[70]="MOV R7,R0";
        exp_pc[71]=12; exp_r0[71]=1031; exp_r1[71]=33023; exp_r2[71]=0; exp_r3[71]=8160; exp_r4[71]=16; exp_r5[71]=40673; exp_r6[71]=15; exp_r7[71]=1; exp_z[71]=0; exp_label[71]="AND R7,#1";
        exp_pc[72]=13; exp_r0[72]=1031; exp_r1[72]=33023; exp_r2[72]=0; exp_r3[72]=8160; exp_r4[72]=16; exp_r5[72]=40673; exp_r6[72]=15; exp_r7[72]=1; exp_z[72]=0; exp_label[72]="JEQ 3";
        exp_pc[73]=14; exp_r0[73]=1031; exp_r1[73]=33023; exp_r2[73]=0; exp_r3[73]=8160; exp_r4[73]=16; exp_r5[73]=48833; exp_r6[73]=15; exp_r7[73]=1; exp_z[73]=0; exp_label[73]="ADD R5,R3";
        exp_pc[74]=15; exp_r0[74]=1031; exp_r1[74]=33023; exp_r2[74]=0; exp_r3[74]=8160; exp_r4[74]=16; exp_r5[74]=48833; exp_r6[74]=31; exp_r7[74]=1; exp_z[74]=0; exp_label[74]="ADC R6,R4";
        exp_pc[75]=16; exp_r0[75]=1031; exp_r1[75]=33023; exp_r2[75]=0; exp_r3[75]=8160; exp_r4[75]=32; exp_r5[75]=48833; exp_r6[75]=31; exp_r7[75]=1; exp_z[75]=0; exp_label[75]="LSL R4,#1";
        exp_pc[76]=17; exp_r0[76]=1031; exp_r1[76]=33023; exp_r2[76]=0; exp_r3[76]=16320; exp_r4[76]=32; exp_r5[76]=48833; exp_r6[76]=31; exp_r7[76]=1; exp_z[76]=0; exp_label[76]="LSL R3,#1";
        exp_pc[77]=18; exp_r0[77]=1031; exp_r1[77]=33023; exp_r2[77]=0; exp_r3[77]=16320; exp_r4[77]=32; exp_r5[77]=48833; exp_r6[77]=31; exp_r7[77]=1; exp_z[77]=0; exp_label[77]="ADC R4,#0";
        exp_pc[78]=19; exp_r0[78]=515; exp_r1[78]=33023; exp_r2[78]=0; exp_r3[78]=16320; exp_r4[78]=32; exp_r5[78]=48833; exp_r6[78]=31; exp_r7[78]=1; exp_z[78]=0; exp_label[78]="LSR R0,#1";
        exp_pc[79]=8; exp_r0[79]=515; exp_r1[79]=33023; exp_r2[79]=0; exp_r3[79]=16320; exp_r4[79]=32; exp_r5[79]=48833; exp_r6[79]=31; exp_r7[79]=1; exp_z[79]=0; exp_label[79]="JMP -11";
        exp_pc[80]=9; exp_r0[80]=515; exp_r1[80]=33023; exp_r2[80]=0; exp_r3[80]=16320; exp_r4[80]=32; exp_r5[80]=48833; exp_r6[80]=31; exp_r7[80]=1; exp_z[80]=0; exp_label[80]="CMP R0,#0";
        exp_pc[81]=10; exp_r0[81]=515; exp_r1[81]=33023; exp_r2[81]=0; exp_r3[81]=16320; exp_r4[81]=32; exp_r5[81]=48833; exp_r6[81]=31; exp_r7[81]=1; exp_z[81]=0; exp_label[81]="JEQ 11";
        exp_pc[82]=11; exp_r0[82]=515; exp_r1[82]=33023; exp_r2[82]=0; exp_r3[82]=16320; exp_r4[82]=32; exp_r5[82]=48833; exp_r6[82]=31; exp_r7[82]=515; exp_z[82]=0; exp_label[82]="MOV R7,R0";
        exp_pc[83]=12; exp_r0[83]=515; exp_r1[83]=33023; exp_r2[83]=0; exp_r3[83]=16320; exp_r4[83]=32; exp_r5[83]=48833; exp_r6[83]=31; exp_r7[83]=1; exp_z[83]=0; exp_label[83]="AND R7,#1";
        exp_pc[84]=13; exp_r0[84]=515; exp_r1[84]=33023; exp_r2[84]=0; exp_r3[84]=16320; exp_r4[84]=32; exp_r5[84]=48833; exp_r6[84]=31; exp_r7[84]=1; exp_z[84]=0; exp_label[84]="JEQ 3";
        exp_pc[85]=14; exp_r0[85]=515; exp_r1[85]=33023; exp_r2[85]=0; exp_r3[85]=16320; exp_r4[85]=32; exp_r5[85]=65153; exp_r6[85]=31; exp_r7[85]=1; exp_z[85]=0; exp_label[85]="ADD R5,R3";
        exp_pc[86]=15; exp_r0[86]=515; exp_r1[86]=33023; exp_r2[86]=0; exp_r3[86]=16320; exp_r4[86]=32; exp_r5[86]=65153; exp_r6[86]=63; exp_r7[86]=1; exp_z[86]=0; exp_label[86]="ADC R6,R4";
        exp_pc[87]=16; exp_r0[87]=515; exp_r1[87]=33023; exp_r2[87]=0; exp_r3[87]=16320; exp_r4[87]=64; exp_r5[87]=65153; exp_r6[87]=63; exp_r7[87]=1; exp_z[87]=0; exp_label[87]="LSL R4,#1";
        exp_pc[88]=17; exp_r0[88]=515; exp_r1[88]=33023; exp_r2[88]=0; exp_r3[88]=32640; exp_r4[88]=64; exp_r5[88]=65153; exp_r6[88]=63; exp_r7[88]=1; exp_z[88]=0; exp_label[88]="LSL R3,#1";
        exp_pc[89]=18; exp_r0[89]=515; exp_r1[89]=33023; exp_r2[89]=0; exp_r3[89]=32640; exp_r4[89]=64; exp_r5[89]=65153; exp_r6[89]=63; exp_r7[89]=1; exp_z[89]=0; exp_label[89]="ADC R4,#0";
        exp_pc[90]=19; exp_r0[90]=257; exp_r1[90]=33023; exp_r2[90]=0; exp_r3[90]=32640; exp_r4[90]=64; exp_r5[90]=65153; exp_r6[90]=63; exp_r7[90]=1; exp_z[90]=0; exp_label[90]="LSR R0,#1";
        exp_pc[91]=8; exp_r0[91]=257; exp_r1[91]=33023; exp_r2[91]=0; exp_r3[91]=32640; exp_r4[91]=64; exp_r5[91]=65153; exp_r6[91]=63; exp_r7[91]=1; exp_z[91]=0; exp_label[91]="JMP -11";
        exp_pc[92]=9; exp_r0[92]=257; exp_r1[92]=33023; exp_r2[92]=0; exp_r3[92]=32640; exp_r4[92]=64; exp_r5[92]=65153; exp_r6[92]=63; exp_r7[92]=1; exp_z[92]=0; exp_label[92]="CMP R0,#0";
        exp_pc[93]=10; exp_r0[93]=257; exp_r1[93]=33023; exp_r2[93]=0; exp_r3[93]=32640; exp_r4[93]=64; exp_r5[93]=65153; exp_r6[93]=63; exp_r7[93]=1; exp_z[93]=0; exp_label[93]="JEQ 11";
        exp_pc[94]=11; exp_r0[94]=257; exp_r1[94]=33023; exp_r2[94]=0; exp_r3[94]=32640; exp_r4[94]=64; exp_r5[94]=65153; exp_r6[94]=63; exp_r7[94]=257; exp_z[94]=0; exp_label[94]="MOV R7,R0";
        exp_pc[95]=12; exp_r0[95]=257; exp_r1[95]=33023; exp_r2[95]=0; exp_r3[95]=32640; exp_r4[95]=64; exp_r5[95]=65153; exp_r6[95]=63; exp_r7[95]=1; exp_z[95]=0; exp_label[95]="AND R7,#1";
        exp_pc[96]=13; exp_r0[96]=257; exp_r1[96]=33023; exp_r2[96]=0; exp_r3[96]=32640; exp_r4[96]=64; exp_r5[96]=65153; exp_r6[96]=63; exp_r7[96]=1; exp_z[96]=0; exp_label[96]="JEQ 3";
        exp_pc[97]=14; exp_r0[97]=257; exp_r1[97]=33023; exp_r2[97]=0; exp_r3[97]=32640; exp_r4[97]=64; exp_r5[97]=32257; exp_r6[97]=63; exp_r7[97]=1; exp_z[97]=0; exp_label[97]="ADD R5,R3";
        exp_pc[98]=15; exp_r0[98]=257; exp_r1[98]=33023; exp_r2[98]=0; exp_r3[98]=32640; exp_r4[98]=64; exp_r5[98]=32257; exp_r6[98]=128; exp_r7[98]=1; exp_z[98]=0; exp_label[98]="ADC R6,R4";
        exp_pc[99]=16; exp_r0[99]=257; exp_r1[99]=33023; exp_r2[99]=0; exp_r3[99]=32640; exp_r4[99]=128; exp_r5[99]=32257; exp_r6[99]=128; exp_r7[99]=1; exp_z[99]=0; exp_label[99]="LSL R4,#1";
        exp_pc[100]=17; exp_r0[100]=257; exp_r1[100]=33023; exp_r2[100]=0; exp_r3[100]=65280; exp_r4[100]=128; exp_r5[100]=32257; exp_r6[100]=128; exp_r7[100]=1; exp_z[100]=0; exp_label[100]="LSL R3,#1";
        exp_pc[101]=18; exp_r0[101]=257; exp_r1[101]=33023; exp_r2[101]=0; exp_r3[101]=65280; exp_r4[101]=128; exp_r5[101]=32257; exp_r6[101]=128; exp_r7[101]=1; exp_z[101]=0; exp_label[101]="ADC R4,#0";
        exp_pc[102]=19; exp_r0[102]=128; exp_r1[102]=33023; exp_r2[102]=0; exp_r3[102]=65280; exp_r4[102]=128; exp_r5[102]=32257; exp_r6[102]=128; exp_r7[102]=1; exp_z[102]=0; exp_label[102]="LSR R0,#1";
        exp_pc[103]=8; exp_r0[103]=128; exp_r1[103]=33023; exp_r2[103]=0; exp_r3[103]=65280; exp_r4[103]=128; exp_r5[103]=32257; exp_r6[103]=128; exp_r7[103]=1; exp_z[103]=0; exp_label[103]="JMP -11";
        exp_pc[104]=9; exp_r0[104]=128; exp_r1[104]=33023; exp_r2[104]=0; exp_r3[104]=65280; exp_r4[104]=128; exp_r5[104]=32257; exp_r6[104]=128; exp_r7[104]=1; exp_z[104]=0; exp_label[104]="CMP R0,#0";
        exp_pc[105]=10; exp_r0[105]=128; exp_r1[105]=33023; exp_r2[105]=0; exp_r3[105]=65280; exp_r4[105]=128; exp_r5[105]=32257; exp_r6[105]=128; exp_r7[105]=1; exp_z[105]=0; exp_label[105]="JEQ 11";
        exp_pc[106]=11; exp_r0[106]=128; exp_r1[106]=33023; exp_r2[106]=0; exp_r3[106]=65280; exp_r4[106]=128; exp_r5[106]=32257; exp_r6[106]=128; exp_r7[106]=128; exp_z[106]=0; exp_label[106]="MOV R7,R0";
        exp_pc[107]=12; exp_r0[107]=128; exp_r1[107]=33023; exp_r2[107]=0; exp_r3[107]=65280; exp_r4[107]=128; exp_r5[107]=32257; exp_r6[107]=128; exp_r7[107]=0; exp_z[107]=1; exp_label[107]="AND R7,#1";
        exp_pc[108]=15; exp_r0[108]=128; exp_r1[108]=33023; exp_r2[108]=0; exp_r3[108]=65280; exp_r4[108]=128; exp_r5[108]=32257; exp_r6[108]=128; exp_r7[108]=0; exp_z[108]=1; exp_label[108]="JEQ 3";
        exp_pc[109]=16; exp_r0[109]=128; exp_r1[109]=33023; exp_r2[109]=0; exp_r3[109]=65280; exp_r4[109]=256; exp_r5[109]=32257; exp_r6[109]=128; exp_r7[109]=0; exp_z[109]=0; exp_label[109]="LSL R4,#1";
        exp_pc[110]=17; exp_r0[110]=128; exp_r1[110]=33023; exp_r2[110]=0; exp_r3[110]=65024; exp_r4[110]=256; exp_r5[110]=32257; exp_r6[110]=128; exp_r7[110]=0; exp_z[110]=0; exp_label[110]="LSL R3,#1";
        exp_pc[111]=18; exp_r0[111]=128; exp_r1[111]=33023; exp_r2[111]=0; exp_r3[111]=65024; exp_r4[111]=257; exp_r5[111]=32257; exp_r6[111]=128; exp_r7[111]=0; exp_z[111]=0; exp_label[111]="ADC R4,#0";
        exp_pc[112]=19; exp_r0[112]=64; exp_r1[112]=33023; exp_r2[112]=0; exp_r3[112]=65024; exp_r4[112]=257; exp_r5[112]=32257; exp_r6[112]=128; exp_r7[112]=0; exp_z[112]=0; exp_label[112]="LSR R0,#1";
        exp_pc[113]=8; exp_r0[113]=64; exp_r1[113]=33023; exp_r2[113]=0; exp_r3[113]=65024; exp_r4[113]=257; exp_r5[113]=32257; exp_r6[113]=128; exp_r7[113]=0; exp_z[113]=0; exp_label[113]="JMP -11";
        exp_pc[114]=9; exp_r0[114]=64; exp_r1[114]=33023; exp_r2[114]=0; exp_r3[114]=65024; exp_r4[114]=257; exp_r5[114]=32257; exp_r6[114]=128; exp_r7[114]=0; exp_z[114]=0; exp_label[114]="CMP R0,#0";
        exp_pc[115]=10; exp_r0[115]=64; exp_r1[115]=33023; exp_r2[115]=0; exp_r3[115]=65024; exp_r4[115]=257; exp_r5[115]=32257; exp_r6[115]=128; exp_r7[115]=0; exp_z[115]=0; exp_label[115]="JEQ 11";
        exp_pc[116]=11; exp_r0[116]=64; exp_r1[116]=33023; exp_r2[116]=0; exp_r3[116]=65024; exp_r4[116]=257; exp_r5[116]=32257; exp_r6[116]=128; exp_r7[116]=64; exp_z[116]=0; exp_label[116]="MOV R7,R0";
        exp_pc[117]=12; exp_r0[117]=64; exp_r1[117]=33023; exp_r2[117]=0; exp_r3[117]=65024; exp_r4[117]=257; exp_r5[117]=32257; exp_r6[117]=128; exp_r7[117]=0; exp_z[117]=1; exp_label[117]="AND R7,#1";
        exp_pc[118]=15; exp_r0[118]=64; exp_r1[118]=33023; exp_r2[118]=0; exp_r3[118]=65024; exp_r4[118]=257; exp_r5[118]=32257; exp_r6[118]=128; exp_r7[118]=0; exp_z[118]=1; exp_label[118]="JEQ 3";
        exp_pc[119]=16; exp_r0[119]=64; exp_r1[119]=33023; exp_r2[119]=0; exp_r3[119]=65024; exp_r4[119]=514; exp_r5[119]=32257; exp_r6[119]=128; exp_r7[119]=0; exp_z[119]=0; exp_label[119]="LSL R4,#1";
        exp_pc[120]=17; exp_r0[120]=64; exp_r1[120]=33023; exp_r2[120]=0; exp_r3[120]=64512; exp_r4[120]=514; exp_r5[120]=32257; exp_r6[120]=128; exp_r7[120]=0; exp_z[120]=0; exp_label[120]="LSL R3,#1";
        exp_pc[121]=18; exp_r0[121]=64; exp_r1[121]=33023; exp_r2[121]=0; exp_r3[121]=64512; exp_r4[121]=515; exp_r5[121]=32257; exp_r6[121]=128; exp_r7[121]=0; exp_z[121]=0; exp_label[121]="ADC R4,#0";
        exp_pc[122]=19; exp_r0[122]=32; exp_r1[122]=33023; exp_r2[122]=0; exp_r3[122]=64512; exp_r4[122]=515; exp_r5[122]=32257; exp_r6[122]=128; exp_r7[122]=0; exp_z[122]=0; exp_label[122]="LSR R0,#1";
        exp_pc[123]=8; exp_r0[123]=32; exp_r1[123]=33023; exp_r2[123]=0; exp_r3[123]=64512; exp_r4[123]=515; exp_r5[123]=32257; exp_r6[123]=128; exp_r7[123]=0; exp_z[123]=0; exp_label[123]="JMP -11";
        exp_pc[124]=9; exp_r0[124]=32; exp_r1[124]=33023; exp_r2[124]=0; exp_r3[124]=64512; exp_r4[124]=515; exp_r5[124]=32257; exp_r6[124]=128; exp_r7[124]=0; exp_z[124]=0; exp_label[124]="CMP R0,#0";
        exp_pc[125]=10; exp_r0[125]=32; exp_r1[125]=33023; exp_r2[125]=0; exp_r3[125]=64512; exp_r4[125]=515; exp_r5[125]=32257; exp_r6[125]=128; exp_r7[125]=0; exp_z[125]=0; exp_label[125]="JEQ 11";
        exp_pc[126]=11; exp_r0[126]=32; exp_r1[126]=33023; exp_r2[126]=0; exp_r3[126]=64512; exp_r4[126]=515; exp_r5[126]=32257; exp_r6[126]=128; exp_r7[126]=32; exp_z[126]=0; exp_label[126]="MOV R7,R0";
        exp_pc[127]=12; exp_r0[127]=32; exp_r1[127]=33023; exp_r2[127]=0; exp_r3[127]=64512; exp_r4[127]=515; exp_r5[127]=32257; exp_r6[127]=128; exp_r7[127]=0; exp_z[127]=1; exp_label[127]="AND R7,#1";
        exp_pc[128]=15; exp_r0[128]=32; exp_r1[128]=33023; exp_r2[128]=0; exp_r3[128]=64512; exp_r4[128]=515; exp_r5[128]=32257; exp_r6[128]=128; exp_r7[128]=0; exp_z[128]=1; exp_label[128]="JEQ 3";
        exp_pc[129]=16; exp_r0[129]=32; exp_r1[129]=33023; exp_r2[129]=0; exp_r3[129]=64512; exp_r4[129]=1030; exp_r5[129]=32257; exp_r6[129]=128; exp_r7[129]=0; exp_z[129]=0; exp_label[129]="LSL R4,#1";
        exp_pc[130]=17; exp_r0[130]=32; exp_r1[130]=33023; exp_r2[130]=0; exp_r3[130]=63488; exp_r4[130]=1030; exp_r5[130]=32257; exp_r6[130]=128; exp_r7[130]=0; exp_z[130]=0; exp_label[130]="LSL R3,#1";
        exp_pc[131]=18; exp_r0[131]=32; exp_r1[131]=33023; exp_r2[131]=0; exp_r3[131]=63488; exp_r4[131]=1031; exp_r5[131]=32257; exp_r6[131]=128; exp_r7[131]=0; exp_z[131]=0; exp_label[131]="ADC R4,#0";
        exp_pc[132]=19; exp_r0[132]=16; exp_r1[132]=33023; exp_r2[132]=0; exp_r3[132]=63488; exp_r4[132]=1031; exp_r5[132]=32257; exp_r6[132]=128; exp_r7[132]=0; exp_z[132]=0; exp_label[132]="LSR R0,#1";
        exp_pc[133]=8; exp_r0[133]=16; exp_r1[133]=33023; exp_r2[133]=0; exp_r3[133]=63488; exp_r4[133]=1031; exp_r5[133]=32257; exp_r6[133]=128; exp_r7[133]=0; exp_z[133]=0; exp_label[133]="JMP -11";
        exp_pc[134]=9; exp_r0[134]=16; exp_r1[134]=33023; exp_r2[134]=0; exp_r3[134]=63488; exp_r4[134]=1031; exp_r5[134]=32257; exp_r6[134]=128; exp_r7[134]=0; exp_z[134]=0; exp_label[134]="CMP R0,#0";
        exp_pc[135]=10; exp_r0[135]=16; exp_r1[135]=33023; exp_r2[135]=0; exp_r3[135]=63488; exp_r4[135]=1031; exp_r5[135]=32257; exp_r6[135]=128; exp_r7[135]=0; exp_z[135]=0; exp_label[135]="JEQ 11";
        exp_pc[136]=11; exp_r0[136]=16; exp_r1[136]=33023; exp_r2[136]=0; exp_r3[136]=63488; exp_r4[136]=1031; exp_r5[136]=32257; exp_r6[136]=128; exp_r7[136]=16; exp_z[136]=0; exp_label[136]="MOV R7,R0";
        exp_pc[137]=12; exp_r0[137]=16; exp_r1[137]=33023; exp_r2[137]=0; exp_r3[137]=63488; exp_r4[137]=1031; exp_r5[137]=32257; exp_r6[137]=128; exp_r7[137]=0; exp_z[137]=1; exp_label[137]="AND R7,#1";
        exp_pc[138]=15; exp_r0[138]=16; exp_r1[138]=33023; exp_r2[138]=0; exp_r3[138]=63488; exp_r4[138]=1031; exp_r5[138]=32257; exp_r6[138]=128; exp_r7[138]=0; exp_z[138]=1; exp_label[138]="JEQ 3";
        exp_pc[139]=16; exp_r0[139]=16; exp_r1[139]=33023; exp_r2[139]=0; exp_r3[139]=63488; exp_r4[139]=2062; exp_r5[139]=32257; exp_r6[139]=128; exp_r7[139]=0; exp_z[139]=0; exp_label[139]="LSL R4,#1";
        exp_pc[140]=17; exp_r0[140]=16; exp_r1[140]=33023; exp_r2[140]=0; exp_r3[140]=61440; exp_r4[140]=2062; exp_r5[140]=32257; exp_r6[140]=128; exp_r7[140]=0; exp_z[140]=0; exp_label[140]="LSL R3,#1";
        exp_pc[141]=18; exp_r0[141]=16; exp_r1[141]=33023; exp_r2[141]=0; exp_r3[141]=61440; exp_r4[141]=2063; exp_r5[141]=32257; exp_r6[141]=128; exp_r7[141]=0; exp_z[141]=0; exp_label[141]="ADC R4,#0";
        exp_pc[142]=19; exp_r0[142]=8; exp_r1[142]=33023; exp_r2[142]=0; exp_r3[142]=61440; exp_r4[142]=2063; exp_r5[142]=32257; exp_r6[142]=128; exp_r7[142]=0; exp_z[142]=0; exp_label[142]="LSR R0,#1";
        exp_pc[143]=8; exp_r0[143]=8; exp_r1[143]=33023; exp_r2[143]=0; exp_r3[143]=61440; exp_r4[143]=2063; exp_r5[143]=32257; exp_r6[143]=128; exp_r7[143]=0; exp_z[143]=0; exp_label[143]="JMP -11";
        exp_pc[144]=9; exp_r0[144]=8; exp_r1[144]=33023; exp_r2[144]=0; exp_r3[144]=61440; exp_r4[144]=2063; exp_r5[144]=32257; exp_r6[144]=128; exp_r7[144]=0; exp_z[144]=0; exp_label[144]="CMP R0,#0";
        exp_pc[145]=10; exp_r0[145]=8; exp_r1[145]=33023; exp_r2[145]=0; exp_r3[145]=61440; exp_r4[145]=2063; exp_r5[145]=32257; exp_r6[145]=128; exp_r7[145]=0; exp_z[145]=0; exp_label[145]="JEQ 11";
        exp_pc[146]=11; exp_r0[146]=8; exp_r1[146]=33023; exp_r2[146]=0; exp_r3[146]=61440; exp_r4[146]=2063; exp_r5[146]=32257; exp_r6[146]=128; exp_r7[146]=8; exp_z[146]=0; exp_label[146]="MOV R7,R0";
        exp_pc[147]=12; exp_r0[147]=8; exp_r1[147]=33023; exp_r2[147]=0; exp_r3[147]=61440; exp_r4[147]=2063; exp_r5[147]=32257; exp_r6[147]=128; exp_r7[147]=0; exp_z[147]=1; exp_label[147]="AND R7,#1";
        exp_pc[148]=15; exp_r0[148]=8; exp_r1[148]=33023; exp_r2[148]=0; exp_r3[148]=61440; exp_r4[148]=2063; exp_r5[148]=32257; exp_r6[148]=128; exp_r7[148]=0; exp_z[148]=1; exp_label[148]="JEQ 3";
        exp_pc[149]=16; exp_r0[149]=8; exp_r1[149]=33023; exp_r2[149]=0; exp_r3[149]=61440; exp_r4[149]=4126; exp_r5[149]=32257; exp_r6[149]=128; exp_r7[149]=0; exp_z[149]=0; exp_label[149]="LSL R4,#1";
        exp_pc[150]=17; exp_r0[150]=8; exp_r1[150]=33023; exp_r2[150]=0; exp_r3[150]=57344; exp_r4[150]=4126; exp_r5[150]=32257; exp_r6[150]=128; exp_r7[150]=0; exp_z[150]=0; exp_label[150]="LSL R3,#1";
        exp_pc[151]=18; exp_r0[151]=8; exp_r1[151]=33023; exp_r2[151]=0; exp_r3[151]=57344; exp_r4[151]=4127; exp_r5[151]=32257; exp_r6[151]=128; exp_r7[151]=0; exp_z[151]=0; exp_label[151]="ADC R4,#0";
        exp_pc[152]=19; exp_r0[152]=4; exp_r1[152]=33023; exp_r2[152]=0; exp_r3[152]=57344; exp_r4[152]=4127; exp_r5[152]=32257; exp_r6[152]=128; exp_r7[152]=0; exp_z[152]=0; exp_label[152]="LSR R0,#1";
        exp_pc[153]=8; exp_r0[153]=4; exp_r1[153]=33023; exp_r2[153]=0; exp_r3[153]=57344; exp_r4[153]=4127; exp_r5[153]=32257; exp_r6[153]=128; exp_r7[153]=0; exp_z[153]=0; exp_label[153]="JMP -11";
        exp_pc[154]=9; exp_r0[154]=4; exp_r1[154]=33023; exp_r2[154]=0; exp_r3[154]=57344; exp_r4[154]=4127; exp_r5[154]=32257; exp_r6[154]=128; exp_r7[154]=0; exp_z[154]=0; exp_label[154]="CMP R0,#0";
        exp_pc[155]=10; exp_r0[155]=4; exp_r1[155]=33023; exp_r2[155]=0; exp_r3[155]=57344; exp_r4[155]=4127; exp_r5[155]=32257; exp_r6[155]=128; exp_r7[155]=0; exp_z[155]=0; exp_label[155]="JEQ 11";
        exp_pc[156]=11; exp_r0[156]=4; exp_r1[156]=33023; exp_r2[156]=0; exp_r3[156]=57344; exp_r4[156]=4127; exp_r5[156]=32257; exp_r6[156]=128; exp_r7[156]=4; exp_z[156]=0; exp_label[156]="MOV R7,R0";
        exp_pc[157]=12; exp_r0[157]=4; exp_r1[157]=33023; exp_r2[157]=0; exp_r3[157]=57344; exp_r4[157]=4127; exp_r5[157]=32257; exp_r6[157]=128; exp_r7[157]=0; exp_z[157]=1; exp_label[157]="AND R7,#1";
        exp_pc[158]=15; exp_r0[158]=4; exp_r1[158]=33023; exp_r2[158]=0; exp_r3[158]=57344; exp_r4[158]=4127; exp_r5[158]=32257; exp_r6[158]=128; exp_r7[158]=0; exp_z[158]=1; exp_label[158]="JEQ 3";
        exp_pc[159]=16; exp_r0[159]=4; exp_r1[159]=33023; exp_r2[159]=0; exp_r3[159]=57344; exp_r4[159]=8254; exp_r5[159]=32257; exp_r6[159]=128; exp_r7[159]=0; exp_z[159]=0; exp_label[159]="LSL R4,#1";
        exp_pc[160]=17; exp_r0[160]=4; exp_r1[160]=33023; exp_r2[160]=0; exp_r3[160]=49152; exp_r4[160]=8254; exp_r5[160]=32257; exp_r6[160]=128; exp_r7[160]=0; exp_z[160]=0; exp_label[160]="LSL R3,#1";
        exp_pc[161]=18; exp_r0[161]=4; exp_r1[161]=33023; exp_r2[161]=0; exp_r3[161]=49152; exp_r4[161]=8255; exp_r5[161]=32257; exp_r6[161]=128; exp_r7[161]=0; exp_z[161]=0; exp_label[161]="ADC R4,#0";
        exp_pc[162]=19; exp_r0[162]=2; exp_r1[162]=33023; exp_r2[162]=0; exp_r3[162]=49152; exp_r4[162]=8255; exp_r5[162]=32257; exp_r6[162]=128; exp_r7[162]=0; exp_z[162]=0; exp_label[162]="LSR R0,#1";
        exp_pc[163]=8; exp_r0[163]=2; exp_r1[163]=33023; exp_r2[163]=0; exp_r3[163]=49152; exp_r4[163]=8255; exp_r5[163]=32257; exp_r6[163]=128; exp_r7[163]=0; exp_z[163]=0; exp_label[163]="JMP -11";
        exp_pc[164]=9; exp_r0[164]=2; exp_r1[164]=33023; exp_r2[164]=0; exp_r3[164]=49152; exp_r4[164]=8255; exp_r5[164]=32257; exp_r6[164]=128; exp_r7[164]=0; exp_z[164]=0; exp_label[164]="CMP R0,#0";
        exp_pc[165]=10; exp_r0[165]=2; exp_r1[165]=33023; exp_r2[165]=0; exp_r3[165]=49152; exp_r4[165]=8255; exp_r5[165]=32257; exp_r6[165]=128; exp_r7[165]=0; exp_z[165]=0; exp_label[165]="JEQ 11";
        exp_pc[166]=11; exp_r0[166]=2; exp_r1[166]=33023; exp_r2[166]=0; exp_r3[166]=49152; exp_r4[166]=8255; exp_r5[166]=32257; exp_r6[166]=128; exp_r7[166]=2; exp_z[166]=0; exp_label[166]="MOV R7,R0";
        exp_pc[167]=12; exp_r0[167]=2; exp_r1[167]=33023; exp_r2[167]=0; exp_r3[167]=49152; exp_r4[167]=8255; exp_r5[167]=32257; exp_r6[167]=128; exp_r7[167]=0; exp_z[167]=1; exp_label[167]="AND R7,#1";
        exp_pc[168]=15; exp_r0[168]=2; exp_r1[168]=33023; exp_r2[168]=0; exp_r3[168]=49152; exp_r4[168]=8255; exp_r5[168]=32257; exp_r6[168]=128; exp_r7[168]=0; exp_z[168]=1; exp_label[168]="JEQ 3";
        exp_pc[169]=16; exp_r0[169]=2; exp_r1[169]=33023; exp_r2[169]=0; exp_r3[169]=49152; exp_r4[169]=16510; exp_r5[169]=32257; exp_r6[169]=128; exp_r7[169]=0; exp_z[169]=0; exp_label[169]="LSL R4,#1";
        exp_pc[170]=17; exp_r0[170]=2; exp_r1[170]=33023; exp_r2[170]=0; exp_r3[170]=32768; exp_r4[170]=16510; exp_r5[170]=32257; exp_r6[170]=128; exp_r7[170]=0; exp_z[170]=0; exp_label[170]="LSL R3,#1";
        exp_pc[171]=18; exp_r0[171]=2; exp_r1[171]=33023; exp_r2[171]=0; exp_r3[171]=32768; exp_r4[171]=16511; exp_r5[171]=32257; exp_r6[171]=128; exp_r7[171]=0; exp_z[171]=0; exp_label[171]="ADC R4,#0";
        exp_pc[172]=19; exp_r0[172]=1; exp_r1[172]=33023; exp_r2[172]=0; exp_r3[172]=32768; exp_r4[172]=16511; exp_r5[172]=32257; exp_r6[172]=128; exp_r7[172]=0; exp_z[172]=0; exp_label[172]="LSR R0,#1";
        exp_pc[173]=8; exp_r0[173]=1; exp_r1[173]=33023; exp_r2[173]=0; exp_r3[173]=32768; exp_r4[173]=16511; exp_r5[173]=32257; exp_r6[173]=128; exp_r7[173]=0; exp_z[173]=0; exp_label[173]="JMP -11";
        exp_pc[174]=9; exp_r0[174]=1; exp_r1[174]=33023; exp_r2[174]=0; exp_r3[174]=32768; exp_r4[174]=16511; exp_r5[174]=32257; exp_r6[174]=128; exp_r7[174]=0; exp_z[174]=0; exp_label[174]="CMP R0,#0";
        exp_pc[175]=10; exp_r0[175]=1; exp_r1[175]=33023; exp_r2[175]=0; exp_r3[175]=32768; exp_r4[175]=16511; exp_r5[175]=32257; exp_r6[175]=128; exp_r7[175]=0; exp_z[175]=0; exp_label[175]="JEQ 11";
        exp_pc[176]=11; exp_r0[176]=1; exp_r1[176]=33023; exp_r2[176]=0; exp_r3[176]=32768; exp_r4[176]=16511; exp_r5[176]=32257; exp_r6[176]=128; exp_r7[176]=1; exp_z[176]=0; exp_label[176]="MOV R7,R0";
        exp_pc[177]=12; exp_r0[177]=1; exp_r1[177]=33023; exp_r2[177]=0; exp_r3[177]=32768; exp_r4[177]=16511; exp_r5[177]=32257; exp_r6[177]=128; exp_r7[177]=1; exp_z[177]=0; exp_label[177]="AND R7,#1";
        exp_pc[178]=13; exp_r0[178]=1; exp_r1[178]=33023; exp_r2[178]=0; exp_r3[178]=32768; exp_r4[178]=16511; exp_r5[178]=32257; exp_r6[178]=128; exp_r7[178]=1; exp_z[178]=0; exp_label[178]="JEQ 3";
        exp_pc[179]=14; exp_r0[179]=1; exp_r1[179]=33023; exp_r2[179]=0; exp_r3[179]=32768; exp_r4[179]=16511; exp_r5[179]=65025; exp_r6[179]=128; exp_r7[179]=1; exp_z[179]=0; exp_label[179]="ADD R5,R3";
        exp_pc[180]=15; exp_r0[180]=1; exp_r1[180]=33023; exp_r2[180]=0; exp_r3[180]=32768; exp_r4[180]=16511; exp_r5[180]=65025; exp_r6[180]=16639; exp_r7[180]=1; exp_z[180]=0; exp_label[180]="ADC R6,R4";
        exp_pc[181]=16; exp_r0[181]=1; exp_r1[181]=33023; exp_r2[181]=0; exp_r3[181]=32768; exp_r4[181]=33022; exp_r5[181]=65025; exp_r6[181]=16639; exp_r7[181]=1; exp_z[181]=0; exp_label[181]="LSL R4,#1";
        exp_pc[182]=17; exp_r0[182]=1; exp_r1[182]=33023; exp_r2[182]=0; exp_r3[182]=0; exp_r4[182]=33022; exp_r5[182]=65025; exp_r6[182]=16639; exp_r7[182]=1; exp_z[182]=1; exp_label[182]="LSL R3,#1";
        exp_pc[183]=18; exp_r0[183]=1; exp_r1[183]=33023; exp_r2[183]=0; exp_r3[183]=0; exp_r4[183]=33023; exp_r5[183]=65025; exp_r6[183]=16639; exp_r7[183]=1; exp_z[183]=0; exp_label[183]="ADC R4,#0";
        exp_pc[184]=19; exp_r0[184]=0; exp_r1[184]=33023; exp_r2[184]=0; exp_r3[184]=0; exp_r4[184]=33023; exp_r5[184]=65025; exp_r6[184]=16639; exp_r7[184]=1; exp_z[184]=1; exp_label[184]="LSR R0,#1";
        exp_pc[185]=8; exp_r0[185]=0; exp_r1[185]=33023; exp_r2[185]=0; exp_r3[185]=0; exp_r4[185]=33023; exp_r5[185]=65025; exp_r6[185]=16639; exp_r7[185]=1; exp_z[185]=1; exp_label[185]="JMP -11";
        exp_pc[186]=9; exp_r0[186]=0; exp_r1[186]=33023; exp_r2[186]=0; exp_r3[186]=0; exp_r4[186]=33023; exp_r5[186]=65025; exp_r6[186]=16639; exp_r7[186]=1; exp_z[186]=1; exp_label[186]="CMP R0,#0";
        exp_pc[187]=20; exp_r0[187]=0; exp_r1[187]=33023; exp_r2[187]=0; exp_r3[187]=0; exp_r4[187]=33023; exp_r5[187]=65025; exp_r6[187]=16639; exp_r7[187]=1; exp_z[187]=1; exp_label[187]="JEQ 11";

        // load program into CODEMEM before releasing reset
        rst = 1;
        for (int i = 0; i < PROG_LEN; i++)
            dut.codemem.MEM[i] = PROGRAM[i];

        // Hold reset across two full rising edges, then deassert on a
        // negedge (safely away from the next posedge) to avoid a race
        // between this testbench and the DUT's always_ff blocks.
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        for (cyc = 0; cyc < NUM_CYCLES; cyc++) begin
            @(posedge clk);
            #1; // let combinational logic (INS, ALUOUT, NEXT block) settle
            check(PC_dbg, R0_dbg, R1_dbg, R2_dbg, R3_dbg, R4_dbg, R5_dbg, R6_dbg, R7_dbg, FLAGZ_dbg, cyc);
        end

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED -- R6:R5 = %0d (expect 1090518529 = 33023*33023)", {R6_dbg, R5_dbg});
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule