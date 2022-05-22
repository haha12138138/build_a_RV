import RV_pkg::*;
	// `define SignExt(FINAL_WID,CURR_WID,x) {{(FINAL_WID-CURR_WID){x[CURR_WID-1]}},x}
	//`define UnSignExt(FINAL_WID,CURR_WID,x) {{(FINAL_WID-CURR_WID){1'b0}},x}
module RVdecode (
	input clk,    // Clock
	input rst_n,
	// Fetch stage
	input OperandType PC,
	input RV32InstType Inst,
	input isInstValid,
	output logic FetchStall,
	output logic FetchJump,
	output OperandType TargetPC,
	//Exec and Reg
	output logic          isDecodeReqExec,
	output DecodeCtrlType DecodeOut,
	output OperandType DecodeSrc1,
	output OperandType DecodeSrc2,
	output ImmType     Imm,
	// From Exec
	input ExecStall,
	input ExecBrRetType BranchPredResult,
	// From RegFile
	input RegReadPortType RegSrc1,// forward logic included in RegisterFile
	input RegReadPortType RegSrc2
);
function DecodeCtrlType decSType(RV32InstType Inst, logic[1:0] microcode_state);
	    automatic logic[2:0] func3=Inst[14:12];
	    automatic DecodeCtrlType temp;
		temp.isSrc1Unsign=1'b1;
		temp.isSrc2Unsign=1'b1;
		temp.isSrc2Imm   =1'b1; 
		temp.alusel=SelAluLSU;
		temp.alufunc=AluFuncType'(ADD);
		temp.memop = MemOpWrite;
		casex (func3)
			3'bx00:  // only 000 valid
				temp.memsize = ByteTrans;
			3'bx01:  // only 001 valid
				temp.memsize = HalfWTrans;
			default : 
				temp.memsize = WordTrans;
		endcase
		
		temp.regread1={1'b1,Inst[19:15]};
		temp.regread2={1'b1,Inst[24:20]};
		temp.regwrite1={1'b0,Inst[11:7]};
		temp.src1select=SelRs; 
		decSType=temp;
endfunction : decSType
function DecodeCtrlType decRType(RV32InstType Inst, logic[1:0] microcode_state);
		automatic logic[2:0] func3=Inst[14:12];
		automatic DecodeCtrlType temp;
		temp.isSrc1Unsign=func3[0];// only used in LT
		temp.isSrc2Unsign=func3[0];// only used in LT
		temp.isSrc2Imm   =1'b0;
		temp.memop = MemOpNone;
		temp.memsize = ByteTrans;
		casex(func3)
			3'b000: begin
				temp.alusel=SelAluArith;
				temp.alufunc=(Inst[30])? AluFuncType'(SUB):AluFuncType'(ADD);
			end // 3'b000:
			3'b01x: begin
				temp.alusel=SelAluLogic;
				temp.alufunc=AluFuncType'(LT);
			end // 3'b01x:
			3'b100: begin
				temp.alusel=SelAluLogic;
				temp.alufunc=AluFuncType'(XOR);
			end 
			3'b001: begin
				temp.alusel=SelAluShift;
				temp.alufunc=AluFuncType'(SLL);
			end 
			3'b101: begin
				temp.alusel=SelAluShift;
				temp.alufunc=(Inst[30])?AluFuncType'(SRA) : AluFuncType'(SRL);
			end 
			3'b110: begin 
				temp.alusel=SelAluLogic;
				temp.alufunc=AluFuncType'(OR);
			end 
			3'b111: begin
				temp.alusel=SelAluLogic;
				temp.alufunc=AluFuncType'(AND);
			end  
		endcase
		temp.regread1={1'b1,Inst[19:15]};
		temp.regread2={1'b1,Inst[24:20]};
		temp.regwrite1={1'b1,Inst[11:7]};
		temp.src1select=SelRs;
		decRType=temp;
endfunction : decRType
function DecodeCtrlType decBType(RV32InstType Inst, logic[1:0]microcode_state);
		automatic logic[2:0] func3=Inst[14:12];
		automatic DecodeCtrlType temp;
		temp.isSrc1Unsign=func3[1];
	    temp.isSrc2Unsign=func3[1];
		temp.alusel=(microcode_state)?SelAluArith:SelAluLogic;
		if(microcode_state == 2'd1)begin
		    temp.isSrc2Imm=1'b1;
			temp.alufunc=AluFuncType'(ADD);
			temp.src1select=SelPC;/////
		end else begin // microcode_state == 2'd3 will be treated as nop
			temp.src1select=SelRs;
		    temp.isSrc2Imm=1'b0;
		    
			casex (func3)
			3'b0: begin
				temp.alufunc=AluFuncType'(EQ);
			end 
			3'b1: begin
				temp.alufunc=AluFuncType'(NE);
			end 
			3'b1x0: begin
	
				temp.alufunc=AluFuncType'(LT);
			end 
			3'b1x1: begin
				temp.alufunc=AluFuncType'(GE);
			end 
			default : temp.alufunc=AluFuncType'(EQ);
			endcase
		end
		temp.memop = MemOpNone;
		temp.memsize = ByteTrans;
		temp.regread1={1'b1,Inst[19:15]};
		temp.regread2={1'b1,Inst[24:20]};
		temp.regwrite1={1'b0,Inst[11:7]};	
		decBType=temp;
endfunction : decBType
function DecodeCtrlType decIType(RV32InstType Inst, logic[1:0] microcode_state);
		automatic logic[2:0] func3=Inst[14:12];
		automatic DecodeCtrlType temp;
		temp.isSrc1Unsign=func3[0];// only used in LT
		temp.isSrc2Unsign=func3[0];// only used in LT
		temp.isSrc2Imm   =1'b1;
		case(Inst[6:0])
			7'b0000011: begin
				temp.alusel=SelAluLSU;
				temp.alufunc=AluFuncType'(ADD);
				temp.memop = (func3[2])?MemOpReadUnsigned: MemOpRead;
				casex(func3)
					'bx00:
						temp.memsize = ByteTrans;
					'bx01: 
						temp.memsize = HalfWTrans;
					default:
						temp.memsize = WordTrans;
				endcase // func3
				temp.regread1={1'b1,Inst[19:15]};
				temp.regread2={1'b0,5'b0};
				temp.regwrite1={1'b1,Inst[11:7]};
				temp.src1select=SelRs;
			end // 7'b0000011:
			7'b0010011: begin
				temp.memop = MemOpNone;
				temp.memsize = ByteTrans;
				casex(func3)
					3'b000: begin
						temp.alusel=SelAluArith;
						temp.alufunc=AluFuncType'(ADD);
					end // 3'b000:
					3'b01x: begin
						temp.alusel=SelAluLogic;
						temp.alufunc=AluFuncType'(LT);
					end // 3'b01x:
					3'b100: begin
						temp.alusel=SelAluLogic;
						temp.alufunc=AluFuncType'(XOR);
					end 
					3'b001: begin
						temp.alusel=SelAluShift;
						temp.alufunc=AluFuncType'(SLL);
					end 
					3'b101: begin
						temp.alusel=SelAluShift;
						temp.alufunc=(Inst[30])?AluFuncType'(SRA) : AluFuncType'(SRL);
					end 
					3'b110: begin 
						temp.alusel=SelAluLogic;
						temp.alufunc=AluFuncType'(OR);
					end 
					3'b111: begin
						temp.alusel=SelAluLogic;
						temp.alufunc=AluFuncType'(AND);
					end  
				endcase
				temp.regread1={1'b1,Inst[19:15]};
				temp.regread2={1'b0,5'b0};
				temp.regwrite1={1'b1,Inst[11:7]};
				temp.src1select=SelRs;
			end
			7'b1100111: begin
				if (microcode_state == 2'b1) begin // calc pc
					temp.regwrite1={1'b0,Inst[11:7]};
					// temp.isSrc2Imm   =1'b1;
					temp.src1select=SelRs;
				end else if (microcode_state == 2'd2)  begin // calc ret address
					temp.regwrite1={1'b1,Inst[11:7]};
					// temp.isSrc2Imm   =1'b1;
					temp.src1select=SelPC;
				end else begin // do nothing. should at Normal state
					temp.regwrite1={1'b0,Inst[11:7]};
					// temp.isSrc2Imm   =1'b1;
					temp.src1select=SelPC;
				end
				temp.alusel=SelAluArith;
				temp.alufunc=AluFuncType'(ADD);
				temp.memop = MemOpNone;
				temp.memsize = ByteTrans;
				temp.regread1={1'b1,Inst[19:15]};
				temp.regread2={1'b0,5'b0};
				// temp.regwrite1={1'b1,Inst[11:7]};
				temp.src1select=SelRs;
			end 
			default: begin
				temp.alusel=SelAluArith;
				temp.alufunc=AluFuncType'(PASS);
				temp.memop = MemOpNone;
				temp.regread1={1'b0,5'b0};
				temp.regread2={1'b0,5'b0};
				temp.src1select=SelRs;
				temp.regwrite1={1'b0,Inst[11:7]};
			end
		endcase // Inst[6:0]
		decIType=temp;
endfunction : decIType
function DecodeCtrlType decJType(RV32InstType Inst, logic[1:0] microcode_state);
		automatic DecodeCtrlType temp;
		temp.isSrc1Unsign=1'b1;// doesnt matter
		temp.isSrc2Unsign=1'b1;// doesnt matter
		temp.alusel=SelAluArith;
		temp.alufunc=AluFuncType'(ADD);
		temp.memop = MemOpNone;
		temp.memsize = ByteTrans;
		temp.regread1={1'b1,Inst[19:15]};
		temp.regread2={1'b0,5'b0};
		if (microcode_state == 2'b1) begin // calc pc
			temp.regwrite1={1'b0,Inst[11:7]};
			temp.isSrc2Imm   =1'b1;
			temp.src1select=SelPC;
		end else if (microcode_state == 2'd2)  begin // calc ret address
			temp.regwrite1={1'b1,Inst[11:7]};
			temp.isSrc2Imm   =1'b1;
			temp.src1select=SelPC;
		end else begin // do nothing. should at Normal state
			temp.regwrite1={1'b0,Inst[11:7]};
			temp.isSrc2Imm   =1'b1;
			temp.src1select=SelPC;
		end
		decJType=temp;
endfunction : decJType
function DecodeCtrlType decUType(RV32InstType Inst, logic[1:0] microcode_state);
	automatic DecodeCtrlType temp;
	temp.memsize = ByteTrans;
	temp.isSrc1Unsign=1'b1;// doesnt matter
	temp.isSrc2Unsign=1'b1;// doesnt matter
	temp.isSrc2Imm   =1'b1;
	if(Inst[6:0]==7'b0110111) begin//LUI
		temp.alusel=SelAluArith;
		temp.alufunc=AluFuncType'(PASS);
		temp.memop = MemOpNone;
		temp.regread1={1'b0,5'b0};
		temp.regread2={1'b0,5'b0};
		temp.regwrite1={1'b1,Inst[11:7]};
		temp.src1select=SelPC;
	end else if (Inst[6:0]==7'b0010111) begin
		temp.alusel=SelAluArith;
		temp.alufunc=AluFuncType'(ADD);
		temp.memop = MemOpNone;
		temp.regread1={1'b0,5'b0};
		temp.regread2={1'b0,5'b0};
		temp.src1select=SelPC;
		temp.regwrite1={1'b1,Inst[11:7]};
	end else begin
		temp.alusel=SelAluArith;
		temp.alufunc=AluFuncType'(PASS);
		temp.memop = MemOpNone;
		temp.regread1={1'b0,5'b0};
		temp.regread2={1'b0,5'b0};
		temp.src1select=SelPC;
		temp.regwrite1={1'b0,Inst[11:7]};
	end
	decUType=temp;
endfunction : decUType
function DecodeCtrlType genNopType(DecodeCtrlType decodedInst, logic genBubble);// generate bubbles
		RegCtrlPortType nopWriteCtrl;
		nopWriteCtrl.RegEnable=1'b0;
		nopWriteCtrl.RegAddr= 'b0;
		genNopType.isSrc1Unsign=decodedInst.isSrc1Unsign;// doesnt matter
		genNopType.isSrc2Unsign=decodedInst.isSrc2Unsign;// doesnt matter
		genNopType.isSrc2Imm   =decodedInst.isSrc2Imm;
		genNopType.alusel=decodedInst.alusel;
		genNopType.alufunc=decodedInst.alufunc;
		genNopType.memop = (genBubble)?MemOpNone:decodedInst.memop;
		genNopType.memsize = decodedInst.memsize;
		genNopType.regread1.RegEnable= (genBubble)?0:decodedInst.regread1.RegEnable;
		genNopType.regread1.RegAddr  = decodedInst.regread1.RegAddr;
		genNopType.regread2.RegEnable= (genBubble)?0:decodedInst.regread2.RegEnable;
		genNopType.regread2.RegAddr  = decodedInst.regread2.RegAddr;
		genNopType.regwrite1=(genBubble)?nopWriteCtrl:decodedInst.regwrite1;
		genNopType.src1select=decodedInst.src1select;
endfunction : genNopType
//	RV32InstType -> InstSubType
function InstSubType getInstType(RV32InstType Inst);

	case (Inst[6:0])
		7'b1100011: begin
			getInstType=Btype;
		end 
		7'b0010111,7'b0110111: begin
			getInstType=Utype;
		end 
		7'b1100111,7'b0000011,7'b0010011: begin 
			getInstType=Itype;
		end 
		7'b0110011: begin 
			getInstType=Rtype;
		end 
		7'b1101111: begin
			getInstType=Jtype;
		end 
		7'b0100011: begin 
			getInstType= Stype;
		end 
		default : getInstType=Invalid;
	endcase
endfunction : getInstType
function ImmType getImm(InstSubType type_of_Inst, RV32InstType inst, logic[1:0] microcode_state);
	// InstSubType->RV32InstType->Immtype
		if (microcode_state ==2'd2) begin
					getImm= 'd4;
		end else begin
			case (type_of_Inst)
				Btype: begin
					getImm={{(32-12){inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
				end 
				Utype: begin
					getImm={inst[31:12],12'b0};
				end 
				Jtype: begin
					getImm={{(32-12){inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
				end 
				Itype: begin
					getImm={{(32-12){inst[31]}},inst[31:20]};
				end 
				Stype: begin
					getImm={{(32-12){inst[31]}},inst[31:25],inst[11:7]};
				end 
				default: begin
					getImm={{(32-12){inst[31]}},inst[31:20]};
				end 
			endcase
		end
endfunction : getImm
typedef enum logic[1:0]{
	Normal=0,
	CalcPred=1,
	CalcTarget=2,
	CalcRet=3
}DecFsmType;
/////////////////////////////////////////////////////////////////////////////////
InstSubType SubTypeofInst;
logic       BubbleEnable;
DecFsmType  decode_fsm;
logic       decode_fsm_stall;
logic [1:0] microcode_state;
logic       hasInstHolded;
logic       isInstValid_hold;
RV32InstType Inst_hold,Inst_temp;
DecodeCtrlType NormalDecInst;
assign SubTypeofInst=getInstType(Inst_hold);
assign Imm= getImm(SubTypeofInst,Inst_hold, microcode_state);
assign DecodeSrc1 =(DecodeOut.src1select==SelPC)?PC:RegSrc1;
assign DecodeSrc2 =RegSrc2;
assign isDecodeReqExec=!BubbleEnable;
always_comb begin 
	case(SubTypeofInst)
		Stype: begin
			BubbleEnable=!isInstValid_hold;
			NormalDecInst=decSType(Inst_hold, microcode_state);
		end
		Rtype: begin
			BubbleEnable=!isInstValid_hold;
			NormalDecInst=decRType(Inst_hold, microcode_state);
		end 
		Btype: begin
			BubbleEnable=!isInstValid_hold|(microcode_state==2'd3);
			NormalDecInst=decBType(Inst_hold, microcode_state);
		end  
		Itype: begin
			BubbleEnable=!isInstValid_hold;
			NormalDecInst=decIType(Inst_hold, microcode_state);
		end  
		Jtype: begin 
			BubbleEnable=!isInstValid_hold|(microcode_state==2'd3);
			NormalDecInst=decJType(Inst_hold, microcode_state);
		end  
		Utype: begin
			BubbleEnable=!isInstValid_hold;
			NormalDecInst=decUType(Inst_hold, microcode_state);
		end 
		default: begin
			BubbleEnable=1'b1;
			NormalDecInst=decRType(Inst_hold, microcode_state);// doesnt matter
		end 
	endcase
	DecodeOut=genNopType(NormalDecInst, BubbleEnable);

end

always_ff @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		 decode_fsm <= Normal ;
	end else if(!ExecStall) begin
		 case(decode_fsm)
		 	Normal : begin
		 		if (isInstValid_hold) begin
		 			if(SubTypeofInst==Btype) begin
		 				decode_fsm<= CalcPred;
		 			end else if((SubTypeofInst == Jtype) || (Inst_hold[6:0]==7'b1100111)) begin
		 				decode_fsm<= CalcTarget;
		 			end else begin
		 				decode_fsm<=decode_fsm;
		 			end
		 		end else begin
		 			decode_fsm<=decode_fsm;
		 		end
		 	end 
		 	CalcPred: begin
		 		if(BranchPredResult.isBrPredCorrect==1'b1) begin
		 			decode_fsm<= Normal;
		 		end else begin
		 			decode_fsm<= CalcTarget;
		 		end
		 	end 
		 	CalcTarget: begin
		 		if(SubTypeofInst == Btype)begin
		 			decode_fsm<= Normal;
		 		end else begin
		 			decode_fsm<= CalcRet;
		 		end
		 	end  
		 	default:
		 		decode_fsm<= Normal; 
		 endcase // decode_fsm
	end
end
always_comb begin 
	case(decode_fsm)
		Normal : begin
			if(SubTypeofInst==Btype) begin
				microcode_state=2'b0;
			end else if((SubTypeofInst == Jtype)|| (Inst_hold[6:0]==7'b1100111)) begin
				microcode_state=2'd1;
			end else begin
				microcode_state=2'd3;
			end
		end 
		CalcPred: begin
			if(BranchPredResult.isBrPredCorrect==1'b1) begin
				microcode_state=2'd3;
			end else begin
				microcode_state=2'd1;
			end
		end 
		CalcTarget: begin
			if(SubTypeofInst == Btype)begin
				microcode_state=2'd3;
			end else begin
				microcode_state=2'd2;
			end
		end  
		default:
			microcode_state=2'd3;
	endcase // decode_fsm
end
always_ff @(posedge clk or negedge rst_n) begin : proc_Inst_temp
	if(~rst_n) begin
		Inst_temp <= '0;
		hasInstHolded <=0;
	end else if(FetchStall&isInstValid)begin
		// Currnt Instruction is valid but It is a multicycle instruction
		// so we store it
		Inst_temp <= Inst;
		hasInstHolded<=1;
	end else begin
		Inst_temp <= Inst_temp;
		hasInstHolded <= FetchStall;
	end
end

assign Inst_hold=(hasInstHolded)?Inst_temp:Inst;
assign isInstValid_hold=(hasInstHolded)?1'b1:isInstValid;
assign decode_fsm_stall= microcode_state!=2'd3; /*((decode_fsm == Normal  )&((SubTypeofInst==Btype)|(SubTypeofInst==Jtype)|(Inst_hold[6:0]==7'b1100111))&isInstValid_hold)
						|((decode_fsm == CalcPred)&(BranchPredResult.isBrPredCorrect==1'b0))
						|((decode_fsm == CalcTarget)&((SubTypeofInst!=Btype)));*/
assign FetchStall= ExecStall|decode_fsm_stall|!(RegSrc1.isRegAvailable&RegSrc2.isRegAvailable);
assign FetchJump = decode_fsm==CalcTarget;
assign TargetPC  = BranchPredResult.newBrTarget;
endmodule : RVdecode