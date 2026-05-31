`timescale 1ns/1ps

module REG16x8_tb;

    logic clk, rst, WEN1;
    logic [2:0] AD1, AD2;
    logic [15:0] DIN1, DOUT2;

    REG16x8 dut (
        .clk(clk),
        .rst(rst),
        .WEN1(WEN1),
        .AD1(AD1),
        .AD2(AD2),
        .AD3(),       
        .DIN1(DIN1),
        .DOUT2(DOUT2),
        .DOUT3()     
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // reset
        WEN1 = 0; AD1 = 0; AD2 = 0; DIN1 = 0;
        rst = 1;
        @(posedge clk);
        rst = 0;

        // write all 8 regs
        WEN1 = 1;
        for (int i = 0; i < 8; i++) begin
            AD1 = i;
            DIN1 = i * 16'h1111;
            @(posedge clk);
            #10;
        end
        WEN1 = 0;

        // read all 8 regs
        for (int i = 0; i < 8; i++) begin
            AD2 = i;
            @(posedge clk);
            $display("reg%0d=%h", AD2, DOUT2);
            if (DOUT2 !== AD2*16'h1111) $error("reg%0d wrong", AD2);
        end

        #10;
        $finish;
    end

endmodule
