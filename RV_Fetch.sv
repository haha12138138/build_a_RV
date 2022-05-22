import RV_pkg::*;

module RV_Fetch (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	// to decode
	output OperandType PC,
	output RV32InstType Inst,
	output logic  isInstValid,
	// from decode
	input  logic FetchStall,
	input  logic FetchJump,
	input  OperandType TargetPC,
    // I Memory
	output logic Address_vld,
	output logic[31:0] Address,
	input logic Address_rsp, 

	output WData_vld,
	input  logic [31:0] ReadData,
	output logic [31:0] WriteData,
	input  logic Data_rsp
);
OperandType PC_p4;
logic [1:0] state;
// always_ff @(posedge clk or negedge rst_n) begin : proc_pc
// 	if(~rst_n) begin
// 		PC <= 0;
// 	end else if(FetchJump) begin
// 		PC <= TargetPC;
// 	end else if(!FetchStall&Address_rsp) begin
// 		PC <=PC_p4;
// 	end 
// end
assign PC_p4=PC+4;
assign Address_vld=state==0;
assign Address = PC;
assign WData_vld=0;
assign WriteData=0;
assign isInstValid=(state==1)&Data_rsp;
assign Inst=RV32InstType'(ReadData);
always_ff @(posedge clk or negedge rst_n) begin : proc_state
	if(~rst_n) begin
		state <= 0;
		PC<=0;
	end else begin
		case (state)
		0: begin
			if(Address_rsp) begin
				state <= 1;
			end 
			PC<=PC;
		end 
		1: begin
			if(Data_rsp&FetchStall&!FetchJump)begin
				state<=2;
				PC<=PC;
			end else if (Data_rsp)begin
				state<=0;
				PC<=(FetchJump)?TargetPC:PC_p4;
			end
		end 
		2: begin
			if(FetchStall&!FetchJump)begin
				state<=state;
				PC<=PC;
			end else begin
				state<=0;
				PC<=(FetchJump)?TargetPC:PC_p4;
			end
		end 
		endcase
	end
end

endmodule : RV_Fetch