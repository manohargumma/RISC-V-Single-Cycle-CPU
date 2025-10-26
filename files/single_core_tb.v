`timescale 1ns / 1ps

module Single_Cycle_Top_Tb;

    reg clk;
    reg reset;

    // Instantiate CPU correctly
    RISCV_Top uut (
        .clk(clk),
        .rst(reset)
    );

    integer outfile;
    integer cycle;

    // Clock: 10ns period (100MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        outfile = $fopen("full_cpu_output.txt","w");

        $dumpfile("sim.vcd");
        $dumpvars(0, uut);

        #20 reset = 0;

        for (cycle = 0; cycle < 50; cycle = cycle + 1) begin
            @(posedge clk);

            $fdisplay(outfile, "\nCycle %0d:", cycle);
            $fdisplay(outfile, "PC = %h", uut.PC.pc_out);
            $fdisplay(outfile, "Instruction = %h", uut.Instr_Mem.instruction_out);
            $fdisplay(outfile, "Reg x1 = %h", uut.Reg_File.Registers[1]);
            $fdisplay(outfile, "Reg x2 = %h", uut.Reg_File.Registers[2]);
            $fdisplay(outfile, "Reg x3 = %h", uut.Reg_File.Registers[3]);
            $fdisplay(outfile, "ALU Result = %h", uut.ALU_unit.Result);
            $fdisplay(outfile, "Mem Read Data = %h", uut.Data_Mem.read_data);
        end

        $fclose(outfile);
        $finish;
    end
endmodule

