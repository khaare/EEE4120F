`timescale 1ns / 1ps

module DataMemory (input clk, 
input MemWr, 
input MemRd,
input [15:0] memAddress, 
input [15:0] writeData,
output [15:0] readData
);

	wire [2:0] address = memAddress [2:0];
	reg [15:0] dataMemory [0:7];

	initial begin
		$readmemb ("test.data",dataMemory,0,7);
	end

	always @ (posedge clk) begin
		if (MemWr)
			dataMemory[address] <= writeData;
	end
	
	assign readData = MemRd? dataMemory[address] : 16'd0;

endmodule