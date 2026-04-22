// =====================================
// Module Hazard_Unit
// Forward + Stall
// =====================================

//`include "Forwarding_Unit.v"
//`include "Stall_Unit.v"

module Hazard_Unit (

	input clk,
	input reset,

	// Forwarding
	input RegWriteM,
	input RegWriteW_fwd,
	input [4:0] RD_M,
	input [4:0] RD_W,
	input [4:0] RS1_E,
	input [4:0] RS2_E,

	// Stall
	input MemReadE,
	input [4:0] RD_E,
	input [4:0] RS1_D,
	input [4:0] RS2_D,

	// BRAM stall
	input MemReadM,

	// Branch
	input PCSrcE,

	//Ouput
	output [1:0] ForwardA_E,
	output [1:0] ForwardB_E,
	output StallF,
	output StallD,
	output StallE,
	output StallM,
	output HoldE,
	output FlushD,
	output FlushE

);

	// =============== FORWARDING ===============
	Forwarding_Unit forward (
	
		// Input 
		.RegWriteM			(RegWriteM),
		.RegWriteW_fwd			(RegWriteW_fwd),
		.RD_M				(RD_M),
		.RD_W				(RD_W),
		.RS1_E				(RS1_E),
		.RS2_E				(RS2_E),
		
		// Output
		.ForwardA_E			(ForwardA_E),
		.ForwardB_E			(ForwardB_E)
	);
	
	
	// =============== STALL ===============
	wire StallF_lw, StallD_lw, FlushE_stall;

	Stall_Unit stall (

		// Input
		.MemReadE			(MemReadE),
		.RD_E				(RD_E),
		.RS1_D				(RS1_D),
		.RS2_D				(RS2_D),

		.StallF				(StallF_lw),
		.StallD				(StallD_lw),
		.FlushE				(FlushE_stall)
	);


	// =============== BRAM Stall ===============
	reg bram_wait;

	always @(posedge clk or negedge reset) begin
		if (!reset) bram_wait <= 1'b0;
		else        bram_wait <= MemReadM && !bram_wait;
	end

	wire bram_stall = MemReadM && !bram_wait;


	// =============== Flush / Stall Outputs ===============
	assign StallF  = StallF_lw | bram_stall;
	assign StallD  = StallD_lw | bram_stall;
	assign StallE  = bram_stall;
	assign StallM  = bram_stall;
	assign HoldE   = bram_stall;
	assign FlushD  = PCSrcE;
	assign FlushE  = FlushE_stall;

endmodule