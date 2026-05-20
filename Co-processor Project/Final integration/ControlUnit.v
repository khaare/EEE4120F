`timescale 1ns / 1ps


module ControlUnit (input [3:0] opcode,
output reg [1:0] ALUOp,
output reg RegDst,
output reg ALUSrc,
output reg MemToReg,
output reg RegWrite,
output reg MemRd,
output reg MemWr,
output reg Branch,
output reg Jump
);

	always @ (opcode) begin // combinational always block thats sensitive to every signal read inside this block, can say * to be safe for when more inputs later - maintain
// a block is combinational when it has no clock edge trigger. output is assigned on every possible path - no latches
		
		ALUOp = 2'b00;
		RegDst= 1'b0;
		ALUSrc = 1'b0;
		MemToReg = 1'b0;
		RegWrite = 1'b0;
		MemRd = 1'b0;
		MemWr = 1'b0; 
		Branch = 1'b0;
		Jump = 1'b0;

		case (opcode)
			4'b0000: begin   	//LD
				ALUOp = 2'b10;
				RegDst= 1'b0;
				ALUSrc = 1'b1;
				MemToReg = 1'b1;
				RegWrite = 1'b1;
				MemRd = 1'b1;
				MemWr = 1'b0; 
				Branch = 1'b0;
				Jump = 1'b0;
			end
			4'b0001: begin		//ST
				ALUOp = 2'b10;
				RegDst= 1'b0;
				ALUSrc = 1'b1;
				MemToReg = 1'b0;
				RegWrite = 1'b0;
				MemRd = 1'b0;
				MemWr = 1'b1; 
				Branch = 1'b0;
				Jump = 1'b0;
			end
			4'b0010, 4'b0011, 4'b0100, 4'b0101, 4'b0110, 4'b0111, 4'b1000, 	4'b1001: begin 			//R-TYPE
				ALUOp = 2'b00;
				RegDst= 1'b1;
				ALUSrc = 1'b0;
				MemToReg = 1'b0;
				RegWrite = 1'b1;
				MemRd = 1'b0;
				MemWr = 1'b0; 
				Branch = 1'b0;
				Jump = 1'b0;
			end
			4'b1011, 4'b1100: begin		//BEQ/BNE
				ALUOp = 2'b01;
				RegDst= 1'b0;
				ALUSrc = 1'b0;
				MemToReg = 1'b0;
				RegWrite = 1'b0;
				MemRd = 1'b0;
				MemWr = 1'b0; 
				Branch = 1'b1;
				Jump = 1'b0;
			end
			4'b1101: begin			//JMP
				ALUOp = 2'b00;
				RegDst= 1'b0;
				ALUSrc = 1'b0;
				MemToReg = 1'b0;
				RegWrite = 1'b0;
				MemRd = 1'b0;
				MemWr = 1'b0; 
				Branch = 1'b0;
				Jump = 1'b1;
			end
			4'b1010: begin			//RSVD
				ALUOp = 2'b00;
				RegDst= 1'b0;
				ALUSrc = 1'b0;
				MemToReg = 1'b0;
				RegWrite = 1'b0;
				MemRd = 1'b0;
				MemWr = 1'b0; 
				Branch = 1'b0;
				Jump = 1'b0;
			end
			default: begin
				ALUOp = 2'b00;
				RegDst= 1'b0;
				ALUSrc = 1'b0;
				MemToReg = 1'b0;
				RegWrite = 1'b0;
				MemRd = 1'b0;
				MemWr = 1'b0; 
				Branch = 1'b0;
				Jump = 1'b0;
			end
		endcase
	end
				
endmodule

