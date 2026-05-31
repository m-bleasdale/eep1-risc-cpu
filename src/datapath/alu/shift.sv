/*

SHIFTOPC

00: LSL (Logical Left) 
01: LSR (Logical Right)
10: ASR (Arithmetic Right)
11: XSR (Right, shift in FlagC)

*/

module SHIFT (
    
    input logic [15:0] IN,

    input logic SFTIN, //bit to shift in (0/1)
    input logic [1:0] SHIFTOPC,
    input logic [3:0] SCNT, //how much to shift by

    output logic [15:0] OUT,
    output logic SFTOUT //bit shifted out

);

    always_comb begin
        case(SHIFTOPC)
            2'b00: begin //LSL
                OUT = IN << SCNT;
                SFTOUT = (SCNT == 0) ? 1'b0 : IN[16 - SCNT];
            end
            2'b01: begin //LSR
                OUT = IN >> SCNT;
                SFTOUT = (SCNT == 0) ? 1'b0 : IN[SCNT-1];
            end
            2'b10: begin //ASR
                OUT = $signed(IN) >>> SCNT;
                SFTOUT = (SCNT == 0) ? 1'b0 : IN[SCNT-1];
            end
            2'b11: begin //XSR
                OUT = (IN >> SCNT) | ({16{SFTIN}} << (16 - SCNT));
                SFTOUT = (SCNT == 0) ? 1'b0 : IN[SCNT-1];
                
            end
            default: begin
                OUT = IN;
                SFTOUT = 1'b0;
            end
        endcase


    end
    
endmodule