/*
Async ROM to hold pre-loaded program instructions

Connects to CONTROLPATH 
*/

module CODEMEM (

    input logic [15:0] ADDR, //set by PC
    output logic [15:0] DOUT

);

    //16-bit addr gives 2^16 memory locations
    logic [15:0] MEM [0:65535];

    //async read
    assign DOUT = MEM[ADDR];
    
endmodule