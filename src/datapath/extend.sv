/*
The max input size for an IMM is 8-bits.
Registers are 16-bits, so the upper 8-bits of any input IMM must be extended to 16-bits.

Normally sign extension is done: 
    0x00 -> 0x0000
    0x01 -> 0x0001
    0x7F -> 0x007F
    0x80 -> 0xFF80
    0xFF -> 0xFFFF
MSB of IMM is copyed to the upper 8-bits of IMMEXT

An EXT instruction can be used, with an 8-bit input, to set the upper 8 bits of the next input.
Eg:
    EXT 0xAB (cycle 1)
    IMM 0xCD (cycle 2)
    IMMEXT = 0xABCD (cycle 2)

A register is used to hold the upper 8-bits from the EXT instruction, and is used to extend the IMM on the next cycle.

*/

module EXTEND (
    
    input logic clk,
    input logic rst,

    input logic [15:0] IMM,
    input logic EXT,

    output logic [15:0] IMMEXT

);

    logic [7:0] IMM_d_upper; //holds the upper 8bits of the output (from lower 8 of EXT instruction) 
    logic EXT_d;

    //DFF for IMM and EXT from prev cycle
    always_ff @( posedge clk ) begin 
        if (rst) begin 
            IMM_d_upper <= 8'b0;
            EXT_d <= 1'b0;
        end
        else begin
            IMM_d_upper <= IMM[7:0];
            EXT_d <= EXT;
        end
    end

    assign IMMEXT = EXT_d ? {IMM_d_upper, IMM[7:0]} : IMM;

endmodule