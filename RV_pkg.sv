package RV_pkg;
	typedef enum logic [2:0]{
		Btype=0,
		Utype=1,
		Itype=2,
		Rtype=3,
		Jtype=4,
		Stype=5,
		Invalid=6
	}InstSubType;
	typedef logic[31:0] ImmType;
	typedef logic[31:0] OperandType;
	typedef logic[31:0] RV32InstType;
	// macro function

	//-----------------------------------------
	typedef logic[2:0] AluFuncType;
	typedef enum AluFuncType {
		EQ=0,
		NE=1,
		LT=2,
		GE=3,
		AND=4,
		OR=5,
		XOR=6
	}AluLogicOpType;
	typedef enum AluFuncType {
	    _EQSUB=0, // should not be used in decode stage
	    _NESUB=1,
	    _LTSUB=2,
	    _GESUB=3,
		PASS=4,
		ADD=5,
		SUB=6
	}AluArithOpType;
	typedef enum AluFuncType {
		SLL=0,
		SRL=1,
		SRA=2
	}AluShiftOpType;
	typedef enum logic[1:0]{
		SelAluLogic=0,
		SelAluArith=1,
		SelAluShift=2,
		SelAluLSU  =3
	}ALuSelType;
	typedef enum logic{
		SelRs=0,
		SelPC=1
	}Src1SelType;
	//-----------------------------------------
	
	typedef struct packed{
		logic RegEnable;
		logic [4:0] RegAddr;
	}RegCtrlPortType;

	typedef struct packed{
		RegCtrlPortType WriteCtrl;
		OperandType PhyRegWriteData;
	}RegWritePortType;

	typedef struct packed {
		logic isRegAvailable;
		OperandType PhyRegReadData;
	}RegReadPortType;
	//------------------------------------------
	typedef enum logic [1:0]{
		MemOpNone=0,
		MemOpWrite=1,
		MemOpRead=2,
		MemOpReadUnsigned=3
	}MemOpType;
	typedef enum logic [1:0]{
		ByteTrans=0,
		HalfWTrans=1,
		WordTrans=2
	}MemSizeType;
	typedef struct packed{
		MemOpType    MemCtrl;
		OperandType MemAddr;
		OperandType MemWriteData;
	}MemWritePortType;
	typedef struct packed{
		logic MemOpDone;
		OperandType MemReadData;
	}MemReadPortType;
	//-----------------------------------------
	typedef struct packed {
		ALuSelType alusel;
		AluFuncType alufunc;
		logic isSrc1Unsign;
		logic isSrc2Unsign;
		logic isSrc2Imm;
		MemOpType   memop;	
		MemSizeType memsize;
		RegCtrlPortType regwrite1;
		Src1SelType     src1select;
		RegCtrlPortType regread1;
		RegCtrlPortType regread2;
	}DecodeCtrlType;
	//----------------------------------------
	typedef struct packed {
		logic isBrPredCorrect;
		OperandType newBrTarget;
	}ExecBrRetType;
endpackage : RV_pkg