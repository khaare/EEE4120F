// controller_mac.v — Group 9, MRWDOU002
// FSM controller for the 16-bit MAC co-processor (NIA)
// States: IDLE, INIT, LOAD, RUN, TEST, ADD, DONE

module controller_mac (
    input  wire clk,
    input  wire reset,          // active-low async reset
    input  wire START,          // asserted by StarCore opcode-1010 decode
    input  wire END_MULT,       // asserted by 16-bit multiplier when done
    input  wire OVF,            // overflow flag from 40-bit accumulator
    output reg  FINISH_cmd,     // result ready — read by StarCore
    output reg  RESET_cmd,      // active-low: clears all sub-modules
    output reg  LOAD_MULT_cmd,  // latch operands into multiplier input regs
    output reg  BEGIN_MULT_cmd, // start the 16-bit multiplier
    output reg  ADD_cmd,        // trigger add-accumulate step
    output reg  OVF_latch       // latched overflow for StarCore status reg
);

    // State encoding (one-hot for readability and synthesis clarity)
    localparam [6:0]
        IDLE = 7'b0000001,
        INIT = 7'b0000010,
        LOAD = 7'b0000100,
        RUN  = 7'b0001000,
        TEST = 7'b0010000,
        ADD  = 7'b0100000,
        DONE = 7'b1000000;

    reg [6:0] state;

    // ── State register ──────────────────────────────────────────────
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state    <= IDLE;
            OVF_latch <= 1'b0;
        end else begin
            case (state)
                IDLE: state <= START    ? INIT : IDLE;
                INIT: state <= LOAD;
                LOAD: state <= RUN;
                RUN:  state <= TEST;
                TEST: state <= END_MULT ? ADD  : TEST;
                ADD:  begin
                    if (OVF) OVF_latch <= 1'b1; // latch overflow
                    state <= DONE;
                end
                DONE: begin
                    OVF_latch <= 1'b0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // ── Output logic (combinational) ────────────────────────────────
    always @(*) begin
        FINISH_cmd    = (state == DONE) | (state == IDLE);
        RESET_cmd     = (state == INIT) ? 1'b0 : 1'b1; // active-low
        LOAD_MULT_cmd = (state == LOAD);
        BEGIN_MULT_cmd= (state == RUN);
        ADD_cmd       = (state == ADD);
    end

endmodule