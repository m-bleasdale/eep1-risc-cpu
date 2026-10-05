module ALU_tb;

    logic [2:0] ALUOPC;
    logic [3:0] SCNT;
    logic [1:0] SHIFTOPC;
    logic OP2SEL;

    logic FLAGCIN;

    logic [15:0] RA, RB, IMM;

    logic FLAGC, FLAGV;
    logic [15:0] OUT;

    ALU dut (
        .ALUOPC(ALUOPC),
        .SCNT(SCNT),
        .SHIFTOPC(SHIFTOPC),
        .OP2SEL(OP2SEL),
        .FLAGCIN(FLAGCIN),
        .RA(RA),
        .RB(RB),
        .IMM(IMM),
        .FLAGC(FLAGC),
        .FLAGV(FLAGV),
        .OUT(OUT)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] exp_out,
        input logic exp_c, exp_v,
        input string label
    );
        if (OUT === exp_out && FLAGC === exp_c && FLAGV === exp_v) begin
            $display("PASS | %-30s | OUT=%h FLAGC=%b FLAGV=%b", label, OUT, FLAGC, FLAGV);
            pass_count++;
        end else begin
            $display("FAIL | %-30s | OUT=%h FLAGC=%b FLAGV=%b (expected OUT=%h FLAGC=%b FLAGV=%b)",
                     label, OUT, FLAGC, FLAGV, exp_out, exp_c, exp_v);
            fail_count++;
        end
    endtask

    initial begin

        FLAGCIN=0; SCNT=0; SHIFTOPC=0;

        //MOV
        ALUOPC=3'd0; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        check(16'd5, 0, 0, "MOV: RB=5");

        //AND
        ALUOPC=3'd5; OP2SEL=0; RA=16'hF0F0; RB=16'h0FF0; IMM=16'hAAAA; #10;
        check(16'h00F0, 1, 0, "AND: F0F0 & 0FF0");

        //ADD RB
        ALUOPC=3'd1; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        check(16'd15, 0, 0, "ADD RB: 10 + 5");

        //ADD IMM
        ALUOPC=3'd1; OP2SEL=1; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        check(16'd13, 0, 0, "ADD IMM: 10 + 3");

        //SUB RB
        ALUOPC=3'd2; OP2SEL=0; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        check(16'd15, 1, 0, "SUB RB: 20 - 5");

        //SUB IMM
        ALUOPC=3'd2; OP2SEL=1; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        check(16'd17, 1, 0, "SUB IMM: 20 - 3");

        //ADC RB
        //FLAGCIN = 1 (A+B+CARRYIN)
        FLAGCIN=1;
        ALUOPC=3'd3; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        check(16'd16, 0, 0, "ADC RB (C=1): 10 + 5 + 1");

        //ADC IMM
        ALUOPC=3'd3; OP2SEL=1; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        check(16'd14, 0, 0, "ADC IMM (C=1): 10 + 3 + 1");

        FLAGCIN=0;

        //SBC RB
        //FLAGCIN = 0 (A-B-1)
        ALUOPC=3'd4; OP2SEL=0; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        check(16'd14, 1, 0, "SBC RB (C=0): 20 - 5 - 1");

        //SBC IMM
        ALUOPC=3'd4; OP2SEL=1; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        check(16'd16, 1, 0, "SBC IMM (C=0): 20 - 3 - 1");

        FLAGCIN=0;

        //CMP
        ALUOPC=3'd6; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        check(16'd5, 1, 0, "CMP: 10 - 5");


        //SHIFT LSL
        ALUOPC=3'd7; OP2SEL=0; RA=16'h00F0; SCNT=4'd1; SHIFTOPC=2'b00; #10;
        check(16'h01E0, 0, 0, "LSL: 00F0 << 1");

        //SHIFT LSR
        ALUOPC=3'd7; SHIFTOPC=2'b01; #10;
        check(16'h0078, 0, 0, "LSR: 00F0 >> 1");

        //SHIFT ASR
        ALUOPC=3'd7; RA=16'hF0F0; SHIFTOPC=2'b10; #10;
        check(16'hF878, 0, 0, "ASR: F0F0 >> 1");

        //SHIFT XSR (C=1)
        FLAGCIN=1;
        ALUOPC=3'd7; RA=16'h8001; SHIFTOPC=2'b11; #10;
        check(16'hC000, 1, 0, "XSR C=1: 8001 >> 1");

        //SHIFT XSR (C=0)
        FLAGCIN=0;
        ALUOPC=3'd7; RA=16'h8001; SHIFTOPC=2'b11; #10;
        check(16'h4000, 1, 0, "XSR C=0: 8001 >> 1");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
