`timescale 1ns / 1ps

module Control(op, RegDst, ALUSrcB, ALUOp, RegWrite, MemtoReg, MemWr, PCSource);
	input [5:0] op;
	output RegDst, ALUSrcB, ALUOp, RegWrite, MemtoReg, MemWr, PCSource;
	 
	assign RegDst = (op == 6'b000000) ? 1 : 0;
	assign ALUSrcB = (op == 6'b100011 || op == 6'b101011) ? 1 : 0;
	assign ALUOp = (op == 6'b000010) ? 0 : 1;
	assign RegWrite = (op == 6'b000000 || op == 6'b100011) ? 1 : 0;
	assign MemtoReg = (op == 6'b100011) ? 1 : 0;
	assign MemWr = (op == 6'b101011) ? 1 : 0;
	assign PCSource = (op == 6'b000010) ? 1 : 0;
	
endmodule
	