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

    initial begin

        INS = 8'b1;
        #10;
        INS = 8'b0;

    end

    initial begin
        $monitor("INS=%b ||| A=%b B=%b C=%b",
            INS, A, B, C);
    end


endmodule