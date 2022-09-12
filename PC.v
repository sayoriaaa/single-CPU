`timescale 1ns / 1ps

module PC(clk, PCSource, JumpTarget, InsAddr);
	input clk, PCSource;
	input [25:0] JumpTarget;

	output [31:0] InsAddr;
	reg [31:0] InsAddr;
	
	always @(posedge clk)
		begin
			case(PCSource)
				1'b0:begin
					InsAddr = InsAddr+1;
				end
				1'b1:begin
					InsAddr = {6'b0,JumpTarget};
				end
			endcase
		end
		
endmodule
					
					
				
	
	
	