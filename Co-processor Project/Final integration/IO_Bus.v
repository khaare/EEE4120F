// =============================================================================
// File        : IO_Bus.v
// Purpose     : Memory-Mapped I/O Bus for StarCore1
//
// Address map (16-bit):
//   0x0000 – 0xFEFF   Normal DataMemory
//   0xFF00 – 0xFFFF   Memory-mapped I/O (256 possible registers)
//
// I/O Register Map:
// ---------------------------------------------------------------------------
//  ADDR    NAME            R/W   DESCRIPTION
// ---------------------------------------------------------------------------
//  0xFF00  GPIO_OUT_A       W    16-bit general-purpose output port A (LEDs etc.)
//  0xFF01  GPIO_OUT_B       W    16-bit general-purpose output port B
//  0xFF02  GPIO_IN_A        R    16-bit general-purpose input port A (switches etc.)
//  0xFF03  GPIO_IN_B        R    16-bit general-purpose input port B
//  0xFF04  GPIO_DIR         W    Direction register: bit=1 means output, bit=0 means input
//  0xFF05  GPIO_STATUS      R    Bit[0]=port A input ready, Bit[1]=port B input ready
//
//  0xFF10  UART_TX_DATA     W    Write byte here to transmit over UART (bits [7:0] used)
//  0xFF11  UART_RX_DATA     R    Read received byte from UART (bits [7:0])
//  0xFF12  UART_STATUS      R    Bit[0]=TX ready, Bit[1]=RX data available
//  0xFF13  UART_CTRL        W    Bit[0]=enable TX, Bit[1]=enable RX, Bit[2]=clear RX flag
//
//  0xFF20  TIMER_CTRL       W    Bit[0]=enable, Bit[1]=auto-reload, Bit[2]=interrupt enable
//  0xFF21  TIMER_LOAD       W    Preload value (counts down to 0)
//  0xFF22  TIMER_COUNT      R    Current timer count value
//  0xFF23  TIMER_STATUS     R    Bit[0]=expired (count reached 0)
//
//  0xFF30  PWM_DUTY         W    PWM duty cycle (0x0000=0%, 0xFFFF=100%)
//  0xFF31  PWM_PERIOD       W    PWM period in clock cycles
//  0xFF32  PWM_CTRL         W    Bit[0]=enable PWM output
//
//  0xFF40  SPI_TX_DATA      W    Data byte to shift out on SPI MOSI
//  0xFF41  SPI_RX_DATA      R    Data byte shifted in on SPI MISO
//  0xFF42  SPI_CTRL         W    Bit[0]=start transfer, Bit[1]=CS assert
//  0xFF43  SPI_STATUS       R    Bit[0]=busy, Bit[1]=transfer complete
//
//  0xFF50  IRQ_MASK         W    Bit per source: 1=enabled. [0]=timer,[1]=uart_rx,[2]=spi
//  0xFF51  IRQ_STATUS       R    Bit per source: 1=pending (write 1 to clear)
//  0xFF52  IRQ_CLEAR        W    Write 1 to bit to clear that IRQ flag
//
//  0xFF60  SCRATCH_0        R/W  Scratch register 0 (general use)
//  0xFF61  SCRATCH_1        R/W  Scratch register 1
// ---------------------------------------------------------------------------
// =============================================================================

