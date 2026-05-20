// =============================================================================
// File        : NIA_Controller.v
// Purpose     : FSM Controller for NIA — accumulation-safe version
//               DOES NOT auto-clear accumulator on each start.
//               External clear_acc (from NIA_CLEAR MMIO register) is used.
//               Sequences: IDLE -> LOAD -> RUN -> TEST -> ADD -> DONE -> IDLE
// =============================================================================
`timescale 1ns / 1ps

module NIA_Controller (
    input  wire clk,
    input  wire reset,          // active-low
    input  wire start,          // from NIA_CTRL[0]
    input  wire mult_done,      // STOP from multiplier
    output reg  mult_start,
    output reg  acc_enable,
    output wire finish          // 1 when idle or done
);
    localparam IDLE  = 3'd0,
               LOAD  = 3'd1,
               RUN   = 3'd2,
               TEST  = 3'd3,
               ADD   = 3'd4,
               DONE  = 3'd5;

    reg [2:0] state;

    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= IDLE;
        else case (state)
            IDLE: state <= start ? LOAD  : IDLE;
            LOAD: state <= RUN;
            RUN:  state <= TEST;
            TEST: state <= mult_done ? ADD : TEST;
            ADD:  state <= DONE;
            DONE: state <= IDLE;
            default: state <= IDLE;
        endcase
    end

    always @(*) begin
        mult_start = (state == RUN);
        acc_enable = (state == ADD);
    end

    // finish is 1 when ready for next command (IDLE) or just completed (DONE)
    assign finish = (state == IDLE) | (state == DONE);

endmodule
