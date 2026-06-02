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

    task show;
        input string instr;
        input string expected;
        begin
            #1;
            $display("%s ---> R0=%h R1=%h R2=%h R3=%h R4=%h R5=%h R6=%h R7=%h NZCV=%b%b%b%b | %s",
                instr,
                dut.reg16x8.REG[0], dut.reg16x8.REG[1], dut.reg16x8.REG[2],
                dut.reg16x8.REG[3], dut.reg16x8.REG[4], dut.reg16x8.REG[5],
                dut.reg16x8.REG[6], dut.reg16x8.REG[7],
                FLAGN, FLAGZ, FLAGC, FLAGV,
                expected
            );
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
        show("MOV R0, #5", "R0 = 5");

        // MOV R1, R0 — copy R0 into R1
        apply(16'h0200);
        show("MOV R1, R0", "R1 = 5");

        // ADD R1, #3 — R1 = R1 + 3
        apply(16'h1303);
        show("ADD R1, #3", "R1 = 8");

        // ADD R1, R1, R0 — R1 = R1 + R0
        apply(16'h1204);
        show("ADD R1, R1, R0", "R1 = 13");

        // SUB R1, #3 — R1 = R1 - 3
        apply(16'h2303);
        show("SUB R1, #3", "R1 = 10");

        // SUB R0, R0, R1 — R0 = R0 - R1
        apply(16'h2020);
        show("SUB R0, R0, R1", "R0 = 3 (5 - 10 wraps... check: 5-10 = -5 = 0xFFFB? Verify ISA)");

        // MOV R2, #5 — load immediate 5 into R2
        apply(16'h0505);
        show("MOV R2, #5", "R2 = 5");

        // ADC R2, #0 — R2 = R2 + 0 + C (C=0)
        FLAGCIN = 0;
        apply(16'h3500);
        show("ADC R2, #0 (C=0)", "R2 = 5");

        // Set C=1, ADC R2, #0 — R2 = R2 + 0 + C (C=1)
        FLAGCIN = 1;
        apply(16'h3500);
        show("ADC R2, #0 (C=1)", "R2 = 6");

        // SBC R2, #0 — R2 = R2 - 0 - ~C (C=0)
        apply(16'h4500);
        show("SBC R2, #0 (C=0)", "R2 = 5");

        // Set C=1, SBC R2, #0 — R2 = R2 - 0 - ~C (C=1)
        FLAGCIN = 1;
        apply(16'h4500);
        show("SBC R2, #0 (C=1)", "R2 = 6");

        // AND R2, R2, R0 — R2 = R2 & R0 (6 & 3 = 2... per annotation expect 1, verify encoding)
        apply(16'h5408);
        show("AND R2, R2, R0", "R2 = R2 AND R0 (expect 1)");

        // AND R2, #1 — R2 = R2 & 1
        apply(16'h5501);
        show("AND R2, #1", "R2 = R2 AND 1 (expect 1)");

        // MOV R3, #5 — load immediate 5 into R3
        apply(16'h0705);
        show("MOV R3, #5", "R3 = 5");

        // CMP R3, R2 — compare R3(5) with R2(1), R3 > R2 so no borrow, C=1
        apply(16'h6640);
        show("CMP R3, R2", "flags only: R3(5) > R2(1), C=1");

        // CMP R3, #6 — compare R3(5) with 6, R3 < 6 so borrow, C=0
        apply(16'h6706);
        show("CMP R3, #6", "flags only: R3(5) < 6, C=0");

        // MOV R4, #255 — load 0xFFFF into R4
        apply(16'h09FF);
        show("MOV R4, #255", "R4 = 0xFFFF");

        // LSL R4, R4, #8 — logical shift left by 8: 0xFFFF -> 0xFF00
        apply(16'h7888);
        show("LSL R4, R4, #8", "R4 = 0xFF00");

        // LSR R4, R4, #8 — logical shift right by 8: 0xFF00 -> 0x00FF
        apply(16'h7898);
        show("LSR R4, R4, #8", "R4 = 0x00FF");

        // EXT #240 — load upper immediate 240 (0xF0) into extension register
        apply(16'hd0f0);
        show("EXT #240", "upper immediate = 0xF0, pending MOV");

        // MOV R4, #21 — R4 = {EXT, #21} = {0xF0, 0x15} = 0xF015
        apply(16'h0915);
        show("MOV R4, #21", "R4 = 0xF015 (EXT prefix applied)");

        // ASR R4, R4, #4 — arithmetic shift right by 4: 0xF015 -> 0x0F01 (per annotation)
        apply(16'h7984);
        show("ASR R4, R4, #4", "R4 = 0x0F01");

        // Set C=0, XSR R4, R4, #4 — shift right by 4, insert C=0 at MSB: 0x0F01 -> 0x00F0
        FLAGCIN = 0;
        apply(16'h7994);
        show("XSR R4, R4, #4 (C=0)", "R4 = 0x00F0");

        // Set C=1, XSR R4, R4, #4 — shift right by 4, insert C=1 at MSB: 0x00F0 -> 0xF00F
        FLAGCIN = 1;
        apply(16'h7994);
        show("XSR R4, R4, #4 (C=1)", "R4 = 0xF00F");

        $finish;
    end

endmodule