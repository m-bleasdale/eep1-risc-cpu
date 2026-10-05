module DATAPATH_TB;

    logic clk, rst;
    logic [15:0] INS, PCIN, MEMDOUT;
    logic FLAGCIN;

    logic [15:0] RAOUT, IMMEXT;
    logic FLAGN, FLAGZ, FLAGC, FLAGV;

    logic [15:0] MEMADDR, MEMDIN;
    logic MEMWEN;

    // DUT
    DATAPATH dut (
        .clk(clk),
        .rst(rst),
        .INS(INS),
        .PCIN(PCIN),
        .FLAGCIN(FLAGCIN),
        .MEMDOUT(MEMDOUT),
        .RAOUT(RAOUT),
        .IMMEXT(IMMEXT),
        .FLAGN(FLAGN),
        .FLAGZ(FLAGZ),
        .FLAGC(FLAGC),
        .FLAGV(FLAGV),
        .MEMADDR(MEMADDR),
        .MEMDIN(MEMDIN),
        .MEMWEN(MEMWEN)
    );

    always #5 clk = ~clk;

    task apply;
        input [15:0] instruction;
        begin
            INS = instruction;
            $display("DEBUG: EXT=%b IMMS8=%h IMMEXT=%h", 
                dut.EXT,
                dut.IMMS8,
                dut.IMMEXT
            );
                @(posedge clk);

        end
    endtask

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input string instr,
        input int r,
        input logic [15:0] exp_val
    );
        #1;
        if (dut.reg16x8.REG[r] === exp_val) begin
            $display("PASS | %-22s | R%0d=%h", instr, r, dut.reg16x8.REG[r]);
            pass_count++;
        end else begin
            $display("FAIL | %-22s | R%0d=%h (expected %h)", instr, r, dut.reg16x8.REG[r], exp_val);
            fail_count++;
        end
    endtask

    task automatic check_flags(
        input string instr,
        input logic [3:0] exp_nzcv
    );
        #1;
        if ({FLAGN, FLAGZ, FLAGC, FLAGV} === exp_nzcv) begin
            $display("PASS | %-22s | NZCV=%b%b%b%b", instr, FLAGN, FLAGZ, FLAGC, FLAGV);
            pass_count++;
        end else begin
            $display("FAIL | %-22s | NZCV=%b%b%b%b (expected %b)", instr, FLAGN, FLAGZ, FLAGC, FLAGV, exp_nzcv);
            fail_count++;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        PCIN = 0;
        MEMDOUT = 0;
        FLAGCIN = 0;

        #10 rst = 0;

        /*

        Assembly instructions were compiled using an assembler
        /asm has the assembly instructions and the compiled .ram file

        */


        // MOV R0, #5 — load immediate 5 into R0
        apply(16'h0105);
        check("MOV R0, #5", 0, 16'h0005);

        // MOV R1, R0 — copy R0 into R1
        apply(16'h0200);
        check("MOV R1, R0", 1, 16'h0005);

        // ADD R1, #3 — R1 = R1 + 3
        apply(16'h1303);
        check("ADD R1, #3", 1, 16'h0008);

        // ADD R1, R1, R0 — R1 = R1 + R0
        apply(16'h1204);
        check("ADD R1, R1, R0", 1, 16'h000D);

        // SUB R1, #3 — R1 = R1 - 3
        apply(16'h2303);
        check("SUB R1, #3", 1, 16'h000A);

        // SUB R0, R0, R1 — R0 = R0 - R1
        apply(16'h2020);
        check("SUB R0, R0, R1", 0, 16'hFFFB);

        // MOV R2, #5 — load immediate 5 into R2
        apply(16'h0505);
        check("MOV R2, #5", 2, 16'h0005);

        // ADC R2, #0 — R2 = R2 + 0 + C (C=0)
        FLAGCIN = 0;
        apply(16'h3500);
        check("ADC R2, #0 (C=0)", 2, 16'h0005);

        // Set C=1, ADC R2, #0 — R2 = R2 + 0 + C (C=1)
        FLAGCIN = 1;
        apply(16'h3500);
        check("ADC R2, #0 (C=1)", 2, 16'h0006);

        // SBC R2, #0 — R2 = R2 - 0 - ~C (C=0)
        FLAGCIN = 0;
        apply(16'h4500);
        check("SBC R2, #0 (C=0)", 2, 16'h0005);

        // Set C=1, SBC R2, #0 — R2 = R2 - 0 - ~C (C=1)
        FLAGCIN = 1;
        apply(16'h4500);
        check("SBC R2, #0 (C=1)", 2, 16'h0005);

        // AND R2, R2, R0 — R2 = R2 & R0 (6 & 3 = 2... per annotation expect 1, verify encoding)
        apply(16'h5408);
        check("AND R2, R2, R0", 2, 16'h0001);

        // AND R2, #1 — R2 = R2 & 1
        apply(16'h5501);
        check("AND R2, #1", 2, 16'h0001);

        // MOV R3, #5 — load immediate 5 into R3
        apply(16'h0705);
        check("MOV R3, #5", 3, 16'h0005);

        // CMP R3, R2 — compare R3(5) with R2(1), R3 > R2 so no borrow, C=1
        apply(16'h6640);
        check_flags("CMP R3, R2", 4'b0010);

        // CMP R3, #6 — compare R3(5) with 6, R3 < 6 so borrow, C=0
        apply(16'h6706);
        check_flags("CMP R3, #6", 4'b1000);

        // MOV R4, #255 — load 0xFFFF into R4
        apply(16'h09FF);
        check("MOV R4, #255", 4, 16'hFFFF);

        // LSL R4, R4, #8 — logical shift left by 8: 0xFFFF -> 0xFF00
        apply(16'h7888);
        check("LSL R4, R4, #8", 4, 16'hFF00);

        // LSR R4, R4, #8 — logical shift right by 8: 0xFF00 -> 0x00FF
        apply(16'h7898);
        check("LSR R4, R4, #8", 4, 16'h00FF);

        // EXT #240 — load upper immediate 240 (0xF0) into extension register
        apply(16'hd0f0);
        check("EXT #240", 4, 16'h00FF);

        // MOV R4, #21 — R4 = {EXT, #21} = {0xF0, 0x15} = 0xF015
        apply(16'h0915);
        check("MOV R4, #21", 4, 16'hF015);

        // ASR R4, R4, #4 — arithmetic shift right by 4: 0xF015 -> 0x0F01 (per annotation)
        apply(16'h7984);
        check("ASR R4, R4, #4", 4, 16'hFF01);

        // Set C=0, XSR R4, R4, #4 — shift right by 4, insert C=0 at MSB: 0x0F01 -> 0x00F0
        FLAGCIN = 0;
        apply(16'h7994);
        check("XSR R4, R4, #4 (C=0)", 4, 16'h0FF0);

        // Set C=1, XSR R4, R4, #4 — shift right by 4, insert C=1 at MSB: 0x00F0 -> 0xF00F
        FLAGCIN = 1;
        apply(16'h7994);
        check("XSR R4, R4, #4 (C=1)", 4, 16'hF0FF);

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule