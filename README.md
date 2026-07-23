# EEP1 - Arm-based RISC CPU in SystemVerilog

This project is a SystemVerilog implementation of **EEP1**, a 16-bit Harvard-architecture
CPU based on design practices used by [Arm](https://www.arm.com/). 

It is a Reduced Instruction Set Computing (RISC) Central Proccessing Unit (CPU). 
*Reduced* meaning it has smaller, simpler instructions that can execute in a single cycle.
Each instruction is highly regular and perform a single operation.

This ReadMe gives a **high-level overview** of how the EEP1 is designed and how a program can be run on it. 
Module files (located in [/src](./src/)) contain a more detailed explanation of how each module works 
and explains design choices made.

EEP1 instructions are 16-bit and encoded using [this instruction format](./EEP1%20Instruction%20Format%20-%20Imperial.pdf). *Encoding is explained where relevant, so reading this isn't required to continue.*

### Examples

[examples/multiplication.md](./examples/multiplication/multiplication.md) - How an assembly program can be used with EEP1 to multiply 2 numbers using shift and add.


## What is EEP1?

EEP1 is a 16-bit, Harvard-architecture CPU.

At the [top level](./src/top.sv) it has 4 modules:

| Block | Responsibility |
|---|---|
| [**Control Path**](./src/controlpath/controlpath.sv) | Program counter, flag registers (N/Z/C/V), jump/interrupt logic - **fetches instructions**. |
| [**Datapath**](./src/datapath/datapath.sv) | Register files, ALU, memory read/write logic - **decodes and executes instructions**. |
| [**Instruction Memory**](./src/codemem.sv)  | Async ROM to hold pre-loaded program instructions. Connects to CONTROLPATH  |
| [**Data Memory**](./src/datamem.sv)  | Async RAM to hold data stored in memory by program instructions. Connects to the DATAPATH |

- The datapath has 8 16-bit registers, each with a 3-bit address. `R0` - `R7`

- Instructions are executed in a single cycle.

- Flags are updated by some ALU instructions and are used by conditional or carry instructions in the next cycle.

## Instruction Encoding

Instructions are 16-bits. They are encoded using [this instruction format](./EEP1%20Instruction%20Format%20-%20Imperial.pdf).

The most significant bits are used to select instruction type.

Datapath instructions are decoded by [DPDECODE](./src/datapath/dpdecode.sv) and control path instructions are decoded by [CONTROLDECODE](./src/controlpath/controldecode.sv). *See these modules for full decoding process.*

There are 4 instruction types:

<table>
    <tr>
    <th>INS</th>
    <th>15</th><th>14</th><th>13</th><th>12</th>
    <th></th>
    </tr>
    <tr>
        <td>ALU</td>
        <td>0</td>
        <td>X</td>
        <td>X</td>
        <td>X</td>
        <td>ALU operations (arithmetic / registers)</td>
    </tr>
    <tr>
        <td>Load / Store</td>
        <td>1</td>
        <td>0</td>
        <td>X</td>
        <td>X</td>
        <td>Loading and storing data from RAM data memory</td>
    </tr>
    <tr>
        <td>Jump</td>
        <td>1</td>
        <td>1</td>
        <td>0</td>
        <td>0</td>
        <td>Conditional/unconditional jumps program to different point</td>
    </tr>
    <tr>
        <td>EXT</td>
        <td>1</td>
        <td>1</td>
        <td>0</td>
        <td>1</td>
        <td>Extend 8-bit immediate to 16-bits without default sign-extension. 
        (See <a href="./src/datapath/extend.sv">EXTEND</a>)</td>
    </tr>
</table>

## ALU Operations

ALU instructions are formatted as follows:

<table>
    <tr>
    <th>15</th><th>14</th><th>13</th><th>12</th>
    <th>11</th><th>10</th><th>9</th>
    <th>8</th>
    <th>7</th><th>6</th><th>5</th>
    <th>4</th>
    <th>3</th><th>2</th><th>1</th><th>0</th>
  </tr>

  <tr>
    <td rowspan="3">0</td>
    <td colspan="3">ALUOPC=7</td>
    <td colspan="3">RegA</td>
    <td>SHIFT <br>OPC (1)</td>
    <td colspan="3">RegB</td>
    <td>SHIFT <br>OPC (0)</td>
    <td colspan="4">Imm4 (SCNT)</td>
  </tr>

  <tr>
    <td rowspan="2" colspan="3">ALUOPC=0..6</td>
    <td rowspan="2" colspan="3">RegA</td>
    <td>0</td>
    <td colspan="3">RegB</td>
    <td colspan="3">RegC</td>
    <td colspan="2">(0)</td>

  </tr>
 
  <tr>
    <td>1</td>
    <td colspan="8">Imms8 (IMM)</td>
  </tr>
 
</table>

`ALUOPC` is used to select which ALU instruction will be executed. It is 3-bits, giving 8 different operations. 

The result of an operation is always loaded into a register. The 3-bit register addresses are given in the instruction, data is loaded from them for ALU operation. The first address is the destination register.

For `ALUOPC=0..6`, operations take either two registers as input and write the result to a third, or one register and an 8-bit constant (extended to 16 bits), writing the result back to that same register.

All ALU operations update flags.

ALU operations are shown below:

<table>
    <tr>
    <th>ALUOPC</th>
    <th>INS</th>
    <th>INS[8] = 0 (Reg-Reg)</th>
    <th>INS[8] = 1 (Reg-Imm)</th>
    <th>Writes flags</th>
    <th>Operation</th>
    </tr>
    <tr>
        <td>0</td>
        <td><code>MOV</code></td>
        <td><code>MOV Ra, Rb</code></td>
        <td><code>MOV Ra, #IMM</code></td>
        <td>N, Z only</td>
        <td>Load into <code>Ra</code></td>
    </tr>
    <tr>
        <td>1</td>
        <td><code>ADD</code></td>
        <td><code>ADD Rc, Ra, Rb</code></td>
        <td><code>ADD Ra, #IMM</code></td>
        <td>All (NZCV)</td>
        <td><code>A + B</code></td>
    </tr>
    <tr>
        <td>2</td>
        <td><code>SUB</code></td>
        <td><code>SUB Rc, Ra, Rb</code></td>
        <td><code>SUB Ra, #IMM</code></td>
        <td>All (NZCV)</td>
        <td><code>A - B</code></td>
    </tr>
    <tr>
        <td>3</td>
        <td><code>ADC</code></td>
        <td><code>ADC Rc, Ra, Rb</code></td>
        <td><code>ADC Ra, #IMM</code></td>
        <td>All (NZCV)</td>
        <td><code>A + B + FlagC</code></td>
    </tr>
    <tr>
        <td>4</td>
        <td><code>SBC</code></td>
        <td><code>SBC Rc, Ra, Rb</code></td>
        <td><code>SBC Ra, #IMM</code></td>
        <td>All (NZCV)</td>
        <td><code>A - B + (FlagC - 1)</code></td>
    </tr>
    <tr>
        <td>5</td>
        <td><code>AND</code></td>
        <td><code>AND Rc, Ra, Rb</code></td>
        <td><code>AND Ra, #IMM</code></td>
        <td>N, Z only</td>
        <td><code>A & B</code></td>
    </tr>
    <tr>
        <td>6</td>
        <td><code>CMP</code></td>
        <td><code>CMP Rc, Ra, Rb</code></td>
        <td><code>CMP Ra, #IMM</code></td>
        <td>All (NZCV)</td>
        <td><code>A - B</code> update flags, discard output</td>
    </tr>
    <tr>
        <td>7</td>
        <td><code>SHIFT</code></td>
        <td colspan="2"><code>SHIFT Ra, Rb, #SCNT</code></td>
        <td>All (NZCV)</td>
        <td>See <a href="./README.md#shift-operations">Shift Operations</a></td>
    </tr>
</table>

ALU instructions are executed by the [ALU](./src/datapath/alu/alu.sv).

`ADD`, `SUB`, `ADC`, `SBC`, `CMP` are handled by [ADDSUB](./src/datapath/alu/addsub.sv). 
*See comments for explanation on ADC/SBC and 2's complement*.

`AND` is a 16-bit bitwise, an AND operation is carried out on each bit.

### Shift Operations

`SHIFT` (`ALUOPC=7`) uses a 2-bit `SHIFTOPC` to determine the type of shift, and a 4-bit `SCNT` to determine how much to shift by.

| SHIFTOPC | Mnemonic | Behaviour |
|---|---|---|
| 00 | `LSL` | Logical shift left, 0-fill |
| 01 | `LSR` | Logical shift right, 0-fill |
| 10 | `ASR` | Arithmetic shift right, sign-bit fill |
| 11 | `XSR` | Multi-word shift right, fills in `FlagC` |

## Memory Operations

Memory operations can only read/write to data RAM (`DATAMEM`). `DATAMEM` takes a 16-bit address (giving $2^16$ memory locations). Each memory location holds a 16-bit value. 

Memory can only be loaded to / written from a register.

| Form | Assembly | Effective address |
|---|---|---|
| Register offset load | `LDR Ra, [Rb, #Imms5]` | `Rb + Imms5` |
| Register load (no offset) | `LDR Ra, [Rb]` | `Rb` |
| Direct load | `LDR Ra, [#Imms8]` | `Imms8` |
| Register offset store | `STR Ra, [Rb, #Imms5]` | `Rb + Imms5` |
| Direct store | `STR Ra, [#Imms8]` | `Imms8` |

*See [DATAMEM](./src/datamem.sv) for further detail.*

## Flags

There are four 1-bit flags held in flip-flops. **The flags in the current cycle are set by the result of the instruction executed in the previous cycle**.

| Flag | Meaning | Set when |
|---|---|---|
| `FlagN` | Negative | Signed result < 0 |
| `FlagZ` | Zero | Result = 0 |
| `FlagC` | Carry | Arithmetic carry-out, or bit shifted out |
| `FlagV` | Signed overflow | Signed add/subtract overflowed its range |

Flag values are used by control path for jump instructions and by the datapath for ALU operations (such as ADC/SBC). 

Flags are only updated by ALU operations. `MOV` and `AND` only update `FlagN` and `FlagZ`. 

## Program Counter

The program counter (`PC`) is a 16-bit memory address which holds the location in `CODEMEM` of the current instruction.

The next `PC` is determined by the [`NEXT`](./src/controlpath/next.sv) module. There are 3 scenarios:

`PCNEXT = PC + 1` (normal)
`PCNEXT = PC + OFFSET` (jump)
`PCNEXT = RA` (jump to register value)

Jumps are instructions that will set the PC to a specific value if their jump conditions are met. See [Jump Instructions](./README.md#jump-instructions) 

## Jump Instructions

A 4-bit `JMPOPC` determines which jump condition to check for. Jump conditions are a boolean expression of flag values. If they are satisfied, the program will jump (by setting the `PC` to a specific value).

Jump conditions are evaluated by the [`COND`](./src/controlpath/cond.sv) module. 

`JMPOPC[3:1]` selects which jump. `JMPOPC[0]` selects whether to invert the condition.

| JMPOPC(3:1) | Flag condition | Non-inverted condition | Non-inverted INS | Inverted INS |
|---|---|---|---|---|
| 0 | `1` | always | `JMP` | `NOP` |
| 1 | `Z` | result = 0| `JEQ` (equal) | `JNE` (not equal) |
| 2 | `C` | C=1 ($u(Ra) ≥ u(Op)$)| `JCS` (carry set / unsigned ≥) | `JCC` (carry clear / unsigned <) |
| 3 | `N` | $z(result) < 0$ | `JMI` (minus) | `JPL` (plus) |
| 4 | `N̄⊕V` | $z(Ra) ≥ z(Op)$ | `JGE` (signed ≥) | `JLT` (signed <) |
| 5 | `(N̄⊕V)·Z̄` | $z(Ra) > z(Op)$ | `JGT` (signed >) | `JLE` (signed ≤) |
| 6 | `C·Z̄` | $u(Ra) > u(Op)$ | `JHI` (unsigned >) | `JLS` (unsigned ≤) |
| 7 | `1` | always | `JSR` (call) | `RET` (return) |

*$Op$ refers to the result of the previous instruction.*

`JSR` and `RET` are special jumps for subroutine calls and returns. Both are carried out always.

## EXT

*See [`EXTEND`](./src/datapath/extend.sv) for detail.*

The max input size for an immediate value in an instruction is 8-bits.

Registers are 16-bits, so the upper 8-bits of any input immediate value must be extended to 16-bits.

Normally sign extension is done: 

`0x00 -> 0x0000`

`0x01 -> 0x0001`

`0x7F -> 0x007F`

`0x80 -> 0xFF80`

`0xFF -> 0xFFFF`

MSB of immediate (the sign bit) is copied to the upper 8-bits of `IMMEXT`.

An `EXT` instruction can be used, with an 8-bit input, to set the upper 8 bits of the input in the next cycle.

Eg:
```
EXT 0xAB (cycle 1)
IMM 0xCD (cycle 2)
IMMEXT = 0xABCD (cycle 2)
```

A register is used to hold the upper 8-bits from the EXT instruction, and is used to extend the immediate on the next cycle.

## Subroutines

Subroutines are callable blocks of code, similar to a function. It involves setting the `PC` to a different part of `CODEMEM` and then returning to the original `PC` after the subroutine is finished.

`JSR` enters a subroutine. When executed it saves `PC + 1` to `R7` and sets the `PC` to the address specified in the instruction.

`RET` returns a subroutine. When executed it restores `PC` to the value in `R7`.

## What's similar to Arm?

The design of EEP1 is based on Arm's design principles. [Arm](https://www.arm.com/) is a hardware company that designs CPU IPs that mainly implement the "[ARM architecture](https://en.wikipedia.org/wiki/ARM_architecture_family)". 
This is a family of RISC instruction set architectures (mainly 32-bit and 64-bit) which inspired the design of EEP1. *NB: ARM is by Arm, but they are not the same thing.*

While EEP1 does not implement the ARM instruction set directly, several of its design choices are drawn from Arm's architecture:

**Conditional jumps** - EEP1 and ARM both use a flag-based conditional branching model to execute jumps if certain flag conditions are met. Arm also uses the same condition flags (NZCV). 
This avoids the need for a dedicated comparison operation being implemented within the jump instruction.

**Memory** - EEP1/ARM also both use dedicated instructions to access memory (`LDR` and `STR`). These are the only instructions that can access memory, other instructions can only operate on registers. 
Unlike RISC, CISC (complex instruction set computing) has instructions which can directly interact with memory.

**Carrying** - EEP1's `ADC`/`SBC` instructions allow multi-word arithmetic by propagating the carry flag between operations. This is a characteristic used by ARM ALUs as well.

**Subroutines** - `JSR`/`RET` are used to enter/exit a subroutine. The return address is saved in a register (`R7`). ARM also uses a dedicated register for return addresses.



