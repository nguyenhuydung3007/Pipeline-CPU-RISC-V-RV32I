.section .text.start
.global start

start:
    la sp, _stack_top

    /* copy .data từ IMEM → DMEM */
    la a0, _sidata
    la a1, _sdata
    la a2, _edata

copy_data:
    beq a1, a2, clear_bss
    lw t0, 0(a0)
    sw t0, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    j copy_data

clear_bss:
    la a0, _sbss
    la a1, _ebss

zero_bss:
    beq a0, a1, main
    sw zero, 0(a0)
    addi a0, a0, 4
    j zero_bss

main:
    call main

loop:
    j loop