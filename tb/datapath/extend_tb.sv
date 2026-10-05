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

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] exp_immext,
        input string label
    );
        if (IMMEXT === exp_immext) begin
            $display("PASS | %-30s | IMM=%h EXT=%b IMMEXT=%h", label, IMM, EXT, IMMEXT);
            pass_count++;
        end else begin
            $display("FAIL | %-30s | IMM=%h EXT=%b IMMEXT=%h (expected %h)",
                     label, IMM, EXT, IMMEXT, exp_immext);
            fail_count++;
        end
    endtask

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
        check(16'h29F5, "EXT, (x0029, xFFF5)");

        //No extend
        EXT = 1'b0; IMM = 16'h0029;
        @(posedge clk);
        IMM = 16'hFFF5;
        @(negedge clk);
        check(16'hFFF5, "No EXT, (x0029, xFFF5)");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        #10;
        $finish;
    end

endmodule
