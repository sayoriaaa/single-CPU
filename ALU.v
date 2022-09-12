`timescale 1ns / 1ps

module ALU(inputA, inputB, inExt, ALUScrB, ALUOp, result);
	input [31:0] inputA, inputB, inExt;
	input ALUScrB, ALUOp;
	output [31:0] result;
	
	wire [31:0] MUX;
	assign MUX = ALUScrB?inExt:inputB;
	
	reg [31:0] result;
	
	always @(*)
		begin
			case(ALUOp)
				1'b1:begin
					result = inputA + MUX;
				end
			endcase
		end
endmodule
		