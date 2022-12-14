首先我们确定每个要编写单元的输入和输出，然后根据指导书上的数据通路确定输入输出之间的对应关系，通过代码来描述硬件的内部逻辑从而完成模块的设计

[TOC]



# ALU

仅考虑ALU自身的功能，则输入输出接口如下

输入

- inputA (32)
- inputB (32)
- ALUOp (1)

输出

- result (32)

在ALUop为1的情况下，对输入的inputA和inputB执行加法运算，然后在下一个时钟上升沿将result写回寄存器，而考虑提供的数据通路，我们将MUX的部分整合进ALU，从而支持对立即数的运算

![捕获](D:\大三上\汇编与接口\project\捕获.JPG)

增加部分：

输入

- ALUScrB
- inExt

ALUScrB对应MUX的实现，如图为1时执行立即数inExt的加法，为0时执行inputB的加法

进而编写对应的代码，我们需要实现：

在ALUOp为1时，遇到任何电平变化即执行inputA与由ALUScrB确定的inputB或inExt的加法

根据上述思路编写程序后编译出现后这样的问题

```
Error (10137): Verilog HDL Procedural Assignment error at alu.v(13): object "result" on left-hand side of assignment must have a variable data type
```

由于output result实际上是一个wire类型的变量，所以我们还要添加一个同名的reg来保存加法运算后的数值就解决了

```
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
```

至此ALU部分完成！

# PC

![捕获](D:\大三上\汇编与接口\project\捕获.JPG)

对于一般指令，PC在下一个时钟上升沿对当前指令执行+1操作(由于每条指令为32位，所以就数值而言+8)，而对于跳转命令，PC写入需要跳转的地址，这两者如图通过PCSource控制，

分析它的输入输出：

输入

- clk
- PCSource
- JumpTarget (26)

输出

- InsAddr

与编写ALU的逻辑相同，(需要额外加入26-32的强制转换)我们很快可以得到

```
module PC(clk, PCSource, JumpTarget, InsAddr);
	input clk, PCSource;
	input [25:0] JumpTarget;

	output [31:0] InsAddr;
	reg [31:0] InsAddr;
	
	always @(posedge clk)
		begin
			case(PCSource)
				1'b0:begin
					InsAddr = InsAddr+8;
				end
				1'b1:begin
					InsAddr = {6'b0,JumpTarget}*8+8;
				end
			endcase
		end
		
endmodule
```

# Memory

由于采用哈弗架构，需要编写两份分别存储指令和数据的器件

## Data Memory



![捕获3](D:\大三上\汇编与接口\project\捕获3.JPG)

这张图上的存储器包含数据和指令，只考虑数据的部分

输入 (CLK)

- DataAddr 32
- Data 32
- MemWr 1

输出

- B 32

编写的逻辑如下：

当存储器存储数据时，MemWr为0，存储器中由DataAddr对应的地址单元在CLK处于上升沿被输入的Data覆盖；当读取数据时，MemWr为1，B端口输出DataAddr对应地址单元的数据

除此之外，我们最好还要在最开始的情况下对内存进行初始化全部置于0

由此

```
module DataMemory(DataAddr, Data, MemWr, B);
	input [31:0] DataAddr, Data;
	input MemWr;
	output reg [31:0] B;
	
	reg [31:0] Mem[31:0];
	
	always @(MemWr) begin
		if (MemWr==0) B = Mem[DataAddr];
		end
	
	integer i;
	initial begin
		for(i=0; i<32; i=i+1) Mem[i]=0;
	end
	
	always@(*)
		begin
			if(MemWr) Mem[DataAddr]=Data;
		end
endmodule
```

## InstructionMemory

相比数据存储器，这里只需要根据PC取对应的指令即可，但是我们额外需要做的就是把测试用的汇编代码预先在初始化的时候就写进去，还有看数据通路注意到要把输出的指令分成5段(op, rs, rt, rd, offset)

输入

- PC
- MemWr

输出

- op
- rs
- rt
- rd
- offset
- jump (导到PC)

其中offset直接从内部的16位强制转换为32位输出

```
module InstructionMemory(PC, MemWr, op, rs, rt, rd, offset);
	input [31:0] PC;
	input MemWr;
	output [5:0] op;
	output [4:0] rs, rt, rd;
	output [31:0] offset;
	
	wire [31:0] mem[0:16];
	
	assign mem[0] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[1] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[2] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[3] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[4] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[5] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[6] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[7] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[8] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[9] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[10] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[11] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[12] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[13] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[14] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[15] = 32'b 000000_00000_00000_0000000000000000;
	assign mem[16] = 32'b 000000_00000_00000_0000000000000000;
	
	assign op = mem[PC[6:3]][31:26];
	assign rs = mem[PC[6:3]][25:21];
	assign rt = mem[PC[6:3]][20:16];
	assign rd = mem[PC[6:3]][15:11];
	assign offset = {16'b0, mem[PC[6:3]][15:0]};
endmodule
```



