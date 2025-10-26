// riscv_single_file.v
// Single-file RISC-V small single-cycle CPU (subset) - ready for TB
// Modules: program_counter, pc_adder, pc_mux, instruction_memory, register_file,
// main_control_unit, immediate_generator, ALU, ALU_Control, MUX2to1, Data_Memory,
// MUX2to1_DataMemory, Branch_Adder, RISCV_Top

// 1) Program Counter
module program_counter(
    input clk,
    input rst,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) pc_out <= 32'd0;
        else     pc_out <= pc_in;
    end
endmodule

// 2) PC adder (pc + 4)
module pc_adder(
    input [31:0] pc_in,
    output [31:0] pc_next
);
    assign pc_next = pc_in + 32'd4;
endmodule

// 3) PC mux (choose between pc+4 and branch target)
module pc_mux(
    input [31:0] pc_plus4,
    input [31:0] pc_branch,
    input pc_select,
    output [31:0] pc_out
);
    assign pc_out = pc_select ? pc_branch : pc_plus4;
endmodule

// 4) Instruction memory (word-addressed). Depth: 64 words (adjust index bits if you need more)
module Instruction_Memory(
    input rst,
    input clk,
    input [31:0] read_address,    // byte address
    output [31:0] instruction_out
);
    reg [31:0] I_Mem [0:63];
    integer i;
    initial begin
        // default zeroes
        for (i = 0; i < 64; i = i + 1) I_Mem[i] = 32'd0;
        // small example program (word indices)
        // 0: NOP (addi x0,x0,0)
        I_Mem[0]  = 32'h00000013;
        // 1: addi x1, x0, 5  -> x1 = 5
        I_Mem[1]  = 32'h00500093; // addi x1,x0,5  (imm=5 -> 0x005, rd=1, funct3=0, rs1=0, opcode=0x13)
        // 2: addi x2, x0, 3  -> x2 = 3
        I_Mem[2]  = 32'h00300113; // addi x2,x0,3
        // 3: add x3, x1, x2  -> x3 = x1 + x2
        I_Mem[3]  = 32'h002081b3; // add x3,x1,x2 (funct7=0, rs2=2, rs1=1, funct3=0, rd=3, opcode=0x33)
        // 4: sw x3, 0(x0)    -> store x3 to data mem[0]
        I_Mem[4]  = 32'h00302023; // sw x3,0(x0)
        // 5: lw x4, 0(x0)    -> load into x4
        I_Mem[5]  = 32'h00002103; // lw x4,0(x0) with rd=4, rs1=0, imm=0
        // rest are zeros (NOP)
    end

    // index by word: address[7:2] for 64 entries (6 bits)
    wire [5:0] idx = read_address[7:2];
    assign instruction_out = I_Mem[idx];
endmodule

