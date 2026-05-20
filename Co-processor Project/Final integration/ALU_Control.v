`timescale 1ns / 1ps

module ALU_Control (
input [1:0] ALUOp_signal,
input [3:0] opcode,
output reg [2:0] ALUcnt);

	
	always @ (*) begin
		if (ALUOp_signal == 2'b00)
			case (opcode)
				4'b0010 : ALUcnt = 3'b000;	//ADD
				4'b0011 : ALUcnt = 3'b001;	//SUB
				4'b0100 : ALUcnt = 3'b100;	//INV
				4'b0101 : ALUcnt = 3'b101;	//SHL
				4'b0110 : ALUcnt = 3'b110;	//SHR
				4'b0111 : ALUcnt = 3'b010;	//AND
				4'b1000 : ALUcnt = 3'b011;	//OR
				4'b1001 : ALUcnt = 3'b111;	//SLT
				default: ALUcnt = 3'b000;
			endcase

		else if (ALUOp_signal == 2'b01)
			ALUcnt = 3'b001;
		else
			ALUcnt = 3'b000;
	end

endmodule




