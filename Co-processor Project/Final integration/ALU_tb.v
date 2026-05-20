
`timescale 1ns / 1ps
`include "Parameter.v"

module ALU_tb;

    reg  [15:0] a;
    reg  [15:0] b;
    reg  [ 2:0] alu_control;
    wire [15:0] result;
    wire        zero;

    ALU uut (
        .a           (a),
        .b           (b),
        .control_signal (alu_control),
        .out      (result),
        .zero        (zero)
    );

    initial begin
        $dumpfile("waves/alu_tb.vcd");
        $dumpvars(0, ALU_tb);
    end

    integer fail_count;
    integer test_id;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    task check_result;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: result = %0d (0x%h), expected = %0d (0x%h)",
                         id, got, got, expected, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: result = %0d (0x%h)", id, got, got);
            end
        end
    endtask

    task check_zero;
        input got;
        input expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d] zero flag: got = %b, expected = %b", id, got, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d] zero flag = %b", id, got);
            end
        end
    endtask

    initial begin
        $display("=== ALU Testbench ===");
        $display("--- ADD ---");

        a = 16'd10;   b = 16'd5;      alu_control = 3'b000; #10;
        check_result(result, 16'd15,     test_id); test_id = test_id + 1;

        a = 16'hFFFF; b = 16'd1;      alu_control = 3'b000; #10;
        check_result(result, 16'h0000,   test_id); test_id = test_id + 1;

        a = 16'd0;    b = 16'd0;      alu_control = 3'b000; #10;
        check_result(result, 16'd0,      test_id); test_id = test_id + 1;

        $display("--- SUB ---");

        a = 16'd10;   b = 16'd5;      alu_control = 3'b001; #10;
        check_result(result, 16'd5,      test_id); test_id = test_id + 1;

        a = 16'd7;    b = 16'd7;      alu_control = 3'b001; #10;
        check_result(result, 16'd0,      test_id); test_id = test_id + 1;
        check_zero(zero, 1'b1,           test_id); test_id = test_id + 1;

        a = 16'd5;    b = 16'd10;     alu_control = 3'b001; #10;
        check_result(result, 16'hFFFB,   test_id); test_id = test_id + 1;

        $display("--- INV ---");

        a = 16'h0000; b = 16'd0;      alu_control = 3'b100; #10;
        check_result(result, 16'hFFFF,   test_id); test_id = test_id + 1;

        a = 16'hFFFF; b = 16'd0;      alu_control = 3'b100; #10;
        check_result(result, 16'h0000,   test_id); test_id = test_id + 1;

        a = 16'hA5A5; b = 16'd0;      alu_control = 3'b100; #10;
        check_result(result, 16'h5A5A,   test_id); test_id = test_id + 1;

        $display("--- SHL ---");

        a = 16'h0001; b = 16'd4;      alu_control = 3'b101; #10;
        check_result(result, 16'h0010,   test_id); test_id = test_id + 1;

        a = 16'h0003; b = 16'd2;      alu_control = 3'b101; #10;
        check_result(result, 16'h000C,   test_id); test_id = test_id + 1;

        a = 16'hFFFF; b = 16'd8;      alu_control = 3'b101; #10;
        check_result(result, 16'hFF00,   test_id); test_id = test_id + 1;

        $display("--- SHR ---");

        a = 16'h0080; b = 16'd4;      alu_control = 3'b110; #10;
        check_result(result, 16'h0008,   test_id); test_id = test_id + 1;

        a = 16'hFFFF; b = 16'd8;      alu_control = 3'b110; #10;
        check_result(result, 16'h00FF,   test_id); test_id = test_id + 1;

        a = 16'h0001; b = 16'd1;      alu_control = 3'b110; #10;
        check_result(result, 16'h0000,   test_id); test_id = test_id + 1;

        $display("--- AND ---");

        a = 16'hFFFF; b = 16'h0F0F;   alu_control = 3'b010; #10;
        check_result(result, 16'h0F0F,   test_id); test_id = test_id + 1;

        a = 16'hAAAA; b = 16'h5555;   alu_control = 3'b010; #10;
        check_result(result, 16'h0000,   test_id); test_id = test_id + 1;

        a = 16'h0000; b = 16'hBEEF;   alu_control = 3'b010; #10;
        check_result(result, 16'h0000,   test_id); test_id = test_id + 1;

        $display("--- OR ---");

        a = 16'h0F0F; b = 16'hF0F0;   alu_control = 3'b011; #10;
        check_result(result, 16'hFFFF,   test_id); test_id = test_id + 1;

        a = 16'hAAAA; b = 16'h5555;   alu_control = 3'b011; #10;
        check_result(result, 16'hFFFF,   test_id); test_id = test_id + 1;

        a = 16'h0000; b = 16'hBEEF;   alu_control = 3'b011; #10;
        check_result(result, 16'hBEEF,   test_id); test_id = test_id + 1;

        $display("--- SLT ---");

        a = 16'd5;    b = 16'd10;     alu_control = 3'b111; #10;
        check_result(result, 16'd1,      test_id); test_id = test_id + 1;

        a = 16'd10;   b = 16'd10;     alu_control = 3'b111; #10;
        check_result(result, 16'd0,      test_id); test_id = test_id + 1;

        a = 16'd15;   b = 16'd3;      alu_control = 3'b111; #10;
        check_result(result, 16'd0,      test_id); test_id = test_id + 1;

        $display("--- Zero flag edge cases ---");

        a = 16'd9;    b = 16'd9;      alu_control = 3'b001; #10;
        check_zero(zero, 1'b1,           test_id); test_id = test_id + 1;

        a = 16'd10;   b = 16'd3;      alu_control = 3'b001; #10;
        check_zero(zero, 1'b0,           test_id); test_id = test_id + 1;

        a = 16'hFFFF; b = 16'd0;      alu_control = 3'b010; #10;
        check_zero(zero, 1'b1,           test_id); test_id = test_id + 1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
