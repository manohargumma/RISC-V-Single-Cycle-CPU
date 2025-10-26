

# RISC-V Single-Cycle CPU (RV32I Subset)



## 📌 Overview

This repository implements a **32-bit single-cycle RISC-V CPU** capable of executing a subset of **RV32I instructions**, including:

* **R-Type:** `ADD`, `SUB`, `AND`, `OR`, `SLT`
* **I-Type:** `ADDI`, `LW`
* **S-Type:** `SW`
* **B-Type:** `BEQ`

The CPU is designed for **educational purposes** and can be easily extended to support more instructions or pipelining.

**Key Features:**

* Single-cycle execution (all operations complete in one clock cycle)
* Word-addressed **instruction and data memory**
* 32 general-purpose registers with **x0 hardwired to zero**
* Full **ALU and Control Unit implementation**
* Supports **immediate generation**, branch calculation, and memory access

---

##  File Structure

| Module                | Description                                                  |
| --------------------- | ------------------------------------------------------------ |
| `program_counter`     | Holds the current PC value; synchronous reset                |
| `pc_adder`            | Computes `PC + 4`                                            |
| `pc_mux`              | Selects next PC between `PC+4` and branch target             |
| `Instruction_Memory`  | Stores program instructions; word-addressed                  |
| `Register_File`       | 32x32 register file; synchronous write, asynchronous read    |
| `main_control_unit`   | Generates control signals from opcode                        |
| `immediate_generator` | Generates sign-extended immediates                           |
| `ALU`                 | Performs arithmetic and logic operations                     |
| `ALU_Control`         | Converts `funct3`, `funct7`, `ALUOp` into ALU operation code |
| `MUX2to1`             | Generic 2:1 multiplexer                                      |
| `Data_Memory`         | Read/write memory for LW/SW instructions                     |
| `MUX2to1_DataMemory`  | Write-back selection between ALU and memory                  |
| `Branch_Adder`        | Computes branch target addresses                             |
| `RISCV_Top`           | Top-level wrapper integrating all modules                    |

---

##  Instruction Examples

The instruction memory is preloaded with a **simple ALU program**:

| Addr | Instruction    | Description                |
| ---- | -------------- | -------------------------- |
| 0x00 | `addi x0,x0,0` | NOP                        |
| 0x04 | `addi x1,x0,5` | x1 = 5                     |
| 0x08 | `addi x2,x0,3` | x2 = 3                     |
| 0x0C | `add x3,x1,x2` | x3 = x1 + x2               |
| 0x10 | `sw x3,0(x0)`  | Store x3 in data memory[0] |
| 0x14 | `lw x4,0(x0)`  | Load memory[0] into x4     |

**Expected CPU Behavior:**

* x1 = 5
* x2 = 3
* x3 = 8
* Memory[0] = 8
* x4 = 8

---

##  CPU Datapath Overview

The CPU has a **single-cycle datapath**, where all instruction types are executed in **one clock cycle**:

1. **Fetch:** Read instruction from `Instruction_Memory` using PC
2. **Decode:** Parse instruction fields, read registers, generate control signals
3. **Execute:** ALU performs arithmetic/logic or calculates memory/branch addresses
4. **Memory:** Read/write data memory for `LW`/`SW`
5. **Write-Back:** Update register file with ALU or memory result

**Branching:** `BEQ` instruction uses a **branch adder** and PC mux to select next PC.

---

##  Control Signals

| Signal     | Function                                                |
| ---------- | ------------------------------------------------------- |
| `RegWrite` | Enable writing to register file                         |
| `MemRead`  | Enable reading from data memory                         |
| `MemWrite` | Enable writing to data memory                           |
| `MemToReg` | Select between ALU result or memory data for write-back |
| `ALUSrc`   | Choose ALU operand (register or immediate)              |
| `Branch`   | Indicates branch instruction                            |
| `ALUOp`    | Determines ALU operation type                           |

---

##  ALU Operations

