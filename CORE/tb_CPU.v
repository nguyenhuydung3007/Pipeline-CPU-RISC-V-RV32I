`timescale 1ns/1ps

module tb_CPU;

    // =========================
    // SIGNAL
    // =========================
    reg clk;
    reg reset;

    // =========================
    // CLOCK 50MHz
    // =========================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 20ns → 50MHz
    end

    // =========================
    // RESET
    // =========================
    initial begin
        reset = 0;
        #50;
        reset = 1;
    end

    // =========================
    // DUT
    // =========================
    CPU dut (
        .clk(clk),
        .reset(reset)
    );

    // =========================
    // CHECK MEMORY LOAD
    // =========================
    initial begin
        #5;
        $display("=========================================");
        $display("CHECK INSTRUCTION MEMORY");
        $display("MEM[0] = %h", dut.Fetch.instruction_memory.mem[0]);
        $display("MEM[1] = %h", dut.Fetch.instruction_memory.mem[1]);
        $display("=========================================");
    end

    // =========================
    // HEADER
    // =========================
    initial begin
        $display("=====================================================================================");
        $display("Time | PC | Instr | RegW | RD | Result | Stall | Flush | FwdA | FwdB | ALU | MemWrite");
        $display("=====================================================================================");
    end

    // =========================
    // MAIN PIPELINE MONITOR
    // =========================
    always @(posedge clk) begin
        if (reset) begin

            $display("%0t | %h | %h |  %b   | %2d | %h |   %b%b   |  %b%b   |  %b  |  %b  | %h |    %b",
                
                $time,

                // FETCH
                dut.Fetch.PCD,
                dut.InstrD,

                // WRITEBACK
                dut.RegWriteW_out,
                dut.RD_out,
                dut.ResultW,

                // HAZARD
                dut.StallF,
                dut.StallD,

                dut.FlushD,
                dut.FlushE,

                // FORWARDING
                dut.ForwardA_E,
                dut.ForwardB_E,

                // ALU
                dut.Execute.ALU_ResultM_out,

                // MEMORY
                dut.MemWriteM
            );
        end
    end

    // =========================
    // WRITEBACK LOG
    // =========================
    always @(posedge clk) begin
        if (reset && dut.RegWriteW_out) begin
            $display(">>> WB: x%0d = %h", dut.RD_out, dut.ResultW);
        end
    end

    // =========================
    // BRANCH & FLUSH
    // =========================
    always @(posedge clk) begin
        if (reset && dut.PCSrcE) begin
            $display(">>> BRANCH TAKEN at time %0t", $time);
        end

        if (reset && (dut.FlushD || dut.FlushE)) begin
            $display(">>> PIPELINE FLUSH at time %0t", $time);
        end
    end

    // =========================
    // 🚨 X DETECTOR (QUAN TRỌNG)
    // =========================
    always @(posedge clk) begin
        if (reset) begin

            if (^dut.ResultW === 1'bx)
                $display("❌ ERROR: ResultW = X at %0t", $time);

            if (^dut.Execute.ALU_ResultM_out === 1'bx)
                $display("❌ ERROR: ALU = X at %0t", $time);

            if (^dut.Fetch.PCD === 1'bx)
                $display("❌ ERROR: PC = X at %0t", $time);

            if (^dut.InstrD === 1'bx)
                $display("❌ ERROR: InstrD = X at %0t", $time);

            if (^dut.ResultSrcW === 1'bx)
                $display("❌ ERROR: ResultSrcW = X at %0t", $time);

            if (^dut.ForwardA_E === 1'bx || ^dut.ForwardB_E === 1'bx)
                $display("❌ ERROR: Forward = X at %0t", $time);
        end
    end

    // =========================
    // 🚨 ASSERT: KHÔNG GHI X
    // =========================
    always @(posedge clk) begin
        if (reset && dut.RegWriteW_out) begin
            if (^dut.ResultW === 1'bx) begin
                $display("🔥 FATAL: WRITEBACK X DETECTED");
                $stop;
            end
        end
    end

    // =========================
    // OPTIONAL: WAVEFORM
    // =========================
    

    // =========================
    // STOP SIMULATION
    // =========================
    initial begin
        #2000000;
        $display("Simulation finished");
        $stop;
    end

endmodule