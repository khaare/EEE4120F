`timescale 1ns / 1ps
module DFF (

	input reset,
	input clk,
	input D,
	output reg Q
);

	always @(posedge clk or negedge reset) begin
		if(!reset)
			Q <= 1'b0;
		else
			Q <= D;
	end
endmodule