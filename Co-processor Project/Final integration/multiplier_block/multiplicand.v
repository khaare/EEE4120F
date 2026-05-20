`timescale 1ns / 1ps
// -----------------------------------------------------------------------
// Purpose : MULTIPLICAND BLOCK
// 16 DFFs, loaded on LOAD_cmd.
// Shared by both Paper 1 and Paper 2 multiplier implementations.
// -----------------------------------------------------------------------
module MULTIPLICAND (
    input        reset,
    input [15:0] A_in,
    input        LOAD_cmd,
    output [15:0] RA
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : MAND_DFF
            DFF dff_inst (
                .reset (reset),
                .clk   (LOAD_cmd),
                .D     (A_in[i]),
                .Q     (RA[i])
            );
        end
    endgenerate
endmodule


// -----------------------------------------------------------------------
// Purpose : MULTIPLIER_RESULT BLOCK
// 33-bit shift register (16+16+1 carry guard), 32-bit product output.
// Iterates 16 times.
//
// RB  — upper 16 bits fed into the adder as the partial accumulation
// ACC — same upper 16 bits exposed separately so Paper 1's
//       compressor_adder_16 can use them as its 4th input (D port),
//       merging the add and accumulate into one compressor stage.
//       Paper 2 does not use ACC — it adds RA+RB sequentially.
// -----------------------------------------------------------------------
module MULTIPLIER_RESULT (
    input  wire        reset,
    input  wire        clk,
    input  wire [15:0] B_in,
    input  wire        LOAD_cmd,
    input  wire        SHIFT_cmd,
    input  wire        ADD_cmd,
    input  wire [15:0] Add_out,
    input  wire        C_out,
    output wire [31:0] RC_MULT,
    output wire        LSB,
    output wire [15:0] RB,
    output wire [15:0] ACC        // accumulator feedback for Paper 1
);
    reg [32:0] temp_register;
    reg        temp_Add;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            temp_register <= 33'b0;
            temp_Add      <= 1'b0;
        end else begin
            if (LOAD_cmd) begin
                temp_register[32:16] <= 17'b0;
                temp_register[15:0]  <= B_in;
            end
            if (ADD_cmd)
                temp_Add <= 1'b1;
            if (SHIFT_cmd) begin
                if (temp_Add) begin
                    temp_Add      <= 1'b0;
                    temp_register <= {1'b0, C_out, Add_out, temp_register[15:1]};
                end else begin
                    temp_register <= {1'b0, temp_register[32:1]};
                end
            end
        end
    end

    assign RB      = temp_register[31:16];
    assign ACC     = temp_register[31:16];  // same as RB, named separately for clarity
    assign LSB     = temp_register[0];
    assign RC_MULT = temp_register[31:0];
endmodule