# RegisterFile

输入 (CLK)

- rs (5) 
- rt (5) 
- rd (5) 
- ALUData (32)
- MemoryData (32)
- RegWrite (1)
- RegDst (1)
- MemtoReg (1)

输出

- ReadData1 (32)
- ReadData2 (32)

![捕获3](D:\大三上\汇编与接口\project\捕获3.JPG)

由RegDst确定WriteRegister (rt/rd)

由MemtoReg确定WriteData (ALUData/MemoryData)

在读取数据时，ReadData1ReadData2输出的始终是寄存器堆中地址为rs rt的值

在写数据时，在CLK上升沿写入对应数据

```
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
```

# 控制器

下面是最核心的部分

清楚了每条指令的执行过程，现在就可以设计控制器了

输入

- op (6)

输出(均为1位)

- RegDst
- ALUSrcB
- ALUOp 
- RegWrite
- MemtoReg
- MemWr
- PCSource 

为了先验证项目是否成功，我们先用不会错的方式写完代码

```
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
```

# 测试



```
`timescale 1ns / 1ps
```

对于排线没有采用bus tool 导致编译错误



我们采用了图形和代码混合的设计方法，因为各个模块的运行逻辑用代码表示较为清楚，而模块之间的连线较为繁琐，所以通过图形的拖拽连接比较直观

因为仿真的需要，所以在bdf布局时需要引入相应的各个输出output，然而利用所给元件进行连接后发现输出端口不能自适应输出数据的位宽(因为是在bdf文件，如果是.v文件在声明的时候就确定了)，花费一些时间查找资料后(实际上在property改名的时候就有提示没看到/(ㄒoㄒ)/~~)才知道原来是需要在`Pin name(s)`中直接修改声明的

----------

在进行仿真的时候，又出现了这样的错误

```
 Error: (vsim-19) Failed to access library 'cycloneive_ver' at "cycloneive_ver".
# 
# No such file or directory. (errno = ENOENT)
# ** Error: (vsim-19) Failed to access library 'altera_ver' at "altera_ver".
```

在这个仿真界面的simulation option中选择VHDL

在`Tools-Launch Simulation Compiler Library`中把VHDL给勾选上，重新编译再进行仿真

然后再在`assignments-settings-libraries`里把编译出来的路径添加到项目里

我嘚天终于被我试出来了！！！

之后新建仿真的时候也都要手动在`Tools-Launch Simulation Compiler Library`中把VHDL给勾选上(我谢谢你quartus)

# 仿真

## 测试I： LW与ADD

第一次仿真

![捕获4](D:\大三上\汇编与接口\project\捕获4.JPG)

发现指令可以读取，但是ALU这部分完全不对

然后发现是数据写错了(对汇编指令格式不熟悉)，发现运用LW指令时把应该要计算的数据放到了寄存器堆而不是内存里，ADD指令也把rt和rd的顺序搞反了，所以修改代码如下

```
assign mem[0] = 32'b 100011_00000_00000_0000000000000000;
assign mem[1] = 32'b 100011_00000_00001_0000000000000000;
assign mem[2] = 32'b 000000_00001_00010_0000000000000000;
```

第二次仿真

![捕获5](D:\大三上\汇编与接口\project\捕获5.JPG)

发现ALU仅在第一次LW指令时有参与运算，然后把PC的OUT也打印了出来，发现PC值是正确的但滞后有点严重，所以改变时钟频率从10ns到100ns，发现比原来好了一些

这次多打印了一些输出端口来便于观察调试信息，结果编译错误，正好就是在原先编译正确的基础上加了ALU立即数那里的输出，所以以为错误信息里缺的那15位是因为Offset拼接导致的，然后怎么查都想不明白会出错，最后问同学才知道只是恰好设置的输出端口数量(188)超出了用来仿真的FPGA的输出端口数量(173)

最后我重新写了用于测试的汇编指令，方便我更详细的观察每个端口的输出情况

首先预设内存中的数据如下(方便我观察内存地址与内存地址对应的值)

```
	integer i;
	initial begin
		for(i=0; i<32; i=i+1) Mem[i]=i+3;
	end
