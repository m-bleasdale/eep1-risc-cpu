/*

ADD: INVERT: 0, CARRYIN: 0
SUB: INVERT: 1, CARRYIN: 1
ADC: INVERT: 0, CARRYIN: FLAGCIN
SBC: INVERT: 1, CARRYIN: FLAGCIN
CMP: INVERT: 1, CARRYIN: 1 (no ALU output)

SUB/SBC are inverted due to 2's complement:

-B = INVERT(B) + 1
[INVERT(B) = -B - 1]

ADD - C=0 I=0 
A + B

SUB - C=1 I=1
A + INVERT(B) + 1 = A - B - 1 + 1  = A - B

ADC - C=(1) I=0 (C set by FlagC)
A + B + 1

SBC - C=(0) I=1 (C set by FlagC)
A + INVERT(B) + 0 = A - B - 1 + 0 = A - B - 1

*/

module ADDSUB (
    
    input logic [15:0] INA, 
    input logic [15:0] INB,
    input logic CARRYIN, //Carry in to adder/subtractor (1 for SUB, due to 2's complement)
    input logic INVERT, //Invert INB for subtraction (2's complement)

    output logic [15:0] OUT,
    output logic CARRYOUT, //Feeds into FlagC
    output logic FLAGV //Signed overflow flag

);

    logic [15:0] B;
    assign B = INVERT ? ~INB : INB;

    logic [16:0] SUM;
    assign SUM = {1'b0, INA} + {1'b0, B} + CARRYIN;

    assign OUT = SUM[15:0];
    assign CARRYOUT = SUM[16];
    assign FLAGV = (INA[15] == B[15]) && (OUT[15] != INA[15]);

endmodule