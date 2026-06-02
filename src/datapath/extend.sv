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