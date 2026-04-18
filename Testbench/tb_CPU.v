`timescale 1ns/1ps

// ============================================================
// Testbench: tb_CPU
// Firmware: firmware.hex (comprehensive CPU test)
//
// Cấu trúc firmware:
//   PC=0x00: AUIPC x2, 1        ; SP = 0x1000
//   PC=0x04: ADDI x2, x2, 0
//   PC=0x08: JAL x1, 12         ; call main tại PC=0x14, x1=0x0C
//   PC=0x0C: fn_add (ADD+ret)
//   PC=0x14: main() — ADDI x2, x2, -32  ; SP = 0xFE0
//   ...
//   PC=0x178: JAL x0, 0          ; halt
//
// Expected final state:
//   x2 = 0x00000FE0  (SP = 0x1000 - 32)
//
//   mem[64]  = 17          ADD   : 5 + 12
//   mem[65]  = 7           SUB   : 12 - 5
//   mem[66]  = 4           AND   : 5 & 12
//   mem[67]  = 13          OR    : 5 | 12
//   mem[68]  = 9           XOR   : 5 ^ 12
//   mem[69]  = 20          SLL   : 5 << 2
//   mem[70]  = 6           SRL   : 12 >> 1
//   mem[71]  = 0xFFFFFFFC  SRA   : -8 >> 1
//   mem[72]  = 1           SLT   : 5 < 12
//   mem[73]  = 1           SLTU  : 5 < 12 unsigned
//   mem[74]  = 0x12000000  LUI
//   mem[75]  = 99          LW/SW + load-use hazard
//   mem[76]  = 1           BEQ   taken
//   mem[77]  = 1           BNE   taken
//   mem[78]  = 1           BLT   taken
//   mem[79]  = 1           BGE   taken
//   mem[80]  = 1           BLTU  taken
//   mem[81]  = 10          JAL + JALR : fn_add(3,7)
//   mem[82]  = 39          Forwarding chain EX->EX
//   mem[83]  = 5           Loop (backward branch x5)
// ============================================================

module tb_CPU;

    // ========================
    // SIGNAL
    // ========================
    reg clk;
    reg reset;

    integer pass_count;
    integer fail_count;

    // ========================
    // CLOCK 50MHz (20ns)
    // ========================
    initial clk = 0;
    always #10 clk = ~clk;

    // ========================
    // RESET (active low)
    // ========================
    initial begin
        reset = 0;
        #50;
        reset = 1;
    end

    // ========================
    // DUT
    // ========================
    CPU dut (
        .clk   (clk),
        .reset (reset)
    );

    // ========================
    // TASK: CHECK
    // ========================
    task check;
        input [255:0] name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual === expected) begin
                $display("  PASS | %-24s | got = 0x%08h", name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-24s | got = 0x%08h | expected = 0x%08h", name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ========================
    // FIRMWARE LOAD CHECK
    // ========================
    initial begin
        #5;
        $display("============================================================");
        $display("FIRMWARE CHECK");
        $display("  mem[0] = %h  (expected: 00001117 = AUIPC x2, 1)", dut.Fetch.instruction_memory.mem[0]);
        $display("  mem[1] = %h  (expected: 00010113 = ADDI x2, x2, 0)", dut.Fetch.instruction_memory.mem[1]);
        $display("  mem[2] = %h  (expected: 00c000ef = JAL x1, 12)", dut.Fetch.instruction_memory.mem[2]);
        $display("============================================================");
    end

    // ========================
    // PIPELINE MONITOR
    // ========================
    initial begin
        $display("\n============================================================");
        $display("PIPELINE MONITOR");
        $display("Time(ns) | PCD      | InstrD   | RegW | RD | ResultW  | StlF StlD | FlsD FlsE | FwdA FwdB | ALU_Result");
        $display("------------------------------------------------------------");
    end

    always @(posedge clk) begin
        if (reset) begin
            $display("%7t  | %h | %h |  %b   | x%-2d | %h |   %b    %b  |   %b    %b  |  %2b   %2b  | %h",
                $time,
                dut.Fetch.PCF_reg,
                dut.InstrD,
                dut.RegWriteW_out,
                dut.RD_out,
                dut.ResultW,
                dut.StallF,
                dut.StallD,
                dut.FlushD,
                dut.FlushE,
                dut.ForwardA_E,
                dut.ForwardB_E,
                dut.Execute.ALU_ResultM_out
            );
        end
    end

    // ========================
    // WRITEBACK LOG
    // ========================
    always @(posedge clk) begin
        if (reset && dut.RegWriteW_out && dut.RD_out != 0) begin
            $display("  >>> WB: x%-2d <= 0x%08h", dut.RD_out, dut.ResultW);
        end
    end

    // ========================
    // BRANCH / STALL LOG
    // ========================
    always @(posedge clk) begin
        if (reset) begin
            if (dut.PCSrcE)
                $display("  >>> BRANCH/JUMP at t=%0t | PCTarget=0x%08h", $time, dut.PCTargetE);
            if (dut.StallF)
                $display("  >>> STALL at t=%0t (load-use hazard)", $time);
        end
    end

    // ========================
    // X DETECTOR
    // ========================
    always @(posedge clk) begin
        if (reset) begin
            if (^dut.ResultW          === 1'bx) $display("  ERROR: ResultW   = X at t=%0t", $time);
            if (^dut.Fetch.PCF_reg    === 1'bx) $display("  ERROR: PC        = X at t=%0t", $time);
            if (^dut.InstrD           === 1'bx) $display("  ERROR: InstrD    = X at t=%0t", $time);
            if (^dut.ForwardA_E       === 1'bx) $display("  ERROR: ForwardA  = X at t=%0t", $time);
            if (^dut.ForwardB_E       === 1'bx) $display("  ERROR: ForwardB  = X at t=%0t", $time);
            if (^dut.Execute.ALU_ResultM_out === 1'bx)
                                                $display("  ERROR: ALU_Result= X at t=%0t", $time);
        end
    end

    // ========================
    // VERIFICATION
    // ~95 instr x 2.5 cycle + loop overhead ≈ 260 cycle x 20ns = 5200ns
    // Dùng #10000 để chắc chắn
    // ========================
    initial begin
        pass_count = 0;
        fail_count = 0;

        #10000;

        $display("\n============================================================");
        $display("REGISTER VERIFICATION");
        $display("------------------------------------------------------------");
        check("x2 (stack ptr)",      dut.Decode.regfile.Register[2],  32'h0000_0FE0);

        $display("\n------------------------------------------------------------");
        $display("DATA MEMORY VERIFICATION  (base addr 0x100, index = addr>>2)");
        $display("------------------------------------------------------------");
        check("mem[64]  ADD   5+12",  dut.Memory.dmem.mem[64],  32'd17);
        check("mem[65]  SUB  12-5",   dut.Memory.dmem.mem[65],  32'd7);
        check("mem[66]  AND   5&12",  dut.Memory.dmem.mem[66],  32'd4);
        check("mem[67]  OR    5|12",  dut.Memory.dmem.mem[67],  32'd13);
        check("mem[68]  XOR   5^12",  dut.Memory.dmem.mem[68],  32'd9);
        check("mem[69]  SLL   5<<2",  dut.Memory.dmem.mem[69],  32'd20);
        check("mem[70]  SRL  12>>1",  dut.Memory.dmem.mem[70],  32'd6);
        check("mem[71]  SRA  -8>>1",  dut.Memory.dmem.mem[71],  32'hFFFF_FFFC);
        check("mem[72]  SLT   5<12",  dut.Memory.dmem.mem[72],  32'd1);
        check("mem[73]  SLTU  5<12",  dut.Memory.dmem.mem[73],  32'd1);
        check("mem[74]  LUI",         dut.Memory.dmem.mem[74],  32'h1200_0000);
        check("mem[75]  LW/SW luse",  dut.Memory.dmem.mem[75],  32'd99);
        check("mem[76]  BEQ  taken",  dut.Memory.dmem.mem[76],  32'd1);
        check("mem[77]  BNE  taken",  dut.Memory.dmem.mem[77],  32'd1);
        check("mem[78]  BLT  taken",  dut.Memory.dmem.mem[78],  32'd1);
        check("mem[79]  BGE  taken",  dut.Memory.dmem.mem[79],  32'd1);
        check("mem[80]  BLTU taken",  dut.Memory.dmem.mem[80],  32'd1);
        check("mem[81]  JAL+JALR",    dut.Memory.dmem.mem[81],  32'd10);
        check("mem[82]  Forwarding",  dut.Memory.dmem.mem[82],  32'd39);
        check("mem[83]  Loop x5",     dut.Memory.dmem.mem[83],  32'd5);

        $display("\n============================================================");
        $display("RESULT: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("============================================================\n");

        $display("RD1_E=%h RD2_E=%h | ForwardA_out=%h ForwardB_out=%h | SrcA=%h SrcB=%h",
    dut.Execute.RD1_E,
    dut.Execute.RD2_E,
    dut.Execute.ForwardA_out,
    dut.Execute.ForwardB_out,
    dut.Execute.SrcA,
    dut.Execute.SrcB
);

$display("RS2_E=%d ForwardB=%b WriteDataM=%h",
    dut.RS2_E,
    dut.ForwardB_E,
    dut.Memory.WriteDataM
);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED - Kiem tra pipeline monitor phia tren");

        $stop;
    end

    // ========================
    // TIMEOUT GUARD
    // ========================
    initial begin
        #4000000;
        $display("TIMEOUT - Simulation exceeded limit");
        
        $stop;
    end

endmodule
