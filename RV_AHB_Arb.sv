function integer log2;
  input integer value;
  begin
    value = value-1;
    for (log2=0; value>0; log2=log2+1)
      value = value>>1;
  end
endfunction
module RV_AHB_Arb (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	// mst1
	input [31:0] A1,
	input [1:0]  TRANS1,
	input [31:0] WD1,
	output logic [31:0] RD1,
	output logic RDY1,
	output logic a_grant1,
	output logic d_grant1,
	// mst2
	input [31:0] A2,
	input [1:0]  TRANS2,
	input [31:0] WD2,
	output logic [31:0] RD2,
	output logic RDY2,
	output logic a_grant2,
	output logic d_grant2,
	//
	output [31:0] ABus,
	output [1:0]  TRANSBus,
	output [31:0] WDBus,
	input  logic [31:0] RDBus,
	input  logic RDYBus
);
logic [1:0] M_req;
logic [1:0] bin_out,temp_oh_out;
assign M_req[0]=TRANS1==2'd2;
assign M_req[1]=TRANS2==2'd2;
assign RDY1=RDYBus;
assign RDY2=RDYBus;
OH_2_BIN #(.WID(2)) inst_OH_2_BIN (.sel(M_req), .bin_out(bin_out), .valid());
assign temp_oh_out = 1<< bin_out[0];
assign a_grant1=temp_oh_out[0];
assign a_grant2=temp_oh_out[1];
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		 {d_grant1, d_grant2}<= 0;
	end else if(RDYBus) begin
		 {d_grant1, d_grant2}<={a_grant1, a_grant2} ;
	end
end
assign RD1=RDBus;
assign RD2=RDBus;
assign ABus = ({32{a_grant1}}&A1)|({32{a_grant2}}&A2);
assign WDBus= ({32{d_grant1}}&WD1)|({32{d_grant2}}&WD2);
endmodule : RV_AHB_Arb
module OH_2_BIN 
#(parameter WID=4)
(
	input [WID-1:0] sel,
	output [log2(WID)-1:0] bin_out,
	output valid
);
 logic [log2(WID)-1:0] temp [WID-1:0];
 genvar i;
 assign temp[WID-2]=(sel[WID-2])?WID-2:WID-1;

 generate
 	for (i = 0;i<WID-2;i++) begin
 		assign temp[i]=(sel[i])?(i):temp[i+1];
 	end 
 endgenerate

 assign bin_out=temp[0];
 assign valid=|sel;
endmodule : OH_2_BIN