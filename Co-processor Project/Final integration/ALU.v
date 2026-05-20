`timescale 1ns / 1ps
`include "Parameter.v"
// with this i can use `define for the operations- sounds like a good idead
// i think this needs to be a module so...ill use module and case

module ALU (input [15:0] a,b, input [2:0] control_signal, output reg [15:0] out, output zero ); 
//16-bit inputs, 3-bits signal and 16-bits output

	assign zero = (out == 16'd0) ? 1'b1: 1'b0;

	always @ (a,b,control_signal) begin
		case(control_signal)
			3'b000	: out = a+b;
			3'b001	: out = a-b;
			3'b010	: out = a&b;
			3'b011	: out = a|b;
			3'b100	: out = ~a;
			3'b101	: out = a << b[3:0];
			3'b110	: out = a >> b[3:0];
			3'b111	: out = a<b ? 1:0;
			default	: out = 16'd0;
		endcase
	end

endmodule
			