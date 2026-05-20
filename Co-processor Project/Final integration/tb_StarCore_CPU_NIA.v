// =============================================================================
// File        : tb_StarCore_CPU_NIA.v
// Purpose     : Full CPU Pipeline Testbench — StarCore-1 + NIA Co-Processor
//
// Tests the COMPLETE pipeline: CPU fetches real instructions from instruction
// memory, decodes and executes them through the Datapath + ControlUnit, issues
// MMIO writes/reads through IO_Bus_NIA, and the NIA performs a MAC operation.
//
// Program being executed (nia_mac_test.prog):
//   [0]  LD  r1, 0(r0)      ; r1 = mem[0] = 3  (weight)
//   [1]  LD  r2, 1(r0)      ; r2 = mem[1] = 5  (activation)
//   [2]  LD  r5, 2(r0)      ; r5 = mem[2] = 0xFF70 (NIA MMIO base)
//   [3]  LD  r3, 3(r0)      ; r3 = mem[3] = 1  (start constant)
//   [4]  LD  r4, 4(r0)      ; r4 = mem[4] = 2  (result_ready mask)
//   [5]  ST  r1, 1(r5)      ; NIA_OP_A = 3
//   [6]  ST  r2, 2(r5)      ; NIA_OP_B = 5
//   [7]  ST  r3, 0(r5)      ; NIA_CTRL = 1 (start)
//   [8]  LD  r6, 3(r5)      ; r6 = NIA_STATUS
//   [9]  AND r6, r6, r4     ; r6 = r6 & 2 (isolate result_ready bit)
//   [10] BEQ r6, r0, -3     ; if not ready, loop back to [8]
//   [11] LD  r7, 4(r5)      ; r7 = NIA_RESULT_LO  (bits [15:0])
//   [12] LD  r6, 5(r5)      ; r6 = NIA_RESULT_MI  (bits [31:16])
//   [13] JMP 13              ; halt (infinite loop)
//
// Expected result: 3 * 5 = 15 → NIA_RESULT_LO = 0x000F, NIA_RESULT_MI = 0x0000
//
// Data memory layout (nia_mac_test.data):
//   mem[0] = 0x0003;  // 10
//   mem[1] = 0x0005;  // 5
//   mem[2] = 0xFF70  NIA MMIO base address
//   mem[3] = 0x0001  constant 1
//   mem[4] = 0x0002  result_ready mask
// =============================================================================

