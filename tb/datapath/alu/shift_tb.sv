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

    initial begin
        // LSL
        IN = 16'b0001_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b00; #10;
        $display("LSL 1  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // LSL (SOFTOUT)
        IN = 16'b1101_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b00; #10;
        $display("LSL SO  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // LSL (SOFTOUT) 2 bits
        IN = 16'b0101_0011_0101_1110;
        SCNT = 2; SHIFTOPC = 2'b00; #10;
        $display("LSL SO 2  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // LSR
        IN = 16'b1001_0011_0101_1110;
        SCNT = 1; SHIFTOPC = 2'b01; #10;
        $display("LSR 1  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // LSR (SFTOUT)
        IN = 16'b1001_0011_0101_1111;
        SCNT = 1; SHIFTOPC = 2'b01; #10;
        $display("LSR SO  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // LSR (SFTOUT) 2 bits
        IN = 16'b1001_0011_0101_1010;
        SCNT = 2; SHIFTOPC = 2'b01; #10;
        $display("LSR SO 2  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // ASR
        IN = 16'b1001_0011_0101_1110; 
        SCNT = 1; SHIFTOPC = 2'b10; #10;
        $display("ASR 1  OUT=%b SFTOUT=%b", OUT, SFTOUT);

        // XSR (test both carry in cases)
        IN = 16'b0000_1111_0000_1111;
        SCNT = 2; SHIFTOPC = 2'b11;

        SFTIN = 1; #10;
        $display("XSR 2 C=1 OUT=%b SFTOUT=%b", OUT, SFTOUT);

        SFTIN = 0; #10;
        $display("XSR 2 C=0 OUT=%b SFTOUT=%b", OUT, SFTOUT);

        $finish;
    end

endmodule