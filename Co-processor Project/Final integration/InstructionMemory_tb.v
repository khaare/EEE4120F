`timescale 1ns / 1ps
`include "Parameter.v"

module InstructionMemory_tb;

    reg  [15:0] pc;
    wire [15:0] instruction;

    InstructionMemory uut (.pc(pc), .out(instruction));

    initial begin
        $dumpfile("waves/im_tb.vcd");
        $dumpvars(0, InstructionMemory_tb);
    end

    integer fail_count;
    integer test_id;
    integer i;
    reg [15:0] expected [0:15];

    initial begin
        fail_count = 0;
        test_id    = 1;

        $display("=== InstructionMemory Testbench ===");

expected[0]  = 16'b0000010000000000;
expected[1]  = 16'b0000010001000001;
expected[2]  = 16'b0010000001010000;
expected[3]  = 16'b0001001010000000;
expected[4]  = 16'b0011000001010000;
expected[5]  = 16'b0111000001010000;
expected[6]  = 16'b1000000001010000;
expected[7]  = 16'b1001000001010000;
expected[8]  = 16'b0010000000000000;
expected[9]  = 16'b1011000001000001;
expected[10] = 16'b1100000001000000;
expected[11] = 16'b1101000000001011;
expected[12] = 16'b0000000000000000;
expected[13] = 16'b0000000000000000;
expected[14] = 16'b0000000000000000;
expected[15] = 16'b0000000000000000;

        for (i = 0; i < 16; i = i + 1) begin
            pc = i * 2;
            #5;
            if (instruction !== expected[i]) begin
                $display("FAIL [T%0d]: PC=%0d got %b expected %b",
                         test_id, pc, instruction, expected[i]);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: PC=%0d instr=%b", test_id, pc, instruction);
            test_id = test_id + 1;
        end

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule