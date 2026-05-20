`timescale 1ns / 1ps
// -----------------------------------------------------------------------
// Purpose : 16x16 SHIFT/ADD MULTIPLIER — Paper 2 approach
//
// Sequential shift-and-add. 16-bit inputs, 32-bit output.
// Takes 16 clock cycles per multiply.
// Addition unit: carry_select16 — adds RA + RB each ADD cycle.
// ACC port of MULTIPLIER_RESULT is unused here (Paper 2 does not
// merge accumulation into the adder).
// -----------------------------------------------------------------------
module MULTIPLIER_PAPER2 (
    input [15:0] A_in,
    input [15:0] B_in,
    input        clk,
    input        reset,
    input        START,
    output [31:0] RC_MULT,
    output        STOP
);
    wire [15:0] RA;
    wire [15:0] RB;
    wire [15:0] ACC;           // exposed but not used by Paper 2 adder
    wire [15:0] add_result;
    wire        carry_out;
    wire        LSB;
    wire        ADD_cmd, SHIFT_cmd, LOAD_cmd;

    MULTIPLICAND u_multiplicand (
        .reset    (reset),
        .A_in     (A_in),
        .LOAD_cmd (LOAD_cmd),
        .RA       (RA)
    );

    // Paper 2: adds RA + RB only (ACC not involved)
    carry_select16 u_adder (
        .A     (RA),
        .B     (RB),
        .C_in  (1'b0),
        .SUM   (add_result),
        .C_out (carry_out)
    );

    MULTIPLIER_RESULT u_mult_result (
        .reset     (reset),
        .clk       (clk),
        .B_in      (B_in),
        .LOAD_cmd  (LOAD_cmd),
        .SHIFT_cmd (SHIFT_cmd),
        .ADD_cmd   (ADD_cmd),
        .Add_out   (add_result),
        .C_out     (carry_out),
        .RC_MULT   (RC_MULT),
        .LSB       (LSB),
        .RB        (RB),
        .ACC       (ACC)
    );

    CONTROLLER u_controller (
        .reset     (reset),
        .clk       (clk),
        .START     (START),
        .LSB       (LSB),
        .ADD_cmd   (ADD_cmd),
        .SHIFT_cmd (SHIFT_cmd),
        .LOAD_cmd  (LOAD_cmd),
        .STOP      (STOP)
    );
endmodule