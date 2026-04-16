// =====================================
// Module Hazard_Unit
// Forward + Stall
// =====================================

//`include "Forwarding_Unit.v"
//`include "Stall_Unit.v"

module Hazard_Unit (

	// Forwarding
	input RegWriteM,
	input RegWriteW,
	input [4:0] RD_M,
	input [4:0] RD_W,
	input [4:0] RS1_E,
	input [4:0] RS2_E,
	
	// Stall
	input MemReadE,
	input [4:0] RD_E,
	input [4:0] RS1_D,
	input [4:0] RS2_D,
	
	// Branch
	input PCSrcE,
	
	//Ouput
	output [1:0] ForwardA_E,
	output [1:0] ForwardB_E,
	output StallF,
	output StallD,
	output FlushD,
	output FlushE
	
);

	// =============== FORWARDING ===============
	
	Forwarding_Unit forward (
	
		// Input 
		.RegWriteM			(RegWriteM),
		.RegWriteW			(RegWriteW),
		.RD_M					(RD_M),
		.RD_W					(RD_W),
		.RS1_E				(RS1_E),
		.RS2_E				(RS2_E),
		
		// Output
		.ForwardA_E			(ForwardA_E),
		.ForwardB_E			(ForwardB_E)
	);
	
	
	// =============== STALL ===============
	
	wire FlushE_stall;
	
	Stall_Unit stall (
		
		// Input
		.MemReadE			(MemReadE),
		.RD_E					(RD_E),
		.RS1_D				(RS1_D),
		.RS2_D				(RS2_D),
		
		.StallF				(StallF),
		.StallD				(StallD),
		.FlushE				(FlushE_stall)
	);
	
	
	// =============== Flush Logic ===============
	
	assign FlushD	= PCSrcE;
	assign FlushE	= FlushE_stall | PCSrcE;

endmodule