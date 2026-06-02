/*

ALUOPC determines which ALU operation to perform

0: MOV - Put Imm value into RA
1: ADD - RA + RB
2: SUB - RA - RB
3: ADC - RA + RB + C
4: SBC - RA - RB + (C - 1)
5: AND - RA & RB
6: CMP - RA - RB (update flags, discard output)
7: SHIFT - Shift RA by Imm value according to SHIFTOPC

ADD, SUB, ADC, SBC - Can be done with Reg or Imm.


Shift type determined by SHIFTOPC.
00: Logical left shift
01: Logical right shift
10: Arithmetic right shift
11: XSR (Right shift, sub in FlagC)

See documentation for instruction encoding.

*/

module DATAPATH (
    
    input logic clk,
    input logic rst,

    //From control path
    input logic [15:0] INS,
    input logic [15:0] PCIN, //Program counter
    input logic FLAGCIN, //FlagC from prev cycle

    //From memory
    input logic [15:0] MEMDOUT,

    //To control path
    output logic [15:0] RAOUT, //Reg output
    output logic [15:0] IMMEXT,
    output logic FLAGN, FLAGZ, FLAGC, FLAGV, //updated flags

    //To memory
    output logic [15:0] MEMADDR,
    output logic [15:0] MEMDIN,
    output logic MEMWEN

);

    logic [15:0] OUT;
    assign OUT = (MEMLDR) ? MEMDOUT : ALUOUT;

    //DPDECODE
    logic [2:0] A, B, C;
    logic [2:0] ALUOPC;
    logic WEN1, AD1SELC, OP2SEL;
    logic [3:0] SCNT;
    logic [1:0] SHIFTOPC;
    logic [15:0] IMMS8, IMMS5;
    logic MEMLDR, MEMSTR;
    logic PCWRITE;
    logic EXT;

    DPDECODE dpdecode (
        .INS(INS),
        .A(A), .B(B), .C(C),
        .ALUOPC(ALUOPC),
        .WEN1(WEN1), .AD1SELC(AD1SELC), .OP2SEL(OP2SEL),
        .SCNT(SCNT), .SHIFTOPC(SHIFTOPC),
        .IMMS8(IMMS8), .IMMS5(IMMS5),
        .MEMLDR(MEMLDR), .MEMSTR(MEMSTR),
        .PCWRITE(PCWRITE),
        .EXT(EXT)
    );

    //Register addresses
    logic [2:0] AD1;
    assign AD1 = (AD1SELC) ? C : A;

    //Register data in/out
    logic [15:0] DIN1;
    logic [15:0] DOUT2, DOUT3;

    assign DIN1 = (PCWRITE) ? PCIN : OUT;

    assign RAOUT = DOUT2;

    REG16x8 reg16x8 (
        .clk(clk), .rst(rst),
        .WEN1(WEN1),
        .AD1(AD1), .AD2(A), .AD3(B),
        .DIN1(DIN1),
        .DOUT2(DOUT2), .DOUT3(DOUT3)
    );

    //Extend
    EXTEND extend (
        .clk(clk), .rst(rst),
        .IMM(IMMS8),
        .EXT(EXT),
        .IMMEXT(IMMEXT)
    );

    //ALU
    logic [15:0] ALUOUT;

    ALU alu (
        .ALUOPC(ALUOPC),
        .SCNT(SCNT),
        .SHIFTOPC(SHIFTOPC),
        .OP2SEL(OP2SEL),
        .FLAGCIN(FLAGCIN),
        .RA(DOUT2),
        .RB(DOUT3),
        .IMM(IMMEXT),
        .FLAGC(FLAGC),
        .FLAGV(FLAGV),
        .OUT(ALUOUT)
    );

    //Flags
    NZGEN nzgen (
        .DATA(OUT),
        .FLAGN(FLAGN),
        .FLAGZ(FLAGZ)
    );

    //Memory
    assign MEMDIN = DOUT2;
    assign MEMADDR = OP2SEL ? IMMEXT : (DOUT3 + IMMS5);
    assign MEMWEN = MEMSTR;
    

endmodule