// =============================================================================
// File        : tb_StarCore_NIA.v
// Purpose     : System-Level Testbench — StarCore-1 → NIA Co-Processor
//
// Simulates the StarCore-1 CPU issuing MMIO transactions to the NIA.
// Since we don't load a real instruction image, the testbench drives the
// memory bus directly (as if the CPU fetched and executed LD/ST instructions).
//
// Sequence simulated:
//   1. Write NIA_OP_A = weight
//   2. Write NIA_OP_B = activation
//   3. Write NIA_CTRL = 0x0001 (start)
//   4. Poll NIA_STATUS until result_ready (bit 1)
//   5. Read NIA_RESULT_LO / NIA_RESULT_MI
//   6. Check result and measure latency
//
// Two full-chip instances are created: one with P1 multiplier, one with P2,
// driven in lock-step for direct cycle-accurate comparison.
// =============================================================================

`timescale 1ns / 1ps

module tb_StarCore_NIA;

    localparam CLK_PERIOD = 10; // 10 ns

    // =========================================================================
    // Clock / Reset
    // =========================================================================
    reg clk, reset;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // Shared peripheral stubs (tied off)
    // =========================================================================
    reg  [15:0] gpio_in_a   = 16'hABCD; // sensor data A
    reg  [15:0] gpio_in_b   = 16'h1234; // sensor data B
    reg  [7:0]  uart_rx_data = 8'h00;
    reg         uart_tx_ready = 1'b1;
    reg         uart_rx_valid = 1'b0;
    reg  [15:0] timer_count   = 16'h0;
    reg         timer_expired = 1'b0;
    reg  [7:0]  spi_rx_data  = 8'h00;
    reg         spi_busy     = 1'b0;
    reg         spi_done     = 1'b0;

    // =========================================================================
    // System Instance A — NIA Paper 1
    // =========================================================================
    // We drive the CPU's memory bus directly through the IO_Bus_NIA port
    // by instantiating just the IO_Bus_NIA + NIA combination (StarCore
    // submodules not included to keep the testbench self-contained).

    reg  [15:0] bus_addr;
    reg  [15:0] bus_wdata;
    reg         bus_rd, bus_wr;
    wire [15:0] bus_rdata_p1, bus_rdata_p2;

    // Fake data memory (all zeros — not the focus here)
    wire [15:0] dm_addr_p1, dm_wdata_p1;
    wire        dm_rd_p1, dm_wr_p1;
    wire [15:0] dm_addr_p2, dm_wdata_p2;
    wire        dm_rd_p2, dm_wr_p2;
    wire [15:0] dm_rdata_p1 = 16'h0;
    wire [15:0] dm_rdata_p2 = 16'h0;

    // NIA signals Paper1
    wire [15:0] p1_nia_op_a, p1_nia_op_b;
    wire        p1_nia_start, p1_nia_clear;
    wire [39:0] p1_nia_result;
    wire        p1_nia_busy, p1_nia_finish, p1_nia_overflow;

    // NIA signals Paper2
    wire [15:0] p2_nia_op_a, p2_nia_op_b;
    wire        p2_nia_start, p2_nia_clear;
    wire [39:0] p2_nia_result;
    wire        p2_nia_busy, p2_nia_finish, p2_nia_overflow;

    // Unused IO ports (tied off)
    wire [15:0] gpio_out_a_p1, gpio_out_b_p1, gpio_dir_p1;
    wire [7:0]  uart_tx_p1; wire uart_txv_p1; wire [1:0] uctrl_p1;
    wire [2:0]  tctrl_p1; wire [15:0] tload_p1;
    wire [15:0] pwmd_p1, pwmp_p1; wire pwme_p1;
    wire [7:0]  spitx_p1; wire spist_p1, spics_p1;
    wire        irq_p1;

    wire [15:0] gpio_out_a_p2, gpio_out_b_p2, gpio_dir_p2;
    wire [7:0]  uart_tx_p2; wire uart_txv_p2; wire [1:0] uctrl_p2;
    wire [2:0]  tctrl_p2; wire [15:0] tload_p2;
    wire [15:0] pwmd_p2, pwmp_p2; wire pwme_p2;
    wire [7:0]  spitx_p2; wire spist_p2, spics_p2;
    wire        irq_p2;

    // --- IO_Bus_NIA + NIA Paper1 ---
    IO_Bus_NIA io_p1 (
        .clk(clk), .reset(reset),
        .mem_addr(bus_addr), .mem_wdata(bus_wdata),
        .mem_rd(bus_rd), .mem_wr(bus_wr), .mem_rdata(bus_rdata_p1),
        .dm_addr(dm_addr_p1), .dm_wdata(dm_wdata_p1),
        .dm_rd(dm_rd_p1), .dm_wr(dm_wr_p1), .dm_rdata(dm_rdata_p1),
        .gpio_out_a(gpio_out_a_p1), .gpio_out_b(gpio_out_b_p1), .gpio_dir(gpio_dir_p1),
        .gpio_in_a(gpio_in_a), .gpio_in_b(gpio_in_b),
        .uart_tx_data(uart_tx_p1), .uart_tx_valid(uart_txv_p1), .uart_ctrl(uctrl_p1),
        .uart_rx_data(uart_rx_data), .uart_tx_ready(uart_tx_ready), .uart_rx_valid(uart_rx_valid),
        .timer_ctrl(tctrl_p1), .timer_load(tload_p1),
        .timer_count(timer_count), .timer_expired(timer_expired),
        .pwm_duty(pwmd_p1), .pwm_period(pwmp_p1), .pwm_enable(pwme_p1),
        .spi_tx_data(spitx_p1), .spi_start(spist_p1), .spi_cs(spics_p1),
        .spi_rx_data(spi_rx_data), .spi_busy(spi_busy), .spi_done(spi_done),
        .irq_out(irq_p1),
        .nia_op_a(p1_nia_op_a), .nia_op_b(p1_nia_op_b),
        .nia_start(p1_nia_start), .nia_clear(p1_nia_clear),
        .nia_result(p1_nia_result),
        .nia_busy(p1_nia_busy), .nia_finish(p1_nia_finish), .nia_overflow(p1_nia_overflow)
    );

    NIA_Top_P1 nia_p1 (
        .clk(clk), .reset(reset),
        .start(p1_nia_start),
        .operand_A(p1_nia_op_a), .operand_B(p1_nia_op_b),
        .clear_acc(p1_nia_clear),
        .mac_result(p1_nia_result),
        .finish(p1_nia_finish), .overflow(p1_nia_overflow)
    );
    assign p1_nia_busy = ~p1_nia_finish;

    // --- IO_Bus_NIA + NIA Paper2 ---
    IO_Bus_NIA io_p2 (
        .clk(clk), .reset(reset),
        .mem_addr(bus_addr), .mem_wdata(bus_wdata),
        .mem_rd(bus_rd), .mem_wr(bus_wr), .mem_rdata(bus_rdata_p2),
        .dm_addr(dm_addr_p2), .dm_wdata(dm_wdata_p2),
        .dm_rd(dm_rd_p2), .dm_wr(dm_wr_p2), .dm_rdata(dm_rdata_p2),
        .gpio_out_a(gpio_out_a_p2), .gpio_out_b(gpio_out_b_p2), .gpio_dir(gpio_dir_p2),
        .gpio_in_a(gpio_in_a), .gpio_in_b(gpio_in_b),
        .uart_tx_data(uart_tx_p2), .uart_tx_valid(uart_txv_p2), .uart_ctrl(uctrl_p2),
        .uart_rx_data(uart_rx_data), .uart_tx_ready(uart_tx_ready), .uart_rx_valid(uart_rx_valid),
        .timer_ctrl(tctrl_p2), .timer_load(tload_p2),
        .timer_count(timer_count), .timer_expired(timer_expired),
        .pwm_duty(pwmd_p2), .pwm_period(pwmp_p2), .pwm_enable(pwme_p2),
        .spi_tx_data(spitx_p2), .spi_start(spist_p2), .spi_cs(spics_p2),
        .spi_rx_data(spi_rx_data), .spi_busy(spi_busy), .spi_done(spi_done),
        .irq_out(irq_p2),
        .nia_op_a(p2_nia_op_a), .nia_op_b(p2_nia_op_b),
        .nia_start(p2_nia_start), .nia_clear(p2_nia_clear),
        .nia_result(p2_nia_result),
        .nia_busy(p2_nia_busy), .nia_finish(p2_nia_finish), .nia_overflow(p2_nia_overflow)
    );

    NIA_Top_P2 nia_p2 (
        .clk(clk), .reset(reset),
        .start(p2_nia_start),
        .operand_A(p2_nia_op_a), .operand_B(p2_nia_op_b),
        .clear_acc(p2_nia_clear),
        .mac_result(p2_nia_result),
        .finish(p2_nia_finish), .overflow(p2_nia_overflow)
    );
    assign p2_nia_busy = ~p2_nia_finish;

    // =========================================================================
    // MMIO access tasks (emulates StarCore LD/ST instructions)
    // =========================================================================

    // Write to memory-mapped address (1 clock cycle like ST instruction)
    task mmio_write;
        input [15:0] addr;
        input [15:0] data;
        begin
            @(negedge clk);   // setup before rising edge
            bus_addr  = addr;
            bus_wdata = data;
            bus_wr    = 1'b1;
            bus_rd    = 1'b0;
            @(posedge clk);   // latch on rising edge
            @(negedge clk);
            bus_wr = 1'b0;
        end
    endtask

    // Read from memory-mapped address (1 cycle like LD instruction)
    task mmio_read;
        input  [15:0] addr;
        output [15:0] rdata_p1;
        output [15:0] rdata_p2;
        begin
            @(negedge clk);
            bus_addr = addr;
            bus_rd   = 1'b1;
            bus_wr   = 1'b0;
            @(posedge clk);
            rdata_p1 = bus_rdata_p1;
            rdata_p2 = bus_rdata_p2;
            @(negedge clk);
            bus_rd = 1'b0;
        end
    endtask

    // Poll NIA_STATUS until result_ready (bit 1), count CPU cycles
    task poll_until_ready;
        output integer cycles_p1;
        output integer cycles_p2;
        begin
            reg [15:0] stat_p1, stat_p2;
            reg        done_p1, done_p2;
            done_p1 = 0; done_p2 = 0;
            cycles_p1 = 0; cycles_p2 = 0;

            while (!done_p1 || !done_p2) begin
                mmio_read(16'hFF73, stat_p1, stat_p2);
                if (!done_p1) begin
                    cycles_p1 = cycles_p1 + 1;
                    if (stat_p1[1]) done_p1 = 1;
                end
                if (!done_p2) begin
                    cycles_p2 = cycles_p2 + 1;
                    if (stat_p2[1]) done_p2 = 1;
                end
            end
        end
    endtask

    // Full StarCore→NIA transaction: write operands, start, poll, read result
    task starcore_mac;
        input  [15:0] weight;
        input  [15:0] activation;
        output [15:0] result_lo_p1, result_lo_p2;
        output [15:0] result_mi_p1, result_mi_p2;
        output integer lat_p1, lat_p2;
        begin
            reg [15:0] dummy_p1, dummy_p2;

            // --- StarCore ST instructions to NIA registers ---
            mmio_write(16'hFF71, weight);      // ST R0, NIA_OP_A
            mmio_write(16'hFF72, activation);  // ST R1, NIA_OP_B
            mmio_write(16'hFF70, 16'h0001);    // ST R2, NIA_CTRL  (start=1)

            // --- StarCore poll loop: LD R3, NIA_STATUS; BNE poll ---
            poll_until_ready(lat_p1, lat_p2);

            // --- StarCore LD instructions to read result ---
            mmio_read(16'hFF74, result_lo_p1, result_lo_p2);  // LD R4, NIA_RESULT_LO
            mmio_read(16'hFF75, result_mi_p1, result_mi_p2);  // LD R5, NIA_RESULT_MI
        end
    endtask

    // =========================================================================
    // Main test
    // =========================================================================
    integer lat_p1, lat_p2;
    reg [15:0] rlo_p1, rlo_p2, rmi_p1, rmi_p2;
    reg [31:0] full_p1, full_p2;
    integer i;

    // Satellite sensor pattern recognition vectors
    // 8-tap FIR filter: output = sum(w[i] * x[i]) for i=0..7
    reg [15:0] weights     [0:7];
    reg [15:0] sensor_data [0:7];
    reg [63:0] ref_fir;

    integer total_lat_p1, total_lat_p2;
    integer t_start_p1, t_start_p2;

    initial begin
        // FIR filter weights (fixed-point Q8.8 scale, representing small fractions)
        weights[0] = 16'd10; weights[1] = 16'd25;
        weights[2] = 16'd40; weights[3] = 16'd60;
        weights[4] = 16'd60; weights[5] = 16'd40;
        weights[6] = 16'd25; weights[7] = 16'd10;

        // Satellite sensor readings (12-bit ADC range mapped to 16-bit)
        sensor_data[0] = 16'd512;  sensor_data[1] = 16'd768;
        sensor_data[2] = 16'd1024; sensor_data[3] = 16'd896;
        sensor_data[4] = 16'd640;  sensor_data[5] = 16'd384;
        sensor_data[6] = 16'd256;  sensor_data[7] = 16'd128;

        // Reference (computed in 64-bit integer)
        ref_fir = 64'd0;
        ref_fir = ref_fir + 10*512 + 25*768 + 40*1024 + 60*896;
        ref_fir = ref_fir + 60*640 + 40*384 + 25*256  + 10*128;

        $display("================================================================");
        $display(" SYSTEM TESTBENCH: StarCore-1 -> NIA Co-Processor");
        $display(" Satellite Sensor Pattern Recognition — 8-tap FIR Filter");
        $display(" Clock: %0d MHz", 1000/CLK_PERIOD);
        $display("================================================================");

        clk = 0;
        bus_addr = 0; bus_wdata = 0; bus_rd = 0; bus_wr = 0;
        reset = 0;
        repeat(4) @(posedge clk);
        reset = 1;
        repeat(2) @(posedge clk);

        // --- Clear NIA accumulators ---
        mmio_write(16'hFF77, 16'h0001);  // NIA_CLEAR
        repeat(2) @(posedge clk);

        $display("\n--- StarCore executing 8-tap FIR (8 MAC operations) ---");
        $display("%-4s %-8s %-8s %-14s %-14s %-8s %-8s",
                 "Tap","Weight","Sensor","P1 acc[31:0]","P2 acc[31:0]","P1 lat","P2 lat");
        $display("%-4s %-8s %-8s %-14s %-14s %-8s %-8s",
                 "---","--------","--------","--------------","--------------","--------","--------");

        total_lat_p1 = 0;
        total_lat_p2 = 0;
        t_start_p1 = $time;
        t_start_p2 = $time;

        for (i = 0; i < 8; i = i + 1) begin
            starcore_mac(weights[i], sensor_data[i],
                         rlo_p1, rlo_p2, rmi_p1, rmi_p2,
                         lat_p1, lat_p2);

            full_p1 = {rmi_p1, rlo_p1};
            full_p2 = {rmi_p2, rlo_p2};
            total_lat_p1 = total_lat_p1 + lat_p1;
            total_lat_p2 = total_lat_p2 + lat_p2;

            $display("%-4d %-8d %-8d 0x%08X     0x%08X     %-8d %-8d",
                i, weights[i], sensor_data[i],
                {rmi_p1, rlo_p1}, {rmi_p2, rlo_p2},
                lat_p1, lat_p2);

            @(posedge clk);
        end

        $display("");
        $display("Reference FIR output : %0d (0x%010X)", ref_fir, ref_fir);
        $display("P1 final accumulator : 0x%04X_%04X", rmi_p1, rlo_p1);
        $display("P2 final accumulator : 0x%04X_%04X", rmi_p2, rlo_p2);
        $display("P1 correct: %s", ({rmi_p1,rlo_p1} == ref_fir[31:0]) ? "YES" : "NO ***");
        $display("P2 correct: %s", ({rmi_p2,rlo_p2} == ref_fir[31:0]) ? "YES" : "NO ***");

        $display("\n--- Timing Report ---");
        $display("Total StarCore poll cycles (8 MACs):");
        $display("  P1 (Compressor):  %0d CPU cycles, %0d ns",
            total_lat_p1, total_lat_p1 * CLK_PERIOD);
        $display("  P2 (CarrySel):    %0d CPU cycles, %0d ns",
            total_lat_p2, total_lat_p2 * CLK_PERIOD);
        $display("  Avg per MAC — P1: %.1f cycles | P2: %.1f cycles",
            total_lat_p1/8.0, total_lat_p2/8.0);
        $display("  Wall time P1: %0d ns | P2: %0d ns",
            $time - t_start_p1, $time - t_start_p2);

        $display("\n--- I/O Bus Verification ---");
        $display("GPIO_IN_A (sensor bus): 0x%04X", gpio_in_a);
        // Read it back via MMIO
        begin
            reg [15:0] g_p1, g_p2;
            mmio_read(16'hFF02, g_p1, g_p2);
            $display("MMIO read 0xFF02 (GPIO_IN_A): P1=0x%04X P2=0x%04X  %s",
                g_p1, g_p2,
                (g_p1 == gpio_in_a && g_p2 == gpio_in_a) ? "PASS" : "FAIL ***");
        end

        $display("\n================================================================");
        $display(" SIMULATION COMPLETE");
        $display("================================================================");

        #100;
        $finish;
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("tb_StarCore_NIA.vcd");
        $dumpvars(0, tb_StarCore_NIA);
    end

endmodule
