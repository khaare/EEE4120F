`timescale 1ns / 1ps
// ROM - Read only memory is a non-volatile storage medium that permanently stores data and doesnt need power to retain the data

module InstructionMemory( input [15:0] pc,  output [15:0] out);

	wire [3:0] romAddress = pc[4:1];

	reg [15:0] memoryLocation [0:15];
	integer i;
	initial begin
		for (i=0;i<16;i=i+1)
			memoryLocation[i] = 16'b0;
		$readmemb ("test.prog", memoryLocation,0,15);
	end
	
	assign out = memoryLocation[romAddress];

endmodule
		