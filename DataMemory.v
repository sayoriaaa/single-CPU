`timescale 1ns / 1ps

module DataMemory(clk, DataAddr, Data, MemWr, B);
	input [31:0] DataAddr, Data;
	input MemWr, clk;
	output reg [31:0] B;
	
	reg [31:0] Mem[31:0];
	
	always @(MemWr) begin
		if (MemWr==0) B = Mem[DataAddr];
		end
	
	integer i;
	initial begin
		for(i=0; i<32; i=i+1) Mem[i]=i+3;
	end
	
	always@(posedge clk)
		begin
			if(MemWr==1) Mem[DataAddr]=Data;
		end
endmodule
	