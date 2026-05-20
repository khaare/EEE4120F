`timescale 1ns / 1ps
// -----------------------------------------------------------------------
// Purpose : MULTIPLIER INTERNAL CONTROLLER (FSM)
// Updated for 16-bit inputs — runs 16 shift/add iterations instead of 8.
// temp_count is now 4-bit, terminal count is 4'b1111.
// Shared by both Paper 1 and Paper 2 multiplier implementations.
// -----------------------------------------------------------------------
module CONTROLLER (
    input  reset,
    input  clk,
    input  START,
    input  LSB,
    output reg  ADD_cmd,
    output reg  SHIFT_cmd,
    output reg  LOAD_cmd,
    output reg  STOP
);
    localparam IDLE  = 3'd0,
               INIT  = 3'd1,
               TEST  = 3'd2,
               ADD   = 3'd3,
               SHIFT = 3'd4;

    reg [2:0] state;
    reg [3:0] temp_count;   // 4-bit to count 16 iterations (0-15)

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state      <= IDLE;
            temp_count <= 4'b0000;
        end else begin
            case (state)
                IDLE:  state <= (START) ? INIT : IDLE;
                INIT:  state <= TEST;
                TEST:  state <= (LSB == 1'b0) ? SHIFT : ADD;
                ADD:   state <= SHIFT;
                SHIFT: begin
                    if (temp_count == 4'b1111) begin  // 16 iterations done
                        temp_count <= 4'b0000;
                        state      <= IDLE;
                    end else begin
                        temp_count <= temp_count + 1;
                        state      <= TEST;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    always @(*) begin
        STOP      = (state == IDLE)  ? 1'b1 : 1'b0;
        ADD_cmd   = (state == ADD)   ? 1'b1 : 1'b0;
        SHIFT_cmd = (state == SHIFT) ? 1'b1 : 1'b0;
        LOAD_cmd  = (state == INIT)  ? 1'b1 : 1'b0;
    end
endmodule