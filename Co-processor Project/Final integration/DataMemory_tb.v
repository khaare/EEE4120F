`timescale 1ns / 1ps
`include "Parameter.v"

module DataMemory_tb;

    reg         clk;
    reg  [15:0] mem_access_addr;
    reg  [15:0] mem_write_data;
    reg         mem_write_en;
    reg         mem_read;
    wire [15:0] mem_read_data;

    DataMemory uut (
        .clk             (clk),
        .MemWr  (mem_write_en),
        .MemRd   (mem_read),
        .memAddress (mem_access_addr),
        .writeData    (mem_write_data),
        .readData       (mem_read_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waves/dm_tb.vcd");
        $dumpvars(0, DataMemory_tb);
    end

    integer fail_count;
    integer test_id;
    integer i;

    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got=0x%h expected=0x%h", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: value=0x%h", id, got);
        end
    endtask

    initial begin
        fail_count      = 0;
        test_id         = 1;
        mem_write_en    = 1'b0;
        mem_read        = 1'b0;
        mem_access_addr = 16'd0;
        mem_write_data  = 16'd0;

        $display("=== DataMemory Testbench ===");

        @(posedge clk); #1;

        $display("--- Group 1: Verify $readmemb initialisation ---");

        mem_read = 1'b1;
        mem_access_addr = 16'd0; #5; check16(mem_read_data, 16'h0001, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd1; #5; check16(mem_read_data, 16'h0002, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd2; #5; check16(mem_read_data, 16'h0003, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd3; #5; check16(mem_read_data, 16'h0004, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd4; #5; check16(mem_read_data, 16'h0005, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd5; #5; check16(mem_read_data, 16'h0006, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd6; #5; check16(mem_read_data, 16'h0007, test_id); test_id = test_id + 1;
        mem_access_addr = 16'd7; #5; check16(mem_read_data, 16'h0008, test_id); test_id = test_id + 1;
        mem_read = 1'b0;

        $display("--- Group 2: Write then read all 8 locations ---");

        for (i = 0; i < 8; i = i + 1) begin
            mem_write_en    = 1'b1;
            mem_access_addr = i;
            mem_write_data  = 16'hA000 + i;
            @(posedge clk); #1;
            mem_write_en    = 1'b0;
            mem_read        = 1'b1;
            mem_access_addr = i; #5;
            check16(mem_read_data, 16'hA000 + i, test_id); test_id = test_id + 1;
            mem_read = 1'b0;
        end

        $display("--- Group 3: mem_read disabled -> output must be 0 ---");

        mem_read = 1'b0;
        mem_access_addr = 16'd0; #5;
        check16(mem_read_data, 16'd0, test_id); test_id = test_id + 1;

        mem_access_addr = 16'd4; #5;
        check16(mem_read_data, 16'd0, test_id); test_id = test_id + 1;

        $display("--- Group 4: Write followed by immediate read ---");

        mem_write_en    = 1'b1;
        mem_access_addr = 16'd3;
        mem_write_data  = 16'hBEEF;
        @(posedge clk); #1;
        mem_write_en    = 1'b0;
        mem_read        = 1'b1;
        mem_access_addr = 16'd3; #5;
        check16(mem_read_data, 16'hBEEF, test_id); test_id = test_id + 1;
        mem_read = 1'b0;

        $display("--- Group 5: mem_write_en=0 must not overwrite memory ---");

        mem_write_en    = 1'b0;
        mem_access_addr = 16'd3;
        mem_write_data  = 16'hDEAD;
        @(posedge clk); #1;
        mem_read        = 1'b1;
        mem_access_addr = 16'd3; #5;
        check16(mem_read_data, 16'hBEEF, test_id); test_id = test_id + 1;
        mem_read = 1'b0;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule