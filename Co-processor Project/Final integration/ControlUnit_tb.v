`timescale 1ns / 1ps
`include "Parameter.v"

module ControlUnit_tb;

    reg  [3:0] opcode;

    wire [1:0] ALUOp;
    wire       Jump;
    wire       Branch;
    wire       MemRd;
    wire       MemWr;
    wire       ALUSrc;
    wire       RegDst;
    wire       MemToReg;
    wire       RegWrite;

    ControlUnit uut (
        .opcode   (opcode),
        .ALUOp    (ALUOp),
        .Jump     (Jump),
        .Branch   (Branch),
        .MemRd    (MemRd),
        .MemWr    (MemWr),
        .ALUSrc   (ALUSrc),
        .RegDst   (RegDst),
        .MemToReg (MemToReg),
        .RegWrite (RegWrite)
    );

    initial begin
        $dumpfile("waves/cu_tb.vcd");
        $dumpvars(0, ControlUnit_tb);
    end

    integer fail_count;
    integer test_id;

    task check_ctrl;
        input [1:0] e_aluop;
        input       e_jump, e_branch;
        input       e_memrd, e_memwr;
        input       e_alusrc, e_regdst;
        input       e_memtoreg, e_regwrite;
        input [63:0] id;

        reg failed;
        begin
            failed = 1'b0;

            if (ALUOp    !== e_aluop)   begin $display("  MISMATCH ALUOp:    %b vs %b", ALUOp,    e_aluop);   failed=1; end
            if (Jump     !== e_jump)    begin $display("  MISMATCH Jump:     %b vs %b", Jump,     e_jump);    failed=1; end
            if (Branch   !== e_branch)  begin $display("  MISMATCH Branch:   %b vs %b", Branch,   e_branch);  failed=1; end
            if (MemRd    !== e_memrd)   begin $display("  MISMATCH MemRd:    %b vs %b", MemRd,    e_memrd);   failed=1; end
            if (MemWr    !== e_memwr)   begin $display("  MISMATCH MemWr:    %b vs %b", MemWr,    e_memwr);   failed=1; end
            if (ALUSrc   !== e_alusrc)  begin $display("  MISMATCH ALUSrc:   %b vs %b", ALUSrc,   e_alusrc);  failed=1; end
            if (RegDst   !== e_regdst)  begin $display("  MISMATCH RegDst:   %b vs %b", RegDst,   e_regdst);  failed=1; end
            if (MemToReg !== e_memtoreg)begin $display("  MISMATCH MemToReg: %b vs %b", MemToReg, e_memtoreg);failed=1; end
            if (RegWrite !== e_regwrite)begin $display("  MISMATCH RegWrite: %b vs %b", RegWrite, e_regwrite);failed=1; end

            if (failed) begin
                $display("FAIL [T%0d]: opcode=%b", id, opcode);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: opcode=%b all signals correct", id, opcode);
        end
    endtask

    initial begin
        fail_count = 0;
        test_id    = 1;
        $display("=== ControlUnit Testbench ===");

        opcode = 4'b0000; #10;
        check_ctrl(2'b10, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b0001; #10;
        check_ctrl(2'b10, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        opcode = 4'b0010; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b0011; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b0100; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b0101; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b0110; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b0111; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b1000; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b1001; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
        test_id = test_id + 1;

        opcode = 4'b1010; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        opcode = 4'b1011; #10;
        check_ctrl(2'b01, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        opcode = 4'b1100; #10;
        check_ctrl(2'b01, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        opcode = 4'b1101; #10;
        check_ctrl(2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        opcode = 4'b1111; #10;
        check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
        test_id = test_id + 1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule