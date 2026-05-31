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

    initial begin

        FLAGCIN=0; SCNT=0; SHIFTOPC=0;

        //MOV
        ALUOPC=3'd0; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        $display("MOV: RA=10 -> OUT=%h FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //AND
        ALUOPC=3'd5; OP2SEL=0; RA=16'hF0F0; RB=16'h0FF0; IMM=16'hAAAA; #10;
        $display("AND: F0F0 & 0FF0 -> OUT=%h FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //ADD RB
        ALUOPC=3'd1; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        $display("ADD RB: 10 + 5 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //ADD IMM
        ALUOPC=3'd1; OP2SEL=1; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        $display("ADD IMM: 10 + 3 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //SUB RB
        ALUOPC=3'd2; OP2SEL=0; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        $display("SUB RB: 20 - 5 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //SUB IMM
        ALUOPC=3'd2; OP2SEL=1; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        $display("SUB IMM: 20 - 3 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //ADC RB
        //FLAGCIN = 1 (A+B+CARRYIN)
        FLAGCIN=1; 
        ALUOPC=3'd3; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        $display("ADC RB (C=1): 10 + 5 + 1 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //ADC IMM
        ALUOPC=3'd3; OP2SEL=1; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        $display("ADC IMM (C=1): 10 + 3 + 1 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        FLAGCIN=0;

        //SBC RB
        //FLAGCIN = 0 (A-B-1)
        ALUOPC=3'd4; OP2SEL=0; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        $display("SBC RB (C=0): 20 - 5 - 1 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        //SBC IMM
        ALUOPC=3'd4; OP2SEL=1; RA=16'd20; RB=16'd5; IMM=16'd3; #10;
        $display("SBC IMM (C=0): 20 - 3 - 1 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);

        FLAGCIN=0;

        //CMP
        ALUOPC=3'd6; OP2SEL=0; RA=16'd10; RB=16'd5; IMM=16'd3; #10;
        $display("CMP: 10 - 5 -> OUT=%d FLAGC=%b FLAGV=%b", OUT, FLAGC, FLAGV);


        //SHIFT LSL
        ALUOPC=3'd7; OP2SEL=0; RA=16'h00F0; SCNT=4'd1; SHIFTOPC=2'b00; #10;
        $display("LSL: 00F0 << 1 -> OUT=%h FLAGC=%b", OUT, FLAGC);

        //SHIFT LSR
        ALUOPC=3'd7; SHIFTOPC=2'b01; #10;
        $display("LSR: 00F0 >> 1 -> OUT=%h FLAGC=%b", OUT, FLAGC);

        //SHIFT ASR
        ALUOPC=3'd7; RA=16'hF0F0; SHIFTOPC=2'b10; #10;
        $display("ASR: F0F0 >> 1 -> OUT=%h FLAGC=%b", OUT, FLAGC);

        //SHIFT XSR (C=1)
        FLAGCIN=1;
        ALUOPC=3'd7; RA=16'h8001; SHIFTOPC=2'b11; #10;
        $display("XSR C=1: 8001 >> 1 -> OUT=%h FLAGC=%b", OUT, FLAGC);

        //SHIFT XSR (C=0)
        FLAGCIN=0;
        ALUOPC=3'd7; RA=16'h8001; SHIFTOPC=2'b11; #10;
        $display("XSR C=0: 8001 >> 1 -> OUT=%h FLAGC=%b", OUT, FLAGC);

        $finish;
    end

endmodule