// =============================================================================
// File        : IO_Bus_NIA.v
// Purpose     : Extended Memory-Mapped I/O Bus for StarCore1 + NIA Co-Processor
//
// Extends IO_Bus.v with NIA register block at 0xFF70–0xFF7F:
//   0xFF70  NIA_CTRL      W    Bit[0]=start MAC operation
//   0xFF71  NIA_OP_A      W    16-bit operand A (weight/input)
//   0xFF72  NIA_OP_B      W    16-bit operand B (activation/input)
//   0xFF73  NIA_STATUS    R    Bit[0]=busy, Bit[1]=result_ready, Bit[2]=overflow
//   0xFF74  NIA_RESULT_LO R    mac_result[15:0]
//   0xFF75  NIA_RESULT_MI R    mac_result[31:16]
//   0xFF76  NIA_RESULT_HI R    mac_result[39:32] (8-bit guard bits, zero-padded)
//   0xFF77  NIA_CLEAR     W    Write any value to clear/reset accumulator
// =============================================================================

`timescale 1ns / 1ps

module IO_Bus_NIA (
    input  wire        clk,
    input  wire        reset,         // active-low

    // --- Datapath memory bus ---
    input  wire [15:0] mem_addr,
    input  wire [15:0] mem_wdata,
    input  wire        mem_rd,
    input  wire        mem_wr,
    output reg  [15:0] mem_rdata,

    // --- DataMemory ---
    output wire [15:0] dm_addr,
    output wire [15:0] dm_wdata,
    output wire        dm_rd,
    output wire        dm_wr,
    input  wire [15:0] dm_rdata,

    // --- GPIO ---
    output reg  [15:0] gpio_out_a,
    output reg  [15:0] gpio_out_b,
    output reg  [15:0] gpio_dir,
    input  wire [15:0] gpio_in_a,
    input  wire [15:0] gpio_in_b,

    // --- UART ---
    output reg  [7:0]  uart_tx_data,
    output reg         uart_tx_valid,
    output reg  [1:0]  uart_ctrl,
    input  wire [7:0]  uart_rx_data,
    input  wire        uart_tx_ready,
    input  wire        uart_rx_valid,

    // --- Timer ---
    output reg  [2:0]  timer_ctrl,
    output reg  [15:0] timer_load,
    input  wire [15:0] timer_count,
    input  wire        timer_expired,

    // --- PWM ---
    output reg  [15:0] pwm_duty,
    output reg  [15:0] pwm_period,
    output reg         pwm_enable,

    // --- SPI ---
    output reg  [7:0]  spi_tx_data,
    output reg         spi_start,
    output reg         spi_cs,
    input  wire [7:0]  spi_rx_data,
    input  wire        spi_busy,
    input  wire        spi_done,

    // --- Interrupt output ---
    output wire        irq_out,

    // --- NIA Co-Processor Bus ---
    output reg  [15:0] nia_op_a,
    output reg  [15:0] nia_op_b,
    output reg         nia_start,
    output reg         nia_clear,
    input  wire [39:0] nia_result,
    input  wire        nia_busy,
    input  wire        nia_finish,
    input  wire        nia_overflow
);

    // =========================================================================
    // Region decode
    // =========================================================================
    wire io_sel  = (mem_addr[15:8] == 8'hFF);
    wire nia_sel = io_sel && (mem_addr[7:4] == 4'h7);  // 0xFF70-0xFF7F

    // DataMemory pass-through (not I/O space)
    assign dm_addr  = mem_addr;
    assign dm_wdata = mem_wdata;
    assign dm_rd    = mem_rd & ~io_sel;
    assign dm_wr    = mem_wr & ~io_sel;

    // =========================================================================
    // Internal registers
    // =========================================================================
    reg [15:0] scratch_0, scratch_1;
    reg [15:0] irq_mask;
    reg [15:0] irq_status;

    // =========================================================================
    // IRQ aggregation
    // =========================================================================
    wire irq_timer   = timer_expired & irq_mask[0];
    wire irq_uart_rx = uart_rx_valid & irq_mask[1];
    wire irq_spi     = spi_done      & irq_mask[2];
    assign irq_out = irq_timer | irq_uart_rx | irq_spi;

    // =========================================================================
    // Write logic
    // =========================================================================
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            gpio_out_a    <= 16'h0;
            gpio_out_b    <= 16'h0;
            gpio_dir      <= 16'h0;
            uart_tx_data  <= 8'h0;
            uart_tx_valid <= 1'b0;
            uart_ctrl     <= 2'b0;
            timer_ctrl    <= 3'b0;
            timer_load    <= 16'h0;
            pwm_duty      <= 16'h0;
            pwm_period    <= 16'hFFFF;
            pwm_enable    <= 1'b0;
            spi_tx_data   <= 8'h0;
            spi_start     <= 1'b0;
            spi_cs        <= 1'b0;
            irq_mask      <= 16'h0;
            irq_status    <= 16'h0;
            scratch_0     <= 16'h0;
            scratch_1     <= 16'h0;
            // NIA
            nia_op_a      <= 16'h0;
            nia_op_b      <= 16'h0;
            nia_start     <= 1'b0;
            nia_clear     <= 1'b0;
        end else begin
            uart_tx_valid <= 1'b0;
            spi_start     <= 1'b0;
            nia_start     <= 1'b0;
            nia_clear     <= 1'b0;

            if (mem_wr && io_sel) begin
                casez (mem_addr[7:0])
                    // ---- GPIO ----
                    8'h00: gpio_out_a    <= mem_wdata;
                    8'h01: gpio_out_b    <= mem_wdata;
                    8'h04: gpio_dir      <= mem_wdata;
                    // ---- UART ----
                    8'h10: begin
                               uart_tx_data  <= mem_wdata[7:0];
                               uart_tx_valid <= 1'b1;
                           end
                    8'h13: uart_ctrl     <= mem_wdata[1:0];
                    // ---- Timer ----
                    8'h20: timer_ctrl    <= mem_wdata[2:0];
                    8'h21: timer_load    <= mem_wdata;
                    // ---- PWM ----
                    8'h30: pwm_duty      <= mem_wdata;
                    8'h31: pwm_period    <= mem_wdata;
                    8'h32: pwm_enable    <= mem_wdata[0];
                    // ---- SPI ----
                    8'h40: spi_tx_data   <= mem_wdata[7:0];
                    8'h42: begin
                               spi_start <= mem_wdata[0];
                               spi_cs    <= mem_wdata[1];
                           end
                    // ---- IRQ ----
                    8'h50: irq_mask      <= mem_wdata;
                    8'h52: irq_status    <= irq_status & ~mem_wdata;
                    // ---- Scratch ----
                    8'h60: scratch_0     <= mem_wdata;
                    8'h61: scratch_1     <= mem_wdata;
                    // ---- NIA Co-Processor ----
                    8'h70: nia_start     <= mem_wdata[0];   // NIA_CTRL
                    8'h71: nia_op_a      <= mem_wdata;      // NIA_OP_A
                    8'h72: nia_op_b      <= mem_wdata;      // NIA_OP_B
                    8'h77: nia_clear     <= 1'b1;           // NIA_CLEAR
                    default: ;
                endcase
            end

            // Hardware IRQ latching
            if (timer_expired) irq_status[0] <= 1'b1;
            if (uart_rx_valid) irq_status[1] <= 1'b1;
            if (spi_done)      irq_status[2] <= 1'b1;
        end
    end

    // =========================================================================
    // Read logic
    // =========================================================================
    always @(*) begin
        mem_rdata = dm_rdata;  // default: memory data
        if (mem_rd && io_sel) begin
            casez (mem_addr[7:0])
                // GPIO
                8'h00: mem_rdata = gpio_out_a;
                8'h01: mem_rdata = gpio_out_b;
                8'h02: mem_rdata = gpio_in_a;
                8'h03: mem_rdata = gpio_in_b;
                8'h04: mem_rdata = gpio_dir;
                8'h05: mem_rdata = 16'h0003;
                // UART
                8'h11: mem_rdata = {8'h0, uart_rx_data};
                8'h12: mem_rdata = {14'h0, uart_rx_valid, uart_tx_ready};
                // Timer
                8'h22: mem_rdata = timer_count;
                8'h23: mem_rdata = {15'h0, timer_expired};
                // PWM
                8'h30: mem_rdata = pwm_duty;
                8'h31: mem_rdata = pwm_period;
                // SPI
                8'h41: mem_rdata = {8'h0, spi_rx_data};
                8'h43: mem_rdata = {14'h0, spi_done, spi_busy};
                // IRQ
                8'h50: mem_rdata = irq_mask;
                8'h51: mem_rdata = irq_status;
                // Scratch
                8'h60: mem_rdata = scratch_0;
                8'h61: mem_rdata = scratch_1;
                // NIA
                8'h73: mem_rdata = {13'h0, nia_overflow, nia_finish, nia_busy};
                8'h74: mem_rdata = nia_result[15:0];
                8'h75: mem_rdata = nia_result[31:16];
                8'h76: mem_rdata = {8'h0, nia_result[39:32]};
                default: mem_rdata = 16'hDEAD;
            endcase
        end
    end

endmodule
