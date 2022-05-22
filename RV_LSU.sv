import RV_pkg::*;

module RV_LSU (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input logic         ExecReq,
	input DecodeCtrlType DecodeCtrl,
	input OperandType MemAddress,
	input OperandType MemWData,
	// to Exec
	output MemReadPortType MemReadPort,
	// 
	output logic Address_vld,
	output logic[31:0] MemAddress_o,
	output logic MemOp,
	output logic[1:0] MemOpSize,
	input logic Address_rsp,

	output logic WData_vld,
	input  logic [31:0] ReadData_o,
	output logic [31:0] WriteData_o,
	input  logic Data_rsp
);
logic addr_ld;
OperandType MemAddress_temp;
typedef enum logic[1:0] {
	IDLE_ST=0,
	ADDR_ST=1,
	DATA_ST=2
} LSU_FSMType;

LSU_FSMType LSU_FSM, nxt_LSU_FSM;
always_ff @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		 LSU_FSM<= IDLE_ST;
	end else begin
		 LSU_FSM<= nxt_LSU_FSM;
	end
end
always_ff @(posedge clk) begin
	MemAddress_temp<= (addr_ld)?MemAddress:MemAddress_temp;
end
assign MemAddress_o=MemAddress_temp;

always_comb begin 
	case (LSU_FSM)
		IDLE_ST: begin
			Address_vld=1'b0;
			WData_vld  =1'b0;
			MemReadPort.MemOpDone=1'b0;
			if (ExecReq && (DecodeCtrl.alusel== SelAluLSU)) begin
				nxt_LSU_FSM=ADDR_ST;
				addr_ld    =1'b1;
			end else begin
				nxt_LSU_FSM=IDLE_ST;
				addr_ld    =1'b0;
			end
		end 
		ADDR_ST: begin
			Address_vld=1'b1;
			WData_vld  =1'b0;
			addr_ld    =1'b0;
			MemReadPort.MemOpDone=1'b0;
			if (Address_rsp) begin
				nxt_LSU_FSM=DATA_ST;
			end else begin
				nxt_LSU_FSM=ADDR_ST;
			end
		end 
		DATA_ST: begin
			Address_vld=1'b0;
			WData_vld  =1'b1;
			addr_ld    =1'b0;
			MemReadPort.MemOpDone=Data_rsp;
			if (Data_rsp) begin
				nxt_LSU_FSM=IDLE_ST;
			end else begin
				nxt_LSU_FSM=DATA_ST;
			end
		end 
	default :begin
			Address_vld=1'b0;
			WData_vld  =1'b0;
			addr_ld    =1'b0;
			MemReadPort.MemOpDone=1'b0;
			nxt_LSU_FSM=IDLE_ST;
		end 
	endcase
end
always_comb begin 
	case(DecodeCtrl.memsize)
		ByteTrans: WriteData_o={4{MemWData[7:0]}}; 
		HalfWTrans: WriteData_o={2{MemWData[15:0]}};
		WordTrans: WriteData_o=MemWData;
		default: WriteData_o=MemWData;
	endcase // DecodeCtrl.memsize
end
assign MemReadPort.MemReadData= OperandType'(ReadData_o);
assign MemOp = (DecodeCtrl.memop == MemOpWrite);
assign MemOpSize = (DecodeCtrl.memsize);
endmodule : RV_LSU