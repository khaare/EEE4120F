///////////////////////////////////////////////////////////////////////////////
// Testbench for 16-bit MAC Add-Accumulator
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_add_accumulator();

    parameter CLK_PERIOD = 10;
    
    reg         clk;
    reg         rst_n;
    reg         enable;
    reg  [31:0] product_in;
    reg         clear_acc;
    reg         saturate_en;
    wire [39:0] acc_out;
    wire        overflow;
    
    integer passed, failed;
    integer i;
    integer test_num;
    
    function [31:0] to_q16_16;
        input real x;
        begin
            to_q16_16 = $rtoi(x * 65536.0);
        end
    endfunction
    
    function real to_real;
        input [39:0] x;
        begin
            to_real = $itor($signed(x)) / 65536.0;
        end
    endfunction
    
    add_accumulator uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .enable      (enable),
        .product_in  (product_in),
        .clear_acc   (clear_acc),
        .saturate_en (saturate_en),
        .acc_out     (acc_out),
        .overflow    (overflow)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    task add_value;
        input real value;
        begin
            product_in = to_q16_16(value);
            enable = 1;
            @(posedge clk);
            enable = 0;
            @(negedge clk);
        end
    endtask
    
    task clear_accumulator;
        begin
            clear_acc = 1;
            @(posedge clk);
            clear_acc = 0;
            @(negedge clk);
        end
    endtask
    
    initial begin
        passed = 0;
        failed = 0;
        test_num = 0;
        
        $display("\n");
        $display("============================================================");
        $display("       16-bit MAC Add-Accumulator Testbench");
        $display("============================================================");
        $display("\n");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        product_in = 32'b0;
        clear_acc = 0;
        saturate_en = 1;
        
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        $display("  Reset complete - accumulator = %f\n", to_real(acc_out));
        
        // TEST 1: Basic addition
        test_num = test_num + 1;
        $display("--- TEST %0d: 2.0 + 3.0 = 5.0 ---", test_num);
        clear_accumulator();
        add_value(2.0);
        add_value(3.0);
        $display("    Expected: 5.0");
        $display("    Actual:   %f", to_real(acc_out));
        if (to_real(acc_out) > 4.999 && to_real(acc_out) < 5.001) begin
            $display("    Result: PASS ✓\n");
            passed = passed + 1;
        end else begin
            $display("    Result: FAIL ✗\n");
            failed = failed + 1;
        end
        
        // TEST 2: Multiple additions
        test_num = test_num + 1;
        $display("--- TEST %0d: 1+2+3+4+5+6+7+8 = 36 ---", test_num);
        clear_accumulator();
        for (i = 1; i <= 8; i = i + 1) begin
            add_value($itor(i));
        end
        $display("    Expected: 36.0");
        $display("    Actual:   %f", to_real(acc_out));
        if (to_real(acc_out) > 35.999 && to_real(acc_out) < 36.001) begin
            $display("    Result: PASS ✓\n");
            passed = passed + 1;
        end else begin
            $display("    Result: FAIL ✗\n");
            failed = failed + 1;
        end
        
        // TEST 3: Negative numbers
        test_num = test_num + 1;
        $display("--- TEST %0d: -2.0 + -3.0 = -5.0 ---", test_num);
        clear_accumulator();
        add_value(-2.0);
        add_value(-3.0);
        $display("    Expected: -5.0");
        $display("    Actual:   %f", to_real(acc_out));
        if (to_real(acc_out) > -5.001 && to_real(acc_out) < -4.999) begin
            $display("    Result: PASS ✓\n");
            passed = passed + 1;
        end else begin
            $display("    Result: FAIL ✗\n");
            failed = failed + 1;
        end
        
        // TEST 4: Mixed signs
        test_num = test_num + 1;
        $display("--- TEST %0d: 5.0 + -3.0 = 2.0 ---", test_num);
        clear_accumulator();
        add_value(5.0);
        add_value(-3.0);
        $display("    Expected: 2.0");
        $display("    Actual:   %f", to_real(acc_out));
        if (to_real(acc_out) > 1.999 && to_real(acc_out) < 2.001) begin
            $display("    Result: PASS ✓\n");
            passed = passed + 1;
        end else begin
            $display("    Result: FAIL ✗\n");
            failed = failed + 1;
        end
        
        // TEST 5: Clear mid-sequence
        test_num = test_num + 1;
        $display("--- TEST %0d: Clear Mid-Sequence ---", test_num);
        clear_accumulator();
        add_value(10.0);
        add_value(20.0);
        $display("    [CLEARING ACCUMULATOR]");
        clear_accumulator();
        add_value(5.0);
        add_value(3.0);
        $display("    Expected: 8.0");
        $display("    Actual:   %f", to_real(acc_out));
        if (to_real(acc_out) > 7.999 && to_real(acc_out) < 8.001) begin
            $display("    Result: PASS ✓\n");
            passed = passed + 1;
        end else begin
            $display("    Result: FAIL ✗\n");
            failed = failed + 1;
        end
        
        // Summary
        $display("============================================================");
        $display("                     TEST SUMMARY");
        $display("============================================================");
        $display("  Passed: %0d", passed);
        $display("  Failed: %0d", failed);
        $display("============================================================");
        
        if (failed == 0) begin
            $display("           ALL TESTS PASSED! ✓✓✓");
            $display("    Add-Accumulator is ready for integration!");
        end else begin
            $display("           SOME TESTS FAILED! ✗✗✗");
        end
        $display("============================================================\n");
        
        $finish;
    end
endmodule