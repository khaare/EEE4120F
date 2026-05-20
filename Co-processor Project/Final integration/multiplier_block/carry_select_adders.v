`timescale 1ns / 1ps
// -----------------------------------------------------------------------
// Purpose : 4-BIT CARRY SELECT ADDER
// Building block for wider carry select adders
// -----------------------------------------------------------------------
module carry_select4 (
    input [3:0] c,
    input [3:0] d,
    input       C_input,
    output [3:0] Result,
    output       C_output
);
    wire [3:0] SUM0, SUM1;
    wire       carry0, carry1;

    ripple_carry4 S0 (
        .e         (c),
        .f         (d),
        .carry_in  (1'b0),
        .S         (SUM0),
        .carry_out (carry0)
    );

    ripple_carry4 S1 (
        .e         (c),
        .f         (d),
        .carry_in  (1'b1),
        .S         (SUM1),
        .carry_out (carry1)
    );

    assign Result   = (C_input == 1'b0) ? SUM0 : SUM1;
    assign C_output = C_input ? carry1 : carry0;
endmodule


// -----------------------------------------------------------------------
// Purpose : 16-BIT CARRY SELECT ADDER
// Updated from 8-bit to match 16-bit input operands.
// Used as the addition unit inside Paper 2's multiplier.
// Four carry_select4 blocks chained together.
// -----------------------------------------------------------------------
module carry_select16 (
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire        C_in,
    output wire [15:0] SUM,
    output wire        C_out
);
    wire tempc1, tempc2, tempc3;

    carry_select4 S0 (.c(A[3:0]),   .d(B[3:0]),   .C_input(C_in),   .Result(SUM[3:0]),   .C_output(tempc1));
    carry_select4 S1 (.c(A[7:4]),   .d(B[7:4]),   .C_input(tempc1), .Result(SUM[7:4]),   .C_output(tempc2));
    carry_select4 S2 (.c(A[11:8]),  .d(B[11:8]),  .C_input(tempc2), .Result(SUM[11:8]),  .C_output(tempc3));
    carry_select4 S3 (.c(A[15:12]), .d(B[15:12]), .C_input(tempc3), .Result(SUM[15:12]), .C_output(C_out));
endmodule


// -----------------------------------------------------------------------
// Purpose : 32-BIT CARRY SELECT ADDER
// Used in the Add-Accumulator block to accumulate 32-bit products.
// Eight carry_select4 blocks chained together.
// -----------------------------------------------------------------------
module carry_select32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        C_in,
    output wire [31:0] SUM,
    output wire        C_out
);
    wire tempc1, tempc2, tempc3, tempc4, tempc5, tempc6, tempc7;

    carry_select4 S0 (.c(A[3:0]),   .d(B[3:0]),   .C_input(C_in),   .Result(SUM[3:0]),   .C_output(tempc1));
    carry_select4 S1 (.c(A[7:4]),   .d(B[7:4]),   .C_input(tempc1), .Result(SUM[7:4]),   .C_output(tempc2));
    carry_select4 S2 (.c(A[11:8]),  .d(B[11:8]),  .C_input(tempc2), .Result(SUM[11:8]),  .C_output(tempc3));
    carry_select4 S3 (.c(A[15:12]), .d(B[15:12]), .C_input(tempc3), .Result(SUM[15:12]), .C_output(tempc4));
    carry_select4 S4 (.c(A[19:16]), .d(B[19:16]), .C_input(tempc4), .Result(SUM[19:16]), .C_output(tempc5));
    carry_select4 S5 (.c(A[23:20]), .d(B[23:20]), .C_input(tempc5), .Result(SUM[23:20]), .C_output(tempc6));
    carry_select4 S6 (.c(A[27:24]), .d(B[27:24]), .C_input(tempc6), .Result(SUM[27:24]), .C_output(tempc7));
    carry_select4 S7 (.c(A[31:28]), .d(B[31:28]), .C_input(tempc7), .Result(SUM[31:28]), .C_output(C_out));
endmodule