module RV_AHB_Intf (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input Address_vld,
	input [31:0] Address,
	output logic Address_rsp,

	input WData_vld,
	output logic [31:0] ReadData,
	input        [31:0] WriteData,
	output logic Data_rsp,

	output [1:0]  TRANS,
	output [31:0] A,
	output [31:0] WD,
	input  [31:0] RD,
	input  bus_rdy,
	input  d_grant,
	input  a_grant
);
assign Address_rsp=a_grant&bus_rdy;
assign Data_rsp   =d_grant&bus_rdy;
assign TRANS 	  =(Address_vld)?2'd2:2'd0;
assign A = Address;
assign ReadData=RD;
assign WD= WriteData;
endmodule : RV_AHB_Intf