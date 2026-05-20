`timescale 1ns / 1ps

// making a register vector

module GPR (input clk,
input write, //enable pin
input [2:0] address1,
input [2:0] address2,
input [2:0] writeDest,
input [15:0] writeData,
output [15:0] readData1,
output [15:0] readData2
);

	reg [15:0] registers [0:7]; // 8-reg with each reg being 16-bits wide
	integer i;

	initial begin
	
		for (i=0;i<8;i=i+1) begin
			registers[i] <= 16'b0;
		end
	end


	always @ (posedge clk) begin//synchronised
	
		if (write)
			if (writeDest != 3'd0)
				registers[writeDest] <= writeData;
	end

	assign readData1 = registers[address1];
	assign readData2 = registers[address2];
endmodule

// if (write)
// if (writeDest == 000)
// register[writeDest]<= writeData
// readData =< register[writeDest]
// register[writeDest]<= 0;