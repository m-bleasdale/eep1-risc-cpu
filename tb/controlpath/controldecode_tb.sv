`timescale 1ns/1ps

module CONTROLDECODE_tb;

    logic [15:0] INS;
    logic [15:0] IMMEXT;

    logic NZEN;
    logic CVEN;
    logic JMP;
    logic [3:0] JMPCOND;
    logic [15:0] JOFFSET;

    CONTROLDECODE dut (
        .INS(INS),
        .IMMEXT(IMMEXT),
        .NZEN(NZEN),
        .CVEN(CVEN),
        .JMP(JMP),
        .JMPCOND(JMPCOND),
        .JOFFSET(JOFFSET)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] ins,
        input logic [15:0] immext,
        input logic exp_nzen, exp_cven, exp_jmp,
        input logic [3:0] exp_jmpcond,
        input logic [15:0] exp_joffset,
        input string label
    );
        INS = ins;
        IMMEXT = immext;
        #1;

        if (NZEN === exp_nzen && CVEN === exp_cven && JMP === exp_jmp &&
            JMPCOND === exp_jmpcond && JOFFSET === exp_joffset) begin
            $display("PASS | %-45s | NZEN=%b CVEN=%b JMP=%b JMPCOND=%04b JOFFSET=%04h",
                     label, NZEN, CVEN, JMP, JMPCOND, JOFFSET);
            pass_count++;
        end else begin
            $display("FAIL | %-45s | NZEN=%b CVEN=%b JMP=%b JMPCOND=%04b JOFFSET=%04h (expected NZEN=%b CVEN=%b JMP=%b JMPCOND=%04b JOFFSET=%04h)",
                     label, NZEN, CVEN, JMP, JMPCOND, JOFFSET,
                     exp_nzen, exp_cven, exp_jmp, exp_jmpcond, exp_joffset);
            fail_count++;
        end
    endtask

    initial begin

        //JOFFSET passthrough
        check(16'h0000, 16'hABCD, 1,0,0, 4'h0, 16'hABCD, "JOFFSET passthrough ABCD");
        check(16'h0000, 16'h1234, 1,0,0, 4'h0, 16'h1234, "JOFFSET passthrough 1234");
        check(16'h0000, 16'hFFFF, 1,0,0, 4'h0, 16'hFFFF, "JOFFSET passthrough FFFF");

        //JMPCOND passthrough (INS[11:8])
        check(16'h0F00, 16'h0000, 1,0,0, 4'hF, 16'h0000, "JMPCOND = F from INS[11:8]");
        check(16'h0A00, 16'h0000, 1,0,0, 4'hA, 16'h0000, "JMPCOND = A from INS[11:8]");
        check(16'h0000, 16'h0000, 1,0,0, 4'h0, 16'h0000, "JMPCOND = 0 from INS[11:8]");

        //NZEN: INS[15]=0 -> NZEN=1 (ALU), INS[15]=1 -> NZEN=0 (JMP/EXT)
        check(16'h0000, 16'h0000, 1,0,0, 4'h0, 16'h0000, "NZEN=1: INS[15]=0");
        check(16'h8000, 16'h0000, 0,0,0, 4'h0, 16'h0000, "NZEN=0: INS[15]=1");

        //JMP: INS[15:12]=1100 -> JMP=1
        check(16'hC000, 16'h0000, 0,0,1, 4'h0, 16'h0000, "JMP=1: INS[15:12]=1100");
        check(16'hC100, 16'h0000, 0,0,1, 4'h1, 16'h0000, "JMP=1: JMPCOND=1");
        check(16'hCF00, 16'h0000, 0,0,1, 4'hF, 16'h0000, "JMP=1: JMPCOND=F");
        check(16'h8000, 16'h0000, 0,0,0, 4'h0, 16'h0000, "JMP=0: INS[15:12]=1000");
        check(16'hD000, 16'h0000, 0,0,0, 4'h0, 16'h0000, "JMP=0: INS[15:12]=1101");
        check(16'h0000, 16'h0000, 1,0,0, 4'h0, 16'h0000, "JMP=0: INS[15:12]=0000");

        //CVEN: ALU operations
        //MOV: ALUOPC=000, CVEN=0 (INS[15]=0, INS[14:12]=000)
        check(16'h0000, 16'h0000, 1,0,0, 4'h0, 16'h0000, "MOV: ALUOPC=000 CVEN=0");

        //ADD: ALUOPC=001, CVEN=NZEN=1 (INS[15]=0)
        check(16'h1000, 16'h0000, 1,1,0, 4'h0, 16'h0000, "ADD: ALUOPC=001 CVEN=1");

        //SUB: ALUOPC=010, CVEN=NZEN=1
        check(16'h2000, 16'h0000, 1,1,0, 4'h0, 16'h0000, "SUB: ALUOPC=010 CVEN=1");

        //ADC: ALUOPC=011, CVEN=NZEN=1
        check(16'h3000, 16'h0000, 1,1,0, 4'h0, 16'h0000, "ADC: ALUOPC=011 CVEN=1");

        //SBC: ALUOPC=100, CVEN=NZEN=1
        check(16'h4000, 16'h0000, 1,1,0, 4'h0, 16'h0000, "SBC: ALUOPC=100 CVEN=1");

        //AND: ALUOPC=101, CVEN=0
        check(16'h5000, 16'h0000, 1,0,0, 4'h0, 16'h0000, "AND: ALUOPC=101 CVEN=0");

        //CMP: ALUOPC=110, CVEN=NZEN=1
        check(16'h6000, 16'h0000, 1,1,0, 4'h0, 16'h0000, "CMP: ALUOPC=110 CVEN=1");

        //SHIFT: ALUOPC=111, CVEN=NZEN=1
        check(16'h7000, 16'h0000, 1,1,0, 4'h0, 16'h0000, "SHIFT: ALUOPC=111 CVEN=1");

        //CVEN=0 when INS[15]=1 (NZEN=0), even for opcodes that would set CVEN
        //ADD with INS[15]=1: NZEN=0 so CVEN=NZEN=0
        check(16'h9000, 16'h0000, 0,0,0, 4'h0, 16'h0000, "ADD INS[15]=1: CVEN=NZEN=0");
        check(16'hB000, 16'h0000, 0,0,0, 4'h0, 16'h0000, "SBC INS[15]=1: CVEN=NZEN=0");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule