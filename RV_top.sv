import RV_pkg::*;

module RV_top (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	output logic 		IMemAddress_vld,
	output logic[31:0] 	IMemAddress,
	input  logic  	    IMemAddress_rsp,
	input  logic[31:0]	IMemReadData,
	input  logic 		IMemData_rsp,
	output logic 		DMemAddress_vld,
	output logic [31:0]	DMemAddress,
	output logic        DMemOp,
	output logic [1:0]  DMemOpSize,
	input  logic		DMemAddress_rsp,
	output logic		DMemWData_vld,
	input  logic [31:0]	DMemReadData,
	output logic [31:0]	DMemWriteData,
	input  logic 		DMemData_rsp
);
OperandType PC;
RV32InstType Inst;
logic  isInstValid;
logic FetchStall;
logic FetchJump;
OperandType TargetPC;
logic       isDecodeReqExec;
DecodeCtrlType DecodeOut;
OperandType DecodeSrc1;
OperandType DecodeSrc2;
ImmType     Imm;
logic       ExecStall;
ExecBrRetType BranchPredResult;
RegReadPortType RegSrc1;
RegReadPortType RegSrc2;
logic isExecReqWB;
RegWritePortType ExecResult;

RV_Fetch inst_RV_Fetch
	(
		.clk         (clk),
		.rst_n       (rst_n),
		.PC          (PC),
		.Inst        (Inst),
		.isInstValid (isInstValid),
		.FetchStall  (FetchStall),
		.FetchJump   (FetchJump),
		.TargetPC    (TargetPC),
		.Address_vld (IMemAddress_vld),
		.Address     (IMemAddress),
		.Address_rsp (IMemAddress_rsp),
		.WData_vld   (),
		.ReadData    (IMemReadData),
		.WriteData   (),
		.Data_rsp    (IMemData_rsp)
	);
RVdecode inst_RVdecode
	(
		.clk              (clk),
		.rst_n            (rst_n),
		.PC               (PC),
		.Inst             (Inst),
		.isInstValid      (isInstValid),
		.FetchStall       (FetchStall),
		.FetchJump        (FetchJump),
		.TargetPC         (TargetPC),
		.isDecodeReqExec  (isDecodeReqExec),
		.DecodeOut        (DecodeOut),
		.DecodeSrc1       (DecodeSrc1),
		.DecodeSrc2       (DecodeSrc2),
		.Imm              (Imm),
		.ExecStall        (ExecStall),
		.BranchPredResult (BranchPredResult),
		.RegSrc1          (RegSrc1),
		.RegSrc2          (RegSrc2)
	);
RV_Exec inst_RV_Exec
	(
		.clk              (clk),
		.rst_n            (rst_n),
		.ExecReq          (isDecodeReqExec),
		.DecodeCtrl       (DecodeOut),
		.DecodeSrc1       (DecodeSrc1),
		.DecodeSrc2       (DecodeSrc2),
		.Imm              (Imm),
		.ExecStall        (ExecStall),
		.BranchPredResult (BranchPredResult),
		.isExecReqWB      (isExecReqWB),
		.ExecResult       (ExecResult),
		.Address_vld      (DMemAddress_vld),
		.MemAddress_o     (DMemAddress),
		.MemOp            (DMemOp),
		.MemOpSize        (DMemOpSize),
		.Address_rsp      (DMemAddress_rsp),
		.WData_vld        (DMemWData_vld),
		.ReadData_o       (DMemReadData),
		.WriteData_o      (DMemWriteData),
		.Data_rsp         (DMemData_rsp)
	);
RV_Regfile inst_RV_Regfile
	(
		.clk                 (clk),
		.rst_n               (rst_n),
		.DecodeRegReadCtrl1  (DecodeOut.regread1),
		.DecodeRegReadCtrl2  (DecodeOut.regread2),
		.DecodeRegWriteCtrl1 (DecodeOut.regwrite1),
		.ExecResultBypass    (ExecResult),
		.DecodeRegReadData1  (RegSrc1),
		.DecodeRegReadData2  (RegSrc2)
	);


RV32InstType ExecInst;
integer i;
always_ff @(posedge clk or negedge rst_n) begin : proc_ExecInst
	if(~rst_n) begin
		ExecInst <= 0;
	end else if (!ExecStall)begin
		ExecInst <= inst_RVdecode.Inst_hold;
	end
end

endmodule : RV_top