/*

All ALU operations update FlagN and FlagZ.
All ALU operation except MOV and AND update FlagC and FlagV.
Jump and EXT instructions do not update any flags.

INS[15] = 0 for ALU operations, 1 for jump and EXT instructions.

*/

module CONTROLDECODE (
    
    input logic [15:0] INS, //current instruction
    input logic [15:0] IMMEXT, //extended IMM from datapath (output of EXT block)

    output logic NZEN, //enable write for FlagN and FlagZ
    output logic CVEN, //enable write for FlagC and FlagV

    output logic JMP, //jump control signal (is jump instruction)
    output logic [3:0] JMPCOND, //jump condition (see COND block)

    output logic [15:0] JOFFSET 

);

    assign JOFFSET = IMMEXT;

    assign JMPCOND = INS[11:8];

    assign NZEN = !INS[15]; //NZ enabled for all ALU operations only

    logic [2:0] ALUOPC;
    assign ALUOPC = INS[14:12];

    assign JMP = (INS[15:12] == 4'b1100); //all JMP instructions start with 1100

    //CV enabled for all ALU operations except MOV and AND
    always_comb begin
        case(ALUOPC)
            3'd0: CVEN = 0; //MOV
            3'd1: CVEN = NZEN; //ADD
            3'd2: CVEN = NZEN; //SUB
            3'd3: CVEN = NZEN; //ADC
            3'd4: CVEN = NZEN; //SBC
            3'd5: CVEN = 0; //AND
            3'd6: CVEN = NZEN; //CMP
            3'd7: CVEN = NZEN; //SHIFT
            default: CVEN = 0;
        endcase
    end

endmodule