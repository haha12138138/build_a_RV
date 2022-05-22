module RV_Mem 
#(
	parameter FILE="D:\\codes\\verilog\\RHBD_IP\\RV\\C_Code\\t.verilog"
)(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input logic  MemAddress_vld,
	input logic  [31:0] MemAddress,
	input logic  MemOp,
	input logic  [1:0] MemOpSize,
	output logic MemAddress_rsp,
	input logic  MemWData_vld,
	output logic [31:0]MemReadData,
	input logic  [31:0]MemWriteData,
	output logic  MemData_rsp
);
    logic [7:0] mem[1023:0];
	logic[31:0] Address_t;
	logic Address_vld_t;
	logic op;
	initial begin
		$readmemh(FILE,mem);
	end
	assign MemAddress_rsp=1'b1;
	always @(posedge clk) begin 
		if(op&MemWData_vld) begin
			case (MemOpSize)
				0: mem[Address_t]<=MemWriteData[7:0];
				1: {mem[Address_t+1],mem[Address_t]}<=MemWriteData[15:0];
				2: {mem[Address_t+3],mem[Address_t+2],mem[Address_t+1],mem[Address_t]}<=MemWriteData;
				default: {mem[Address_t+3],mem[Address_t+2],mem[Address_t+1],mem[Address_t]}<=MemWriteData;
			endcase
		end 
	end
	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			Address_t <= 0;
			Address_vld_t<=0;
			op<=0;
		end else begin
			Address_t <= MemAddress;
			Address_vld_t=MemAddress_vld;
			op<=MemOp;
		end
	end
	
	always_comb begin
		if(Address_vld_t ==0) begin
			MemReadData='bx;
			MemData_rsp=0;
		end else begin
			MemReadData={mem[{Address_t[31:2],2'b00}+3],mem[{Address_t[31:2],2'b00}+2],mem[{Address_t[31:2],2'b00}+1],mem[{Address_t[31:2],2'b00}]};
			MemData_rsp=1;
		end
	end
endmodule : RV_Mem