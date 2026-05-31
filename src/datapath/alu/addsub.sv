module ADDSUB (
    
    input logic [15:0] INA,
    input logic [15:0] INB,
    input logic CARRYIN,
    input logic INVERT,

    output logic [15:0] OUT,
    output logic CARRYOUT,
    output logic FLAGV

);

    logic [15:0] B;
    assign B = INVERT ? ~INB : INB;

    logic [16:0] SUM;
    assign SUM = {1'b0, INA} + {1'b0, B} + CARRYIN;

    assign OUT = SUM[15:0];
    assign CARRYOUT = SUM[16];
    assign FLAGV = (INA[15] == B[15]) && (OUT[15] != INA[15]);

endmodule