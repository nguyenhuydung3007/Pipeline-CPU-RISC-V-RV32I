`timescale 1ns/1ps

// ============================================================
// Testbench: tb_CPU_firmware
// Firmware: firmware.hex
//
// Chương trình được test:
//   SP = 0x1000
//   JAL ra, main          ; gọi hàm tại 0xC
//   main:
//     SP = SP - 16        ; cấp phát stack frame
//     mem[SP+0]  = 100    ; lưu a = 100
//     mem[SP+4]  = 200    ; lưu b = 200
//     i = 0
//     while (2 >= i):
//         i++             ; vòng lặp 3 lần
//     halt                ; JAL x0, 0
//
// Expected final state:
//   x1  = 0x0000000C  (return address từ JAL tại PC=0x8)
//   x2  = 0x00000FF0  (stack pointer = 0x1000 - 16)
//   x14 = 2           (hằng số so sánh trong vòng lặp)
//   x15 = 3           (biến đếm i sau 3 lần lặp)
//   Data_RAM[1020]    = 100  (SW tại địa chỉ 0xFF0)
//   Data_RAM[1021]    = 200  (SW tại địa chỉ 0xFF4)
// ============================================================

module tb_CPU_firmware;

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
                $display("  PASS | %-20s | got = 0x%08h", name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-20s | got = 0x%08h | expected = 0x%08h", name, actual, expected);
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
        $display("  mem[2] = %h  (expected: 004000ef = JAL x1, 4)", dut.Fetch.instruction_memory.mem[2]);
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
                $display("  >>> BRANCH/JUMP taken at t=%0t | PCTarget = 0x%08h", $time, dut.PCTargetE);
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
    // VERIFICATION (sau khi chương trình hoàn thành)
    // Ước tính: ~40 cycle x 20ns = 800ns sau reset
    // Chờ t=1600ns để chắc chắn
    // ========================
    initial begin
        pass_count = 0;
        fail_count = 0;

        // Chờ chương trình chạy xong (vào halt loop tại 0x34)
        #1600;

        $display("\n============================================================");
        $display("REGISTER FILE VERIFICATION");
        $display("------------------------------------------------------------");
        check("x1 (return addr)",  dut.Decode.regfile.Register[1],  32'h0000_000C);
        check("x2 (stack ptr)",    dut.Decode.regfile.Register[2],  32'h0000_0FF0);
        check("x14 (cmp const)",   dut.Decode.regfile.Register[14], 32'h0000_0002);
        check("x15 (loop i)",      dut.Decode.regfile.Register[15], 32'h0000_0003);

        $display("\n------------------------------------------------------------");
        $display("DATA MEMORY VERIFICATION");
        $display("  (addr 0xFF0 -> index [11:2] = 0x3FC = 1020)");
        $display("  (addr 0xFF4 -> index [11:2] = 0x3FD = 1021)");
        $display("------------------------------------------------------------");
        check("mem[0xFF0] = 100",  dut.Memory.dmem.mem[1020], 32'd100);
        check("mem[0xFF4] = 200",  dut.Memory.dmem.mem[1021], 32'd200);

        $display("\n============================================================");
        $display("RESULT: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("============================================================\n");

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
