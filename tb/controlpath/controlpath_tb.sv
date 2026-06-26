`timescale 1ns/1ps

module CONTROLPATH_tb;

    logic        clk;
    logic        rst;

    logic        ND, ZD, CD, VD;
    logic [15:0] RA;
    logic [15:0] IMMEXT;
    logic [15:0] MEMDATA;

    logic        FLAGC;
    logic [15:0] INS;
    logic [15:0] RETADR;
    logic [15:0] MEMADDR;

    CONTROLPATH dut (
        .clk(clk),
        .rst(rst),
        .ND(ND), .ZD(ZD), .CD(CD), .VD(VD),
        .RA(RA),
        .IMMEXT(IMMEXT),
        .MEMDATA(MEMDATA),
        .FLAGC(FLAGC),
        .INS(INS),
        .RETADR(RETADR),
        .MEMADDR(MEMADDR)
    );

    int pass_count = 0;
    int fail_count = 0;

    //Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    //Helper: issue reset for one cycle then release
    task automatic do_reset();
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
    endtask

    //Helper: drive inputs, wait one cycle, let outputs settle
    task automatic tick(
        input logic [15:0] memdata,
        input logic [15:0] immext,
        input logic [15:0] ra,
        input logic        nd, zd, cd, vd
    );
        MEMDATA = memdata;
        IMMEXT  = immext;
        RA      = ra;
        ND = nd; ZD = zd; CD = cd; VD = vd;
        @(posedge clk); #1;
    endtask

    //Check combinational outputs that are visible this cycle
    task automatic check_comb(
        input logic [15:0] exp_ins,
        input logic [15:0] exp_memaddr,
        input logic [15:0] exp_retadr,
        input string       label
    );
        if (INS     === exp_ins     &&
            MEMADDR === exp_memaddr &&
            RETADR  === exp_retadr) begin
            $display("PASS | %-50s | INS=%04h MEMADDR=%04h RETADR=%04h",
                     label, INS, MEMADDR, RETADR);
            pass_count++;
        end else begin
            $display("FAIL | %-50s | INS=%04h MEMADDR=%04h RETADR=%04h (expected INS=%04h MEMADDR=%04h RETADR=%04h)",
                     label, INS, MEMADDR, RETADR,
                     exp_ins, exp_memaddr, exp_retadr);
            fail_count++;
        end
    endtask

    //Check registered outputs that are visible after a clock edge
    task automatic check_reg(
        input logic        exp_flagc,
        input logic [15:0] exp_memaddr,
        input logic [15:0] exp_retadr,
        input string       label
    );
        if (FLAGC   === exp_flagc   &&
            MEMADDR === exp_memaddr &&
            RETADR  === exp_retadr) begin
            $display("PASS | %-50s | FLAGC=%b MEMADDR=%04h RETADR=%04h",
                     label, FLAGC, MEMADDR, RETADR);
            pass_count++;
        end else begin
            $display("FAIL | %-50s | FLAGC=%b MEMADDR=%04h RETADR=%04h (expected FLAGC=%b MEMADDR=%04h RETADR=%04h)",
                     label, FLAGC, MEMADDR, RETADR,
                     exp_flagc, exp_memaddr, exp_retadr);
            fail_count++;
        end
    endtask

    //Helper: set flags via a single ADD cycle (NZEN=1, CVEN=1) then leave
    //PC at whatever it lands on.  Caller supplies the flag values to latch.
    task automatic set_flags(
        input logic nd, zd, cd, vd
    );
        tick(16'h1000, 16'h0000, 16'h0000, nd, zd, cd, vd);
    endtask

    initial begin

        //Initialise inputs
        rst     = 0;
        MEMDATA = 16'h0000;
        IMMEXT  = 16'h0000;
        RA      = 16'h0000;
        ND = 0; ZD = 0; CD = 0; VD = 0;


        //RESET
        //PC should be 0 after reset; MEMADDR=PC=0, RETADR=PC+1=1
        do_reset();
        check_reg(0, 16'h0000, 16'h0001, "Reset: PC=0, MEMADDR=0, RETADR=1");


        //1. MEMDATA passthroughs to INS

        //INS is a direct wire from MEMDATA
        MEMDATA = 16'hBEEF;
        #1;
        check_comb(16'hBEEF, 16'h0000, 16'h0001, "INS passthrough: MEMDATA=BEEF");

        MEMDATA = 16'h1234;
        #1;
        check_comb(16'h1234, 16'h0000, 16'h0001, "INS passthrough: MEMDATA=1234");

        MEMDATA = 16'h0000;
        #1;


        //2. PC = PC + 1

        //After reset PC=0; feed a plain ALU instruction each cycle and
        //confirm PC increments by 1 each time.
        //MOV: INS[15:12]=0000 -> NZEN=1, no jump
        do_reset();

        tick(16'h0000, 16'h0000, 16'h0000, 0,0,0,0); //PC becomes 1
        check_reg(0, 16'h0001, 16'h0002, "PC+1: cycle 1 after reset");

        tick(16'h0000, 16'h0000, 16'h0000, 0,0,0,0); //PC becomes 2
        check_reg(0, 16'h0002, 16'h0003, "PC+1: cycle 2 after reset");

        tick(16'h0000, 16'h0000, 16'h0000, 0,0,0,0); //PC becomes 3
        check_reg(0, 16'h0003, 16'h0004, "PC+1: cycle 3 after reset");


        //3. NZ Flags

        //NZ flags written by all ALU instructions (NZEN=1 when INS[15]=0).
        //After the clock edge the flag outputs reflect the data inputs from the
        //previous cycle.  FLAGC is the registered CQ output.

        do_reset();

        //Cycle 1: ADD instruction (INS[15:12]=0001), drive ND=1 ZD=0 CD=1 VD=0
        //NZEN=1 -> NQ and ZQ will update; CVEN=1 -> CQ and VQ will update
        tick(16'h1000, 16'h0000, 16'h0000, 1,0,1,0);
        //After this edge: NQ=1 ZQ=0 CQ=1 VQ=0 -> FLAGC=CQ=1
        check_reg(1, 16'h0001, 16'h0002, "ADD: FLAGC=1 after CD=1 driven");

        //Cycle 2: MOV instruction (ALUOPC=000), drive different flag values
        //NZEN=1 -> NQ ZQ update; CVEN=0 -> CQ VQ do NOT update (stay 1,0)
        tick(16'h0000, 16'h0000, 16'h0000, 0,1,0,1);
        //CQ should still be 1 (MOV does not write CV)
        check_reg(1, 16'h0002, 16'h0003, "MOV: FLAGC unchanged (CVEN=0)");

        //Cycle 3: AND instruction (ALUOPC=101 -> INS[14:12]=101 -> INS=5000)
        //NZEN=1, CVEN=0 -> CV still held
        tick(16'h5000, 16'h0000, 16'h0000, 0,0,0,1);
        check_reg(1, 16'h0003, 16'h0004, "AND: FLAGC unchanged (CVEN=0)");

        //Cycle 4: SUB instruction (ALUOPC=010), drive CD=0
        //CVEN=1 -> CQ updates to 0
        tick(16'h2000, 16'h0000, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0004, 16'h0005, "SUB: FLAGC=0 after CD=0 driven");


        //4. CV Flags

        do_reset();

        //ADC (ALUOPC=011): CVEN=1, drive VD=1
        tick(16'h3000, 16'h0000, 16'h0000, 0,0,1,1);
        check_reg(1, 16'h0001, 16'h0002, "ADC: FLAGC=1 (CVEN=1, CD=1)");

        //SBC (ALUOPC=100): CVEN=1, drive CD=0 VD=0
        tick(16'h4000, 16'h0000, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0002, 16'h0003, "SBC: FLAGC=0 (CVEN=1, CD=0)");

        //CMP (ALUOPC=110): CVEN=1, drive CD=1
        tick(16'h6000, 16'h0000, 16'h0000, 1,0,1,0);
        check_reg(1, 16'h0003, 16'h0004, "CMP: FLAGC=1 (CVEN=1, CD=1)");

        //SHIFT (ALUOPC=111): CVEN=1, drive CD=0
        tick(16'h7000, 16'h0000, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0004, 16'h0005, "SHIFT: FLAGC=0 (CVEN=1, CD=0)");


        //5. Jumps: JMP (JMPCOND=3'b000, bit0=0) / NOP (JMPCOND=3'b000, bit0=1)

        //INS[15:12]=1100 -> JMP instruction opcode
        //INS[11:8] = JMPCOND

        do_reset();

        //JMP always (JMPCOND=0000): offset=+3 -> PC=0+3=3
        tick(16'hC000, 16'h0003, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0003, 16'h0004, "JMP always: PC+3 -> MEMADDR=3");

        //JMP always from PC=3: offset=+5 -> PC=8
        tick(16'hC000, 16'h0005, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0008, 16'h0009, "JMP always: PC+5 -> MEMADDR=8");

        //NOP (JMPCOND=0001): never jumps regardless of flags or offset
        tick(16'hC100, 16'h0020, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0009, 16'h000A, "NOP (never): PC+1=9, offset ignored");


        //6. Jumps: JEQ (Z=1) / JNE (Z=0)

        do_reset();

        //Set ZQ=1: ADD with ZD=1
        set_flags(0,1,0,0); //PC->1, ZQ=1

        //JEQ (JMPCOND=0010): Z=1 -> taken; offset=+4 -> PC=1+4=5
        tick(16'hC200, 16'h0004, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0005, 16'h0006, "JEQ taken (Z=1): PC=1+4=5");

        //JNE (JMPCOND=0011): Z=1 -> NOT taken -> PC+1=6
        //Refresh ZQ=1 while executing the JNE itself
        tick(16'hC300, 16'h0004, 16'h0000, 0,1,0,0);
        check_reg(0, 16'h0006, 16'h0007, "JNE not taken (Z=1): PC+1=6");

        //Now ZQ=1 (refreshed above). Clear Z: set_flags with ZD=0
        set_flags(0,0,0,0); //PC->7, ZQ=0

        //JEQ (JMPCOND=0010): Z=0 -> NOT taken -> PC+1=8
        tick(16'hC200, 16'h0004, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0008, 16'h0009, "JEQ not taken (Z=0): PC+1=8");

        //JNE (JMPCOND=0011): Z=0 -> taken; offset=+4 -> PC=8+4=12
        tick(16'hC300, 16'h0004, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h000C, 16'h000D, "JNE taken (Z=0): PC=8+4=12");


        //7. Jumps: JCS (C=1) / JCC (C=0)

        do_reset();

        //Set CQ=1: ADD (CVEN=1) with CD=1
        set_flags(0,0,1,0); //PC->1, CQ=1

        //JCS (JMPCOND=0100): C=1 -> taken; offset=+2 -> PC=3
        tick(16'hC400, 16'h0002, 16'h0000, 0,0,1,0);
        check_reg(1, 16'h0003, 16'h0004, "JCS taken (C=1): PC=1+2=3");

        //JCC (JMPCOND=0101): C=1 -> NOT taken -> PC+1=4
        tick(16'hC500, 16'h0002, 16'h0000, 0,0,1,0);
        check_reg(1, 16'h0004, 16'h0005, "JCC not taken (C=1): PC+1=4");

        //Clear CQ: set_flags with CD=0
        set_flags(0,0,0,0); //PC->5, CQ=0

        //JCS (JMPCOND=0100): C=0 -> NOT taken -> PC+1=6
        tick(16'hC400, 16'h0002, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0006, 16'h0007, "JCS not taken (C=0): PC+1=6");

        //JCC (JMPCOND=0101): C=0 -> taken; offset=+2 -> PC=8
        tick(16'hC500, 16'h0002, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0008, 16'h0009, "JCC taken (C=0): PC=6+2=8");


        //8. Jumps: JMI (N=1) / JPL (N=0)

        do_reset();

        //Set NQ=1: ADD (NZEN=1) with ND=1
        set_flags(1,0,0,0); //PC->1, NQ=1

        //JMI (JMPCOND=0110): N=1 -> taken; offset=+1 -> PC=2
        tick(16'hC600, 16'h0001, 16'h0000, 1,0,0,0);
        check_reg(0, 16'h0002, 16'h0003, "JMI taken (N=1): PC=1+1=2");

        //JPL (JMPCOND=0111): N=1 -> NOT taken -> PC+1=3
        tick(16'hC700, 16'h0001, 16'h0000, 1,0,0,0);
        check_reg(0, 16'h0003, 16'h0004, "JPL not taken (N=1): PC+1=3");

        //Clear NQ: set_flags with ND=0
        set_flags(0,0,0,0); //PC->4, NQ=0

        //JMI (JMPCOND=0110): N=0 -> NOT taken -> PC+1=5
        tick(16'hC600, 16'h0001, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0005, 16'h0006, "JMI not taken (N=0): PC+1=5");

        //JPL (JMPCOND=0111): N=0 -> taken; offset=+1 -> PC=6
        tick(16'hC700, 16'h0001, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0006, 16'h0007, "JPL taken (N=0): PC=5+1=6");


        //9. Jumps: JGE (N=V, signed >=) / JLT (N!=V, signed <)
        //Condition: JGE when N==V (both 0 or both 1); JLT when N!=V

        do_reset();

        //Case: N=0 V=0 -> N==V -> JGE taken, JLT not taken
        set_flags(0,0,0,0); //PC->1, NQ=0 VQ=0

        //JGE (JMPCOND=1000): N==V -> taken; offset=+3 -> PC=4
        tick(16'hC800, 16'h0003, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0004, 16'h0005, "JGE taken (N=0,V=0): PC=1+3=4");

        //JLT (JMPCOND=1001): N==V -> NOT taken -> PC+1=5
        tick(16'hC900, 16'h0003, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0005, 16'h0006, "JLT not taken (N=0,V=0): PC+1=5");

        //Case: N=1 V=1 -> N==V -> JGE taken, JLT not taken
        set_flags(1,0,0,1); //PC->6, NQ=1 VQ=1
 
        //JGE (JMPCOND=1000): N==V -> taken; offset=+2 -> PC=6+2=8
        tick(16'hC800, 16'h0002, 16'h0000, 1,0,0,1);
        check_reg(0, 16'h0008, 16'h0009, "JGE taken (N=1,V=1): PC=6+2=8");
 
        //JLT (JMPCOND=1001): N==V -> NOT taken -> PC+1=9
        tick(16'hC900, 16'h0002, 16'h0000, 1,0,0,1);
        check_reg(0, 16'h0009, 16'h000A, "JLT not taken (N=1,V=1): PC+1=9");
 
        //Case: N=1 V=0 -> N!=V -> JGE not taken, JLT taken
        set_flags(1,0,0,0); //PC->10, NQ=1 VQ=0
 
        //JGE (JMPCOND=1000): N!=V -> NOT taken -> PC+1=11
        tick(16'hC800, 16'h0002, 16'h0000, 1,0,0,0);
        check_reg(0, 16'h000B, 16'h000C, "JGE not taken (N=1,V=0): PC+1=11");
 
        //JLT (JMPCOND=1001): N!=V -> taken; offset=+2 -> PC=11+2=13
        tick(16'hC900, 16'h0002, 16'h0000, 1,0,0,0);
        check_reg(0, 16'h000D, 16'h000E, "JLT taken (N=1,V=0): PC=11+2=13");
 
        //Case: N=0 V=1 -> N!=V -> JGE not taken, JLT taken
        set_flags(0,0,0,1); //PC->14, NQ=0 VQ=1
 
        //JGE (JMPCOND=1000): N!=V -> NOT taken -> PC+1=15
        tick(16'hC800, 16'h0002, 16'h0000, 0,0,0,1);
        check_reg(0, 16'h000F, 16'h0010, "JGE not taken (N=0,V=1): PC+1=15");
 
        //JLT (JMPCOND=1001): N!=V -> taken; offset=+2 -> PC=15+2=17
        tick(16'hC900, 16'h0002, 16'h0000, 0,0,0,1);
        check_reg(0, 16'h0011, 16'h0012, "JLT taken (N=0,V=1): PC=15+2=17");


        //10. Jumps: JGT (signed >) / JLE (signed <=)
        //Condition: JGT when Z=0 AND N==V; JLE when Z=1 OR N!=V

        do_reset();

        //Case: Z=0 N=0 V=0 -> Z=0 AND N==V -> JGT taken, JLE not taken
        set_flags(0,0,0,0); //PC->1, ZQ=0 NQ=0 VQ=0

        //JGT (JMPCOND=1010): taken; offset=+3 -> PC=4
        tick(16'hCA00, 16'h0003, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0004, 16'h0005, "JGT taken (Z=0,N=0,V=0): PC=1+3=4");

        //JLE (JMPCOND=1011): not taken -> PC+1=5
        tick(16'hCB00, 16'h0003, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0005, 16'h0006, "JLE not taken (Z=0,N=0,V=0): PC+1=5");

        //Case: Z=1 N=0 V=0 -> Z=1 -> JGT not taken, JLE taken
        set_flags(0,1,0,0); //PC->6, ZQ=1 NQ=0 VQ=0

        //JGT (JMPCOND=1010): Z=1 -> not taken -> PC+1=7
        tick(16'hCA00, 16'h0003, 16'h0000, 0,1,0,0);
        check_reg(0, 16'h0007, 16'h0008, "JGT not taken (Z=1,N=0,V=0): PC+1=7");

        //JLE (JMPCOND=1011): Z=1 -> taken; offset=+3 -> PC=10
        tick(16'hCB00, 16'h0003, 16'h0000, 0,1,0,0);
        check_reg(0, 16'h000A, 16'h000B, "JLE taken (Z=1,N=0,V=0): PC=7+3=10");

        //Case: Z=0 N=1 V=0 -> N!=V -> JGT not taken, JLE taken
        set_flags(1,0,0,0); //PC->11, ZQ=0 NQ=1 VQ=0

        //JGT (JMPCOND=1010): N!=V -> not taken -> PC+1=12
        tick(16'hCA00, 16'h0003, 16'h0000, 1,0,0,0);
        check_reg(0, 16'h000C, 16'h000D, "JGT not taken (Z=0,N=1,V=0): PC+1=12");

        //JLE (JMPCOND=1011): N!=V -> taken; offset=+3 -> PC=15
        tick(16'hCB00, 16'h0003, 16'h0000, 1,0,0,0);
        check_reg(0, 16'h000F, 16'h0010, "JLE taken (Z=0,N=1,V=0): PC=12+3=15");


        //11. Jumps: JHI (unsigned >) / JLS (unsigned <=)
        //Condition: JHI when C=1 AND Z=0; JLS when C=0 OR Z=1

        do_reset();

        //Case: C=1 Z=0 -> JHI taken, JLS not taken
        set_flags(0,0,1,0); //PC->1, CQ=1 ZQ=0

        //JHI (JMPCOND=1100): taken; offset=+4 -> PC=5
        tick(16'hCC00, 16'h0004, 16'h0000, 0,0,1,0);
        check_reg(1, 16'h0005, 16'h0006, "JHI taken (C=1,Z=0): PC=1+4=5");

        //JLS (JMPCOND=1101): not taken -> PC+1=6
        tick(16'hCD00, 16'h0004, 16'h0000, 0,0,1,0);
        check_reg(1, 16'h0006, 16'h0007, "JLS not taken (C=1,Z=0): PC+1=6");

        //Case: C=0 Z=0 -> C=0 -> JHI not taken, JLS taken
        set_flags(0,0,0,0); //PC->7, CQ=0 ZQ=0

        //JHI (JMPCOND=1100): C=0 -> not taken -> PC+1=8
        tick(16'hCC00, 16'h0004, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0008, 16'h0009, "JHI not taken (C=0,Z=0): PC+1=8");

        //JLS (JMPCOND=1101): C=0 -> taken; offset=+4 -> PC=12
        tick(16'hCD00, 16'h0004, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h000C, 16'h000D, "JLS taken (C=0,Z=0): PC=8+4=12");

        //Case: C=1 Z=1 -> Z=1 -> JHI not taken, JLS taken
        set_flags(0,1,1,0); //PC->13, CQ=1 ZQ=1

        //JHI (JMPCOND=1100): Z=1 -> not taken -> PC+1=14
        tick(16'hCC00, 16'h0004, 16'h0000, 0,1,1,0);
        check_reg(1, 16'h000E, 16'h000F, "JHI not taken (C=1,Z=1): PC+1=14");

        //JLS (JMPCOND=1101): Z=1 -> taken; offset=+4 -> PC=18
        tick(16'hCD00, 16'h0004, 16'h0000, 0,1,1,0);
        check_reg(1, 16'h0012, 16'h0013, "JLS taken (C=1,Z=1): PC=14+4=18");


        //12. Jumps: JSR (JMPCOND=1110) — always taken, PC <- offset

        do_reset();

        //JSR always executes; RETADR=PC+1 is the return address for the datapath
        //PC=0, offset=16 -> PCNEXT=16
        tick(16'hCE00, 16'h0010, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0010, 16'h0011, "JSR: always taken, PC=0+16=16");

        //RETADR reflects new PC+1 combinationally after the jump
        check_comb(16'hCE00, 16'h0010, 16'h0011, "JSR: RETADR=PC+1=17 post-jump");

        //JSR from non-zero PC: PC=16, offset=8 -> PCNEXT=24
        tick(16'hCE00, 16'h0008, 16'h0000, 0,0,0,0);
        check_reg(0, 16'h0018, 16'h0019, "JSR: PC=16+8=24");


        //13. Jumps: RET (JMPCOND=1111) — always taken, PC <- RA

        do_reset();

        //RET always executes; PC <- RA regardless of flags
        tick(16'hCF00, 16'h0000, 16'hABCD, 0,0,0,0);
        check_reg(0, 16'hABCD, 16'hABCE, "RET: PC <- RA=ABCD");

        //RET with different RA
        tick(16'hCF00, 16'h0000, 16'h0042, 0,0,0,0);
        check_reg(0, 16'h0042, 16'h0043, "RET: PC <- RA=0042");

        //RET is unconditional: flags should have no effect
        set_flags(1,1,1,1); //all flags set; PC advances by 1 from 0042
        tick(16'hCF00, 16'h0000, 16'h0007, 1,1,1,1);
        check_reg(1, 16'h0007, 16'h0008, "RET unconditional (all flags set): PC=0007");


        $display("PASSED: %0d / FAILED: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule