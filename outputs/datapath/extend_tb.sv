#! /c/Source/iverilog-install/bin/vvp
:ivl_version "12.0 (devel)" "(s20150603-1539-g2693dd32b)";
:ivl_delay_selection "TYPICAL";
:vpi_time_precision - 12;
:vpi_module "C:\iverilog\lib\ivl\system.vpi";
:vpi_module "C:\iverilog\lib\ivl\vhdl_sys.vpi";
:vpi_module "C:\iverilog\lib\ivl\vhdl_textio.vpi";
:vpi_module "C:\iverilog\lib\ivl\v2005_math.vpi";
:vpi_module "C:\iverilog\lib\ivl\va_math.vpi";
:vpi_module "C:\iverilog\lib\ivl\v2009.vpi";
S_00000222e23fbd90 .scope package, "$unit" "$unit" 2 1;
 .timescale 0 0;
S_00000222e22e63a0 .scope module, "EXTEND_TB" "EXTEND_TB" 3 3;
 .timescale -9 -12;
v00000222e22f38b0_0 .var "EXT", 0 0;
v00000222e22f3c70_0 .var "IMM", 15 0;
v00000222e22f4030_0 .net "IMMEXT", 15 0, v00000222e23f6580_0;  1 drivers
v00000222e22f3db0_0 .var "clk", 0 0;
v00000222e22f3d10_0 .var "rst", 0 0;
E_00000222e22e53a0 .event negedge, v00000222e22f3630_0;
S_00000222e22e6530 .scope module, "dut" "EXTEND" 3 10, 4 1 0, S_00000222e22e63a0;
 .timescale 0 0;
    .port_info 0 /INPUT 1 "clk";
    .port_info 1 /INPUT 1 "rst";
    .port_info 2 /INPUT 16 "IMM";
    .port_info 3 /INPUT 1 "EXT";
    .port_info 4 /OUTPUT 16 "IMMEXT";
v00000222e22e6260_0 .net "EXT", 0 0, v00000222e22f38b0_0;  1 drivers
v00000222e22e66c0_0 .var "EXT_d", 0 0;
v00000222e23f64e0_0 .net "IMM", 15 0, v00000222e22f3c70_0;  1 drivers
v00000222e23f6580_0 .var "IMMEXT", 15 0;
v00000222e23f6620_0 .var "IMM_d", 15 0;
v00000222e23f66c0_0 .net "IMM_high", 7 0, L_00000222e22f3590;  1 drivers
v00000222e23f6760_0 .net "IMM_low", 7 0, L_00000222e22f4170;  1 drivers
v00000222e23f6800_0 .net *"_ivl_3", 7 0, L_00000222e22f34f0;  1 drivers
v00000222e23f68a0_0 .net *"_ivl_5", 7 0, L_00000222e22f3270;  1 drivers
v00000222e22f3630_0 .net "clk", 0 0, v00000222e22f3db0_0;  1 drivers
v00000222e22f3450_0 .net "rst", 0 0, v00000222e22f3d10_0;  1 drivers
E_00000222e22e5b60 .event anyedge, v00000222e23f66c0_0, v00000222e23f6760_0;
E_00000222e22e5420 .event posedge, v00000222e22f3630_0;
L_00000222e22f4170 .part v00000222e22f3c70_0, 0, 8;
L_00000222e22f34f0 .part v00000222e23f6620_0, 0, 8;
L_00000222e22f3270 .part v00000222e22f3c70_0, 8, 8;
L_00000222e22f3590 .functor MUXZ 8, L_00000222e22f3270, L_00000222e22f34f0, v00000222e22e66c0_0, C4<>;
    .scope S_00000222e22e6530;
T_0 ;
    %wait E_00000222e22e5420;
    %load/vec4 v00000222e22f3450_0;
    %flag_set/vec4 8;
    %jmp/0xz  T_0.0, 8;
    %pushi/vec4 0, 0, 16;
    %assign/vec4 v00000222e23f6620_0, 0;
    %pushi/vec4 0, 0, 1;
    %assign/vec4 v00000222e22e66c0_0, 0;
    %jmp T_0.1;
T_0.0 ;
    %load/vec4 v00000222e23f64e0_0;
    %assign/vec4 v00000222e23f6620_0, 0;
    %load/vec4 v00000222e22e6260_0;
    %assign/vec4 v00000222e22e66c0_0, 0;
T_0.1 ;
    %jmp T_0;
    .thread T_0;
    .scope S_00000222e22e6530;
T_1 ;
Ewait_0 .event/or E_00000222e22e5b60, E_0x0;
    %wait Ewait_0;
    %load/vec4 v00000222e23f66c0_0;
    %load/vec4 v00000222e23f6760_0;
    %concat/vec4; draw_concat_vec4
    %store/vec4 v00000222e23f6580_0, 0, 16;
    %jmp T_1;
    .thread T_1, $push;
    .scope S_00000222e22e63a0;
T_2 ;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v00000222e22f3db0_0, 0, 1;
    %end;
    .thread T_2;
    .scope S_00000222e22e63a0;
T_3 ;
    %delay 5000, 0;
    %load/vec4 v00000222e22f3db0_0;
    %inv;
    %store/vec4 v00000222e22f3db0_0, 0, 1;
    %jmp T_3;
    .thread T_3;
    .scope S_00000222e22e63a0;
T_4 ;
    %pushi/vec4 1, 0, 1;
    %store/vec4 v00000222e22f3d10_0, 0, 1;
    %wait E_00000222e22e5420;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v00000222e22f3d10_0, 0, 1;
    %pushi/vec4 1, 0, 1;
    %store/vec4 v00000222e22f38b0_0, 0, 1;
    %pushi/vec4 41, 0, 16;
    %store/vec4 v00000222e22f3c70_0, 0, 16;
    %wait E_00000222e22e5420;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v00000222e22f38b0_0, 0, 1;
    %pushi/vec4 65525, 0, 16;
    %store/vec4 v00000222e22f3c70_0, 0, 16;
    %wait E_00000222e22e53a0;
    %vpi_call/w 3 32 "$display", "EXT, (x0029, xFFF5), IMM=%h EXT=%b IMMEXT=%h", v00000222e22f3c70_0, v00000222e22f38b0_0, v00000222e22f4030_0 {0 0 0};
    %pushi/vec4 0, 0, 1;
    %store/vec4 v00000222e22f38b0_0, 0, 1;
    %pushi/vec4 41, 0, 16;
    %store/vec4 v00000222e22f3c70_0, 0, 16;
    %wait E_00000222e22e5420;
    %pushi/vec4 65525, 0, 16;
    %store/vec4 v00000222e22f3c70_0, 0, 16;
    %wait E_00000222e22e53a0;
    %vpi_call/w 3 39 "$display", "No EXT, (x0029, xFFF5), IMM=%h EXT=%b IMMEXT=%h", v00000222e22f3c70_0, v00000222e22f38b0_0, v00000222e22f4030_0 {0 0 0};
    %delay 10000, 0;
    %vpi_call/w 3 42 "$finish" {0 0 0};
    %end;
    .thread T_4;
# The file index is used to find the file name in the following table.
:file_names 5;
    "N/A";
    "<interactive>";
    "-";
    "./testing/datapath/extend_tb.sv";
    "./datapath/extend.sv";
