/*
JMPOPC determines which jump condition to check for. If satisfied, jump.
JMPOPC[3:1] - which jump
JMOPC[0] - whether to invert condition 

See documentation for full conditions (page 6)

JMPOPC[3:1]   |   JMPOPC[0] = 0  |  JMPOPC[0] = 1
0                 JMP (always)      NOP (never)
1                 JEQ (Z=1)         JNE (Z=0)
2                 JCS (C=1)         JCC (C=0)
3                 JMI (N=1)         JPL (N=0)
4                 JGE (>=)          JLT (<)
5                 JGT (>)           JLE (<=)
6                 JHI (unsigned >)  JLS (unsigned <=)
7                 JSR               RET

JSR and RET are special jumps for subroutine calls and returns.
Both carried out always.

*/

module COND (
    
    input logic [3:0] JMPCOND,
    input logic FLAGN, FLAGZ, FLAGC, FLAGV,

    output logic JUMP, //jump condition met
    output logic RET 

);

    logic [2:0] JMPOPC;
    assign JMPOPC = JMPCOND[3:1];

    logic INVERT;
    assign INVERT = JMPCOND[0];

    //OUT holds JUMP before inversion cond evaluated
    logic OUT;

    always_comb begin
        case(JMPOPC)
            3'd0: OUT = 1; //JMP (always)
            3'd1: OUT = FLAGZ; //JEQ 
            3'd2: OUT = FLAGC; //JCS
            3'd3: OUT = FLAGN; //JMI
            3'd4: OUT = (~FLAGN) ^ FLAGV; //JGE
            3'd5: OUT = ((~FLAGN) ^ FLAGV) && (~FLAGZ); //JGT
            3'd6: OUT = FLAGC && (~FLAGZ); //JHI
            3'd7: OUT = 1;
            default: OUT = 0;
        endcase

        JUMP = (JMPOPC != 3'd7 && INVERT) ? ~OUT : OUT;

        RET = (JMPCOND == 4'hf);

    end
    
endmodule