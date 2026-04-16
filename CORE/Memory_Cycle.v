// ======================================
// module Memory_Cycle
// + MEM stage
// ======================================

module Memory_Cycle (

	input clk,
	input reset,
	
	// ---------------------------------
	// Từ Execute stage (EX --> MEM)
	// ---------------------------------
	input RegWriteM,
	input MemReadM,
	input MemWriteM,
	
	input [1:0] ResultSrcM,			// Tín hiệu điều khiển WB sẽ lấy giá trị từ đâu
	
	input [4:0] RD_M,					// Địa chỉ của thanh ghi đích
	input [31:0] PCPlus4M,
	input [31:0] WriteDataM,		// Dữ liệu cần ghi vào RAM
	input [31:0] ALU_ResultM,		// Kết quả tính ở ALU (EX stage)
	
	
	// ----------------------------------
	// Output sang Write Back (WB stage)
	// ----------------------------------
	output RegWriteW,
	output [1:0] ResultSrcW,
	output [4:0] RD_W,
	output [31:0] PCPlus4W,
	output [31:0] ALU_ResultW,
	output [31:0] ReadDataW
);


	// =============== DATA RAM ===============
	wire [31:0] ReadDataM;
	
	Data_RAM dmem (
	
		// Input
		.clk				(clk),
		.addr				(ALU_ResultM),
		.write_data		(WriteDataM),
		.write_en		(MemWriteM),
		.read_en			(MemReadM),
		
		.read_data		(ReadDataM)
	);
	
	
	// =============== PIPELINE REGISTER ===============
	reg RegWriteM_r;
	reg [1:0] ResultSrcM_r;
	reg [4:0] RD_M_r;
	reg [31:0] PCPlus4M_r;
	reg [31:0] ALU_ResultM_r;
	reg [31:0] ReadDataM_r;
	
	always @(posedge clk or negedge reset) begin
	
		if (!reset) begin
			RegWriteM_r			<= 0;
			ResultSrcM_r		<= 2'b0;
			RD_M_r				<= 5'b0;
			PCPlus4M_r			<= 32'h0000_0000;
			ALU_ResultM_r		<= 32'h0000_0000;
			ReadDataM_r			<= 32'h0000_0000;
		end
		
		else begin
			RegWriteM_r			<= RegWriteM;
			ResultSrcM_r		<= ResultSrcM;
			RD_M_r				<= RD_M;
			PCPlus4M_r			<= PCPlus4M;
			ALU_ResultM_r		<= ALU_ResultM;
			ReadDataM_r			<= ReadDataM;
			
//			if (MemReadM) begin
//				ReadDataM_r		<= ReadDataM;
//			end
//			
//			else begin
//				ReadDataM_r		<= 32'h0000_0000;
//			end
			
		end
		
	end
	
	
	// =============== OUPUT sang WB ===============
	assign RegWriteW		= RegWriteM_r;
	assign ResultSrcW		= ResultSrcM_r;
	assign RD_W				= RD_M_r;
	assign PCPlus4W		= PCPlus4M_r;
	assign ALU_ResultW	= ALU_ResultM_r;
	assign ReadDataW		= ReadDataM_r;

endmodule