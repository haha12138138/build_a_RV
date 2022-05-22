
`timescale 1ns/1ps

module tb_RV_top (); /* this is automatically generated */

	// clock
	logic clk;
	initial begin
		clk = '0;
		forever #(0.5) clk = ~clk;
	end

	// synchronous reset
		logic        rst_n;

	initial begin
		rst_n <= '0;
		repeat(1)@(posedge clk);
		rst_n <= '1;
	end

	// (*NOTE*) replace reset, clock, others

	logic        IMemAddress_vld;
	logic [31:0] IMemAddress;
	logic        IMemAddress_rsp;
	logic [31:0] IMemReadData;
	logic        IMemData_rsp;
	logic        DMemAddress_vld;
	logic [31:0] DMemAddress;
	logic        DMemAddress_rsp;
	logic        DMemWData_vld;
	logic [31:0] DMemReadData;
	logic [31:0] DMemWriteData;
	logic        DMemData_rsp;
	logic        DMemOp;
    logic [1:0]  DMemOpSize;
	RV_top inst_RV_top
		(
			.clk             (clk),
			.rst_n           (rst_n),
			.IMemAddress_vld (IMemAddress_vld),
			.IMemAddress     (IMemAddress),
			.IMemAddress_rsp (IMemAddress_rsp),
			.IMemReadData    (IMemReadData),
			.IMemData_rsp    (IMemData_rsp),
			.DMemAddress_vld (DMemAddress_vld),
			.DMemAddress     (DMemAddress),
			.DMemOp          (DMemOp),
			.DMemOpSize      (DMemOpSize),
			.DMemAddress_rsp (DMemAddress_rsp),
			.DMemWData_vld   (DMemWData_vld),
			.DMemReadData    (DMemReadData),
			.DMemWriteData   (DMemWriteData),
			.DMemData_rsp    (DMemData_rsp)
		);
    	RV_Mem inst_RV_IMem (
			.clk            (clk),
			.rst_n          (rst_n),
			.MemAddress_vld (IMemAddress_vld),
			.MemAddress     (IMemAddress),
			.MemOp          (1'b0),
			.MemOpSize      (2'b11),
			.MemAddress_rsp (IMemAddress_rsp),
			.MemWData_vld   (1'b0),
			.MemReadData    (IMemReadData),
			.MemWriteData   (0),
			.MemData_rsp    (IMemData_rsp)
		);
    	RV_Mem #(
			.FILE("D:\\codes\\verilog\\RHBD_IP\\RV\\C_Code\\d.verilog")
		) inst_RV_DMem (
			.clk            (clk),
			.rst_n          (rst_n),
			.MemAddress_vld (DMemAddress_vld),
			.MemAddress     (DMemAddress-32'h1000),
			.MemOp          (DMemOp),
			.MemOpSize      (DMemOpSize),
			.MemAddress_rsp (DMemAddress_rsp),
			.MemWData_vld   (DMemWData_vld),
			.MemReadData    (DMemReadData),
			.MemWriteData   (DMemWriteData),
			.MemData_rsp    (DMemData_rsp)
		);
int base,i;
	initial begin
	i=0;
	base=16;
	while(1) begin
		@(negedge clk);
		$display("--------@ cycle %d-----------",i);
		$display("Currently Decoding= %h @%h ",inst_RV_top.inst_RVdecode.Inst_hold, inst_RV_top.inst_RV_Fetch.PC);
		$display("Currently Exec    = %h ,WBEN= %h",inst_RV_top.ExecInst, inst_RV_top.isExecReqWB);
		$display("--------Reg Status-----------");
		$display("ra=%h, sp=%h, gp=%h, tp=%h"	,inst_RV_top.inst_RV_Regfile.regfile[1]
											 	,inst_RV_top.inst_RV_Regfile.regfile[2]
											 	,inst_RV_top.inst_RV_Regfile.regfile[3]
											 	,inst_RV_top.inst_RV_Regfile.regfile[4]);
		$display("t0=%h, t1=%h, t2=%h, s0=%h"	,inst_RV_top.inst_RV_Regfile.regfile[5]
											 	,inst_RV_top.inst_RV_Regfile.regfile[6]
											 	,inst_RV_top.inst_RV_Regfile.regfile[7]
											 	,inst_RV_top.inst_RV_Regfile.regfile[8]);
		$display("s1=%h, a0=%h, a1=%h, a2=%h"	,inst_RV_top.inst_RV_Regfile.regfile[9]
											 	,inst_RV_top.inst_RV_Regfile.regfile[10]
											 	,inst_RV_top.inst_RV_Regfile.regfile[11]
											 	,inst_RV_top.inst_RV_Regfile.regfile[12]);
		$display("a3=%h, a4=%h, a5=%h, a6=%h"	,inst_RV_top.inst_RV_Regfile.regfile[13]
											 	,inst_RV_top.inst_RV_Regfile.regfile[14]
											 	,inst_RV_top.inst_RV_Regfile.regfile[15]
											 	,inst_RV_top.inst_RV_Regfile.regfile[16]);
		$display("a7=%h, s2=%h, s3=%h, s4=%h"	,inst_RV_top.inst_RV_Regfile.regfile[17]
											 	,inst_RV_top.inst_RV_Regfile.regfile[18]
											 	,inst_RV_top.inst_RV_Regfile.regfile[19]
											 	,inst_RV_top.inst_RV_Regfile.regfile[20]);
		$display("s5=%h, s6=%h, s7=%h, s8=%h"	,inst_RV_top.inst_RV_Regfile.regfile[21]
											 	,inst_RV_top.inst_RV_Regfile.regfile[22]
											 	,inst_RV_top.inst_RV_Regfile.regfile[23]
											 	,inst_RV_top.inst_RV_Regfile.regfile[24]);
		$display("s9=%h, s10=%h, s11=%h, t3=%h" ,inst_RV_top.inst_RV_Regfile.regfile[25]
											 	,inst_RV_top.inst_RV_Regfile.regfile[26]
											 	,inst_RV_top.inst_RV_Regfile.regfile[27]
											 	,inst_RV_top.inst_RV_Regfile.regfile[28]);
		$display("t4=%h, t5=%h, t6=%h        "	,inst_RV_top.inst_RV_Regfile.regfile[29]
											 	,inst_RV_top.inst_RV_Regfile.regfile[30]
											 	,inst_RV_top.inst_RV_Regfile.regfile[31]);
		$display("--------Mem Status-----------");
		$display("arr1 = ");
		base=16;
		$display("%h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h"
			     ,inst_RV_DMem.mem[base+0],inst_RV_DMem.mem[base+1],inst_RV_DMem.mem[base+2],inst_RV_DMem.mem[base+3]
			     ,inst_RV_DMem.mem[base+4],inst_RV_DMem.mem[base+5],inst_RV_DMem.mem[base+6],inst_RV_DMem.mem[base+7]
			     ,inst_RV_DMem.mem[base+8],inst_RV_DMem.mem[base+9],inst_RV_DMem.mem[base+10],inst_RV_DMem.mem[base+11]
			     ,inst_RV_DMem.mem[base+12],inst_RV_DMem.mem[base+13],inst_RV_DMem.mem[base+14],inst_RV_DMem.mem[base+15]);
		base=32;
		$display("arr2 = ");
		$display("%h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h"
			     ,inst_RV_DMem.mem[base+0],inst_RV_DMem.mem[base+1],inst_RV_DMem.mem[base+2],inst_RV_DMem.mem[base+3]
			     ,inst_RV_DMem.mem[base+4],inst_RV_DMem.mem[base+5],inst_RV_DMem.mem[base+6],inst_RV_DMem.mem[base+7]
			     ,inst_RV_DMem.mem[base+8],inst_RV_DMem.mem[base+9],inst_RV_DMem.mem[base+10],inst_RV_DMem.mem[base+11]
			     ,inst_RV_DMem.mem[base+12],inst_RV_DMem.mem[base+13],inst_RV_DMem.mem[base+14],inst_RV_DMem.mem[base+15]);
		base=48;
		$display("arr3 = ");
		$display("%h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h"
			     ,inst_RV_DMem.mem[base+0],inst_RV_DMem.mem[base+1],inst_RV_DMem.mem[base+2],inst_RV_DMem.mem[base+3]
			     ,inst_RV_DMem.mem[base+4],inst_RV_DMem.mem[base+5],inst_RV_DMem.mem[base+6],inst_RV_DMem.mem[base+7]
			     ,inst_RV_DMem.mem[base+8],inst_RV_DMem.mem[base+9],inst_RV_DMem.mem[base+10],inst_RV_DMem.mem[base+11]
			     ,inst_RV_DMem.mem[base+12],inst_RV_DMem.mem[base+13],inst_RV_DMem.mem[base+14],inst_RV_DMem.mem[base+15]);
		$display("-----------------------------");
		i=i+1;
		@(posedge clk);
	end 
end 

	initial begin
		// do something
		repeat(3000)@(posedge clk);
		$stop;
	end
endmodule
