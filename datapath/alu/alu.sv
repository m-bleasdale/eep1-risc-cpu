/*
    MOV = 0,
    ADD = 1,
    SUB = 2,
    ADC = 3,
    SBC = 4,
    AND = 5,
    CMP = 6,
    SHIFT = 7
*/

module ALU (
    
    //Control signals
    input logic [2:0] ALUOPC,
    input logic [3:0] SCNT,
    input logic [1:0] SHIFTOPC,
    input logic OP2SEL,

    input logic FLAGCIN,

    //Data signals
    input logic [15:0] RA,
    input logic [15:0] RB,
    input logic [15:0] IMM,

    //Flag outputs
    output logic FLAGC,
    output logic FLAGV,

    //Output
    output logic [15:0] OUT

);

    //Selects between Reg or Imm for operand 2 (operand 1 is always a register)
    logic [15:0] INB;
    assign INB = (OP2SEL) ? IMM : RB;

    //ALUDECODE outputs
    logic ADDSUBCIN, INVERT;

    //ADDSUB and SHIFT outputs
    logic [15:0] ADDOUT, SHIFTOUT;
    logic ADDCARRY, SHIFTCARRY;

    ALUDECODE aludecode (
        .ALUOPC(ALUOPC),
        .FLAGCIN(FLAGCIN),
        .ADDSUBCIN(ADDSUBCIN),
        .INVERT(INVERT)
    );

    ADDSUB addsub (
        .INA(RA),
        .INB(INB),
        .CARRYIN(ADDSUBCIN),
        .INVERT(INVERT),
        .OUT(ADDOUT),
        .CARRYOUT(ADDCARRY),
        .FLAGV(FLAGV)
    );

    SHIFT shift (
        .IN(RA),
        .SCNT(SCNT),
        .SHIFTOPC(SHIFTOPC),
        .SFTIN(FLAGCIN),
        .OUT(SHIFTOUT),
        .SFTOUT(SHIFTCARRY)
    );

    //AND (ALUOPC = 5) bitwise
    logic [15:0] ANDOUT;
    assign ANDOUT = RA & INB;

    //ALU Outputs
    always_comb begin
        case(ALUOPC)
            3'd7: OUT = SHIFTOUT; //SHIFT
            3'd1, 3'd2, 3'd3, 3'd4, 3'd6: OUT = ADDOUT; //ADD, SUB, ADC, SBC, CMP
            3'd5: OUT = ANDOUT; //AND
            default: OUT = 16'b0; //MOV, undefined
        endcase
    end

    //FlagC
    assign FLAGC = (ALUOPC == 3'd7) ? SHIFTCARRY : ADDCARRY;
    
endmodule