`timescale 1ns/1ps

module NEXT_tb;

    logic [15:0] PC;
    logic [15:0] OFFSET;
    logic [15:0] RA;

    logic        JMP;
    logic [3:0]  JMPCOND;

    logic        FLAGN, FLAGZ, FLAGC, FLAGV;

    logic [15:0] PCNEXT;

    NEXT dut (
        .PC(PC),
        .OFFSET(OFFSET),
        .RA(RA),
        .JMP(JMP),
        .JMPCOND(JMPCOND),
        .FLAGN(FLAGN),
        .FLAGZ(FLAGZ),
        .FLAGC(FLAGC),
        .FLAGV(FLAGV),
        .PCNEXT(PCNEXT)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] pc,
        input logic [15:0] offset,
        input logic [15:0] ra,
        input logic jmp,
        input logic [3:0] jmpcond,
        input logic flagn, flagz, flagc, flagv,
        input logic [15:0] exp_pcnext,
        input string label
    );
        PC = pc;
        OFFSET = offset;
        RA = ra;
        JMP = jmp;
        JMPCOND = jmpcond;
        FLAGN = flagn;
        FLAGZ = flagz;
        FLAGC = flagc;
        FLAGV = flagv;
        #1; //let combinational logic settle

        if (PCNEXT === exp_pcnext) begin
            $display("PASS | %-45s | PCNEXT=%04h", label, PCNEXT);
            pass_count++;
        end else begin
            $display("FAIL | %-45s | PCNEXT=%04h (expected %04h)",
                     label, PCNEXT, exp_pcnext);
            fail_count++;
        end
    endtask

    initial begin

        //1. NORMAL (PC + 1): JMP=0, condition irrelevant

        //No jump: JMPCOND=JMP (always), but JMP input is 0 -> PC+1
        check(16'h0000, 16'h0010, 16'hABCD, 0, 4'b0000, 0,0,0,0, 16'h0001, "PC+1: JMP=0, JMPCOND=JMP(always)");
        check(16'hFFFF, 16'h0001, 16'h1234, 0, 4'b0000, 0,0,0,0, 16'h0000, "PC+1: overflow wrap (FFFF+1=0000)");
        check(16'h0100, 16'hFFF0, 16'h0000, 0, 4'b0001, 1,1,1,1, 16'h0101, "PC+1: JMP=0, all flags set");

        //No jump: JMP=1 but condition evaluates to JUMP=0 and RET=0
        //JMPCOND=NOP (4'b0001) -> COND always outputs JUMP=0, RET=0
        check(16'h0050, 16'h0020, 16'hBEEF, 1, 4'b0001, 0,0,0,0, 16'h0051, "PC+1: JMP=1, JMPCOND=NOP(never)");
        check(16'h0050, 16'h0020, 16'hBEEF, 1, 4'b0001, 1,1,1,1, 16'h0051, "PC+1: JMP=1, JMPCOND=NOP, all flags");

        //JEQ: JMP=1, condition requires Z=1, but Z=0 -> no jump
        check(16'h0010, 16'h0005, 16'h9999, 1, 4'b0010, 0,0,0,0, 16'h0011, "PC+1: JMP=1, JEQ, Z=0 -> no jump");

        //JCS: JMP=1, condition requires C=1, but C=0 -> no jump
        check(16'h0010, 16'h0005, 16'h9999, 1, 4'b0100, 0,0,0,0, 16'h0011, "PC+1: JMP=1, JCS, C=0 -> no jump");

        //2. JUMP (PC + OFFSET): JMP=1, JUMP=1, RET=0

        //JMP always (JMPCOND=4'b0000): unconditional branch
        check(16'h0000, 16'h0010, 16'hDEAD, 1, 4'b0000, 0,0,0,0, 16'h0010, "PC+OFFSET: JMP always, PC=0000 OFF=0010");
        check(16'h0100, 16'h0010, 16'hDEAD, 1, 4'b0000, 1,1,1,1, 16'h0110, "PC+OFFSET: JMP always, flags all set");
        check(16'hFF00, 16'h0100, 16'hDEAD, 1, 4'b0000, 0,0,0,0, 16'hFF00+16'h0100, "PC+OFFSET: JMP always, large PC");
        check(16'h0010, 16'hFFFE, 16'hDEAD, 1, 4'b0000, 0,0,0,0, 16'h000E, "PC+OFFSET: negative offset (wrap)");

        //JEQ: Z=1 -> jump
        check(16'h0020, 16'h0008, 16'hAAAA, 1, 4'b0010, 0,1,0,0, 16'h0028, "PC+OFFSET: JEQ, Z=1 -> jump");

        //JNE: Z=0 -> jump
        check(16'h0020, 16'h0008, 16'hAAAA, 1, 4'b0011, 0,0,0,0, 16'h0028, "PC+OFFSET: JNE, Z=0 -> jump");

        //JCS: C=1 -> jump
        check(16'h0030, 16'h000F, 16'hAAAA, 1, 4'b0100, 0,0,1,0, 16'h003F, "PC+OFFSET: JCS, C=1 -> jump");

        //JCC: C=0 -> jump
        check(16'h0030, 16'h000F, 16'hAAAA, 1, 4'b0101, 0,0,0,0, 16'h003F, "PC+OFFSET: JCC, C=0 -> jump");

        //JMI: N=1 -> jump
        check(16'h0040, 16'h0002, 16'hAAAA, 1, 4'b0110, 1,0,0,0, 16'h0042, "PC+OFFSET: JMI, N=1 -> jump");

        //JPL: N=0 -> jump
        check(16'h0040, 16'h0002, 16'hAAAA, 1, 4'b0111, 0,0,0,0, 16'h0042, "PC+OFFSET: JPL, N=0 -> jump");

        //JGE: N=0,V=0 -> jump (N XNOR V = 1)
        check(16'h0050, 16'h0003, 16'hAAAA, 1, 4'b1000, 0,0,0,0, 16'h0053, "PC+OFFSET: JGE, N=0 V=0 -> jump");

        //JGE: N=1,V=1 -> jump
        check(16'h0050, 16'h0003, 16'hAAAA, 1, 4'b1000, 1,0,0,1, 16'h0053, "PC+OFFSET: JGE, N=1 V=1 -> jump");

        //JLT: N=1,V=0 -> jump
        check(16'h0050, 16'h0003, 16'hAAAA, 1, 4'b1001, 1,0,0,0, 16'h0053, "PC+OFFSET: JLT, N=1 V=0 -> jump");

        //JGT: N=0,V=0,Z=0 -> jump
        check(16'h0060, 16'h0001, 16'hAAAA, 1, 4'b1010, 0,0,0,0, 16'h0061, "PC+OFFSET: JGT, N=0 V=0 Z=0 -> jump");

        //JLE: Z=1 -> jump
        check(16'h0060, 16'h0001, 16'hAAAA, 1, 4'b1011, 0,1,0,0, 16'h0061, "PC+OFFSET: JLE, Z=1 -> jump");

        //JHI: C=1,Z=0 -> jump
        check(16'h0070, 16'h0005, 16'hAAAA, 1, 4'b1100, 0,0,1,0, 16'h0075, "PC+OFFSET: JHI, C=1 Z=0 -> jump");

        //JLS: C=0 -> jump
        check(16'h0070, 16'h0005, 16'hAAAA, 1, 4'b1101, 0,0,0,0, 16'h0075, "PC+OFFSET: JLS, C=0 -> jump");

        //JSR: always jump (JUMP=1, RET=0)
        check(16'h0080, 16'h0020, 16'hAAAA, 1, 4'b1110, 0,0,0,0, 16'h00A0, "PC+OFFSET: JSR -> JUMP=1 RET=0");
        check(16'h0080, 16'h0020, 16'hAAAA, 1, 4'b1110, 1,1,1,1, 16'h00A0, "PC+OFFSET: JSR, all flags set");

        //3. RETURN (RA): JMP=1, RET=1 (JMPCOND=4'b1111)

        //RET overrides offset: PCNEXT = RA regardless of OFFSET
        check(16'h0090, 16'h0010, 16'h1234, 1, 4'b1111, 0,0,0,0, 16'h1234, "RA: RET, RA=1234");
        check(16'h0090, 16'hFFFF, 16'hABCD, 1, 4'b1111, 0,0,0,0, 16'hABCD, "RA: RET, large OFFSET ignored");
        check(16'hFFFF, 16'h0001, 16'h0000, 1, 4'b1111, 0,0,0,0, 16'h0000, "RA: RET, RA=0000");
        check(16'h0000, 16'h0000, 16'hFFFF, 1, 4'b1111, 1,1,1,1, 16'hFFFF, "RA: RET, all flags set, RA=FFFF");
        check(16'h0050, 16'h0020, 16'h0300, 1, 4'b1111, 0,1,0,0, 16'h0300, "RA: RET, Z=1 (Z irrelevant for RET)");

        //4. Priority check: RET beats regular jump
        //JMPCOND=1111 -> RET=1, JUMP=1. Priority: JMP&&RET -> RA (not PC+OFFSET)
        check(16'h0010, 16'h0010, 16'h5678, 1, 4'b1111, 0,0,0,0, 16'h5678, "Priority: RET=1 beats PC+OFFSET");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule