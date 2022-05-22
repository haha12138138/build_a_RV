import RV_pkg::*;
module RV_Exec (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input logic         ExecReq,
	input DecodeCtrlType DecodeCtrl,
	input OperandType DecodeSrc1,
	input OperandType DecodeSrc2,
	input ImmType	  Imm,
	// back to decode
	output logic ExecStall,
	output ExecBrRetType BranchPredResult,
    // to WB
    output logic isExecReqWB,
    output RegWritePortType ExecResult,
    // D Memory
    output logic Address_vld,
	output logic [31:0]MemAddress_o,
	output logic MemOp,
	output logic [1:0] MemOpSize,
	input  logic Address_rsp,
	output logic WData_vld,
	input  logic [31:0]ReadData_o,
	output logic [31:0]WriteData_o,
	input  logic Data_rsp
);
typedef logic[32:0] ArithTempType;
//alu logic
// LT,EQ,GE,NE ... will use result from ExecArithOp
function OperandType ExecLogicOp(DecodeCtrlType Ctrl
	                             , OperandType Op1
	                             , ArithTempType ArithResult
	                             , OperandType Op2
	                             , ImmType     Imm);
	// from Imm or from Op
	automatic OperandType MuxedOp2;
	MuxedOp2 = (Ctrl.isSrc2Imm)?OperandType'(Imm):Op2;
	case (AluLogicOpType'(Ctrl.alufunc))
		AND: begin
			ExecLogicOp=Op1&MuxedOp2;
		end 
		OR : begin
			ExecLogicOp=Op1|MuxedOp2;
		end 
		XOR: begin
			ExecLogicOp=Op1^MuxedOp2;
		end 
		EQ: begin
			ExecLogicOp=!(|(ArithResult));
		end 
		NE: begin
			ExecLogicOp=|(ArithResult);
		end 
		LT: begin
			if(Ctrl.isSrc1Unsign==0) begin// signed number
				// first determine whether 2 operand have the same sign
				if(Op1[$bits(Op1)-1] == MuxedOp2[$bits(MuxedOp2)-1]) begin
					// if they are the same, then we check if Arith Result have the same sign
					// if it has the same sign, Op1 > Op2
					ExecLogicOp=!((Op1[$bits(Op1)-1])==ArithResult[$bits(Op1)-1]);
				end else begin
					// if the sign is defferent, if Op1 is negative then the result is true.
					ExecLogicOp=(Op1[$bits(Op1)-1]);
				end
			end else begin // unsigned number
				ExecLogicOp=ArithResult[$bits(ArithResult)-1];
			end
		end 
		GE: begin
			if(Ctrl.isSrc1Unsign==0) begin// signed number
				// first determine whether 2 operand have the same sign
				if(Op1[$bits(Op1)-1] == MuxedOp2[$bits(MuxedOp2)-1]) begin
					// if they are the same, then we check if Arith Result have the same sign
					// if it has the same sign, Op1 > Op2
					ExecLogicOp=((Op1[$bits(Op1)-1])==ArithResult[$bits(ArithResult)-1]);
				end else begin
					// if the sign is defferent, if Op1 is negative then the result is true.
					ExecLogicOp=!(Op1[$bits(Op1)-1]);
				end
			end else begin // unsigned number
				ExecLogicOp=!ArithResult[$bits(ArithResult)-1];
			end
		end
	    default: begin
	    	ExecLogicOp = 0;
	    end 
	endcase
endfunction : ExecLogicOp

function ArithTempType ExecArithOp(DecodeCtrlType Ctrl
	                             , OperandType Op1
	                             , OperandType Op2
	                             , ImmType     Imm);
	// from Imm or from Op
	automatic OperandType MuxedOp2;
	MuxedOp2 = (Ctrl.isSrc2Imm)?OperandType'(Imm):Op2;
	case(AluArithOpType'(Ctrl.alufunc))
		PASS: begin
			ExecArithOp=MuxedOp2;
		end 
		ADD: begin
			ExecArithOp={1'b0,Op1}+{1'b0,MuxedOp2};
		end 
		default: begin
			ExecArithOp={1'b0,Op1}+(~{1'b0,MuxedOp2})+1'b1;
		end 
	endcase // AluArithOpType'(Ctrl.alufunc)
endfunction : ExecArithOp

function OperandType ExecShiftOp(DecodeCtrlType Ctrl
	                             , OperandType Op1
	                             , OperandType Op2
	                             , ImmType     Imm);

	automatic OperandType MuxedOp2;
	MuxedOp2 = (Ctrl.isSrc2Imm)?OperandType'(Imm):Op2;

	case(AluShiftOpType'(Ctrl.alufunc))
		SLL: begin
			ExecShiftOp=Op1<<MuxedOp2[4:0];
		end 
		SRL : begin
			ExecShiftOp=Op1>>MuxedOp2[4:0];
		end 
		SRA: begin
			ExecShiftOp=$signed(Op1)>>>MuxedOp2[4:0];
		end 
		default: begin
			ExecShiftOp=Op1;
		end 
	endcase // AluShiftOpType'(Ctrl.alufunc)
endfunction : ExecShiftOp


logic LSU_RegWriteEnable, isLSU_LdSigned;
ArithTempType ArithRes;
OperandType ShiftRes,LogicRes,LDRes;
MemReadPortType LSU_ReturnData;

logic ExecReq_t;
DecodeCtrlType DecodeCtrl_t;
OperandType DecodeSrc2_t,DecodeSrc1_t;
ImmType Imm_t;
always_ff @(posedge clk or negedge rst_n) begin : proc_pipe
	if(~rst_n) begin
		 ExecReq_t <= 0;
		 DecodeCtrl_t<= '0;
		 DecodeSrc2_t<='0;
		 DecodeSrc1_t<='0;
		 Imm_t <='0;
	end else if(!ExecStall)begin
		 ExecReq_t <=ExecReq;
		 DecodeCtrl_t<= DecodeCtrl;
		 DecodeSrc2_t<=DecodeSrc2;
		 DecodeSrc1_t<=DecodeSrc1;
		 Imm_t <=Imm;
	end
end
assign ArithRes=ExecArithOp(DecodeCtrl_t, DecodeSrc1_t, DecodeSrc2_t, Imm_t);
assign ShiftRes=ExecShiftOp(DecodeCtrl_t, DecodeSrc1_t, DecodeSrc2_t, Imm_t);
assign LogicRes=ExecLogicOp(DecodeCtrl_t, DecodeSrc1_t, ArithRes, DecodeSrc2_t, Imm_t);
assign BranchPredResult.isBrPredCorrect= !LogicRes[0];
assign BranchPredResult.newBrTarget    =ArithRes[31:0];
assign ExecStall=((DecodeCtrl_t.alusel == SelAluLSU)&ExecReq_t)? !LSU_ReturnData.MemOpDone:1'b0;
assign LSU_RegWriteEnable=(LSU_ReturnData.MemOpDone)&
						  (
						  	(DecodeCtrl_t.memop==MemOpRead)|
						  	(DecodeCtrl_t.memop==MemOpReadUnsigned)
						   );
assign isLSU_LdSigned = DecodeCtrl_t.memop == MemOpRead;
assign isExecReqWB   =ExecResult.WriteCtrl.RegEnable;
always_comb begin
	ExecResult.WriteCtrl.RegAddr=DecodeCtrl_t.regwrite1.RegAddr;
	case (DecodeCtrl_t.alusel)
		SelAluArith: begin
			ExecResult.PhyRegWriteData =ArithRes[31:0];
		end 
		SelAluLogic: begin
			ExecResult.PhyRegWriteData =LogicRes;
		end 
		SelAluShift: begin
			ExecResult.PhyRegWriteData =ShiftRes;
		end 
		default:     begin
			ExecResult.PhyRegWriteData =LDRes;
		end 
	endcase
end
always_comb begin 
	if((ExecReq_t == 0) | (DecodeCtrl_t.regwrite1.RegAddr==0)) begin
		// ignore this result if nop or write to x0
		ExecResult.WriteCtrl.RegEnable=0;
	end else begin
		if (DecodeCtrl_t.alusel!=SelAluLSU) begin
			ExecResult.WriteCtrl.RegEnable= DecodeCtrl_t.regwrite1.RegEnable;
		end else begin
			ExecResult.WriteCtrl.RegEnable= LSU_RegWriteEnable;
		end
	end
end


always_comb begin
	case (DecodeCtrl_t.memsize)
		ByteTrans: begin
			case(ArithRes[1:0])
				0: begin
					LDRes={{24{isLSU_LdSigned&LSU_ReturnData[7]}},LSU_ReturnData[7:0]};
				end 
				1: begin
					LDRes={{24{isLSU_LdSigned&LSU_ReturnData[15]}},LSU_ReturnData[15:8]};
				end 
				2: begin
					LDRes={{24{isLSU_LdSigned&LSU_ReturnData[23]}},LSU_ReturnData[23:16]};
				end 
				default: begin
					LDRes={{24{isLSU_LdSigned&LSU_ReturnData[31]}},LSU_ReturnData[31:24]};
				end 
			endcase // ArithRes[1:0]
		end // ByteTrans:
		HalfWTrans: begin
			case(ArithRes[1])
				0: begin
					LDRes={{16{isLSU_LdSigned&LSU_ReturnData[15]}},LSU_ReturnData[15:0]};
				end 
				default: begin
					LDRes={{16{isLSU_LdSigned&LSU_ReturnData[31]}},LSU_ReturnData[31:16]};
				end 
			endcase // ArithRes[1]
		end // HalfWTrans:
		default : begin // WordTrans
			LDRes=LSU_ReturnData[31:0];
		end
	endcase //(DecodeCtrl_t.memsize
end // always_comb
	RV_LSU inst_RV_LSU
		(
			.clk          (clk),
			.rst_n        (rst_n),
			.ExecReq      (ExecReq_t),
			.DecodeCtrl   (DecodeCtrl_t),
			.MemAddress   (ArithRes[31:0]),
			.MemWData     (DecodeSrc2_t),
			.MemReadPort  (LSU_ReturnData),
			.Address_vld  (Address_vld),
			.MemAddress_o (MemAddress_o),
			.Address_rsp  (Address_rsp),
			.MemOp        (MemOp),
			.MemOpSize    (MemOpSize),
			.WData_vld    (WData_vld),
			.ReadData_o   (ReadData_o),
			.WriteData_o  (WriteData_o),
			.Data_rsp     (Data_rsp)
		);

endmodule : RV_Exec