// 5) Register file (32x32): synchronous write, asynchronous read
module Register_File(
    input clk,
    input rst,
    input RegWrite,
    input [4:0] Rs1,
    input [4:0] Rs2,
    input [4:0] Rd,
    input [31:0] Write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] Registers [0:31];
    integer k;
    initial begin
        for (k = 0; k < 32; k = k + 1) Registers[k] = 32'd0;
        // optionally preset values for testing (comment out if undesired)
        Registers[1] = 32'd0;
    end

    // synchronous write (x0 is hardwired zero)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1) Registers[k] <= 32'd0;
        end else if (RegWrite && (Rd != 5'd0)) begin
            Registers[Rd] <= Write_data;
        end
    end

    assign read_data1 = Registers[Rs1];
    assign read_data2 = Registers[Rs2];
endmodule

// 6) Main control unit (very small opcode decoder)
module main_control_unit(
    input [6:0] opcode,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg MemToReg,
    output reg ALUSrc,
    output reg Branch,
    output reg [1:0] ALUOp
);
    always @(*) begin
        // defaults
        RegWrite = 0; MemRead = 0; MemWrite = 0; MemToReg = 0; ALUSrc = 0; Branch = 0; ALUOp = 2'b00;
        case (opcode)
            7'b0110011: begin // R-type
                RegWrite = 1; ALUSrc = 0; ALUOp = 2'b10;
            end
            7'b0010011: begin // I-type (addi, etc.)
                RegWrite = 1; ALUSrc = 1; ALUOp = 2'b10;
            end
            7'b0000011: begin // LW
                RegWrite = 1; ALUSrc = 1; MemRead = 1; MemToReg = 1; ALUOp = 2'b00;
            end
            7'b0100011: begin // SW
                RegWrite = 0; ALUSrc = 1; MemWrite = 1; ALUOp = 2'b00;
            end
            7'b1100011: begin // BEQ
                RegWrite = 0; ALUSrc = 0; Branch = 1; ALUOp = 2'b01;
            end
            default: begin end
        endcase
    end
endmodule

// 7) Immediate generator (I,S,B,U,J types simplified)
module immediate_generator(
    input [31:0] instruction,
    output reg [31:0] imm_out
);
    always @(*) begin
        case (instruction[6:0])
            7'b0010011, 7'b0000011: // I-type, load
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: // S-type
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011: // B-type
                imm_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b0110111, 7'b0010111: // U-type (LUI/AUIPC)
                imm_out = {instruction[31:12], 12'b0};
            7'b1101111: // J-type
                imm_out = {{11{instruction[31]}}, instruction[31:12]}; // approximate for demo
            default:
                imm_out = 32'd0;
        endcase
    end
endmodule

// 8) ALU
module ALU(
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALUcontrol_In,
    output reg [31:0] Result,
    output reg Zero
);
    always @(*) begin
        case (ALUcontrol_In)
            4'b0000: Result = A + B;                  // ADD
            4'b0001: Result = A - B;                  // SUB
            4'b0010: Result = A & B;                  // AND
            4'b0011: Result = A | B;                  // OR
            4'b0100: Result = A ^ B;                  // XOR
            4'b0101: Result = A << B[4:0];            // SLL
            4'b0110: Result = A >> B[4:0];            // SRL
            4'b0111: Result = ($signed(A) >>> B[4:0]); // SRA
            4'b1000: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT
            default: Result = 32'd0;
        endcase
        Zero = (Result == 32'd0);
    end
endmodule

// 9) ALU Control: map ALUOp + funct fields -> ALUcontrol code
module ALU_Control(
    input [2:0] funct3,
    input [6:0] funct7,
    input [1:0] ALUOp,
    output reg [3:0] ALUcontrol_Out
);
    always @(*) begin
        // default: ADD
        ALUcontrol_Out = 4'b0000;
        case (ALUOp)
            2'b00: ALUcontrol_Out = 4'b0000; // loads/stores -> ADD
            2'b01: ALUcontrol_Out = 4'b0001; // branches -> SUB
            2'b10: begin // R-type or I-type
                case ({funct7[5], funct3})
                    {1'b0,3'b000}: ALUcontrol_Out = 4'b0000; // ADD
                    {1'b1,3'b000}: ALUcontrol_Out = 4'b0001; // SUB
                    {1'b0,3'b111}: ALUcontrol_Out = 4'b0010; // AND
                    {1'b0,3'b110}: ALUcontrol_Out = 4'b0011; // OR
                    {1'b0,3'b100}: ALUcontrol_Out = 4'b0100; // XOR
                    {1'b0,3'b001}: ALUcontrol_Out = 4'b0101; // SLL
                    {1'b0,3'b101}: ALUcontrol_Out = 4'b0110; // SRL
                    {1'b1,3'b101}: ALUcontrol_Out = 4'b0111; // SRA
                    {1'b0,3'b010}: ALUcontrol_Out = 4'b1000; // SLT
                    default: ALUcontrol_Out = 4'b0000;
                endcase
            end
        endcase
    end
endmodule

// 10) 2:1 MUX (parameterised not used to keep simple)
module MUX2to1 (
    input [31:0] input0,
    input [31:0] input1,
    input select,
    output [31:0] out
);
    assign out = select ? input1 : input0;
endmodule

// 11) Data memory (word-indexed)
module Data_Memory(
    input clk,
    input rst,
    input MemRead,
    input MemWrite,
    input [31:0] address,     // byte
    input [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] D_Memory [0:63];
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) D_Memory[i] = 32'd0;
        // sample init
        D_Memory[0] = 32'd0;
    end

    wire [5:0] idx = address[7:2];
    assign read_data = (MemRead) ? D_Memory[idx] : 32'd0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1) D_Memory[i] <= 32'd0;
        end else if (MemWrite) begin
            D_Memory[idx] <= write_data;
        end
    end
endmodule

// 12) WB mux for choosing ALU or memory result
module MUX2to1_DataMemory (
    input [31:0] input0,
    input [31:0] input1,
    input select,
    output [31:0] out
);
    assign out = select ? input1 : input0;
endmodule

// 13) Branch adder (PC + offset)
module Branch_Adder(
    input [31:0] PC,
    input [31:0] offset,
    output [31:0] branch_target
);
    assign branch_target = PC + offset;
endmodule

// 14) Top-level RISCV single-cycle wrapper
module RISCV_Top(
    input clk,
    input rst
);
    // wires
    wire [31:0] pc_out_wire, pc_plus4, pc_next, instr;
    wire [31:0] immgen_wire, alu_b, alu_result, mem_read_data, wb_data;
    wire [31:0] reg_read1, reg_read2;
    wire RegWrite, MemRead, MemWrite, MemToReg, ALUSrc, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUcontrol;
    wire Zero;
    wire [31:0] branch_target;

    // instantiations with stable instance names for TB hierarchy access
    program_counter    PC        (.clk(clk), .rst(rst), .pc_in(pc_next), .pc_out(pc_out_wire));
    pc_adder           PC_Adder  (.pc_in(pc_out_wire), .pc_next(pc_plus4));
    Branch_Adder       BranchAdder(.PC(pc_out_wire), .offset(immgen_wire), .branch_target(branch_target));
    pc_mux             PC_Mux    (.pc_plus4(pc_plus4), .pc_branch(branch_target), .pc_select(Branch & Zero), .pc_out(pc_next));
    Instruction_Memory Instr_Mem (.rst(rst), .clk(clk), .read_address(pc_out_wire), .instruction_out(instr));
    Register_File      Reg_File  (.clk(clk), .rst(rst), .RegWrite(RegWrite), .Rs1(instr[19:15]), .Rs2(instr[24:20]), .Rd(instr[11:7]), .Write_data(wb_data), .read_data1(reg_read1), .read_data2(reg_read2));
    main_control_unit  Control   (.opcode(instr[6:0]), .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite), .MemToReg(MemToReg), .ALUSrc(ALUSrc), .Branch(Branch), .ALUOp(ALUOp));
    ALU_Control        ALUCtrl   (.funct3(instr[14:12]), .funct7(instr[31:25]), .ALUOp(ALUOp), .ALUcontrol_Out(ALUcontrol));
    immediate_generator ImmGen   (.instruction(instr), .imm_out(immgen_wire));
    MUX2to1            ALU_MUX   (.input0(reg_read2), .input1(immgen_wire), .select(ALUSrc), .out(alu_b));
    ALU                ALU_unit  (.A(reg_read1), .B(alu_b), .ALUcontrol_In(ALUcontrol), .Result(alu_result), .Zero(Zero));
    Data_Memory        Data_Mem  (.clk(clk), .rst(rst), .MemRead(MemRead), .MemWrite(MemWrite), .address(alu_result), .write_data(reg_read2), .read_data(mem_read_data));
    MUX2to1_DataMemory WB_MUX    (.input0(alu_result), .input1(mem_read_data), .select(MemToReg), .out(wb_data));

    // expose some nets as top-level for easier TB access (optional via hierarchical)
    // e.g., instr, pc_out_wire, reg_read1 etc. are visible via UUT.<name>

endmodule

