// -----------------------------------------------------------------------
// Purpose : COMPRESSOR CELLS — Paper 1
// (Reddy, Vyomal, Choubey - IJET 2018, Section 3A, Figure 3)
// -----------------------------------------------------------------------


// -----------------------------------------------------------------------
// 3:2 COMPRESSOR (standard Full Adder)
// Reduces 3 inputs to sum and carry
// -----------------------------------------------------------------------
module compressor_3_2 (
    input A,
    input B,
    input C,
    output S,
    output CO
);
    assign S  = A ^ B ^ C;
    assign CO = (A & B) | (B & C) | (A & C);
endmodule


// -----------------------------------------------------------------------
// 4:2 COMPRESSOR — Paper 1 proposed cell (Figure 3)
//
// A, B, C, D : four data inputs from the same bit column
// CIN        : carry-in from the adjacent compressor in the same column
// S          : sum output (current bit column)
// CO         : carry out to next stage, same column
// COX        : external carry out to next higher bit column
//
// COX is independent of CIN — this breaks the carry chain between
// columns allowing parallel evaluation and reducing critical path.
// -----------------------------------------------------------------------
module compressor_4_2 (
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    input  wire CIN,
    output wire S,
    output wire CO,
    output wire COX
);
    wire D1;

    assign COX = (A & B) | (B & C) | (A & C);
    assign D1  = A ^ B ^ C;
    assign S   = D1 ^ D ^ CIN;
    assign CO  = (D1 & CIN) | (D & (D1 ^ CIN));
endmodule


// -----------------------------------------------------------------------
// 16-BIT COMPRESSOR-BASED ADDER — Paper 1 approach
//
// Takes FOUR 16-bit inputs per column:
//   A   : multiplicand (RA)
//   B   : upper half of shift register (RB)
//   ACC : accumulator feedback value
//   CO  : carry from previous column's compressor (internal, via D port)
//
// Each bit column has 4 data inputs so 4:2 compressor is used.
// COX from each column feeds as CIN into the next higher column,
// breaking the serial carry chain for lower delay and power.
//
// This is the key difference from Paper 2 — Paper 1 merges the
// multiply and accumulate into a single compressor reduction stage
// rather than doing them sequentially. The accumulator feedback ACC
// is what provides the 4th input to the 4:2 compressor.
// -----------------------------------------------------------------------
module compressor_adder_16 (
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire [15:0] ACC,
    input  wire        C_in,
    output wire [15:0] SUM,
    output wire        C_out
);
    wire [15:0] CO;
    wire [15:0] COX;

    // Bit 0: no previous CO or COX
    compressor_4_2 bit0 (
        .A   (A[0]),
        .B   (B[0]),
        .C   (ACC[0]),
        .D   (1'b0),
        .CIN (C_in),
        .S   (SUM[0]),
        .CO  (CO[0]),
        .COX (COX[0])
    );

    // Bits 1-15: COX from previous column feeds as CIN,
    //            CO from previous column feeds as D
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : COMP_COL
            compressor_4_2 comp_inst (
                .A   (A[i]),
                .B   (B[i]),
                .C   (ACC[i]),
                .D   (CO[i-1]),
                .CIN (COX[i-1]),
                .S   (SUM[i]),
                .CO  (CO[i]),
                .COX (COX[i])
            );
        end
    endgenerate

    assign C_out = COX[15] | CO[15];
endmodule