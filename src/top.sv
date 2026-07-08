module TOP (
    
    input logic clk,
    input logic rst

);

    //Flags
    logic ND, ZD, CD, VD; //flag output from current instruction, used for JMP instructions
    logic FLAGC; //carry flag, used for ALU operations (eg: ADC, SBC)

    //From control path -> data path
    logic [15:0] INS; //instruction string (see docs for format)
    logic [15:0] RETADR; //subroutine return address (current PC + 1, saved to Reg7 when subroutine is called)

    //From data path -> control path
    logic [15:0] IMMEXT; //output from EXT block, used by control path as offset for jump instructions
    logic [15:0] RAOUT; //output from selected register, used by control path as offset for jump instructions

    //Data memory (datapath <--> DATAMEM)
    logic [15:0] DATA_ADDR; //memory address to read/write
    logic [15:0] DATA_DIN; //data input to RAM, always register value (RegA)
    logic [15:0] DATA_DOUT; //data output to datapath
    logic DATA_WEN; //write enable

    //Instruction memory (controlpath <--> CODEMEM)
    logic [15:0] CODE_ADDR; //memory address, read only
    logic [15:0] CODE_DOUT; //data output to controlpath

    CONTROLPATH controlpath (
        .clk(clk), .rst(rst),
        .ND(ND), .ZD(ZD), .CD(CD), .VD(VD),
        .RA(RAOUT),
        .IMMEXT(IMMEXT),
        .MEMDATA(CODE_DOUT),
        .FLAGC(FLAGC),
        .INS(INS),
        .RETADR(RETADR),
        .MEMADDR(CODE_ADDR)
    );

    DATAPATH datapath (
        .clk(clk), .rst(rst),
        .INS(INS),
        .PCIN(RETADR),
        .FLAGCIN(FLAGC),
        .MEMDOUT(DATA_DOUT),
        .RAOUT(RAOUT),
        .IMMEXT(IMMEXT),
        .FLAGN(ND), .FLAGZ(ZD), .FLAGC(CD), .FLAGV(VD),
        .MEMADDR(DATA_ADDR),
        .MEMDIN(DATA_DIN),
        .MEMWEN(DATA_WEN)
    );

    CODEMEM codemem (
        .ADDR(CODE_ADDR),
        .DOUT(CODE_DOUT)
    );

    DATAMEM datamem (
        .ADDR(DATA_ADDR),
        .DIN(DATA_DIN),
        .DOUT(DATA_DOUT),
        .WEN(DATA_WEN)
    );

    
endmodule