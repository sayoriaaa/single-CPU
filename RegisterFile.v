`timescale 1ns / 1ps

module RegisterFile(clk, RegDst, MemtoReg, RegWrite, rs, rt, rd, ALUData, MemoryData, ReadData1, ReadData2);
	input [4:0] rs, rt, rd;
	input [31:0] ALUData, MemoryData;
	input RegWrite, clk, RegWrite, RegDst, MemtoReg;
	
	output [31:0] ReadData1, ReadData2;
	
	wire [4:0] WriteRegister;
	wire [31:0] WriteData;
	assign WriteRegister = RegDst ? rd : rt;
	assign WriteData = MemtoReg ? MemoryData : ALUData;
	
	reg [31:0] register[0:31];
	
	integer i;
	initial begin
	  for(i=0; i<32; i=i+1) register[i] = 0;
	end
	
	assign ReadData1 = register[rs];
	assign ReadData2 = register[rt];
	
	always @(posedge clk) begin
		if(RegWrite) begin
			register[WriteRegister] = WriteData;
		end
	end
	
endmodule
