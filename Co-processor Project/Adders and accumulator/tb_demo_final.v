///////////////////////////////////////////////////////////////////////////////
// FINAL DEMONSTRATION: Multiplier -> Add-Accumulator -> Result
// 
// This uses the EXACT SAME timing that passed all tests in tb_add_accumulator.v
// It demonstrates the complete multiply-accumulate operation:
//   result = result + (a x b)
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_demo_final();

    parameter CLK_PERIOD = 10;
    
    reg         clk;
    reg         rst_n;
    reg         enable;
    reg  [31:0] product_in;
    reg         clear_acc;
    reg         saturate_en;
    wire [39:0] acc_out;
    wire        overflow;
    
    integer i;
    integer errors;
    
    // Helper functions (IDENTICAL to working testbench)
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
    
    // Add value task (IDENTICAL to working testbench)
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
    
    // Clear accumulator task (IDENTICAL to working testbench)
    task clear_accumulator;
        begin
            clear_acc = 1;
            @(posedge clk);
            clear_acc = 0;
            @(negedge clk);
        end
    endtask
    
    // Verify accumulator task
    task verify_acc;
        input real expected;
        input [80:0] test_name;
        begin
            $display("    Expected: %.1f", expected);
            $display("    Actual:   %.1f", to_real(acc_out));
            if (to_real(acc_out) > expected - 0.01 && to_real(acc_out) < expected + 0.01) begin
                $display("    RESULT: %s PASSED!", test_name);
            end else begin
                $display("    RESULT: %s FAILED!", test_name);
                errors = errors + 1;
            end
            $display("");
        end
    endtask
    
    // Instantiate your add-accumulator
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Main demonstration
    initial begin
        errors = 0;
        
        $display("");
        $display("====================================================================");
        $display("  MULTIPLY-ACCUMULATE (MAC) OPERATION DEMONSTRATION");
        $display("====================================================================");
        $display("");
        $display("  This demonstrates: result = result + (a x b)");
        $display("  Using the SAME timing that passed all previous tests.");
        $display("");
        $display("====================================================================");
        $display("");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        product_in = 32'b0;
        clear_acc = 0;
        saturate_en = 1;
        
        // Release reset
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        $display("  RESET COMPLETE - Accumulator = %.1f", to_real(acc_out));
        $display("");
        
        // ============================================================
        // DEMO 1: Basic addition (2 + 3 = 5)
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 1: Basic Addition (2.0 + 3.0 = 5.0)");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        $display("  After clear: accumulator = %.1f", to_real(acc_out));
        
        add_value(2.0);
        $display("  After adding 2.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(3.0);
        $display("  After adding 3.0: accumulator = %.1f", to_real(acc_out));
        
        verify_acc(5.0, "2.0 + 3.0 = 5.0");
        
        // ============================================================
        // DEMO 2: Multiple additions (1+2+3+4 = 10)
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 2: Multiple Additions (1+2+3+4 = 10)");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        add_value(1.0);
        $display("  After adding 1.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(2.0);
        $display("  After adding 2.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(3.0);
        $display("  After adding 3.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(4.0);
        $display("  After adding 4.0: accumulator = %.1f", to_real(acc_out));
        
        verify_acc(10.0, "1+2+3+4 = 10.0");
        
        // ============================================================
        // DEMO 3: Clear and start over
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 3: Clear and Start New Sequence");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        $display("  After clear: accumulator = %.1f", to_real(acc_out));
        
        add_value(10.0);
        $display("  After adding 10.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(20.0);
        $display("  After adding 20.0: accumulator = %.1f", to_real(acc_out));
        
        verify_acc(30.0, "10 + 20 = 30");
        
        // ============================================================
        // DEMO 4: Negative numbers (-2 + -3 = -5)
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 4: Negative Numbers (-2.0 + -3.0 = -5.0)");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        add_value(-2.0);
        $display("  After adding -2.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(-3.0);
        $display("  After adding -3.0: accumulator = %.1f", to_real(acc_out));
        
        verify_acc(-5.0, "-2.0 + -3.0 = -5.0");
        
        // ============================================================
        // DEMO 5: Mixed signs (5 + -3 = 2)
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 5: Mixed Signs (5.0 + -3.0 = 2.0)");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        add_value(5.0);
        $display("  After adding 5.0: accumulator = %.1f", to_real(acc_out));
        
        add_value(-3.0);
        $display("  After adding -3.0: accumulator = %.1f", to_real(acc_out));
        
        verify_acc(2.0, "5.0 + -3.0 = 2.0");
        
        // ============================================================
        // DEMO 6: Simulating multiplier outputs (5x3=15, 2x4=8, 6x7=42)
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 6: Simulating Multiplier Outputs (16-bit MAC)");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        $display("  Starting fresh accumulator...");
        $display("");
        
        // Product 1: 5 x 3 = 15
        product_in = to_q16_16(15.0);
        enable = 1;
        @(posedge clk);
        enable = 0;
        @(negedge clk);
        $display("  Product 1: 5 x 3 = 15.0");
        $display("    Accumulator now: %.1f", to_real(acc_out));
        $display("");
        
        // Product 2: 2 x 4 = 8
        product_in = to_q16_16(8.0);
        enable = 1;
        @(posedge clk);
        enable = 0;
        @(negedge clk);
        $display("  Product 2: 2 x 4 = 8.0");
        $display("    Accumulator now: %.1f (should be 23.0)", to_real(acc_out));
        $display("");
        
        // Product 3: 6 x 7 = 42
        product_in = to_q16_16(42.0);
        enable = 1;
        @(posedge clk);
        enable = 0;
        @(negedge clk);
        $display("  Product 3: 6 x 7 = 42.0");
        $display("    Accumulator now: %.1f (should be 65.0)", to_real(acc_out));
        $display("");
        
        verify_acc(65.0, "15 + 8 + 42 = 65");
        
        // ============================================================
        // DEMO 7: Running total after each multiply (squares)
        // ============================================================
        $display("====================================================================");
        $display("  DEMO 7: Running Total After Each Multiply");
        $display("  Calculating: 1^2 + 2^2 + 3^2 + ... + 8^2 = 204");
        $display("====================================================================");
        $display("");
        
        clear_accumulator();
        
        for (i = 1; i <= 8; i = i + 1) begin
            product_in = to_q16_16($itor(i * i));
            enable = 1;
            @(posedge clk);
            enable = 0;
            @(negedge clk);
            $display("  After adding %0d^2 = %0d: running total = %.1f", 
                     i, i*i, to_real(acc_out));
        end
        
        verify_acc(204.0, "Squares sum = 204");
        
        // ============================================================
        // FINAL SUMMARY
        // ============================================================
        $display("====================================================================");
        $display("                     DEMONSTRATION COMPLETE");
        $display("====================================================================");
        $display("");
        
        if (errors == 0) begin
            $display("  [SUCCESS] ALL TESTS PASSED!");
            $display("");
            $display("  The add-accumulator successfully:");
            $display("  [OK] Takes multiplier output as input");
            $display("  [OK] Adds each product to the running total");
            $display("  [OK] Stores the result back in the accumulator");
            $display("  [OK] Performs multiple MAC operations in sequence");
            $display("  [OK] Maintains correct running total after each step");
            $display("  [OK] Handles positive and negative numbers");
            $display("  [OK] Clears accumulator when commanded");
            $display("");
            $display("  Ready for integration with:");
            $display("    - Person 2's 16-bit Multiplier");
            $display("    - Person 1's Top-Level Controller");
        end else begin
            $display("  [ERROR] %0d tests failed!", errors);
        end
        
        $display("");
        $display("====================================================================");
        $display("            ADD-ACCUMULATOR READY FOR INTEGRATION");
        $display("====================================================================");
        $display("");
        
        $finish;
    end
    
endmodule