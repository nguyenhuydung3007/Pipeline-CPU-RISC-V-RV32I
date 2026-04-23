/* =====================================================
 * Linker script cho RISC-V Pipeline (Harvard)
 * ===================================================== */

ENTRY(start)

/* ================= MEMORY ================= */
MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rw)  : ORIGIN = 0x10000000, LENGTH = 4K
}

/* ================= SECTIONS ================= */
SECTIONS
{
    /* ========== TEXT + RODATA (Instruction Memory) ========== */
    .text :
    {
        . = ALIGN(4);

        *(.text.start)     /* reset vector */
        *(.text*)          /* code */
        *(.rodata*)        /* const data / string */

        . = ALIGN(4);
    } > IMEM

    /* Lưu địa chỉ load của .data trong IMEM */
    _sidata = LOADADDR(.data);

    /* ========== DATA (run ở DMEM, load từ IMEM) ========== */
    .data :
    {
        . = ALIGN(4);

        _sdata = .;
        *(.data*)
        _edata = .;

        . = ALIGN(4);
    } > DMEM AT > IMEM

    /* ========== BSS (zero init) ========== */
    .bss :
    {
        . = ALIGN(4);

        _sbss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;

        . = ALIGN(4);
    } > DMEM

    /* ========== STACK ========== */
    . = ORIGIN(DMEM) + LENGTH(DMEM);
    _stack_top = .;
}