```

然后是设定指令寄存器中的指令如下(寄存器堆的数值全部清0)

```
initial begin
		mem[0] = 32'b 000000_00000_00000_0000000000000000;
		mem[1] = 32'b 100011_00000_00000_0000000000000111;
		mem[2] = 32'b 100011_00001_00001_0000000000001111;
		mem[3] = 32'b 000000_00000_00001_0000000000000000;
		mem[4] = 32'b 000000_00000_00000_0000000000000000;
		mem[5] = 32'b 000000_00000_00000_0000000000000000;
		mem[6] = 32'b 000000_00000_00000_0000000000000000;
		mem[7] = 32'b 000000_00000_00000_0000000000000000;
		mem[8] = 32'b 000000_00000_00000_0000000000000000;
		mem[9] = 32'b 000000_00000_00000_0000000000000000;
		mem[10] = 32'b 000000_00000_00000_0000000000000000;
		mem[11] = 32'b 000000_00000_00000_0000000000000000;
		mem[12] = 32'b 000000_00000_00000_0000000000000000;
		mem[13] = 32'b 000000_00000_00000_0000000000000000;
		mem[14] = 32'b 000000_00000_00000_0000000000000000;
		mem[15] = 32'b 000000_00000_00000_0000000000000000;
		mem[16] = 32'b 000000_00000_00000_0000000000000000;
	end
```

所以对应的操作就是

- 7与寄存器堆地址00000的寄存器的数值相加，结果访问内存7号也就是数值10(A)，存入寄存器堆地址00000的寄存器
- 15与寄存器堆地址00001的寄存器的数值相加，结果访问内存15(F)号也就是数值18(12)，存入寄存器堆地址00001的寄存器
- 寄存器堆地址00000的寄存器的数值10(A)与寄存器堆地址00001的寄存器的数值18(12)相加，将结果28(1C)存入寄存器堆地址00000的寄存器

进行仿真，发现结果完全正确

![捕获7](D:\大三上\汇编与接口\project\捕获7.JPG)

之后的指令全部为0，对应的理解就是将寄存器堆地址00000的寄存器的数值与自身相加再放回寄存器堆地址00000的寄存器，从结果上看就是每隔一个时钟周期寄存器堆地址00000的寄存器的数值x2，也和仿真的结果相对应上了

----------------------

总结一下这次仿真我遇到的问题：

1. 编写汇编代码没有仔细考虑，比如第一次修改指令时这样写

```
assign mem[0] = 32'b 100011_00000_00000_0000000000000000;
assign mem[1] = 32'b 100011_00000_00001_0000000000000000;
assign mem[2] = 32'b 000000_00001_00010_0000000000000000;
```

导致指令1执行的时候寄存器堆00000的数值就不再是0了，从而访问内存时取到的数就和预期的不一致

2. 只考虑了自己代码编写和连线有没有问题，而没有充分考虑硬件上的问题，比如仿真时机器的时钟周期设置过短；没有考虑到FPGA端口数目的限制

## 测试II：SW

在测试I的基础上改动

```
initial begin
		mem[0] = 32'b 000000_00000_00000_0000000000000000;
		mem[1] = 32'b 100011_00000_00000_0000000000000111;
		mem[2] = 32'b 100011_00001_00001_0000000000001111;
		mem[3] = 32'b 000000_00000_00001_0000000000000000;
		mem[4] = 32'b 101011_00010_00000_0000000000000000;
		mem[5] = 32'b 000000_00000_00000_0000000000000000;
		mem[6] = 32'b 101011_00010_00000_0000000000000001;
		mem[7] = 32'b 000000_00000_00000_0000000000000000;
		mem[8] = 32'b 101011_00010_00000_0000000000000010;
		mem[9] = 32'b 000000_00000_00000_0000000000000000;
		mem[10] = 32'b 101011_00010_00000_0000000000000011;
		mem[11] = 32'b 100011_00010_00000_0000000000000010;
		mem[12] = 32'b 100011_00010_00001_0000000000000011;
		mem[13] = 32'b 000000_00000_00001_0000000000000000;
		mem[14] = 32'b 000000_00000_00000_0000000000000000;
		mem[15] = 32'b 000000_00000_00000_0000000000000000;
		mem[16] = 32'b 000000_00000_00000_0000000000000000;
	end
