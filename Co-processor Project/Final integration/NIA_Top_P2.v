// =============================================================================
// File        : NIA_Top_P2.v
// Purpose     : NIA using Paper 2 multiplier (Carry-Select adder)
//               Alternative implementation for performance comparison
// =============================================================================
`timescale 1ns / 1ps

module NIA_Top_P2 (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [15:0] operand_A,
    input  wire [15:0] operand_B,
    input  wire        clear_acc,
    output wire [39:0] mac_result,
    output wire        finish,
    output wire        overflow
);
    wire mult_start;
    wire acc_enable;
    wire mult_done;
    wire [31:0] product;

    NIA_Controller ctrl (
        .clk        (clk),
        .reset      (reset),
        .start      (start),
        .mult_done  (mult_done),
        .mult_start (mult_start),
        .acc_enable (acc_enable),
        .finish     (finish)
    );

    MULTIPLIER_PAPER2 mult (
        .A_in    (operand_A),
        .B_in    (operand_B),
        .clk     (clk),
        .reset   (reset),
        .START   (mult_start),
        .RC_MULT (product),
        .STOP    (mult_done)
    );

    add_accumulator adder_acc (
        .clk         (clk),
        .rst_n       (reset),
        .enable      (acc_enable),
        .product_in  (product),
        .clear_acc   (clear_acc),
        .saturate_en (1'b1),
        .acc_out     (mac_result),
        .overflow    (overflow)
    );

endmodule
