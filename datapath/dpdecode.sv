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

module DPDECODE (
    input logic [15:0] INS,

    //Reg addr
    output logic [2:0] A,
    output logic [2:0] B,
    output logic [2:0] C,

    output logic [2:0] ALUOPC,

    //control signals
    output logic WEN1,
    output logic AD1SELC,
    output logic OP2SEL,
    output logic EXT,

    //shift
    output logic [3:0] SCNT,
    output logic [1:0] SHIFTOPC,

    //immediates
    output logic [15:0] IMMS8,
    output logic [15:0] IMMS5,

    //memory signals
    output logic MEMLDR,
    output logic MEMSTR,

    //program counter write
    output logic PCWRITE

);

    assign A = INS[11:9];
    assign B = INS[7:5];
    assign C = INS[4:2];

    assign ALUOPC = INS[14:12];

    assign OP2SEL = INS[8];

    assign EXT = (INS[15:8] == 8'd0) ? 1'b1 : 1'b0;

    assign SCNT = INS[3:0];
    assign SHIFTOPC = {INS[8], INS[4]};

    //Sign extend IMMS8 and IMMS5
    assign IMMS8 = {{8{INS[7]}}, INS[7:0]};
    assign IMMS5 = {{11{INS[4]}}, INS[4:0]};

    assign MEMLDR = (INS[15:13] == 3'd4) ? 1'b1 : 1'b0;
    assign MEMSTR = (INS[15:13] == 3'd5) ? 1'b1 : 1'b0;

    //Only for JSR
    assign PCWRITE = (INS[15:8] == 8'b1100_1110) ? 1'b1 : 1'b0;

    //WEN1 and AD1SELC depend on ALUOPC
    always_comb begin

        //WEN1=1 for: all ALU except CMP; LDR; JSR
        if(ALUOPC != 3'd6 && INS[15] == 1'b0) begin 
            WEN1 = 1'b1;
        end 
        if (MEMLDR || PCWRITE) begin 
            WEN1 = 1'b1;
        end 
        else begin
            WEN1 = 1'b0;
        end

        //AD1SELC for: MOV, CMP, SHIFT
        if(ALUOPC == 3'd0 || ALUOPC == 3'd6 || ALUOPC == 3'd7) begin
            AD1SELC = 1'b0;
        end else if (!INS[8]) begin
            AD1SELC = 1'b1;
        end else begin
            AD1SELC = 1'b0;
        end
        
    end

endmodule