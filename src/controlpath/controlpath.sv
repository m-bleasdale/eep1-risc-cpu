/*

FlagN: Negative (ALU.Out < 0)
FlagZ: Zero (ALU.Out = 0)
FlagC: Carry
FlagV: signed overflow

NZ: written by all ALU instructions.
CV: written by all ALU instructions except MOV and AND.

Flag values in current cycle set by previous cycle/instruction.

Jump is made if condition is met (COND block). Condition set based on NZCV values:
JMPOPC[3:1]   |   JMPOPC[0] = 0  |  JMPOPC[0] = 1
0                 JMP (always)      NOP (never)
1                 JEQ (Z=1)         JNE (Z=0)
2                 JCS (C=1)         JCC (C=0)
3                 JMI (N=1)         JPL (N=0)
4                 JGE (>=)          JLT (<)
5                 JGT (>)           JLE (<=)
6                 JHI (unsigned >)  JLS (unsigned <=)
7                 JSR               RET
JSR and RET are special, they are always carried out.
[Documentation page 6 + COND block for full details]

PC holds memory location of current instruction. 
Next PC value has 3 scenarios:
PCNEXT = PC + 1 (normal)
PCNEXT = PC + OFFSET (jump)
PCNEXT = RA (jump to register value)

*/

module CONTROLPATH (
    
    input logic clk,
    input logic rst,

    //From data path
    input logic ND, ZD, CD, VD, //Flags from current instruction
    input logic [15:0] RA,
    input logic [15:0] IMMEXT,

    //From memory
    input logic [15:0] MEMDATA,

    //To data path
    output logic FLAGC, //FlagC from previous instruction
    output logic [15:0] INS, //Memory output (MEMDATA)
    output logic [15:0] RETADR, //Return addr, PCIN for datapath

    //To memory
    output logic [15:0] MEMADDR

);

    assign INS = MEMDATA;
    assign FLAGC = CQ;

    assign RETADR = PC + 1;
    assign MEMADDR = PC;

    //flags in current cycle, set by previous instruction
    logic NQ, ZQ, CQ, VQ;

    //signals from CONTROLDECODE
    logic [3:0] JMPCOND;
    logic JMP;
    logic [15:0] JOFFSET;
    logic NZEN, CVEN;

    //Program counter 
    logic [15:0] PC, PCNEXT;

    CONTROLDECODE controldecode (
        .INS(INS),
        .IMMEXT(IMMEXT),
        .NZEN(NZEN),
        .CVEN(CVEN),
        .JMP(JMP),
        .JMPCOND(JMPCOND),
        .JOFFSET(JOFFSET)
    );

    NEXT next (
        .PC(PC),
        .PCNEXT(PCNEXT),
        .OFFSET(JOFFSET),
        .RA(RA),
        .JMP(JMP),
        .JMPCOND(JMPCOND),
        .FLAGN(NQ), .FLAGZ(ZQ), .FLAGC(CQ), .FLAGV(VQ)
    );

    //update flags with flag values from previous instruction
    //only if flag write enable signals are set for that instruction
    always_ff @(posedge clk) begin : Flags
        if(rst) begin
            NQ <= 0;
            ZQ <= 0;
            CQ <= 0;
            VQ <= 0;
        end
        else begin
            if(NZEN) begin
                NQ <= ND;
                ZQ <= ZD;
            end
            if(CVEN) begin
                CQ <= CD;
                VQ <= VD;
            end
        end
    end

    //Update PC with output from NEXT block (PCNEXT)
    always_ff @(posedge clk) begin : NextPC
        if(rst) begin
            PC <= 0;
        end
        else begin
            PC <= PCNEXT;
        end
    end

endmodule