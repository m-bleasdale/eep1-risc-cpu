`timescale 1ns/1ps

module DPDECODE_tb;

    logic clk;
    logic [15:0] INS;
    logic [2:0] A, B, C;
    logic [2:0] ALUOPC;
    logic WEN1, AD1SELC, OP2SEL;
    logic [3:0] SCNT;
    logic [1:0] SHIFTOPC;
    logic [15:0] IMMS8;

    DPDECODE dut (
        .INS(INS),
        .A(A),
        .B(B),
        .C(C),
        .ALUOPC(ALUOPC),
        .WEN1(WEN1),
        .AD1SELC(AD1SELC),
        .OP2SEL(OP2SEL),
        .SCNT(SCNT),
        .SHIFTOPC(SHIFTOPC),
        .IMMS8(IMMS8)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] ins,
        input logic [2:0] exp_a, exp_b, exp_c,
        input logic [2:0] exp_aluopc,
        input logic exp_wen1, exp_ad1selc, exp_op2sel,
        input logic [15:0] exp_imms8,
        input string label
    );
        INS = ins;
        #1;

        if (A === exp_a && B === exp_b && C === exp_c && ALUOPC === exp_aluopc &&
            WEN1 === exp_wen1 && AD1SELC === exp_ad1selc && OP2SEL === exp_op2sel &&
            IMMS8 === exp_imms8) begin
            $display("PASS | %-20s | A=%0d B=%0d C=%0d ALUOPC=%0d WEN1=%b AD1SELC=%b OP2SEL=%b IMMS8=%h",
                     label, A, B, C, ALUOPC, WEN1, AD1SELC, OP2SEL, IMMS8);
            pass_count++;
        end else begin
            $display("FAIL | %-20s | A=%0d B=%0d C=%0d ALUOPC=%0d WEN1=%b AD1SELC=%b OP2SEL=%b IMMS8=%h (expected A=%0d B=%0d C=%0d ALUOPC=%0d WEN1=%b AD1SELC=%b OP2SEL=%b IMMS8=%h)",
                     label, A, B, C, ALUOPC, WEN1, AD1SELC, OP2SEL, IMMS8,
                     exp_a, exp_b, exp_c, exp_aluopc, exp_wen1, exp_ad1selc, exp_op2sel, exp_imms8);
            fail_count++;
        end
    endtask

    initial begin

        check(16'h0105, 0, 0, 1, 0, 1, 0, 1, 16'h0005, "MOV R0, #5");
        check(16'h1204, 1, 0, 1, 1, 1, 1, 0, 16'h0004, "ADD R1, R1, R0");
        check(16'h2303, 1, 0, 0, 2, 1, 0, 1, 16'h0003, "SUB R1, #3");
        check(16'h5408, 2, 0, 2, 5, 1, 1, 0, 16'h0008, "AND R2, R2, R0");
        check(16'h6640, 3, 2, 0, 6, 0, 0, 0, 16'h0040, "CMP R3, R2");
        check(16'h09FF, 4, 7, 7, 0, 1, 0, 1, 16'hFFFF, "MOV R4, #255");
        check(16'h7888, 4, 4, 2, 7, 1, 0, 0, 16'hFF88, "LSL R4, R4, #8");
        check(16'h8000, 0, 0, 0, 0, 1, 0, 0, 16'h0000, "LDR");
        check(16'hA000, 0, 0, 0, 2, 0, 1, 0, 16'h0000, "STR");
        check(16'hD0F0, 0, 7, 4, 5, 0, 1, 0, 16'hFFF0, "EXT #240");
        check(16'hCE00, 7, 0, 0, 4, 1, 1, 0, 16'h0000, "JSR");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end


endmodule