| ALUcontrol | Operation | Description            |
| ---------- | --------- | ---------------------- |
| 0000       | ADD       | Addition               |
| 0001       | SUB       | Subtraction            |
| 0010       | AND       | Bitwise AND            |
| 0011       | OR        | Bitwise OR             |
| 0100       | XOR       | Bitwise XOR            |
| 0101       | SLL       | Shift left logical     |
| 0110       | SRL       | Shift right logical    |
| 0111       | SRA       | Shift right arithmetic |
| 1000       | SLT       | Set less than          |

**Zero flag** is set when ALU result is zero, used for branching.

---

##  Simulation

**Waveform generation** using Icarus Verilog & GTKWave:

```bash
iverilog -o single_cpu.v single_core_tb.v
vvp simv
gtkwave simv.vcd
```
![image](https://github.com/manohargumma/RISC-V-Single-Cycle-CPU/blob/b6b7f883aad7a2d0fbb4b709770c069c3fa6c5ed/images/Screenshot%20from%202025-10-26%2012-26-07.png)
![image](https://github.com/manohargumma/RISC-V-Single-Cycle-CPU/blob/19ad64ecc89207b89ee8e2d84f38c811da22c15b/images/Screenshot%20from%202025-10-26%2015-08-41.png)
Check:

* PC increments by 4
* Register writes occur correctly
* Data memory updates as expected
* ALU operations match instruction semantics

---

##  yosys Reports
### Read design
```bash
$ yosys
$ read_verilog riscv_single_file.v

```
![image](https://github.com/manohargumma/RISC-V-Single-Cycle-CPU/blob/3a2e1066121de5f42eed6b5f67ed898c8d07232a/images/Screenshot%20from%202025-10-26%2015-12-50.png)

### Elaborate hierarchy and set top module
```bash
$ hierarchy -check -top RISCV_Top

```
![image](https://github.com/manohargumma/RISC-V-Single-Cycle-CPU/blob/3a2e1066121de5f42eed6b5f67ed898c8d07232a/images/Screenshot%20from%202025-10-26%2015-13-46.png)
![image](https://github.com/manohargumma/RISC-V-Single-Cycle-CPU/blob/3a2e1066121de5f42eed6b5f67ed898c8d07232a/images/Screenshot%20from%202025-10-26%2015-13-58.png)

### Synthesis

```bash
$ proc

```
 

<details>
<summary>proc Report </summary>


```bash
yosys> proc

3. Executing PROC pass (convert processes to netlists).

3.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

3.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Removed 1 dead cases from process $proc$single_cpu.v:247$266 in module Data_Memory.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:247$266 in module Data_Memory.
Marked 3 switch rules as full_case in process $proc$single_cpu.v:249$259 in module Data_Memory.
Marked 2 switch rules as full_case in process $proc$single_cpu.v:194$254 in module ALU_Control.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:170$242 in module ALU.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:144$241 in module immediate_generator.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:115$240 in module main_control_unit.
Removed 1 dead cases from process $proc$single_cpu.v:101$236 in module Register_File.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:101$236 in module Register_File.
Removed 1 dead cases from process $proc$single_cpu.v:100$233 in module Register_File.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:100$233 in module Register_File.
Marked 3 switch rules as full_case in process $proc$single_cpu.v:92$224 in module Register_File.
Marked 1 switch rules as full_case in process $proc$single_cpu.v:14$6 in module program_counter.
Removed a total of 3 dead cases.

3.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 1 redundant assignment.
Promoted 189 assignments to connections.

3.4. Executing PROC_INIT pass (extract init attributes).
Found init rule in `\Data_Memory.$proc$single_cpu.v:240$269'.
  Set init value: \i = 64
  Set init value: \D_Memory[0] = 0
  Set init value: \D_Memory[1] = 0
  Set init value: \D_Memory[2] = 0
  Set init value: \D_Memory[3] = 0
  Set init value: \D_Memory[4] = 0
  Set init value: \D_Memory[5] = 0
  Set init value: \D_Memory[6] = 0
  Set init value: \D_Memory[7] = 0
  Set init value: \D_Memory[8] = 0
  Set init value: \D_Memory[9] = 0
  Set init value: \D_Memory[10] = 0
  Set init value: \D_Memory[11] = 0
  Set init value: \D_Memory[12] = 0
  Set init value: \D_Memory[13] = 0
  Set init value: \D_Memory[14] = 0
  Set init value: \D_Memory[15] = 0
  Set init value: \D_Memory[16] = 0
  Set init value: \D_Memory[17] = 0
  Set init value: \D_Memory[18] = 0
  Set init value: \D_Memory[19] = 0
  Set init value: \D_Memory[20] = 0
  Set init value: \D_Memory[21] = 0
  Set init value: \D_Memory[22] = 0
  Set init value: \D_Memory[23] = 0
  Set init value: \D_Memory[24] = 0
  Set init value: \D_Memory[25] = 0
  Set init value: \D_Memory[26] = 0
  Set init value: \D_Memory[27] = 0
  Set init value: \D_Memory[28] = 0
  Set init value: \D_Memory[29] = 0
  Set init value: \D_Memory[30] = 0
  Set init value: \D_Memory[31] = 0
  Set init value: \D_Memory[32] = 0
  Set init value: \D_Memory[33] = 0
  Set init value: \D_Memory[34] = 0
  Set init value: \D_Memory[35] = 0
  Set init value: \D_Memory[36] = 0
  Set init value: \D_Memory[37] = 0
  Set init value: \D_Memory[38] = 0
  Set init value: \D_Memory[39] = 0
  Set init value: \D_Memory[40] = 0
  Set init value: \D_Memory[41] = 0
  Set init value: \D_Memory[42] = 0
  Set init value: \D_Memory[43] = 0
  Set init value: \D_Memory[44] = 0
  Set init value: \D_Memory[45] = 0
  Set init value: \D_Memory[46] = 0
  Set init value: \D_Memory[47] = 0
  Set init value: \D_Memory[48] = 0
  Set init value: \D_Memory[49] = 0
  Set init value: \D_Memory[50] = 0
  Set init value: \D_Memory[51] = 0
  Set init value: \D_Memory[52] = 0
  Set init value: \D_Memory[53] = 0
  Set init value: \D_Memory[54] = 0
  Set init value: \D_Memory[55] = 0
  Set init value: \D_Memory[56] = 0
  Set init value: \D_Memory[57] = 0
  Set init value: \D_Memory[58] = 0
  Set init value: \D_Memory[59] = 0
  Set init value: \D_Memory[60] = 0
  Set init value: \D_Memory[61] = 0
  Set init value: \D_Memory[62] = 0
  Set init value: \D_Memory[63] = 0
Found init rule in `\Register_File.$proc$single_cpu.v:85$239'.
  Set init value: \k = 32
  Set init value: \Registers[0] = 0
  Set init value: \Registers[1] = 0
  Set init value: \Registers[2] = 0
  Set init value: \Registers[3] = 0
  Set init value: \Registers[4] = 0
  Set init value: \Registers[5] = 0
  Set init value: \Registers[6] = 0
  Set init value: \Registers[7] = 0
  Set init value: \Registers[8] = 0
  Set init value: \Registers[9] = 0
  Set init value: \Registers[10] = 0
  Set init value: \Registers[11] = 0
  Set init value: \Registers[12] = 0
  Set init value: \Registers[13] = 0
  Set init value: \Registers[14] = 0
  Set init value: \Registers[15] = 0
  Set init value: \Registers[16] = 0
  Set init value: \Registers[17] = 0
  Set init value: \Registers[18] = 0
  Set init value: \Registers[19] = 0
  Set init value: \Registers[20] = 0
  Set init value: \Registers[21] = 0
  Set init value: \Registers[22] = 0
  Set init value: \Registers[23] = 0
  Set init value: \Registers[24] = 0
  Set init value: \Registers[25] = 0
  Set init value: \Registers[26] = 0
  Set init value: \Registers[27] = 0
  Set init value: \Registers[28] = 0
  Set init value: \Registers[29] = 0
  Set init value: \Registers[30] = 0
  Set init value: \Registers[31] = 0

3.5. Executing PROC_ARST pass (detect async resets in processes).
Found async reset \rst in `\Data_Memory.$proc$single_cpu.v:249$259'.
Found async reset \rst in `\Register_File.$proc$single_cpu.v:92$224'.
Found async reset \rst in `\program_counter.$proc$single_cpu.v:14$6'.

3.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 1 switch.
<suppressed ~11 debug messages>

3.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `\Data_Memory.$proc$single_cpu.v:240$269'.
Creating decoders for process `\Data_Memory.$proc$single_cpu.v:247$266'.
     1/1: $1$mem2reg_rd$\D_Memory$single_cpu.v:247$256_DATA[31:0]$268
Creating decoders for process `\Data_Memory.$proc$single_cpu.v:249$259'.
     1/69: $2$mem2reg_wr$\D_Memory$single_cpu.v:253$257_ADDR[5:0]$264
     2/69: $2$mem2reg_wr$\D_Memory$single_cpu.v:253$257_DATA[31:0]$265
     3/69: $1$mem2reg_wr$\D_Memory$single_cpu.v:253$257_DATA[31:0]$263
     4/69: $1$mem2reg_wr$\D_Memory$single_cpu.v:253$257_ADDR[5:0]$262
     5/69: $1\i[31:0]
     6/69: $0\D_Memory[63][31:0]
     7/69: $0\D_Memory[62][31:0]
     8/69: $0\D_Memory[61][31:0]
     9/69: $0\D_Memory[60][31:0]
    10/69: $0\D_Memory[59][31:0]
    11/69: $0\D_Memory[58][31:0]
    12/69: $0\D_Memory[57][31:0]
    13/69: $0\D_Memory[56][31:0]
    14/69: $0\D_Memory[55][31:0]
    15/69: $0\D_Memory[54][31:0]
    16/69: $0\D_Memory[53][31:0]
    17/69: $0\D_Memory[52][31:0]
    18/69: $0\D_Memory[51][31:0]
    19/69: $0\D_Memory[50][31:0]
    20/69: $0\D_Memory[49][31:0]
    21/69: $0\D_Memory[48][31:0]
    22/69: $0\D_Memory[47][31:0]
    23/69: $0\D_Memory[46][31:0]
    24/69: $0\D_Memory[45][31:0]
    25/69: $0\D_Memory[44][31:0]
    26/69: $0\D_Memory[43][31:0]
    27/69: $0\D_Memory[42][31:0]
    28/69: $0\D_Memory[41][31:0]
    29/69: $0\D_Memory[40][31:0]
    30/69: $0\D_Memory[39][31:0]
    31/69: $0\D_Memory[38][31:0]
    32/69: $0\D_Memory[37][31:0]
    33/69: $0\D_Memory[36][31:0]
    34/69: $0\D_Memory[35][31:0]
    35/69: $0\D_Memory[34][31:0]
    36/69: $0\D_Memory[33][31:0]
    37/69: $0\D_Memory[32][31:0]
    38/69: $0\D_Memory[31][31:0]
    39/69: $0\D_Memory[30][31:0]
    40/69: $0\D_Memory[29][31:0]
    41/69: $0\D_Memory[28][31:0]
    42/69: $0\D_Memory[27][31:0]
    43/69: $0\D_Memory[26][31:0]
    44/69: $0\D_Memory[25][31:0]
    45/69: $0\D_Memory[24][31:0]
    46/69: $0\D_Memory[23][31:0]
    47/69: $0\D_Memory[22][31:0]
    48/69: $0\D_Memory[21][31:0]
    49/69: $0\D_Memory[20][31:0]
    50/69: $0\D_Memory[19][31:0]
    51/69: $0\D_Memory[18][31:0]
    52/69: $0\D_Memory[17][31:0]
    53/69: $0\D_Memory[16][31:0]
    54/69: $0\D_Memory[15][31:0]
    55/69: $0\D_Memory[14][31:0]
    56/69: $0\D_Memory[13][31:0]
    57/69: $0\D_Memory[12][31:0]
    58/69: $0\D_Memory[11][31:0]
    59/69: $0\D_Memory[10][31:0]
    60/69: $0\D_Memory[9][31:0]
    61/69: $0\D_Memory[8][31:0]
    62/69: $0\D_Memory[7][31:0]
    63/69: $0\D_Memory[6][31:0]
    64/69: $0\D_Memory[5][31:0]
    65/69: $0\D_Memory[4][31:0]
    66/69: $0\D_Memory[3][31:0]
    67/69: $0\D_Memory[2][31:0]
    68/69: $0\D_Memory[1][31:0]
    69/69: $0\D_Memory[0][31:0]
Creating decoders for process `\ALU_Control.$proc$single_cpu.v:194$254'.
     1/2: $2\ALUcontrol_Out[3:0]
     2/2: $1\ALUcontrol_Out[3:0]
Creating decoders for process `\ALU.$proc$single_cpu.v:170$242'.
     1/1: $1\Result[31:0]
Creating decoders for process `\immediate_generator.$proc$single_cpu.v:144$241'.
     1/1: $1\imm_out[31:0]
Creating decoders for process `\main_control_unit.$proc$single_cpu.v:115$240'.
     1/7: $1\ALUOp[1:0]
     2/7: $1\ALUSrc[0:0]
     3/7: $1\RegWrite[0:0]
     4/7: $1\Branch[0:0]
     5/7: $1\MemToReg[0:0]
     6/7: $1\MemWrite[0:0]
     7/7: $1\MemRead[0:0]
Creating decoders for process `\Register_File.$proc$single_cpu.v:85$239'.
Creating decoders for process `\Register_File.$proc$single_cpu.v:101$236'.
     1/1: $1$mem2reg_rd$\Registers$single_cpu.v:101$223_DATA[31:0]$238
Creating decoders for process `\Register_File.$proc$single_cpu.v:100$233'.
     1/1: $1$mem2reg_rd$\Registers$single_cpu.v:100$222_DATA[31:0]$235
Creating decoders for process `\Register_File.$proc$single_cpu.v:92$224'.
     1/37: $2$mem2reg_wr$\Registers$single_cpu.v:96$221_ADDR[4:0]$231
     2/37: $2$mem2reg_wr$\Registers$single_cpu.v:96$221_DATA[31:0]$232
     3/37: $1$mem2reg_wr$\Registers$single_cpu.v:96$221_DATA[31:0]$228
     4/37: $1$mem2reg_wr$\Registers$single_cpu.v:96$221_ADDR[4:0]$227
     5/37: $1\k[31:0]
     6/37: $0\Registers[31][31:0]
     7/37: $0\Registers[30][31:0]
     8/37: $0\Registers[29][31:0]
     9/37: $0\Registers[28][31:0]
    10/37: $0\Registers[27][31:0]
    11/37: $0\Registers[26][31:0]
    12/37: $0\Registers[25][31:0]
    13/37: $0\Registers[24][31:0]
    14/37: $0\Registers[23][31:0]
    15/37: $0\Registers[22][31:0]
    16/37: $0\Registers[21][31:0]
    17/37: $0\Registers[20][31:0]
    18/37: $0\Registers[19][31:0]
    19/37: $0\Registers[18][31:0]
    20/37: $0\Registers[17][31:0]
    21/37: $0\Registers[16][31:0]
    22/37: $0\Registers[15][31:0]
    23/37: $0\Registers[14][31:0]
    24/37: $0\Registers[13][31:0]
    25/37: $0\Registers[12][31:0]
    26/37: $0\Registers[11][31:0]
    27/37: $0\Registers[10][31:0]
    28/37: $0\Registers[9][31:0]
    29/37: $0\Registers[8][31:0]
    30/37: $0\Registers[7][31:0]
    31/37: $0\Registers[6][31:0]
    32/37: $0\Registers[5][31:0]
    33/37: $0\Registers[4][31:0]
    34/37: $0\Registers[3][31:0]
    35/37: $0\Registers[2][31:0]
    36/37: $0\Registers[1][31:0]
    37/37: $0\Registers[0][31:0]
Creating decoders for process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
Creating decoders for process `\program_counter.$proc$single_cpu.v:14$6'.
     1/1: $0\pc_out[31:0]

3.8. Executing PROC_DLATCH pass (convert process syncs to latches).
No latch inferred for signal `\Data_Memory.$mem2reg_rd$\D_Memory$single_cpu.v:247$256_DATA' from process `\Data_Memory.$proc$single_cpu.v:247$266'.
No latch inferred for signal `\ALU_Control.\ALUcontrol_Out' from process `\ALU_Control.$proc$single_cpu.v:194$254'.
No latch inferred for signal `\ALU.\Result' from process `\ALU.$proc$single_cpu.v:170$242'.
No latch inferred for signal `\ALU.\Zero' from process `\ALU.$proc$single_cpu.v:170$242'.
No latch inferred for signal `\immediate_generator.\imm_out' from process `\immediate_generator.$proc$single_cpu.v:144$241'.
No latch inferred for signal `\main_control_unit.\RegWrite' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\main_control_unit.\MemRead' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\main_control_unit.\MemWrite' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\main_control_unit.\MemToReg' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\main_control_unit.\ALUSrc' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\main_control_unit.\Branch' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\main_control_unit.\ALUOp' from process `\main_control_unit.$proc$single_cpu.v:115$240'.
No latch inferred for signal `\Register_File.$mem2reg_rd$\Registers$single_cpu.v:101$223_DATA' from process `\Register_File.$proc$single_cpu.v:101$236'.
No latch inferred for signal `\Register_File.$mem2reg_rd$\Registers$single_cpu.v:100$222_DATA' from process `\Register_File.$proc$single_cpu.v:100$233'.
No latch inferred for signal `\Instruction_Memory.\i' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$9_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$10_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$11_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$12_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$13_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$14_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$15_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$16_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$17_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$18_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$19_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$20_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$21_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$22_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$23_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$24_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$25_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$26_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$27_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$28_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$29_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$30_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$31_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$32_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$33_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$34_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$35_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$36_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$37_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$38_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$39_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$40_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$41_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$42_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$43_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$44_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$45_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$46_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$47_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$48_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$49_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$50_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$51_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$52_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$53_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$54_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$55_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$56_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$57_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$58_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$59_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$60_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$61_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$62_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$63_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$64_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$65_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$66_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$67_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$68_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$69_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$70_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$71_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:49$72_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:52$73_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:54$74_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:56$75_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:58$76_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:60$77_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.
No latch inferred for signal `\Instruction_Memory.$memwr$\I_Mem$single_cpu.v:62$78_EN' from process `\Instruction_Memory.$proc$single_cpu.v:47$150'.

3.9. Executing PROC_DFF pass (convert process syncs to FFs).
Creating register for signal `\Data_Memory.\i' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3475' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[0]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3478' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[1]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3481' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[2]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3484' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[3]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3487' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[4]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3490' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[5]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3493' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[6]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3496' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[7]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3499' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[8]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3502' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[9]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3505' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[10]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3508' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[11]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3511' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[12]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3514' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[13]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3517' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[14]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3520' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[15]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3523' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[16]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3526' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[17]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3529' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[18]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3532' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[19]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3535' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[20]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3538' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[21]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3541' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[22]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3544' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[23]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3547' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[24]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3550' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[25]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3553' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[26]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3556' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[27]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3559' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[28]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3562' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[29]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3565' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[30]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3568' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[31]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3571' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[32]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3574' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[33]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3577' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[34]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3580' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[35]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3583' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[36]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3586' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[37]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3589' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[38]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3592' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[39]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3595' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[40]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3598' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[41]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3601' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[42]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3604' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[43]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3607' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[44]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3610' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[45]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3613' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[46]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3616' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[47]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3619' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[48]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3622' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[49]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3625' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[50]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3628' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[51]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3631' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[52]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3634' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[53]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3637' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[54]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3640' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[55]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3643' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[56]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3646' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[57]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3649' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[58]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3652' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[59]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3655' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[60]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3658' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[61]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3661' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[62]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3664' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.\D_Memory[63]' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3667' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.$mem2reg_wr$\D_Memory$single_cpu.v:253$257_ADDR' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3670' with positive edge clock and positive level reset.
Creating register for signal `\Data_Memory.$mem2reg_wr$\D_Memory$single_cpu.v:253$257_DATA' using process `\Data_Memory.$proc$single_cpu.v:249$259'.
  created $adff cell `$procdff$3673' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\k' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3676' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[0]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3679' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[1]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3682' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[2]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3685' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[3]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3688' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[4]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3691' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[5]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3694' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[6]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3697' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[7]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3700' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[8]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3703' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[9]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3706' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[10]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3709' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[11]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3712' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[12]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3715' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[13]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3718' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[14]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3721' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[15]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3724' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[16]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3727' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[17]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3730' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[18]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3733' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[19]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3736' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[20]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3739' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[21]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3742' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[22]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3745' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[23]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3748' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[24]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3751' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[25]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3754' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[26]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3757' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[27]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3760' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[28]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3763' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[29]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3766' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[30]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3769' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.\Registers[31]' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3772' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.$mem2reg_wr$\Registers$single_cpu.v:96$221_ADDR' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3775' with positive edge clock and positive level reset.
Creating register for signal `\Register_File.$mem2reg_wr$\Registers$single_cpu.v:96$221_DATA' using process `\Register_File.$proc$single_cpu.v:92$224'.
  created $adff cell `$procdff$3778' with positive edge clock and positive level reset.
Creating register for signal `\program_counter.\pc_out' using process `\program_counter.$proc$single_cpu.v:14$6'.
  created $adff cell `$procdff$3781' with positive edge clock and positive level reset.

3.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

3.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Removing empty process `Data_Memory.$proc$single_cpu.v:240$269'.
Found and cleaned up 1 empty switch in `\Data_Memory.$proc$single_cpu.v:247$266'.
Removing empty process `Data_Memory.$proc$single_cpu.v:247$266'.
Found and cleaned up 2 empty switches in `\Data_Memory.$proc$single_cpu.v:249$259'.
Removing empty process `Data_Memory.$proc$single_cpu.v:249$259'.
Found and cleaned up 2 empty switches in `\ALU_Control.$proc$single_cpu.v:194$254'.
Removing empty process `ALU_Control.$proc$single_cpu.v:194$254'.
Found and cleaned up 1 empty switch in `\ALU.$proc$single_cpu.v:170$242'.
Removing empty process `ALU.$proc$single_cpu.v:170$242'.
Found and cleaned up 1 empty switch in `\immediate_generator.$proc$single_cpu.v:144$241'.
Removing empty process `immediate_generator.$proc$single_cpu.v:144$241'.
Found and cleaned up 1 empty switch in `\main_control_unit.$proc$single_cpu.v:115$240'.
Removing empty process `main_control_unit.$proc$single_cpu.v:115$240'.
Removing empty process `Register_File.$proc$single_cpu.v:85$239'.
Found and cleaned up 1 empty switch in `\Register_File.$proc$single_cpu.v:101$236'.
Removing empty process `Register_File.$proc$single_cpu.v:101$236'.
Found and cleaned up 1 empty switch in `\Register_File.$proc$single_cpu.v:100$233'.
Removing empty process `Register_File.$proc$single_cpu.v:100$233'.
Found and cleaned up 2 empty switches in `\Register_File.$proc$single_cpu.v:92$224'.
Removing empty process `Register_File.$proc$single_cpu.v:92$224'.
Removing empty process `Instruction_Memory.$proc$single_cpu.v:47$150'.
Removing empty process `program_counter.$proc$single_cpu.v:14$6'.
Cleaned up 12 empty switches.

3.12. Executing OPT_EXPR pass (perform const folding).
Optimizing module RISCV_Top.
Optimizing module Branch_Adder.
Optimizing module MUX2to1_DataMemory.
Optimizing module Data_Memory.
<suppressed ~69 debug messages>
Optimizing module MUX2to1.
Optimizing module ALU_Control.
Optimizing module ALU.
<suppressed ~2 debug messages>
Optimizing module immediate_generator.
Optimizing module main_control_unit.
Optimizing module Register_File.
<suppressed ~39 debug messages>
Optimizing module Instruction_Memory.
Optimizing module pc_mux.
Optimizing module pc_adder.
Optimizing module program_counter.
<suppressed ~1 debug messages>

yosys> 


```
</details>
