module ADDSUB_tb;

    logic [15:0] INA;
    logic [15:0] INB;
    logic CARRYIN;
    logic INVERT;

    logic [15:0] OUT;
    logic CARRYOUT;
    logic FLAGV;

    // DUT
    ADDSUB dut (
        .INA(INA),
        .INB(INB),
        .CARRYIN(CARRYIN),
        .INVERT(INVERT),
        .OUT(OUT),
        .CARRYOUT(CARRYOUT),
        .FLAGV(FLAGV)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic [15:0] exp_out,
        input logic exp_cout, exp_v,
        input string label
    );
        if (OUT === exp_out && CARRYOUT === exp_cout && FLAGV === exp_v) begin
            $display("PASS | %-20s | OUT=%0d CARRYOUT=%b FLAGV=%b", label, OUT, CARRYOUT, FLAGV);
            pass_count++;
        end else begin
            $display("FAIL | %-20s | OUT=%0d CARRYOUT=%b FLAGV=%b (expected OUT=%0d CARRYOUT=%b FLAGV=%b)",
                     label, OUT, CARRYOUT, FLAGV, exp_out, exp_cout, exp_v);
            fail_count++;
        end
    endtask

    initial begin
        // ADD (A + B)
        INA = 16'd10; INB = 16'd5; CARRYIN = 0; INVERT = 0; #10;
        check(16'd15, 0, 0, "ADD: 10 + 5");

        // ADC (A + B + 1)
        INA = 16'd10; INB = 16'd5; CARRYIN = 1; INVERT = 0; #10;
        check(16'd16, 0, 0, "ADC: 10 + 5 + 1");

        // SUB (A - B)
        INA = 16'd10; INB = 16'd5; CARRYIN = 1; INVERT = 1; #10;
        check(16'd5, 1, 0, "SUB: 10 - 5");

        // SBC (A - B - 1)
        INA = 16'd10; INB = 16'd5; CARRYIN = 0; INVERT = 1; #10;
        check(16'd4, 1, 0, "SBC: 10 - 5 - 1");

        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
