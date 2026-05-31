module REG16x8 (
    input logic clk,
    input logic WEN1,

    input logic rst,

    input logic [2:0] AD1,
    input logic [2:0] AD2,
    input logic [2:0] AD3,

    input logic [15:0] DIN1,
    output logic [15:0] DOUT2,
    output logic [15:0] DOUT3
);

    reg [15:0] REG [7:0];

    //Write + initial reset
    always_ff @( posedge clk ) begin
        if(rst) begin 
            for (int i = 0; i < 8; i++)
                REG[i] <= 16'b0;
        end
        else if(WEN1) begin
            REG[AD1] <= DIN1;
        end
    end

    //Read
    always_comb begin
        DOUT2 = REG[AD2];
        DOUT3 = REG[AD3];
    end

endmodule