`timescale 1ns / 1ps

module tb_StarCore_CPU_NIA;

    // =========================================================================
    // Clock and reset
    // =========================================================================
    reg clk, reset;
    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // Peripheral stubs (tied off — not under test)
    // =========================================================================
    reg  [15:0] gpio_in_a    = 16'h0000;
    reg  [15:0] gpio_in_b    = 16'h0000;
    reg  [7:0]  uart_rx_data = 8'h00;
    reg         uart_tx_ready = 1'b1;
    reg         uart_rx_valid = 1'b0;
    reg  [15:0] timer_count   = 16'h0;
    reg         timer_expired = 1'b0;
    reg  [7:0]  spi_rx_data  = 8'h00;
    reg         spi_busy     = 1'b0;
    reg         spi_done     = 1'b0;

    // =========================================================================
    // Observable outputs from StarCore1_NIA
    // =========================================================================
    wire [15:0] gpio_out_a, gpio_out_b, gpio_dir;
    wire [7:0]  uart_tx_data;
    wire        uart_tx_valid;
    wire [1:0]  uart_ctrl;
    wire [2:0]  timer_ctrl;
    wire [15:0] timer_load;
    wire [15:0] pwm_duty, pwm_period;
    wire        pwm_enable;
    wire [7:0]  spi_tx_data;
    wire        spi_start, spi_cs;
    wire        irq_out;
    wire [39:0] nia_mac_result;
    wire        nia_finish, nia_overflow;

    // =========================================================================
    // DUT — StarCore-1 with NIA Paper 1 (4:2 Compressor)
    // =========================================================================
    StarCore1_NIA #(.NIA_IMPL(1)) dut (
        .clk           (clk),
        .reset         (reset),
        .gpio_out_a    (gpio_out_a),
        .gpio_out_b    (gpio_out_b),
        .gpio_dir      (gpio_dir),
        .gpio_in_a     (gpio_in_a),
        .gpio_in_b     (gpio_in_b),
        .uart_tx_data  (uart_tx_data),
        .uart_tx_valid (uart_tx_valid),
        .uart_ctrl     (uart_ctrl),
        .uart_rx_data  (uart_rx_data),
        .uart_tx_ready (uart_tx_ready),
        .uart_rx_valid (uart_rx_valid),
        .timer_ctrl    (timer_ctrl),
        .timer_load    (timer_load),
        .timer_count   (timer_count),
        .timer_expired (timer_expired),
        .pwm_duty      (pwm_duty),
        .pwm_period    (pwm_period),
        .pwm_enable    (pwm_enable),
        .spi_tx_data   (spi_tx_data),
        .spi_start     (spi_start),
        .spi_cs        (spi_cs),
        .spi_rx_data   (spi_rx_data),
        .spi_busy      (spi_busy),
        .spi_done      (spi_done),
        .irq_out       (irq_out),
        .nia_mac_result(nia_mac_result),
        .nia_finish    (nia_finish),
        .nia_overflow  (nia_overflow)
    );

    // =========================================================================
    // Simulation
    // =========================================================================
    integer cycle_count;
    integer fail_count;

    initial begin
        $dumpfile("tb_StarCore_CPU_NIA.vcd");
        $dumpvars(0, tb_StarCore_CPU_NIA);
    end

    initial begin
        clk         = 0;
        reset       = 0;
        cycle_count = 0;
        fail_count  = 0;

        $display("================================================================");
        $display(" FULL CPU PIPELINE TESTBENCH — StarCore-1 + NIA (Paper 1)");
        $display(" Test: CPU executes LD/ST/AND/BEQ/JMP to perform 3 x 5 = 15");
        $display("================================================================");

        // Hold reset for 4 cycles
        repeat(4) @(posedge clk);
        reset = 1;
        $display("[%0t] Reset released — CPU pipeline starting", $time);

        // =====================================================================
        // Wait for the CPU to execute the program.
        // The program does:
        //   5 x LD  (5 cycles)     — load operands + constants
        //   2 x ST  (2 cycles)     — write NIA_OP_A / NIA_OP_B
        //   1 x ST  (1 cycle)      — write NIA_CTRL (start)
        //   N x LD+AND+BEQ loop   — poll NIA_STATUS (~22 cycles for NIA to finish)
        //   2 x LD  (2 cycles)     — read result
        //   1 x JMP                — halt
        // Budget: 200 cycles is generous
        // =====================================================================
        repeat(200) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        $display("[%0t] Simulation complete after %0d cycles post-reset", $time, cycle_count);
        $display("");

        // =====================================================================
        // CHECK 1: NIA result correctness
        // 3 * 5 = 15 = 0x0000_0000_000F
        // =====================================================================
        $display("--- CHECK 1: NIA MAC result (3 x 5 = 15) ---");
        if (nia_mac_result === 40'h000000000F) begin
            $display("PASS: nia_mac_result = 0x%010X  (correct: 15)", nia_mac_result);
        end else begin
            $display("FAIL: nia_mac_result = 0x%010X  (expected 0x000000000F)", nia_mac_result);
            fail_count = fail_count + 1;
        end

        // =====================================================================
        // CHECK 2: No overflow on a simple 3*5
        // =====================================================================
        $display("--- CHECK 2: Overflow flag ---");
        if (nia_overflow === 1'b0) begin
            $display("PASS: nia_overflow = 0  (no overflow, correct)");
        end else begin
            $display("FAIL: nia_overflow = 1  (unexpected overflow)");
            fail_count = fail_count + 1;
        end

        // =====================================================================
        // CHECK 3: NIA finished (not stuck in FSM)
        // =====================================================================
        $display("--- CHECK 3: NIA finish signal ---");
        if (nia_finish === 1'b1) begin
            $display("PASS: nia_finish = 1  (FSM returned to IDLE/DONE)");
        end else begin
            $display("FAIL: nia_finish = 0  (NIA FSM may be stuck)");
            fail_count = fail_count + 1;
        end

        // =====================================================================
        // SUMMARY
        // =====================================================================
        $display("");
        $display("================================================================");
        if (fail_count == 0)
            $display(" ALL CHECKS PASSED — Full CPU pipeline + NIA verified");
        else
            $display(" %0d CHECK(S) FAILED", fail_count);
        $display("================================================================");

        #50;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #500000;
        $display("TIMEOUT — simulation exceeded 500us");
        $finish;
    end

    // Cycle counter for waveform annotation
    always @(posedge clk) begin
        if (reset)
            $display("[cycle %0d] PC=%0h  NIA_finish=%b  NIA_result=%0d",
                cycle_count, dut.DU.mem_addr, nia_finish, nia_mac_result);
    end

endmodule
