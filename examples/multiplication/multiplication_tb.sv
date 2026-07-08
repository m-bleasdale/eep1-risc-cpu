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
    wire [15:0] PC_dbg = dut.controlpath.PC;

    //flags in current cycle, set by previous instruction
    wire FLAGN_dbg = dut.controlpath.NQ;
    wire FLAGZ_dbg = dut.controlpath.ZQ;
    wire FLAGC_dbg = dut.controlpath.CQ;
    wire FLAGV_dbg = dut.controlpath.VQ;

    //registers
    wire [15:0] R0_dbg = dut.datapath.reg16x8.REG[0];
    wire [15:0] R1_dbg = dut.datapath.reg16x8.REG[1];
    wire [15:0] R2_dbg = dut.datapath.reg16x8.REG[2];
    wire [15:0] R3_dbg = dut.datapath.reg16x8.REG[3];
    wire [15:0] R4_dbg = dut.datapath.reg16x8.REG[4];

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

    typedef struct {
        int pc_next;
        int r0, r1, r2, r3, r4; 
        int z;                  
        string label;
    } exp_t;

    exp_t trace[0:39];

    task automatic check(
        input logic [15:0] act_pc, act_r0, act_r1, act_r2, act_r3, act_r4,
        input logic act_z,
        input exp_t e,
        input int cycle_num
    );
        bit ok = 1;
        string msg = "";

        if (act_pc !== e.pc_next)                   begin ok = 0; msg = {msg, " PC"}; end
        if (e.r0 != -1 && act_r0 !== e.r0[15:0])     begin ok = 0; msg = {msg, " R0"}; end
        if (e.r1 != -1 && act_r1 !== e.r1[15:0])     begin ok = 0; msg = {msg, " R1"}; end
        if (e.r2 != -1 && act_r2 !== e.r2[15:0])     begin ok = 0; msg = {msg, " R2"}; end
        if (e.r3 != -1 && act_r3 !== e.r3[15:0])     begin ok = 0; msg = {msg, " R3"}; end
        if (e.r4 != -1 && act_r4 !== e.r4[15:0])     begin ok = 0; msg = {msg, " R4"}; end
        if (e.z  != -1 && act_z  !== e.z[0])         begin ok = 0; msg = {msg, " Z"}; end

        if (ok) begin
            $display("PASS | cyc %2d | %-18s | PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d",
                      cycle_num, e.label, act_pc, act_r0, act_r1, act_r2, act_r3, act_r4);
            pass_count++;
        end else begin
            $display("FAIL | cyc %2d | %-18s | mismatch:%s", cycle_num, e.label, msg);
            $display("       actual:   PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d Z=%0b",
                      act_pc, act_r0, act_r1, act_r2, act_r3, act_r4, act_z);
            $display("       expected: PC=%0d R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d",
                      e.pc_next, e.r0, e.r1, e.r2, e.r3, e.r4);
            fail_count++;
        end
    endtask

    initial begin

        trace[0]  = '{1,  12,-1,-1,-1,-1, -1, "MOV R0,#12"};
        trace[1]  = '{2,  12, 5,-1,-1,-1, -1, "MOV R1,#5"};
        trace[2]  = '{3,  12, 5, 5,-1,-1, -1, "MOV R2,R1"};
        trace[3]  = '{4,  12, 5, 5, 0,-1, -1, "MOV R3,#0"};

        trace[4]  = '{5,  12, 5, 5, 0,-1,  0, "CMP R0,#0"};
        trace[5]  = '{6,  12, 5, 5, 0,-1,  0, "JEQ 8 (no)"};
        trace[6]  = '{7,  12, 5, 5, 0, 12, -1, "MOV R4,R0"};
        trace[7]  = '{8,  12, 5, 5, 0,  0,  1, "AND R4,#1"};
        trace[8]  = '{10, 12, 5, 5, 0,  0,  1, "JEQ 2 (yes)"};
        trace[9]  = '{11, 12, 5,10, 0,  0, -1, "LSL R2,#1"};
        trace[10] = '{12,  6, 5,10, 0,  0, -1, "LSR R0,#1"};
        trace[11] = '{4,   6, 5,10, 0,  0, -1, "JMP -8"};

        trace[12] = '{5,   6, 5,10, 0,  0,  0, "CMP R0,#0"};
        trace[13] = '{6,   6, 5,10, 0,  0,  0, "JEQ 8 (no)"};
        trace[14] = '{7,   6, 5,10, 0,  6, -1, "MOV R4,R0"};
        trace[15] = '{8,   6, 5,10, 0,  0,  1, "AND R4,#1"};
        trace[16] = '{10,  6, 5,10, 0,  0,  1, "JEQ 2 (yes)"};
        trace[17] = '{11,  6, 5,20, 0,  0, -1, "LSL R2,#1"};
        trace[18] = '{12,  3, 5,20, 0,  0, -1, "LSR R0,#1"};
        trace[19] = '{4,   3, 5,20, 0,  0, -1, "JMP -8"};

        trace[20] = '{5,   3, 5,20, 0,  0,  0, "CMP R0,#0"};
        trace[21] = '{6,   3, 5,20, 0,  0,  0, "JEQ 8 (no)"};
        trace[22] = '{7,   3, 5,20, 0,  3, -1, "MOV R4,R0"};
        trace[23] = '{8,   3, 5,20, 0,  1,  0, "AND R4,#1"};
        trace[24] = '{9,   3, 5,20, 0,  1,  0, "JEQ 2 (no)"};
        trace[25] = '{10,  3, 5,20,20,  1, -1, "ADD R3,R2"};
        trace[26] = '{11,  3, 5,40,20,  1, -1, "LSL R2,#1"};
        trace[27] = '{12,  1, 5,40,20,  1, -1, "LSR R0,#1"};
        trace[28] = '{4,   1, 5,40,20,  1, -1, "JMP -8"};

        trace[29] = '{5,   1, 5,40,20,  1,  0, "CMP R0,#0"};
        trace[30] = '{6,   1, 5,40,20,  1,  0, "JEQ 8 (no)"};
        trace[31] = '{7,   1, 5,40,20,  1, -1, "MOV R4,R0"};
        trace[32] = '{8,   1, 5,40,20,  1,  0, "AND R4,#1"};
        trace[33] = '{9,   1, 5,40,20,  1,  0, "JEQ 2 (no)"};
        trace[34] = '{10,  1, 5,40,60,  1, -1, "ADD R3,R2"};
        trace[35] = '{11,  1, 5,80,60,  1, -1, "LSL R2,#1"};
        trace[36] = '{12,  0, 5,80,60,  1, -1, "LSR R0,#1"};
        trace[37] = '{4,   0, 5,80,60,  1, -1, "JMP -8"};

        trace[38] = '{5,   0, 5,80,60,  1,  1, "CMP R0,#0"};
        trace[39] = '{13,  0, 5,80,60,  1,  1, "JEQ 8 (yes, END)"};

        // load program into CODEMEM before releasing reset 
        rst = 1;
        for (int i = 0; i < PROG_LEN; i++)
            dut.codemem.MEM[i] = PROGRAM[i];

        @(posedge clk); @(posedge clk);
        rst = 0;

        for (cyc = 0; cyc < 40; cyc++) begin
            @(posedge clk);
            #1; // let combinational logic (INS, ALUOUT, NEXT block) settle
            check(PC_dbg, R0_dbg, R1_dbg, R2_dbg, R3_dbg, R4_dbg, FLAGZ_dbg,
                  trace[cyc], cyc);
        end

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED -- R3 = %0d (expect 60 = 12*5)", R3_dbg);
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