```

前三条与原先相同，从第四条开始：

- 第四条，第六条，...，第十条，将不断翻倍的数据依次存入内存中(因为00010的寄存器没有被写入依然是0)，
- 第11条和第12条将内存第2，3(也就是指令第8，10条存入的数据)加载至寄存器00000，00001中
- 第13条进行寄存器00000，00001相加

这次的仿真非常顺利(除了第一次又把汇编写错了导致出现了奇怪的结果，不过很快又排查出了错误完成了测试)

![捕获8+](D:\大三上\汇编与接口\project\捕获8+.png)

## 测试III：J

在测试II的基础上改动

```
initial begin
		mem[0] = 32'b 000000_00000_00000_0000000000000000;
		mem[1] = 32'b 100011_00000_00000_0000000000000111;
		mem[2] = 32'b 100011_00001_00001_0000000000001111;
		mem[3] = 32'b 000000_00000_00001_0000000000000000;
		mem[4] = 32'b 000010_00000_00000_0000000000000001;
		mem[5] = 32'b 000000_00000_00000_0000000000000000;
		mem[6] = 32'b 101011_00010_00000_0000000000000001;
		mem[7] = 32'b 000000_00000_00000_0000000000000000;
		mem[8] = 32'b 101011_00010_00000_0000000000000010;
		mem[9] = 32'b 000000_00000_00000_0000000000000000;
		mem[10] = 32'b 101011_00010_00000_0000000000000011;
		mem[11] = 32'b 100011_00010_00000_0000000000000010;
		mem[12] = 32'b 100011_00010_00001_0000000000000011;
		mem[13] = 32'b 000000_00000_00001_0000000000000000;
		mem[14] = 32'b 000000_00000_00000_0000000000000000;
		mem[15] = 32'b 000000_00000_00000_0000000000000000;
		mem[16] = 32'b 000000_00000_00000_0000000000000000;
	end
```

将指令4改为强制跳转至指令1，如果J指令有效，则会循环执行测试I而不是测试II

然后运行仿真，发现结果不对(因为寄存器0和寄存器1里的值变了)，算了一下给的内存太小了内存地址溢出，改动一下...

```
initial begin
		mem[0] = 32'b 000000_00000_00000_0000000000000000;
		mem[1] = 32'b 100011_00010_00000_0000000000000111;
		mem[2] = 32'b 100011_00010_00001_0000000000001111;
		mem[3] = 32'b 000000_00000_00001_0000000000000000;
		mem[4] = 32'b 000010_00000_00000_0000000000000001;
		mem[5] = 32'b 000000_00000_00000_0000000000000000;
		mem[6] = 32'b 101011_00010_00000_0000000000000001;
		mem[7] = 32'b 000000_00000_00000_0000000000000000;
		mem[8] = 32'b 101011_00010_00000_0000000000000010;
		mem[9] = 32'b 000000_00000_00000_0000000000000000;
		mem[10] = 32'b 101011_00010_00000_0000000000000011;
		mem[11] = 32'b 100011_00010_00000_0000000000000010;
		mem[12] = 32'b 100011_00010_00001_0000000000000011;
		mem[13] = 32'b 000000_00000_00001_0000000000000000;
		mem[14] = 32'b 000000_00000_00000_0000000000000000;
		mem[15] = 32'b 000000_00000_00000_0000000000000000;
		mem[16] = 32'b 000000_00000_00000_0000000000000000;
	end
```

然后仿真结果就很合理了

![捕获9](D:\大三上\汇编与接口\project\捕获9.JPG)

可以看到周期性的重复

-------------------------

# 更多的指令



# 心得

我发现我以前的认知是有问题的而且在一些细节问题上是模糊的，首先看到单周期CPU以为是每个部件都由CLK驱动，但是真正开始写这个的时候发现不对劲，他们之间不会冲突吗，还有比如LW里就包含了加法运算，为什么他们都可以在同一个周期内完成，LW完成的时间不应该比ADD长吗，所以当时我就怀疑人生了：这单周期CPU的单周期真的是指机器周期吗，如果是的话为什么现在都是多周期CPU，讲道理单周期每条指令执行的时间不是更短更有优势吗

带着这些问题，我重新看数据通路才想明白了，只有PC和写入数据才是被CLK驱动，其他部件在各自输入的电平改变时才运作，所以只要把它们在顶层连接起来，在一个周期内给予特定的指令，就可以自动完成，

当然这个自动是有原因的，首先之所以能在一个周期内完成，是因为PC是时序的而译码ALU写回都是组合逻辑，其次必须是哈弗架构，因为LWSW需要一个单独的周期(存储器必须要在时钟上升沿才能加载或输出)，所以必须把指令与数据分开，通过双总线才能在CLK上升沿并行的完成，单总线的应该是无法在一个周期内完成LWSW指令的

在高低电平触发后微操作之间是顺序(考虑元件的延时)的，但他们都在CLK的水平沿之内完成，这也就是为什么CPU频率不能无限提高，一旦水平沿的宽度小于这些微操作累计的时间，就会发生崩坏。然后这样想也解决了后面的问题，就所以执行微指令的时间的和来说LW应该确确实实比比ADD长，但是他们都是在CLK的水平沿完成的都算在一个周期内



我体会到了CPU中组合电路与时序电路的巧妙结合