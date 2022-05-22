
`timescale 1ns/1ps
import RV_pkg::*;

module tb_RVdecode (); /* this is automatically generated */

	// clock
	logic clk;
	initial begin
		clk = '0;
		forever #(0.5) clk = ~clk;
	end

	// synchronous reset
	logic  rst_n;
	initial begin
		rst_n=0;
		@(posedge clk);
		rst_n=1;
	end
	// (*NOTE*) replace reset, clock, others

	OperandType PC;
	RV32InstType Inst;
	logic  isInstValid;
	logic  FetchStall;
	logic  FetchJump;
	OperandType TargetPC;
	DecodeCtrlType DecodeOut;
	OperandType DecodeSrc1;
	OperandType DecodeSrc2;
	ImmType Imm;
	logic  ExecStall;
	ExecBrRetType BranchPredResult;
	RegReadPortType RegSrc1;
	RegReadPortType RegSrc2;
    RV32InstType Inst_Exec;
    logic Address_vld,Data_rsp;
    logic [31:0] Address;
    logic [31:0] ReadData;
    always_ff @(posedge clk or negedge rst_n) begin : proc_Inst_exec
    	if(~rst_n) begin
    		Inst_Exec <= 0;
    	end else if(!ExecStall) begin
    		Inst_Exec <= (inst_RVdecode.BubbleEnable)?0:inst_RVdecode.Inst_hold;
    	end
    end
	RVdecode inst_RVdecode
		(
			.clk              (clk),
			.rst_n            (rst_n),
			.PC               (PC),
			.Inst             (Inst),
			.isInstValid      (isInstValid),
			.FetchStall       (FetchStall),
			.FetchJump        (FetchJump),
			.TargetPC         (),
			.DecodeOut        (DecodeOut),
			.DecodeSrc1       (DecodeSrc1),
			.DecodeSrc2       (DecodeSrc2),
			.Imm              (Imm),
			.ExecStall        (ExecStall),
			.BranchPredResult (BranchPredResult),
			.RegSrc1          (RegSrc1),
			.RegSrc2          (RegSrc2)
		);
		RV_Fetch inst_RV_Fetch (
			.clk         (clk),
			.rst_n       (rst_n),
			.PC          (PC),
			.Inst        (Inst),
			.isInstValid (isInstValid),
			.FetchStall  (FetchStall),
			.FetchJump   (FetchJump),
			.TargetPC    (PC+4),
			.Address_vld (Address_vld),
			.Address     (Address),
			.Address_rsp (1'b1),
			.WData_vld   (),
			.ReadData    (ReadData),
			.WriteData   (),
			.Data_rsp    (Data_rsp)
		);

	logic [7:0] mem[255:0];
	OperandType Address_t;
	logic Address_vld_t;
	initial begin
		$readmemh("D:\\codes\\verilog\\cortex M0\\v1\\ARM_M0_V1_2022\\RHBD_IP\\RV\\a.txt",mem);
	end
	always_ff @(posedge clk or negedge rst_n) begin : proc_Address_t
		if(~rst_n) begin
			Address_t <= 0;
			Address_vld_t<=0;
		end else begin
			Address_t <= PC;
			Address_vld_t=Address_vld;
		end
	end
	always_ff @(*) begin : proc_mem
		if(Address_vld_t ==0) begin
			ReadData='bx;
			Data_rsp=0;
		end else begin
			ReadData={mem[Address_t+3],mem[Address_t+2],mem[Address_t+1],mem[Address_t]};
			Data_rsp=1;
		end
	end
	task plain_march;
	begin
		// isInstValid=1;
		
		BranchPredResult.newBrTarget=0;
		BranchPredResult.isBrPredCorrect=1;
		RegSrc2.PhyRegReadData=3;
		RegSrc2.isRegAvailable=1'b1;
		RegSrc1.PhyRegReadData=1;
		RegSrc1.isRegAvailable=1'b1;
		ExecStall  =0;
    			while(1) begin
    				#0.1;
    				if(DecodeOut.memop!=MemOpNone) begin
    						@(posedge clk);
    						ExecStall  =1;// calc address
    						@(posedge clk);
    						@(posedge clk);
    						ExecStall  =1;// send req
    						@(posedge clk);
    						ExecStall  =0;//rcv request
    					end else begin
    						@(posedge clk);
    					end 
    				end 
		// @(posedge clk);
		// for(int i=0;i<255;i=i+4) begin
		// 	PC=i;
		// 	isInstValid=0;
		// 	Inst='bx;
		// 	@(posedge clk);
		// 	isInstValid=1;
		// 	Inst={mem[PC+3],mem[PC+2],mem[PC+1],mem[PC]};
		// 	#0.1;
		// 	while((FetchStall!=0)&&(FetchJump==0)) begin
		// 		@(posedge clk);
		// 		isInstValid=0;
		// 		#0.1;
		// 	end 
		// 	@(posedge clk);
		// end // for(int i=0;i<48;i++)
	end
    endtask

	initial begin
		// do something
		fork
			begin
				plain_march();
			end

			begin
				repeat(1000)@(posedge clk);
			end
		join_any
		

		repeat(10)@(posedge clk);
		$stop;
	end


endmodule
