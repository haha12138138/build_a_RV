import RV_pkg::*;
module RV_test;
	logic clk,rst_n;
	logic req1,req2;
	logic [31:0] ABus;
	logic [1:0]  TRANSBus;
	logic [31:0] WDBus;
	logic        RDYBus;
	
	logic        Address_vld1;
	logic [31:0] Address1;
	logic        Address_rsp1;
	logic        WData_vld1;
	logic [31:0] ReadData1;
	logic [31:0] WriteData1;
	logic        Data_rsp1;
	logic  [1:0] TRANS1;
	logic [31:0] A1;
	logic [31:0] WD1;
	logic [31:0] RD1;
	logic        d_grant1;
	logic        a_grant1;

	logic        Address_vld2;
	logic [31:0] Address2;
	logic        Address_rsp2;
	logic        WData_vld2;
	logic [31:0] ReadData2;
	logic [31:0] WriteData2;
	logic        Data_rsp2;
	logic  [1:0] TRANS2;
	logic [31:0] A2;
	logic [31:0] WD2;
	logic [31:0] RD2;
	logic        d_grant2;
	logic        a_grant2;
	RV_Fetch #(32'h0) inst_RV_Fetch1
	(
		.clk         (clk),
		.rst_n       (rst_n),
		.req         (req1),
		.Address_vld (Address_vld1),
		.Address     (Address1),
		.Address_rsp (Address_rsp1),
		.WData_vld   (WData_vld1),
		.ReadData    (ReadData1),
		.WriteData   (WriteData1),
		.Data_rsp    (Data_rsp1)
	);
	RV_AHB_Intf inst_RV_AHB_Intf1
	(
		.clk         (clk),
		.rst_n       (rst_n),
		.Address_vld (Address_vld1),
		.Address     (Address1),
		.Address_rsp (Address_rsp1),
		.WData_vld   (WData_vld1),
		.ReadData    (ReadData1),
		.WriteData   (WriteData1),
		.Data_rsp    (Data_rsp1),
		.TRANS       (TRANS1),
		.A           (A1),
		.WD          (WD1),
		.RD          (RD1),
		.bus_rdy     (RDYBus),
		.d_grant     (d_grant1),
		.a_grant     (a_grant1)
	);

	RV_Fetch #(32'hffffffff) inst_RV_Fetch2
	(
		.clk         (clk),
		.rst_n       (rst_n),
		.req         (req2),
		.Address_vld (Address_vld2),
		.Address     (Address2),
		.Address_rsp (Address_rsp2),
		.WData_vld   (WData_vld2),
		.ReadData    (ReadData2),
		.WriteData   (WriteData2),
		.Data_rsp    (Data_rsp2)
	);
	RV_AHB_Intf inst_RV_AHB_Intf2
	(
		.clk         (clk),
		.rst_n       (rst_n),
		.Address_vld (Address_vld2),
		.Address     (Address2),
		.Address_rsp (Address_rsp2),
		.WData_vld   (WData_vld2),
		.ReadData    (ReadData2),
		.WriteData   (WriteData2),
		.Data_rsp    (Data_rsp2),
		.TRANS       (TRANS2),
		.A           (A2),
		.WD          (WD2),
		.RD          (RD2),
		.bus_rdy     (RDYBus),
		.d_grant     (d_grant2),
		.a_grant     (a_grant2)
	);


	RV_AHB_Arb inst_RV_AHB_Arb
	(
		.clk      (clk),
		.rst_n    (rst_n),
		.A1       (A1),
		.TRANS1   (TRANS1),
		.WD1      (WD1),
		.RD1      (RD1),
		.RDY1     (RDY1),
		.a_grant1 (a_grant1),
		.d_grant1 (d_grant1),
		.A2       (A2),
		.TRANS2   (TRANS2),
		.WD2      (WD2),
		.RD2      (RD2),
		.RDY2     (RDY2),
		.a_grant2 (a_grant2),
		.d_grant2 (d_grant2),
		.ABus     (ABus),
		.TRANSBus (TRANSBus),
		.WDBus    (WDBus),
		.RDBus    (0),
		.RDYBus   (RDYBus)
	);

	initial begin
		clk=0;
		forever begin
			#10 clk=~clk;
		end
	end
	initial begin
		rst_n=0;
		#5 ;
		rst_n=1;
	end
	initial begin
		req1=0;
		req2=1;
		RDYBus=1;
		repeat(5) @(posedge clk);
		RDYBus=0;
		req1=1;
		repeat(3) @(posedge clk);
		RDYBus=1;
		repeat(4) @(posedge clk);
		req1=0;
		repeat(4) @(posedge clk);
		$stop;
	end
endmodule : RV_test