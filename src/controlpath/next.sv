/*
Determines next PC value.

3 scenarios:

PCNEXT = PC + 1 (normal)
PCNEXT = PC + OFFSET (jump)
PCNEXT = RA (jump to register value)

*/

module NEXT (
    
    input logic [15:0] PC,
    
    input logic [15:0] OFFSET, 
    input logic [15:0] RA, //value from register
    
    input logic JMP, //jump control signal (is jump instruction)
    input logic [3:0] JMPCOND, //see COND block

    input logic FLAGN, FLAGZ, FLAGC, FLAGV,

    output logic [15:0] PCNEXT

);

    logic RET;
    logic JUMP;

    COND cond (
        .JMPCOND(JMPCOND),
        .FLAGN(FLAGN),
        .FLAGZ(FLAGZ),
        .FLAGC(FLAGC),
        .FLAGV(FLAGV),
        .JUMP(JUMP),
        .RET(RET)
    );

    always_comb begin 

        PCNEXT = (JMP && RET) ? RA : 
            (JMP && JUMP) ? (PC + OFFSET) : 
            (PC + 1);

    end
    
endmodule