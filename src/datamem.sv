/*
Async RAM to hold data stored in memory by program instructions

Connects to the DATAPATH
*/

module DATAMEM (
    
    input logic [15:0] ADDR, //RegB value + offset
    input logic [15:0] DIN, //RegA value from datapath

    input logic WEN, //Write enable control signal

    output logic [15:0] DOUT

);
    
    //16-bit addr gives 2^16 memory locations
    logic [15:0] MEM [0:65535];

    //async read
    assign DOUT = MEM[ADDR];

    //async write
    always_comb begin
        if (WEN) begin
            MEM[ADDR] = DIN;
        end
    end

endmodule