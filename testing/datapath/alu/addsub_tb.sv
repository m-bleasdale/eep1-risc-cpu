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

    initial begin
        // ADD (A + B)
        INA = 16'd10; INB = 16'd5; CARRYIN = 0; INVERT = 0; #10;
        $display("ADD: %0d + %0d = %0d", INA, INB, OUT);

        // ADC (A + B + 1)
        INA = 16'd10; INB = 16'd5; CARRYIN = 1; INVERT = 0; #10;
        $display("ADC: %0d + %0d + 1 = %0d", INA, INB, OUT);

        // SUB (A - B)
        INA = 16'd10; INB = 16'd5; CARRYIN = 1; INVERT = 1; #10;
        $display("SUB: %0d - %0d = %0d", INA, INB, OUT);

        // SBC (A - B - 1)
        INA = 16'd10; INB = 16'd5; CARRYIN = 0; INVERT = 1; #10;
        $display("SBC: %0d - %0d - 1 = %0d", INA, INB, OUT);

        $finish;
    end

endmodule