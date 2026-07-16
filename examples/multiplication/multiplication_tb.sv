//See multiplication.md for explanation

`timescale 1ns/1ps

module MUL_tb;

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
    logic [15:0] R0_dbg, R1_dbg, R2_dbg, R3_dbg, R4_dbg;
    assign R0_dbg = dut.datapath.reg16x8.REG[0];
    assign R1_dbg = dut.datapath.reg16x8.REG[1];
    assign R2_dbg = dut.datapath.reg16x8.REG[2];
    assign R3_dbg = dut.datapath.reg16x8.REG[3];
    assign R4_dbg = dut.datapath.reg16x8.REG[4];

    //decode/write debug taps -- to diagnose R0 being clobbered
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

    localparam int PROG_LEN = 13;
    logic [15:0] PROGRAM [0:PROG_LEN-1];

    initial begin
        PROGRAM[0]  = 16'h010c; // MOV R0,#12
        PROGRAM[1]  = 16'h0305; // MOV R1,#5
        PROGRAM[2]  = 16'h0420; // MOV R2,R1
        PROGRAM[3]  = 16'h0700; // MOV R3,#0
        PROGRAM[4]  = 16'h6100; // CMP R0,#0
        PROGRAM[5]  = 16'hc208; // JEQ 8
        PROGRAM[6]  = 16'h0800; // MOV R4,R0
        PROGRAM[7]  = 16'h5901; // AND R4,#1
        PROGRAM[8]  = 16'hc202; // JEQ 2
        PROGRAM[9]  = 16'h164c; // ADD R3,R2
        PROGRAM[10] = 16'h7441; // LSL R2,R2,#1
        PROGRAM[11] = 16'h7011; // LSR R0,R0,#1
        PROGRAM[12] = 16'hc0f8; // JMP -8
    end


    int pass_count = 0;
    int fail_count = 0;
    int cyc = 0;

    localparam int NUM_CYCLES = 40;

    int    exp_pc [0:NUM_CYCLES-1];
    int    exp_r0 [0:NUM_CYCLES-1];
    int    exp_r1 [0:NUM_CYCLES-1];
    int    exp_r2 [0:NUM_CYCLES-1];
    int    exp_r3 [0:NUM_CYCLES-1];
    int    exp_r4 [0:NUM_CYCLES-1];
    int    exp_z  [0:NUM_CYCLES-1];
    string exp_label [0:NUM_CYCLES-1];

    task automatic check(
        input logic [15:0] act_pc, act_r0, act_r1, act_r2, act_r3, act_r4,
        input logic act_z,
        input int cycle_num
    );
        bit ok = 1;
        string msg = "";

        if (act_pc !== exp_pc[cycle_num][15:0])
            begin ok = 0; msg = {msg, " PC"}; end
        if (exp_r0[cycle_num] != -1 && act_r0 !== exp_r0[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R0"}; end
        if (exp_r1[cycle_num] != -1 && act_r1 !== exp_r1[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R1"}; end
        if (exp_r2[cycle_num] != -1 && act_r2 !== exp_r2[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R2"}; end
        if (exp_r3[cycle_num] != -1 && act_r3 !== exp_r3[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R3"}; end
        if (exp_r4[cycle_num] != -1 && act_r4 !== exp_r4[cycle_num][15:0])
            begin ok = 0; msg = {msg, " R4"}; end
        if (exp_z[cycle_num] != -1 && act_z !== exp_z[cycle_num][0])
            begin ok = 0; msg = {msg, " Z"}; end

        if (ok) begin
            $display("PASS | cyc %2d | %-18s | PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d",
                      cycle_num, exp_label[cycle_num], act_pc, act_r0, act_r1, act_r2, act_r3, act_r4);
            pass_count++;
        end else begin
            $display("FAIL | cyc %2d | %-18s | mismatch:%s", cycle_num, exp_label[cycle_num], msg);
            $display("       actual:   PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d Z=%0b",
                      act_pc, act_r0, act_r1, act_r2, act_r3, act_r4, act_z);
            $display("       expected: PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d",
                      exp_pc[cycle_num], exp_r0[cycle_num], exp_r1[cycle_num],
                      exp_r2[cycle_num], exp_r3[cycle_num], exp_r4[cycle_num]);
            fail_count++;
        end
    endtask

    initial begin

        exp_pc[0]=1;  exp_r0[0]=12; exp_r1[0]=-1; exp_r2[0]=-1; exp_r3[0]=-1; exp_r4[0]=-1; exp_z[0]=-1; exp_label[0]="MOV R0,#12";
        exp_pc[1]=2;  exp_r0[1]=12; exp_r1[1]=5;  exp_r2[1]=-1; exp_r3[1]=-1; exp_r4[1]=-1; exp_z[1]=-1; exp_label[1]="MOV R1,#5";
        exp_pc[2]=3;  exp_r0[2]=12; exp_r1[2]=5;  exp_r2[2]=5;  exp_r3[2]=-1; exp_r4[2]=-1; exp_z[2]=-1; exp_label[2]="MOV R2,R1";
        exp_pc[3]=4;  exp_r0[3]=12; exp_r1[3]=5;  exp_r2[3]=5;  exp_r3[3]=0;  exp_r4[3]=-1; exp_z[3]=-1; exp_label[3]="MOV R3,#0";

        exp_pc[4]=5;  exp_r0[4]=12; exp_r1[4]=5;  exp_r2[4]=5;  exp_r3[4]=0;  exp_r4[4]=-1; exp_z[4]=0;  exp_label[4]="CMP R0,#0";
        exp_pc[5]=6;  exp_r0[5]=12; exp_r1[5]=5;  exp_r2[5]=5;  exp_r3[5]=0;  exp_r4[5]=-1; exp_z[5]=0;  exp_label[5]="JEQ 8 (no)";
        exp_pc[6]=7;  exp_r0[6]=12; exp_r1[6]=5;  exp_r2[6]=5;  exp_r3[6]=0;  exp_r4[6]=12; exp_z[6]=-1; exp_label[6]="MOV R4,R0";
        exp_pc[7]=8;  exp_r0[7]=12; exp_r1[7]=5;  exp_r2[7]=5;  exp_r3[7]=0;  exp_r4[7]=0;  exp_z[7]=1;  exp_label[7]="AND R4,#1";
        exp_pc[8]=10; exp_r0[8]=12; exp_r1[8]=5;  exp_r2[8]=5;  exp_r3[8]=0;  exp_r4[8]=0;  exp_z[8]=1;  exp_label[8]="JEQ 2 (yes)";
        exp_pc[9]=11; exp_r0[9]=12; exp_r1[9]=5;  exp_r2[9]=10; exp_r3[9]=0;  exp_r4[9]=0;  exp_z[9]=-1; exp_label[9]="LSL R2,#1";
        exp_pc[10]=12; exp_r0[10]=6; exp_r1[10]=5; exp_r2[10]=10; exp_r3[10]=0; exp_r4[10]=0; exp_z[10]=-1; exp_label[10]="LSR R0,#1";
        exp_pc[11]=4;  exp_r0[11]=6; exp_r1[11]=5; exp_r2[11]=10; exp_r3[11]=0; exp_r4[11]=0; exp_z[11]=-1; exp_label[11]="JMP -8";

        exp_pc[12]=5;  exp_r0[12]=6; exp_r1[12]=5; exp_r2[12]=10; exp_r3[12]=0; exp_r4[12]=0; exp_z[12]=0; exp_label[12]="CMP R0,#0";
        exp_pc[13]=6;  exp_r0[13]=6; exp_r1[13]=5; exp_r2[13]=10; exp_r3[13]=0; exp_r4[13]=0; exp_z[13]=0; exp_label[13]="JEQ 8 (no)";
        exp_pc[14]=7;  exp_r0[14]=6; exp_r1[14]=5; exp_r2[14]=10; exp_r3[14]=0; exp_r4[14]=6; exp_z[14]=-1; exp_label[14]="MOV R4,R0";
        exp_pc[15]=8;  exp_r0[15]=6; exp_r1[15]=5; exp_r2[15]=10; exp_r3[15]=0; exp_r4[15]=0; exp_z[15]=1; exp_label[15]="AND R4,#1";
        exp_pc[16]=10; exp_r0[16]=6; exp_r1[16]=5; exp_r2[16]=10; exp_r3[16]=0; exp_r4[16]=0; exp_z[16]=1; exp_label[16]="JEQ 2 (yes)";
        exp_pc[17]=11; exp_r0[17]=6; exp_r1[17]=5; exp_r2[17]=20; exp_r3[17]=0; exp_r4[17]=0; exp_z[17]=-1; exp_label[17]="LSL R2,#1";
        exp_pc[18]=12; exp_r0[18]=3; exp_r1[18]=5; exp_r2[18]=20; exp_r3[18]=0; exp_r4[18]=0; exp_z[18]=-1; exp_label[18]="LSR R0,#1";
        exp_pc[19]=4;  exp_r0[19]=3; exp_r1[19]=5; exp_r2[19]=20; exp_r3[19]=0; exp_r4[19]=0; exp_z[19]=-1; exp_label[19]="JMP -8";

        exp_pc[20]=5;  exp_r0[20]=3; exp_r1[20]=5; exp_r2[20]=20; exp_r3[20]=0; exp_r4[20]=0; exp_z[20]=0; exp_label[20]="CMP R0,#0";
        exp_pc[21]=6;  exp_r0[21]=3; exp_r1[21]=5; exp_r2[21]=20; exp_r3[21]=0; exp_r4[21]=0; exp_z[21]=0; exp_label[21]="JEQ 8 (no)";
        exp_pc[22]=7;  exp_r0[22]=3; exp_r1[22]=5; exp_r2[22]=20; exp_r3[22]=0; exp_r4[22]=3; exp_z[22]=-1; exp_label[22]="MOV R4,R0";
        exp_pc[23]=8;  exp_r0[23]=3; exp_r1[23]=5; exp_r2[23]=20; exp_r3[23]=0; exp_r4[23]=1; exp_z[23]=0; exp_label[23]="AND R4,#1";
        exp_pc[24]=9;  exp_r0[24]=3; exp_r1[24]=5; exp_r2[24]=20; exp_r3[24]=0; exp_r4[24]=1; exp_z[24]=0; exp_label[24]="JEQ 2 (no)";
        exp_pc[25]=10; exp_r0[25]=3; exp_r1[25]=5; exp_r2[25]=20; exp_r3[25]=20; exp_r4[25]=1; exp_z[25]=-1; exp_label[25]="ADD R3,R2";
        exp_pc[26]=11; exp_r0[26]=3; exp_r1[26]=5; exp_r2[26]=40; exp_r3[26]=20; exp_r4[26]=1; exp_z[26]=-1; exp_label[26]="LSL R2,#1";
        exp_pc[27]=12; exp_r0[27]=1; exp_r1[27]=5; exp_r2[27]=40; exp_r3[27]=20; exp_r4[27]=1; exp_z[27]=-1; exp_label[27]="LSR R0,#1";
        exp_pc[28]=4;  exp_r0[28]=1; exp_r1[28]=5; exp_r2[28]=40; exp_r3[28]=20; exp_r4[28]=1; exp_z[28]=-1; exp_label[28]="JMP -8";

        exp_pc[29]=5;  exp_r0[29]=1; exp_r1[29]=5; exp_r2[29]=40; exp_r3[29]=20; exp_r4[29]=1; exp_z[29]=0; exp_label[29]="CMP R0,#0";
        exp_pc[30]=6;  exp_r0[30]=1; exp_r1[30]=5; exp_r2[30]=40; exp_r3[30]=20; exp_r4[30]=1; exp_z[30]=0; exp_label[30]="JEQ 8 (no)";
        exp_pc[31]=7;  exp_r0[31]=1; exp_r1[31]=5; exp_r2[31]=40; exp_r3[31]=20; exp_r4[31]=1; exp_z[31]=-1; exp_label[31]="MOV R4,R0";
        exp_pc[32]=8;  exp_r0[32]=1; exp_r1[32]=5; exp_r2[32]=40; exp_r3[32]=20; exp_r4[32]=1; exp_z[32]=0; exp_label[32]="AND R4,#1";
        exp_pc[33]=9;  exp_r0[33]=1; exp_r1[33]=5; exp_r2[33]=40; exp_r3[33]=20; exp_r4[33]=1; exp_z[33]=0; exp_label[33]="JEQ 2 (no)";
        exp_pc[34]=10; exp_r0[34]=1; exp_r1[34]=5; exp_r2[34]=40; exp_r3[34]=60; exp_r4[34]=1; exp_z[34]=-1; exp_label[34]="ADD R3,R2";
        exp_pc[35]=11; exp_r0[35]=1; exp_r1[35]=5; exp_r2[35]=80; exp_r3[35]=60; exp_r4[35]=1; exp_z[35]=-1; exp_label[35]="LSL R2,#1";
        exp_pc[36]=12; exp_r0[36]=0; exp_r1[36]=5; exp_r2[36]=80; exp_r3[36]=60; exp_r4[36]=1; exp_z[36]=-1; exp_label[36]="LSR R0,#1";
        exp_pc[37]=4;  exp_r0[37]=0; exp_r1[37]=5; exp_r2[37]=80; exp_r3[37]=60; exp_r4[37]=1; exp_z[37]=-1; exp_label[37]="JMP -8";

        exp_pc[38]=5;  exp_r0[38]=0; exp_r1[38]=5; exp_r2[38]=80; exp_r3[38]=60; exp_r4[38]=1; exp_z[38]=1; exp_label[38]="CMP R0,#0";
        exp_pc[39]=13; exp_r0[39]=0; exp_r1[39]=5; exp_r2[39]=80; exp_r3[39]=60; exp_r4[39]=1; exp_z[39]=1; exp_label[39]="JEQ 8 (yes, END)";

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

        for (cyc = 0; cyc < 40; cyc++) begin
            @(posedge clk);
            #1; // let combinational logic (INS, ALUOUT, NEXT block) settle
            check(PC_dbg, R0_dbg, R1_dbg, R2_dbg, R3_dbg, R4_dbg, FLAGZ_dbg, cyc);
        end

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED -- R3 = %0d (expect 60 = 12*5)", R3_dbg);
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule