module NZGEN (
    
    input logic [15:0] DATA,

    output logic FLAGN,
    output logic FLAGZ

);

    assign FLAGN = DATA[15];
    assign FLAGZ = (DATA == 16'b0);
    
endmodule