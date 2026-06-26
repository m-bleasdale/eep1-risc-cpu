`timescale 1ns/1ps

module DATAMEM_tb;

    logic [15:0] ADDR;
    logic [15:0] DIN;
    logic WEN;
    logic [15:0] DOUT;

    DATAMEM dut (
        .ADDR(ADDR),
        .DIN(DIN),
        .WEN(WEN),
        .DOUT(DOUT)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] addr,
        input logic [15:0] din,
        input logic wen,
        input logic [15:0] exp_dout,
        input string label
    );
        ADDR = addr;
        DIN = din;
        WEN = wen;
        #1;

        if (DOUT === exp_dout) begin
            $display("PASS | %-40s | DOUT=%0h", label, DOUT);
            pass_count++;
        end else begin
            $display("FAIL | %-40s | DOUT=%0h (expected %0h)", label, DOUT, exp_dout);
            fail_count++;
        end
    endtask

    initial begin
        ADDR = 16'h0000;
        DIN = 16'h0000;
        WEN = 1'b0;

        //WEN=1, write and read back
        check(16'h0000, 16'h0001, 1, 16'h0001, "Write 0x0001 to addr 0x0000");
        check(16'h0001, 16'h0002, 1, 16'h0002, "Write 0x0002 to addr 0x0001");
        check(16'h0010, 16'h00FF, 1, 16'h00FF, "Write 0x00FF to addr 0x0010");
        check(16'hFFFF, 16'hFFFF, 1, 16'hFFFF, "Write 0xFFFF to addr 0xFFFF (boundary)");

        //WEN=0, no write, only read
        check(16'h0000, 16'h0000, 0, 16'h0001, "Read addr 0x0000 WEN=0");
        check(16'h0001, 16'h0000, 0, 16'h0002, "Read addr 0x0001 WEN=0");
        check(16'h0010, 16'h0000, 0, 16'h00FF, "Read addr 0x0010 WEN=0");
        check(16'hFFFF, 16'h0000, 0, 16'hFFFF, "Read addr 0xFFFF WEN=0");

        //WEN=0, test overwrite doesn't occur
        check(16'h0000, 16'hAAAA, 0, 16'h0001, "No overwrite addr 0x0000 WEN=0");
        check(16'h0010, 16'hAAAA, 0, 16'h00FF, "No overwrite addr 0x0010 WEN=0");

        //Attempt to overwrite with WEN=1 and WEN=0
        check(16'h0000, 16'h0099, 1, 16'h0099, "Overwrite addr 0x0000 with 0x0099");
        check(16'h0000, 16'h0000, 0, 16'h0099, "Read addr 0x0000 after overwrite");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule