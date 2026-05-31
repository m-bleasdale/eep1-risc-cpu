`timescale 1ns/1ps

module EXTEND_TB;

    logic clk, rst;
    logic [15:0] IMM;
    logic EXT;
    logic [15:0] IMMEXT;

    EXTEND dut (
        .clk(clk),
        .rst(rst),
        .IMM(IMM),
        .EXT(EXT),
        .IMMEXT(IMMEXT)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // reset
        rst = 1;
        @(posedge clk);
        rst = 0;

        // Extend
        EXT = 1'b1; IMM = 16'h0029;
        @(posedge clk);
        EXT = 1'b0; IMM = 16'hFFF5;
        @(negedge clk);
        $display("EXT, (x0029, xFFF5), IMM=%h EXT=%b IMMEXT=%h", IMM, EXT, IMMEXT);

        //No extend
        EXT = 1'b0; IMM = 16'h0029;
        @(posedge clk);
        IMM = 16'hFFF5;
        @(negedge clk);
        $display("No EXT, (x0029, xFFF5), IMM=%h EXT=%b IMMEXT=%h", IMM, EXT, IMMEXT);

        #10;
        $finish;
    end
    
endmodule