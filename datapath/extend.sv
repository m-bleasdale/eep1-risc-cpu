module EXTEND (
    
    input logic clk,
    input logic rst,

    input logic [15:0] IMM,
    input logic EXT,

    output logic [15:0] IMMEXT

);

    logic [15:0] IMM_d;
    logic EXT_d;

    //DFF for IMM and EXT from prev cycle
    always_ff @( posedge clk ) begin 
        if (rst) begin 
            IMM_d <= 16'b0;
            EXT_d <= 1'b0;
        end
        else begin
            IMM_d <= IMM;
            EXT_d <= EXT;
        end
    end

    logic [7:0] IMM_low;
    assign IMM_low = IMM[7:0];

    logic [7:0] IMM_high;
    assign IMM_high = EXT_d ? IMM_d[7:0] : IMM[15:8];

    always_comb begin
        IMMEXT = {IMM_high, IMM_low};
    end

endmodule