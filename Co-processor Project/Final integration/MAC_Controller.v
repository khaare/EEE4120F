// ============================================================================
// File        : MAC_Controller.v
// Purpose     : FSM Controller for Neural Inference Accelerator (NIA)
//               Sequences: IDLE -> INIT -> LOAD -> RUN -> TEST -> ADD -> DONE
//               Controls MULTIPLIER_PAPER1 and add_accumulator modules.
// Author      : Douglas Marwa Justine
// Date        : 12 May 2026 (updated to match teammates' modules)
// ============================================================================

`timescale 1ns / 1ps

module MAC_Controller (
    input  wire        clk,
    input  wire        reset,          // active-low system reset
    input  wire        start,          // from StarCore opcode 1010 decoder
    input  wire        mult_done,      // STOP from multiplier (active-high)
    output reg         mult_start,     // pulse to multiplier START
    output reg         acc_enable,     // pulse to add_accumulator enable
    output reg         clear_acc,      // active-high pulse to clear accumulator
    output reg         finish          // handshake to StarCore: result ready
);

    // State encoding
    localparam IDLE  = 3'b000,
               INIT  = 3'b001,
               LOAD  = 3'b010,
               RUN   = 3'b011,
               TEST  = 3'b100,
               ADD   = 3'b101,
               DONE  = 3'b110;

    reg [2:0] state, next_state;

    // State register (asynchronous active-low reset)
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (start) next_state = INIT;
                    else       next_state = IDLE;

            INIT:   next_state = LOAD;      // one cycle for clear_acc

            LOAD:   next_state = RUN;       // one cycle (optional, can be merged)

            RUN:    next_state = TEST;      // assert mult_start

            TEST:   if (mult_done) next_state = ADD;
                    else          next_state = TEST;

            ADD:    next_state = DONE;      // assert acc_enable

            DONE:   next_state = IDLE;      // assert finish

            default: next_state = IDLE;
        endcase
    end

    // Output logic (Mealy style)
    always @(*) begin
        // Defaults
        mult_start = 1'b0;
        acc_enable = 1'b0;
        clear_acc  = 1'b0;
        finish     = 1'b0;

        case (state)
            IDLE:   finish = 1'b1;          // ready when idle

            INIT:   clear_acc = 1'b1;       // clear accumulator before new MAC

            RUN:    mult_start = 1'b1;      // start multiplier

            ADD:    acc_enable = 1'b1;      // add product to accumulator

            DONE:   finish = 1'b1;          // signal StarCore result ready
        endcase
    end

endmodule