# Multiplication in EEP1

EEP1 does not have hardware that can perform a multiplication.

Instead it is implemented using software as a combination of SHIFTs and ADDs.

In C++ multiplication is implemented as follows:

```
// implement sum := op1 ∗ op2 (LS 16 bits of) 
// assume int = 16 bits (16−bit version of C)
unsigned int op1, op2, op2_shifted, sum;
sum = 0;
op2_shifted = op2;
while (op1 != 0) {
	if (op1 & 1) {
		sum = sum + op2_shifted;
	}
	op2_shifted = op2_shifted << 1; //left shift by 1
	op1 = op1 >> 1; //right shift by 1
}
```

This works by checking if the LSB of op1 = 1, if it is, add the current op2 to sum. 

It shifts op2 left by 1 (multiplies by 2) and op1 right (move onto the next bit). Repeats this until all of op1 is processed.

Tracing this for op1 = 12 and op2 = 5:

|        | Last op1[0] | op1              | op2_shifted        | sum |
|--------|-------------|------------------|--------------------|-----|
| -      | -           | 0000 1100 (12)   | 0000 0101 (5)      | 0   |
| Loop 1 | 0           | 0000 0110 (6)    | 0000 1010 (10)     | 0   |
| Loop 2 | 0           | 0000 0011 (3)    | 0001 0100 (20)     | 0   |
| Loop 3 | 1           | 0000 0001 (1)    | 0010 1000 (40)     | 20  |
| Loop 4 | 1           | 0000 0000 (0)    | 0101 0000 (80)     | 60  |

In order to execute this algorithm in C++, it must be converted into assembly language.

```
MOV R0, #12 //op1
MOV R1, #5 //op2
MOV R2, R1 //op2_shifted
MOV R3, #0 //sum

CMP R0, #0 //op1 != 0 – updates FlagZ
JEQ 8 //Jump out of loop
MOV R4, R0
AND R4, #1 //op1 & 1
JEQ 2 //Skip summing if result is 0
ADD R3, R2 //sum + op2_shifted
LSL R2, R2, #1 //op2_shifted << 1
LSR R0, R0, #1 //op1 >> 1
JMP -8
```
This algorithm performs 12 x 5 = 60.