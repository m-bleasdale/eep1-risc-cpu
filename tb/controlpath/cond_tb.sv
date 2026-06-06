`timescale 1ns/1ps

module COND_tb;

    logic [3:0] JMPCOND;
    logic FLAGN, FLAGZ, FLAGC, FLAGV;

    logic JUMP;
    logic RET;

    COND dut (
        .JMPCOND(JMPCOND),
        .FLAGN(FLAGN),
        .FLAGZ(FLAGZ),
        .FLAGC(FLAGC),
        .FLAGV(FLAGV),
        .JUMP(JUMP),
        .RET(RET)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [3:0] jmpcond,
        input logic flagn, flagz, flagc, flagv,
        input logic exp_jump, exp_ret,
        input string label
    );
        JMPCOND = jmpcond;
        FLAGN   = flagn;
        FLAGZ   = flagz;
        FLAGC   = flagc;
        FLAGV   = flagv;
        #1; // let combinational logic settle

        if (JUMP === exp_jump && RET === exp_ret) begin
            $display("PASS | %-30s | JUMP=%b RET=%b", label, JUMP, RET);
            pass_count++;
        end else begin
            $display("FAIL | %-30s | JUMP=%b RET=%b (expected JUMP=%b RET=%b)",
                     label, JUMP, RET, exp_jump, exp_ret);
            fail_count++;
        end
    endtask

    initial begin

        // OPC 0: JMP (always) / NOP (never)
        // JMPCOND[3:1]=000, JMPCOND[0]=0 -> JMP, always jump
        check(4'b0000, 0,0,0,0, 1, 0, "JMP (always)");
        check(4'b0000, 1,1,1,1, 1, 0, "JMP (always, all flags set)");

        // JMPCOND[3:1]=000, JMPCOND[0]=1 -> NOP, never jump
        check(4'b0001, 0,0,0,0, 0, 0, "NOP (never)");
        check(4'b0001, 1,1,1,1, 0, 0, "NOP (never, all flags set)");

        // OPC 1: JEQ (Z=1) / JNE (Z=0)
        check(4'b0010, 0,1,0,0, 1, 0, "JEQ Z=1 -> jump");
        check(4'b0010, 0,0,0,0, 0, 0, "JEQ Z=0 -> no jump");
        check(4'b0011, 0,0,0,0, 1, 0, "JNE Z=0 -> jump");
        check(4'b0011, 0,1,0,0, 0, 0, "JNE Z=1 -> no jump");

        // OPC 2: JCS (C=1) / JCC (C=0)
        check(4'b0100, 0,0,1,0, 1, 0, "JCS C=1 -> jump");
        check(4'b0100, 0,0,0,0, 0, 0, "JCS C=0 -> no jump");
        check(4'b0101, 0,0,0,0, 1, 0, "JCC C=0 -> jump");
        check(4'b0101, 0,0,1,0, 0, 0, "JCC C=1 -> no jump");

        // OPC 3: JMI (N=1) / JPL (N=0)
        check(4'b0110, 1,0,0,0, 1, 0, "JMI N=1 -> jump");
        check(4'b0110, 0,0,0,0, 0, 0, "JMI N=0 -> no jump");
        check(4'b0111, 0,0,0,0, 1, 0, "JPL N=0 -> jump");
        check(4'b0111, 1,0,0,0, 0, 0, "JPL N=1 -> no jump");

        // OPC 4: JGE (~N^V) / JLT (~(~N^V))
        // N=0,V=0 -> ~N^V = 1^0 = 1 -> GE true
        // N=0,V=1 -> ~N^V = 1^1 = 0 -> GE false
        // N=1,V=0 -> ~N^V = 0^0 = 0 -> GE false
        // N=1,V=1 -> ~N^V = 0^1 = 1 -> GE true
        check(4'b1000, 0,0,0,0, 1, 0, "JGE N=0 V=0 -> jump");
        check(4'b1000, 0,0,0,1, 0, 0, "JGE N=0 V=1 -> no jump");
        check(4'b1000, 1,0,0,0, 0, 0, "JGE N=1 V=0 -> no jump");
        check(4'b1000, 1,0,0,1, 1, 0, "JGE N=1 V=1 -> jump");
        // JLT: inverted
        check(4'b1001, 0,0,0,0, 0, 0, "JLT N=0 V=0 -> no jump");
        check(4'b1001, 0,0,0,1, 1, 0, "JLT N=0 V=1 -> jump");
        check(4'b1001, 1,0,0,0, 1, 0, "JLT N=1 V=0 -> jump");
        check(4'b1001, 1,0,0,1, 0, 0, "JLT N=1 V=1 -> no jump");

        // OPC 5: JGT ((~N^V)&~Z) / JLE
        // JGT needs GE condition AND Z=0
        check(4'b1010, 0,0,0,0, 1, 0, "JGT N=0 V=0 Z=0 -> jump");
        check(4'b1010, 0,1,0,0, 0, 0, "JGT N=0 V=0 Z=1 -> no jump (equal)");
        check(4'b1010, 0,0,0,1, 0, 0, "JGT N=0 V=1 Z=0 -> no jump");
        check(4'b1010, 1,0,0,1, 1, 0, "JGT N=1 V=1 Z=0 -> jump");
        check(4'b1010, 1,1,0,1, 0, 0, "JGT N=1 V=1 Z=1 -> no jump (equal)");
        // JLE: inverted
        check(4'b1011, 0,1,0,0, 1, 0, "JLE Z=1 -> jump (equal)");
        check(4'b1011, 0,0,0,1, 1, 0, "JLE N=0 V=1 -> jump (less than)");
        check(4'b1011, 0,0,0,0, 0, 0, "JLE N=0 V=0 Z=0 -> no jump (greater)");

        // OPC 6: JHI (C=1 & Z=0) / JLS
        check(4'b1100, 0,0,1,0, 1, 0, "JHI C=1 Z=0 -> jump");
        check(4'b1100, 0,1,1,0, 0, 0, "JHI C=1 Z=1 -> no jump");
        check(4'b1100, 0,0,0,0, 0, 0, "JHI C=0 Z=0 -> no jump");
        // JLS: inverted
        check(4'b1101, 0,0,0,0, 1, 0, "JLS C=0 -> jump");
        check(4'b1101, 0,1,1,0, 1, 0, "JLS C=1 Z=1 -> jump");
        check(4'b1101, 0,0,1,0, 0, 0, "JLS C=1 Z=0 -> no jump");

        // OPC 7: JSR (1110) / RET (1111)
        // Both always jump, inversion does not apply
        check(4'b1110, 0,0,0,0, 1, 0, "JSR -> JUMP=1 RET=0");
        check(4'b1110, 1,1,1,1, 1, 0, "JSR (all flags) -> JUMP=1 RET=0");
        check(4'b1111, 0,0,0,0, 1, 1, "RET -> JUMP=1 RET=1");
        check(4'b1111, 1,1,1,1, 1, 1, "RET (all flags) -> JUMP=1 RET=1");

        $display("  PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED");

        $finish;
    end

endmodule