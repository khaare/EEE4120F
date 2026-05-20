`timescale 1ns / 1ps
// -----------------------------------------------------------------------
// Purpose : 16x16 SHIFT/ADD MULTIPLIER — Paper 1 approach
//
// Sequential shift-and-add. 16-bit inputs, 32-bit output.
// Takes 16 clock cycles per multiply.
//
// Addition unit: compressor_adder_16 built from Paper 1's proposed
// 4:2 compressor cells (Figure 3, Reddy et al. IJET 2018).
//
// Key difference from Paper 2:
//   Paper 2 adder takes 2 inputs:     RA + RB
//   Paper 1 adder takes 4 inputs:     RA + RB + ACC + CO_prev
//
// The 4th input (ACC) is the current accumulated value fed back from
// the upper half of the shift register. This is what gives the 4:2
// compressor all 4 of its data inputs, allowing it to merge the add
// and accumulate steps into a single compressor reduction stage rather
// than doing them sequentially as Paper 2 does.
//
// COX from each column feeds as CIN into the next column, breaking
// the serial carry chain — this is what reduces delay and power.
// -----------------------------------------------------------------------
module MULTIPLIER_PAPER1 (
    input  wire [15:0] A_in,
    input  wire [15:0] B_in,
    input  wire        clk,
    input  wire        reset,
    input  wire        START,
    output wire [31:0] RC_MULT,
    output wire        STOP
);
    wire [15:0] RA;
    wire [15:0] RB;
    wire [15:0] ACC;           // accumulator feedback — 4th input to compressor
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

    // Paper 1: compressor takes RA + RB + ACC + internal CO
    // ACC is gated by ADD_cmd — only fed in during an ADD cycle,
    // otherwise zeroed so the compressor just passes RA+RB through.
    compressor_adder_16 u_adder (
        .A     (RA),
        .B     (RB),
        .ACC   (ADD_cmd ? ACC : 16'h0000),
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