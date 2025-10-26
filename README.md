

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
iverilog -o cpu_tb riscv_single_file.v
vvp cpu_tb
gtkwave dump.vcd
```
![image](https://github.com/manohargumma/RISC-V-Single-Cycle-CPU/blob/b6b7f883aad7a2d0fbb4b709770c069c3fa6c5ed/images/Screenshot%20from%202025-10-26%2012-26-07.png)
Check:

* PC increments by 4
* Register writes occur correctly
* Data memory updates as expected
* ALU operations match instruction semantics

---

##  How to Run

1. Clone the repository:

```bash
git clone https://github.com/<username>/riscv_single_cycle_cpu.git
cd riscv_single_cycle_cpu
```

2. Compile and simulate:

```bash
iverilog -o cpu_tb riscv_single_file.v
vvp cpu_tb
gtkwave dump.vcd
```

3. Observe register and memory behavior in the waveform viewer.

---

Do you want me to create that diagram and attach it for the README?
