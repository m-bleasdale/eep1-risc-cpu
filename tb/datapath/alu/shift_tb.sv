module SHIFT_tb;

    logic [15:0] IN;
    logic SFTIN;
    logic [1:0] SHIFTOPC;
    logic [3:0] SCNT;

    logic [15:0] OUT;
    logic SFTOUT;

    // DUT
    SHIFT dut (
        .IN(IN),
        .SFTIN(SFTIN),
        .SHIFTOPC(SHIFTOPC),
        .SCNT(SCNT),
        .OUT(OUT),
        .SFTOUT(SFTOUT)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] exp_out,
        input logic exp_sftout,
        input string label
    );
        if (OUT === exp_out && SFTOUT === exp_sftout) begin
            $display("PASS | %-12s | OUT=%b SFTOUT=%b", label, OUT, SFTOUT);
            pass_count++;
        end else begin
            $display("FAIL | %-12s | OUT=%b SFTOUT=%b (expected OUT=%b SFTOUT=%b)",
                     label, OUT, SFTOUT, exp_out, exp_sftout);
            fail_count++;
        end
    endtask

    initial begin
        // LSL
        IN = 16'b0001_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b00; #10;
        check(16'b0010_0110_1011_1100, 0, "LSL 1");

        // LSL (SOFTOUT)
        IN = 16'b1101_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b00; #10;
        check(16'b1010_0110_1011_1100, 1, "LSL SO");

        // LSL (SOFTOUT) 2 bits
        IN = 16'b0101_0011_0101_1110;
        SCNT = 2; SHIFTOPC = 2'b00; #10;
        check(16'b0100_1101_0111_1000, 1, "LSL SO 2");

        // LSR
        IN = 16'b1001_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b01; #10;
        check(16'b0100_1001_1010_1111, 0, "LSR 1");

        // LSR (SFTOUT)
        IN = 16'b1001_0011_0101_1111;
        SCNT = 1; SHIFTOPC = 2'b01; #10;
        check(16'b0100_1001_1010_1111, 1, "LSR SO");

        // LSR (SFTOUT) 2 bits
        IN = 16'b1001_0011_0101_1010;
        SCNT = 2; SHIFTOPC = 2'b01; #10;
        check(16'b0010_0100_1101_0110, 1, "LSR SO 2");

        // ASR
        IN = 16'b1001_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b10; #10;
        check(16'b1100_1001_1010_1111, 0, "ASR 1");

        // XSR (test both carry in cases)
        IN = 16'b0000_1111_0000_1111;
        SCNT = 2; SHIFTOPC = 2'b11;

        SFTIN = 1; #10;
        check(16'b1100_0011_1100_0011, 1, "XSR 2 C=1");

        SFTIN = 0; #10;
        check(16'b0000_0011_1100_0011, 1, "XSR 2 C=0");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
