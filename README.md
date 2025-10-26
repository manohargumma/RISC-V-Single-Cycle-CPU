# RISC-V-Single-Cycle-CPUPerfect! Let’s **expand your README** to make it more detailed, closer to a **mini-project report**, while still keeping it GitHub-friendly. I’ll include:

* More explanation for ALU, Control Unit
* Datapath details with LW, SW, R-type
* Instruction encoding tables
* Example assembly + machine code
* Simulation & extension ideas

Here’s the **enhanced README.md**:

---

# RISC-V Single-Cycle Microarchitecture

### Project By: MERL-DSU 🖥️⚙️

---

## 📌 Overview

This project implements a **32-bit Single-Cycle RISC-V CPU**, designed to execute a core subset of the **RV32I instruction set**.
It integrates **key microarchitecture components**, including:

* Arithmetic Logic Unit (ALU)
* Control Unit (Main & ALU Decoder)
* Register File
* Instruction & Data Memory
* Single-Cycle Datapath supporting **LW, SW, and R-Type instructions**

The design follows **synchronous sequential logic**, with state elements updated on the rising clock edge.

---

## 🔹 Table of Contents

1. [Arithmetic Logic Unit (ALU)](#-arithmetic-logic-unit-alu)
2. [Control Unit](#-control-unit)
3. [Instruction Encoding](#-instruction-encoding)
4. [Microarchitecture Design](#-microarchitecture-design)
5. [Instruction Datapath](#-instruction-datapath)
6. [Verilog Implementation](#-verilog-implementation)
7. [Simulation & Testing](#-simulation--testing)
8. [Project Status & Future Enhancements](#-project-status--future-enhancements)

---

## 🔹 Arithmetic Logic Unit (ALU)

The **ALU** performs arithmetic and logic operations based on a 3-bit **ALUControl** signal.
It generates:

* 32-bit **Result**
* 1-bit **Zero flag** (set when Result = 0)

| ALUControl | Operation | Description                               |
| ---------- | --------- | ----------------------------------------- |
| 000        | ADD       | Addition: Result = A + B                  |
| 001        | SUB       | Subtraction: Result = A - B               |
| 010        | SLT       | Set Less Than: Result = 1 if A < B else 0 |
| 011        | OR        | Bitwise OR: Result = A | B                |
| 100        | AND       | Bitwise AND: Result = A & B               |

**Design Principles:**

* Divide & Conquer: Arithmetic and logic operations handled separately
* Multiplexers select the correct output based on ALUControl
* Supports **future extension** to more operations

---

## 🔹 Control Unit

The **Control Unit** interprets the instruction opcode and function fields to generate signals for the datapath.

| Signal    | Purpose                                                |
| --------- | ------------------------------------------------------ |
| RegWrite  | Enable writing to register file                        |
| MemWrite  | Enable writing to data memory                          |
| ALUOp     | Determines ALU operation                               |
| ALUSrc    | Selects ALU second operand (register or immediate)     |
| ResultSrc | Selects data to write back (ALU result or memory data) |

Two-stage decoding:

1. **Main Decoder:** Generates high-level control signals based on opcode
2. **ALU Decoder:** Converts **ALUOp + funct fields** into 3-bit ALUControl

**Supported Instruction Types:**

* R-Type: ADD, SUB, AND, OR, SLT
* I-Type: LW
* S-Type: SW

---

## 🔹 Instruction Encoding

### R-Type (Register)

| Field  | Bits  | Description                        |
| ------ | ----- | ---------------------------------- |
| funct7 | 31–25 | Specifies operation variation      |
| rs2    | 24–20 | Second source register             |
| rs1    | 19–15 | First source register              |
| funct3 | 14–12 | Specifies ALU operation            |
| rd     | 11–7  | Destination register               |
| opcode | 6–0   | Operation code (33 for all R-type) |

Example: `add x3, x1, x2` → opcode: `33`, funct3: `000`, funct7: `0000000`

### I-Type (Immediate)

| Field  | Bits  | Description                      |
| ------ | ----- | -------------------------------- |
| imm    | 31–20 | 12-bit immediate (sign-extended) |
| rs1    | 19–15 | Source register                  |
| funct3 | 14–12 | Operation type                   |
| rd     | 11–7  | Destination register             |
| opcode | 6–0   | Opcode (e.g., 3 for LW)          |

Example: `lw x5, 12(x1)` → opcode: `0000011`, imm: `12`

### S-Type (Store)

| Field     | Bits  | Description              |
| --------- | ----- | ------------------------ |
| imm[11:5] | 31–25 | Upper immediate bits     |
| rs2       | 24–20 | Source register (data)   |
| rs1       | 19–15 | Base address register    |
| funct3    | 14–12 | Operation type           |
| imm[4:0]  | 11–7  | Lower immediate bits     |
| opcode    | 6–0   | Opcode (e.g., 35 for SW) |

---

## 🔹 Microarchitecture Design

**State Elements:**

| Element              | Size         | Function                         |
| -------------------- | ------------ | -------------------------------- |
| Program Counter (PC) | 32-bit       | Tracks current instruction       |
| Register File        | 32 × 32      | Stores general-purpose registers |
| Instruction Memory   | 32-bit words | Holds program instructions       |
| Data Memory          | 32-bit words | Holds data                       |

**Datapath Features:**

* Heavy lines = 32-bit data bus
* Medium lines = 5-bit register addresses
* Narrow lines = Control signals
* Synchronous updates on **clock rising edge**

---

## 🔹 Instruction Datapath

### LW (Load Word)

1. Read `rs1` from register file → base address
2. Sign-extend 12-bit immediate
3. ALU computes address: `Base + Offset`
4. Data Memory outputs ReadData → write back to `rd`

### SW (Store Word)

1. Read `rs1` → base, `rs2` → data
2. Sign-extend immediate, ALU computes address
3. MemWrite = 1 → store data in memory
4. RegWrite = 0 → no register written

### R-Type (ADD, SUB, AND, OR, SLT)

1. Read `rs1`, `rs2` → ALU inputs
2. ALU performs operation based on ALUControl
3. Write ALUResult to `rd` in Register File
4. ALUSrc = 0 (uses register), ResultSrc = 0 (ALU output)

---

## 💻 Verilog Implementation

### ALU Module

```verilog
module ALU (
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  ALUControl,
    output reg [31:0] Result,
    output Zero
);

always @(*) begin
    case(ALUControl)
        3'b000: Result = A + B;
        3'b001: Result = A - B;
        3'b010: Result = (A < B) ? 32'b1 : 32'b0;
        3'b011: Result = A | B;
        3'b100: Result = A & B;
        default: Result = 32'b0;
    endcase
end

assign Zero = (Result == 0);

endmodule
```

---

## 🔹 Simulation & Testing

Generate waveform:

```bash
iverilog -o cpu_tb cpu.v alu.v control.v regfile.v ...
vvp cpu_tb
gtkwave dump.vcd
```

**Observation:**

* PC increments by 4 every cycle
* LW loads correct memory data
* SW updates memory correctly
* R-Type ALU operations produce expected results

---

## 🔹 Project Status & Future Enhancements

✅ Completed:

* ALU, Control Unit
* Datapath for LW, SW, R-Type
* Register File and Memory Interfaces

🚀 Future Work:

* Implement **Branch & Jump Instructions** (B-Type, JAL)
* Pipeline for higher performance
* Hazard detection and forwarding

---

## 🧑‍💻 Contributors

**MERL-DSU Team** – Hardware design, Verilog coding, simulation & testing

---

If you want, I can **also add:**

1. **Datapath diagrams for all instructions** (LW/SW/R-Type) in **GitHub-friendly SVG/PNG**
2. **Full Verilog top-module** combining ALU, control unit, register file, memories, and muxes
3. **Example assembly programs with expected output**
4. **Waveform screenshots**

This would make your **README almost 10–15 pages worth of content** visually on GitHub.

Do you want me to go ahead and **add diagrams + top-level Verilog + example assembly programs** next?