`timescale 1ns / 1ps

module IO_Bus (
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
    output reg         uart_tx_valid,   // pulses high for 1 cycle when TX written
    output reg  [1:0]  uart_ctrl,
    input  wire [7:0]  uart_rx_data,
    input  wire        uart_tx_ready,   // external UART: ready to accept TX
    input  wire        uart_rx_valid,   // external UART: RX byte available

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
    output reg         spi_start,       // pulses high for 1 cycle to begin transfer
    output reg         spi_cs,
    input  wire [7:0]  spi_rx_data,
    input  wire        spi_busy,
    input  wire        spi_done,

    // --- Interrupt output to processor ---
    output wire        irq_out
);

    // =========================================================================
    // I/O region select
    // =========================================================================
    wire io_sel = (mem_addr[15:8] == 8'hFF);

    // Pass through to DataMemory only when not in I/O space
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
    wire irq_timer   = timer_expired  & irq_mask[0];
    wire irq_uart_rx = uart_rx_valid  & irq_mask[1];
    wire irq_spi     = spi_done       & irq_mask[2];
    assign irq_out = irq_timer | irq_uart_rx | irq_spi;

    // =========================================================================
    // Write logic
    // =========================================================================
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            gpio_out_a   <= 16'h0;
            gpio_out_b   <= 16'h0;
            gpio_dir     <= 16'h0;
            uart_tx_data <= 8'h0;
            uart_tx_valid<= 1'b0;
            uart_ctrl    <= 2'b0;
            timer_ctrl   <= 3'b0;
            timer_load   <= 16'h0;
            pwm_duty     <= 16'h0;
            pwm_period   <= 16'hFFFF;
            pwm_enable   <= 1'b0;
            spi_tx_data  <= 8'h0;
            spi_start    <= 1'b0;
            spi_cs       <= 1'b0;
            irq_mask     <= 16'h0;
            irq_status   <= 16'h0;
            scratch_0    <= 16'h0;
            scratch_1    <= 16'h0;
        end else begin
            // Auto-clear pulse signals
            uart_tx_valid <= 1'b0;
            spi_start     <= 1'b0;

            if (mem_wr && io_sel) begin
                case (mem_addr[7:0])
                    // GPIO
                    8'h00: gpio_out_a    <= mem_wdata;
                    8'h01: gpio_out_b    <= mem_wdata;
                    8'h04: gpio_dir      <= mem_wdata;
                    // UART
                    8'h10: begin
                               uart_tx_data  <= mem_wdata[7:0];
                               uart_tx_valid <= 1'b1;
                           end
                    8'h13: uart_ctrl     <= mem_wdata[1:0];
                    // Timer
                    8'h20: timer_ctrl    <= mem_wdata[2:0];
                    8'h21: timer_load    <= mem_wdata;
                    // PWM
                    8'h30: pwm_duty      <= mem_wdata;
                    8'h31: pwm_period    <= mem_wdata;
                    8'h32: pwm_enable    <= mem_wdata[0];
                    // SPI
                    8'h40: spi_tx_data   <= mem_wdata[7:0];
                    8'h42: begin
                               spi_start <= mem_wdata[0];
                               spi_cs    <= mem_wdata[1];
                           end
                    // IRQ
                    8'h50: irq_mask      <= mem_wdata;
                    // IRQ_CLEAR: clear requested bits first, then hardware sets take
                    // priority below — a simultaneous arriving IRQ is never lost.
                    8'h52: irq_status    <= irq_status & ~mem_wdata;
                    // Scratch
                    8'h60: scratch_0     <= mem_wdata;
                    8'h61: scratch_1     <= mem_wdata;
                    default: ;
                endcase
            end

            // Hardware IRQ latching — applied AFTER the write case so that a
            // simultaneous IRQ_CLEAR + arriving interrupt always preserves the
            // new interrupt (set wins over clear on the same cycle).
            if (timer_expired)  irq_status[0] <= 1'b1;
            if (uart_rx_valid)  irq_status[1] <= 1'b1;
            if (spi_done)       irq_status[2] <= 1'b1;
        end
    end

    // =========================================================================
    // Read logic
    // =========================================================================
    always @(*) begin
        if (mem_rd) begin
            if (io_sel) begin
                case (mem_addr[7:0])
                    // GPIO
                    8'h00: mem_rdata = gpio_out_a;
                    8'h01: mem_rdata = gpio_out_b;
                    8'h02: mem_rdata = gpio_in_a;
                    8'h03: mem_rdata = gpio_in_b;
                    8'h04: mem_rdata = gpio_dir;
                    8'h05: mem_rdata = 16'h0003;          // both ports always ready
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
                    default: mem_rdata = 16'hDEAD;
                endcase
            end else begin
                mem_rdata = dm_rdata;
            end
        end else begin
            // mem_rd not asserted — pass through DataMemory bus so that any
            // spurious MemToReg=1 without MemRd=1 produces the memory value
            // rather than a silent zero, making control-unit bugs visible.
            mem_rdata = dm_rdata;
        end
    end

endmodule
