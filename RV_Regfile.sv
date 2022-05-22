import RV_pkg::*;

module RV_Regfile (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input RegCtrlPortType DecodeRegReadCtrl1,
	input RegCtrlPortType DecodeRegReadCtrl2,
    input RegCtrlPortType DecodeRegWriteCtrl1,
	input RegWritePortType ExecResultBypass,
    output RegReadPortType DecodeRegReadData1,
    output RegReadPortType DecodeRegReadData2
);
OperandType regfile[31:1]; // x0 always ==0;
logic isSrc1Inflight,isSrc2Inflight;
logic isSrc1Zero,isSrc2Zero;
always_comb begin 
	isSrc1Inflight=DecodeRegReadCtrl1.RegAddr == ExecResultBypass.WriteCtrl.RegAddr;
	isSrc2Inflight=DecodeRegReadCtrl2.RegAddr == ExecResultBypass.WriteCtrl.RegAddr;
	isSrc1Zero    =DecodeRegReadCtrl1.RegAddr == 0;
	isSrc2Zero    =DecodeRegReadCtrl2.RegAddr == 0;
end
always_comb begin 
	if (isSrc1Zero) begin
		DecodeRegReadData1.PhyRegReadData =0;
		DecodeRegReadData1.isRegAvailable =1'b1;
	end else begin
		if (isSrc1Inflight) begin
			DecodeRegReadData1.PhyRegReadData=ExecResultBypass.PhyRegWriteData;
			DecodeRegReadData1.isRegAvailable=ExecResultBypass.WriteCtrl.RegEnable|(!DecodeRegReadCtrl1.RegEnable);
		end else begin
			DecodeRegReadData1.PhyRegReadData=regfile[DecodeRegReadCtrl1.RegAddr];
			DecodeRegReadData1.isRegAvailable=1'b1;
		end
	end
end
always_comb begin 
	if (isSrc2Zero) begin
		DecodeRegReadData2.PhyRegReadData =0;
		DecodeRegReadData2.isRegAvailable =1'b1;
	end else begin
		if (isSrc2Inflight) begin
			DecodeRegReadData2.PhyRegReadData=ExecResultBypass.PhyRegWriteData;
			DecodeRegReadData2.isRegAvailable=ExecResultBypass.WriteCtrl.RegEnable|(!DecodeRegReadCtrl2.RegEnable);
		end else begin
			DecodeRegReadData2.PhyRegReadData=regfile[DecodeRegReadCtrl2.RegAddr];
			DecodeRegReadData2.isRegAvailable=1'b1;
		end
	end
end
always_ff @(posedge clk) begin
	 if(ExecResultBypass.WriteCtrl.RegEnable) begin
	 	regfile[ExecResultBypass.WriteCtrl.RegAddr]<=ExecResultBypass.PhyRegWriteData;
	 end 
end

endmodule : RV_Regfile