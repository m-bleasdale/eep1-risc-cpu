/*

Note: -B = INVERT(B) + 1
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

module ALUDECODE (
    
    input logic [2:0] ALUOPC,
    input logic FLAGCIN,

    output logic ADDSUBCIN,
    output logic INVERT

);

    always_comb begin

        case(ALUOPC)
            3'd1: begin //ADD
                ADDSUBCIN = 1'b0;
                INVERT = 1'b0;
            end
            3'd2: begin //SUB
                ADDSUBCIN = 1'b1;
                INVERT = 1'b1;
            end
            3'd3: begin //ADC
                ADDSUBCIN = FLAGCIN;
                INVERT = 1'b0;
            end
            3'd4: begin //SBC
                ADDSUBCIN = FLAGCIN;
                INVERT = 1'b1;
            end
            3'd6: begin //CMP
                ADDSUBCIN = 1'b0;
                INVERT = 1'b1;
            end
            default: begin
                ADDSUBCIN = 1'b0;
                INVERT = 1'b0;
            end
        endcase
    end
    
endmodule