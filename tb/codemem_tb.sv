`timescale 1ns/1ps

module CODEMEM_tb;

    logic [15:0] ADDR;
    logic [15:0] DOUT;

    CODEMEM dut (
        .ADDR(ADDR),
        .DOUT(DOUT)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] addr,
        input logic [15:0] exp_dout,
        input string label
    );
        ADDR = addr;
        #1;

        if (DOUT === exp_dout) begin
            $display("PASS | %-30s | DOUT=%0h", label, DOUT);
            pass_count++;
        end else begin
            $display("FAIL | %-30s | DOUT=%0h (expected %0h)", label, DOUT, exp_dout);
            fail_count++;
        end
    endtask

    initial begin
        //pre-load ROM contents
        dut.MEM[0] = 16'hA001;
        dut.MEM[1] = 16'hB002;
        dut.MEM[2] = 16'hC003;
        dut.MEM[16'hFFFF] = 16'h1234;

        //reads
        check(16'h0000, 16'hA001, "Read addr 0x0000");
        check(16'h0001, 16'hB002, "Read addr 0x0001");
        check(16'h0002, 16'hC003, "Read addr 0x0002");
        check(16'hFFFF, 16'h1234, "Read addr 0xFFFF (boundary)");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule