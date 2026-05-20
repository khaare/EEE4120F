// =============================================================================
// File        : StarCore1_NIA.v
// Purpose     : StarCore-1 Top Level with Memory-Mapped I/O + NIA Co-Processor
//
// The NIA is accessible via:
//   (a) Memory-mapped registers at 0xFF70-0xFF77 (LD/ST instructions)
//   (b) Direct co-processor bus via opcode 1010 (future ISA extension)
//
// NIA variant selected by parameter:
//   NIA_IMPL = 1 → Paper 1 (4:2 Compressor multiplier)
//   NIA_IMPL = 0 → Paper 2 (Carry-Select multiplier)
// =============================================================================

`timescale 1ns / 1ps

module StarCore1_NIA #(
    parameter NIA_IMPL = 1   // 1=Paper1, 0=Paper2
)(
    input  wire        clk,
    input  wire        reset,          // active-low system reset

    // --- GPIO ---
    output wire [15:0] gpio_out_a,
    output wire [15:0] gpio_out_b,
    output wire [15:0] gpio_dir,
    input  wire [15:0] gpio_in_a,
    input  wire [15:0] gpio_in_b,

    // --- UART ---
    output wire [7:0]  uart_tx_data,
    output wire        uart_tx_valid,
    output wire [1:0]  uart_ctrl,
    input  wire [7:0]  uart_rx_data,
    input  wire        uart_tx_ready,
    input  wire        uart_rx_valid,

    // --- Timer ---
    output wire [2:0]  timer_ctrl,
    output wire [15:0] timer_load,
    input  wire [15:0] timer_count,
    input  wire        timer_expired,

    // --- PWM ---
    output wire [15:0] pwm_duty,
    output wire [15:0] pwm_period,
    output wire        pwm_enable,

    // --- SPI ---
    output wire [7:0]  spi_tx_data,
    output wire        spi_start,
    output wire        spi_cs,
    input  wire [7:0]  spi_rx_data,
    input  wire        spi_busy,
    input  wire        spi_done,

    // --- Interrupt ---
    output wire        irq_out,

    // --- NIA status (observable outputs) ---
    output wire [39:0] nia_mac_result,
    output wire        nia_finish,
    output wire        nia_overflow
);

    // =========================================================================
    // Control signals
    // =========================================================================
    wire        jump, branch;
    wire        mem_read, mem_write;
    wire        alu_src, reg_dst, mem_to_reg, reg_write;
    wire [1:0]  alu_op;
    wire [3:0]  opcode;

    // =========================================================================
    // Memory bus
    // =========================================================================
    wire [15:0] mem_addr, mem_wdata, mem_rdata;
    wire        mem_rd, mem_wr;
    wire [15:0] dm_addr, dm_wdata, dm_rdata;
    wire        dm_rd, dm_wr;

    // =========================================================================
    // NIA internal bus
    // =========================================================================
    wire [15:0] nia_op_a, nia_op_b;
    wire        nia_start_mmio, nia_clear_mmio;
    wire        nia_busy_w;

    // =========================================================================
    // Datapath
    // =========================================================================
    Datapath DU (
        .clk       (clk),
        .opcode    (opcode),
        .ALUOp     (alu_op),
        .RegDst    (reg_dst),
        .ALUSrc    (alu_src),
        .MemToReg  (mem_to_reg),
        .RegWrite  (reg_write),
        .MemRd     (mem_read),
        .MemWr     (mem_write),
        .Branch    (branch),
        .Jump      (jump),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rdata (mem_rdata),
        .mem_rd    (mem_rd),
        .mem_wr    (mem_wr)
    );

    // =========================================================================
    // Control Unit
    // =========================================================================
    ControlUnit CU (
        .opcode   (opcode),
        .ALUOp    (alu_op),
        .RegDst   (reg_dst),
        .ALUSrc   (alu_src),
        .MemToReg (mem_to_reg),
        .RegWrite (reg_write),
        .MemRd    (mem_read),
        .MemWr    (mem_write),
        .Branch   (branch),
        .Jump     (jump)
    );

    // =========================================================================
    // Data Memory
    // =========================================================================
    DataMemory dm (
        .clk        (clk),
        .MemWr      (dm_wr),
        .MemRd      (dm_rd),
        .memAddress (dm_addr),
        .writeData  (dm_wdata),
        .readData   (dm_rdata)
    );

    // =========================================================================
    // Extended I/O Bus (includes NIA MMIO registers)
    // =========================================================================
    IO_Bus_NIA io_bus (
        .clk          (clk),
        .reset        (reset),
        // Datapath
        .mem_addr     (mem_addr),
        .mem_wdata    (mem_wdata),
        .mem_rd       (mem_rd),
        .mem_wr       (mem_wr),
        .mem_rdata    (mem_rdata),
        // DataMemory
        .dm_addr      (dm_addr),
        .dm_wdata     (dm_wdata),
        .dm_rd        (dm_rd),
        .dm_wr        (dm_wr),
        .dm_rdata     (dm_rdata),
        // GPIO
        .gpio_out_a   (gpio_out_a),
        .gpio_out_b   (gpio_out_b),
        .gpio_dir     (gpio_dir),
        .gpio_in_a    (gpio_in_a),
        .gpio_in_b    (gpio_in_b),
        // UART
        .uart_tx_data  (uart_tx_data),
        .uart_tx_valid (uart_tx_valid),
        .uart_ctrl     (uart_ctrl),
        .uart_rx_data  (uart_rx_data),
        .uart_tx_ready (uart_tx_ready),
        .uart_rx_valid (uart_rx_valid),
        // Timer
        .timer_ctrl    (timer_ctrl),
        .timer_load    (timer_load),
        .timer_count   (timer_count),
        .timer_expired (timer_expired),
        // PWM
        .pwm_duty      (pwm_duty),
        .pwm_period    (pwm_period),
        .pwm_enable    (pwm_enable),
        // SPI
        .spi_tx_data   (spi_tx_data),
        .spi_start     (spi_start),
        .spi_cs        (spi_cs),
        .spi_rx_data   (spi_rx_data),
        .spi_busy      (spi_busy),
        .spi_done      (spi_done),
        // IRQ
        .irq_out       (irq_out),
        // NIA
        .nia_op_a      (nia_op_a),
        .nia_op_b      (nia_op_b),
        .nia_start     (nia_start_mmio),
        .nia_clear     (nia_clear_mmio),
        .nia_result    (nia_mac_result),
        .nia_busy      (nia_busy_w),
        .nia_finish    (nia_finish),
        .nia_overflow  (nia_overflow)
    );

    // =========================================================================
    // NIA Co-Processor (variant selected by parameter)
    // =========================================================================
    generate
        if (NIA_IMPL == 1) begin : NIA_PAPER1
            NIA_Top_P1 nia (
                .clk        (clk),
                .reset      (reset),
                .start      (nia_start_mmio),
                .operand_A  (nia_op_a),
                .operand_B  (nia_op_b),
                .clear_acc  (nia_clear_mmio),
                .mac_result (nia_mac_result),
                .finish     (nia_finish),
                .overflow   (nia_overflow)
            );
        end else begin : NIA_PAPER2
            NIA_Top_P2 nia (
                .clk        (clk),
                .reset      (reset),
                .start      (nia_start_mmio),
                .operand_A  (nia_op_a),
                .operand_B  (nia_op_b),
                .clear_acc  (nia_clear_mmio),
                .mac_result (nia_mac_result),
                .finish     (nia_finish),
                .overflow   (nia_overflow)
            );
        end
    endgenerate

    assign nia_busy_w = ~nia_finish;

endmodule
