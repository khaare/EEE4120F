`timescale 1ns / 1ps
// -----------------------------------------------------------------------
// Purpose : 4-BIT RIPPLE CARRY ADDER
// Building block of the Carry Select Adder
// -----------------------------------------------------------------------

module ripple_carry4 (
	input [3:0] e,
	input [3:0] f,
	input	carry_in,
	output [3:0] S,		// sum = e+f
	output	carry_out
);

	wire [4:0] tempC;		// store the carry bits, its 5 bits because each bit has its own carry + the input carry
	wire [3:0] P,G;			// P is propagate and G is for generate

	assign tempC[0] = carry_in;
	
	genvar i;
	generate
		for (i=0;i<4;i=i+1) 
			begin: RCA_BIT	// RCA_BIT is a hierarchical label for generated hardware
				assign P[i] = e[i]^f[i];	// carry can travel through this bit. 1: yes, 0:no
				assign G[i] = e[i]&f[i];	// does this bit produce a carry? 1: yes, 0:no
				assign S[i] = P[i]^tempC[i];
				assign tempC[i+1] = G[i] | (tempC[i] & P[i]);
			end
	endgenerate

	assign carry_out = tempC[4];
endmodule