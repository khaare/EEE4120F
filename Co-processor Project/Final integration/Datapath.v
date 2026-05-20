`timescale 1ns / 1ps

module Datapath (input clk,
output [3:0] opcode,
input  [1:0] ALUOp,
input  RegDst,
input  ALUSrc,
input  MemToReg,
input  RegWrite,
input  MemRd,
input  MemWr,
input  Branch,
input  Jump,
// --- Memory-Mapped I/O bus (exposed for StarCore1 to intercept) ---
output [15:0] mem_addr,       // address driven by ALU (used for load/store)
output [15:0] mem_wdata,      // data to write (RS2)
input  [15:0] mem_rdata,      // data returned from memory OR I/O
output        mem_rd,         // load  in progress
output        mem_wr          // store in progress
);

	// Program Counter
   	reg  [15:0] pc_current;             // Current PC value (register)
    	wire [15:0] pc_next;                // Next PC value (combinational)
    	wire [15:0] pc2;                    // PC + 2 (sequential next address)

    	// Instruction fetch 
    	wire [15:0] instr;                  // Fetched instruction word

    	// Register file 
    	wire [2:0]  reg_write_dest;         // Write-back register address (after RegDst mux)
    	wire [15:0] reg_write_data;         // Write-back data (after MemToReg mux)
    	wire [2:0]  reg_read_addr_1;        // RS1 address (from instr[11:9])
    	wire [2:0]  reg_read_addr_2;        // RS2 address (from instr[8:6])
    	wire [15:0] reg_read_data_1;        // Data from RS1
    	wire [15:0] reg_read_data_2;        // Data from RS2

    	// Immediate extension 
    	wire [15:0] ext_im;                 // Sign-extended 6-bit immediate

    	// ALU 
    	wire [15:0] alu_operand_b;          // ALUSrc mux output (RS2 or immediate)
    	wire [2:0]  alu_control;            // ALU function select from ALU_Control
    	wire [15:0] alu_result;             // ALU computed result
   	 wire        zero_flag;              // ALU zero output

    	// Branch / Jump PC computation 
    	wire [15:0] pc_branch;              // Branch target address
   	 wire [15:0] pc_after_branch;        // PC selected after branch evaluation
    	wire [12:0] jump_target;            // Jump target (12 bits + appended 0)
    	wire [15:0] pc_jump;                // Full 16-bit jump target address

   	 // Data memory 
    	wire [15:0] mem_read_data;          // Data read from memory


    	initial begin
    		pc_current <= 16'd0;
    	end

   	 always @(posedge clk) begin
    		pc_current <= pc_next;
    	 end
	
	assign pc2 = pc_current + 16'd2;
	

	InstructionMemory im (
		.pc          (pc_current),
  		.out (instr)
    		);

 	assign opcode = instr[15:12];
	
	assign reg_write_dest = RegDst ? instr[5:3] : instr[8:6];
	assign reg_read_addr_1 = instr[11:9];  // RS1
	assign reg_read_addr_2 = instr[8:6];   // RS2	

	
	GPR reg_file (
                 .clk              (clk),
                 .write       (RegWrite),
		 .address1	(reg_read_addr_1),
		 .address2	(reg_read_addr_2),
                 .writeDest   (reg_write_dest),
                 .writeData   (reg_write_data),
                 .readData1  (reg_read_data_1),
                 .readData2  (reg_read_data_2)
             );

	assign ext_im = { {10{instr[5]}}, instr[5:0] }; //{10{instr[5]}} replicates the sign bit 10 times (bits 15:6)
	//instr[5:0]     is the original 6-bit value (bits 5:0)

	assign alu_operand_b = ALUSrc ? ext_im : reg_read_data_2;


	ALU_Control alu_ctrl (
                 .ALUOp_signal   (ALUOp),
                 .opcode  (instr[15:12]),
                 .ALUcnt (alu_control)
             );
	ALU alu_unit (
                 .a           (reg_read_data_1),
                 .b           (alu_operand_b),
                 .control_signal (alu_control),
                 .out      (alu_result),
                 .zero        (zero_flag)
             );



	assign pc_branch = pc2 + {ext_im[14:0], 1'b0};

	assign pc_after_branch =(Branch & (instr[15:12] == 4'b1011) &  zero_flag) ? pc_branch :
                         (Branch & (instr[15:12] == 4'b1100) & ~zero_flag) ? pc_branch :
                         pc2;

	assign pc_jump = {pc2[15:13], instr[11:0], 1'b0};

	assign pc_next = Jump ? pc_jump : pc_after_branch;

	// Memory bus — driven out to StarCore1 so the I/O interface can intercept
	assign mem_addr  = alu_result;
	assign mem_wdata = reg_read_data_2;
	assign mem_rd    = MemRd;
	assign mem_wr    = MemWr;

	// Read data comes back from StarCore1 (either DataMemory or I/O register)
	assign mem_read_data = mem_rdata;


	//Select the data written back to the register file.
        //mem_to_reg = 0 -> ALU result  (for R-type and other compute instructions)
        //mem_to_reg = 1 -> memory read data (for LD instruction)
        
	assign reg_write_data = MemToReg ? mem_read_data : alu_result;


endmodule
