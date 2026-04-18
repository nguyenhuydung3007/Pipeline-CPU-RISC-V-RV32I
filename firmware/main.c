#include <stdint.h>

/*
 * CPU Pipeline Test Firmware
 *
 * Kết quả lưu tại OUT[n] = mem[0x100 + n*4]
 * Data_RAM index = (0x100 + n*4) >> 2 = 64 + n
 *
 * OUT[ 0] mem[64]  = 17          ADD   : 5 + 12
 * OUT[ 1] mem[65]  = 7           SUB   : 12 - 5
 * OUT[ 2] mem[66]  = 4           AND   : 5 & 12
 * OUT[ 3] mem[67]  = 13          OR    : 5 | 12
 * OUT[ 4] mem[68]  = 9           XOR   : 5 ^ 12
 * OUT[ 5] mem[69]  = 20          SLL   : 5 << 2
 * OUT[ 6] mem[70]  = 6           SRL   : 12 >> 1 (unsigned)
 * OUT[ 7] mem[71]  = 0xFFFFFFFC  SRA   : -8 >> 1 (signed)
 * OUT[ 8] mem[72]  = 1           SLT   : 5 < 12
 * OUT[ 9] mem[73]  = 1           SLTU  : 5 < 12 (unsigned)
 * OUT[10] mem[74]  = 0x12000000  LUI
 * OUT[11] mem[75]  = 99          LW/SW + load-use hazard
 * OUT[12] mem[76]  = 1           BEQ   taken (5 == 5)
 * OUT[13] mem[77]  = 1           BNE   taken (5 != 12)
 * OUT[14] mem[78]  = 1           BLT   taken (5 < 12)
 * OUT[15] mem[79]  = 1           BGE   taken (12 >= 5)
 * OUT[16] mem[80]  = 1           BLTU  taken (5 < 12 unsigned)
 * OUT[17] mem[81]  = 10          JAL + JALR (function call)
 * OUT[18] mem[82]  = 39          Forwarding chain EX->EX
 * OUT[19] mem[83]  = 5           Loop (backward branch)
 */

#define OUT ((volatile uint32_t *)0x00000100)

/* noinline buộc compiler sinh JAL + JALR, tránh inline */
__attribute__((noinline))
static int32_t fn_add(int32_t a, int32_t b) { return a + b; }

int main(void)
{
    volatile uint32_t *out = OUT;
    int n = 0;

    /* volatile buộc LW mỗi lần đọc → sinh R-type thay vì fold constant */
    volatile int32_t a;
    volatile int32_t b;
    a = 5;
    b = 12;

    /* R-TYPE */
    out[n++] = a + b;                                    /* ADD  : 17         */
    out[n++] = b - a;                                    /* SUB  : 7          */
    out[n++] = a & b;                                    /* AND  : 4          */
    out[n++] = a | b;                                    /* OR   : 13         */
    out[n++] = a ^ b;                                    /* XOR  : 9          */

    /* SHIFT */
    out[n++] = a << 2;                                   /* SLL  : 20         */
    out[n++] = (uint32_t)b >> 1;                         /* SRL  : 6          */
    { int32_t t = -8;   out[n++] = t >> 1; }             /* SRA  : 0xFFFFFFFC */

    /* SET LESS THAN */
    out[n++] = (a < b) ? 1 : 0;                          /* SLT  : 1          */
    out[n++] = ((uint32_t)a < (uint32_t)b) ? 1 : 0;     /* SLTU : 1          */

    /* LUI */
    { int32_t t = 0x12000000; out[n++] = t; }            /* LUI  : 0x12000000 */

    /* LW / SW + load-use hazard */
    { volatile int32_t t = 99; out[n++] = t; }           /* LW immediately after SW : 99 */

    /* BRANCH */
    out[n++] = (a == 5)              ? 1 : 0;            /* BEQ  : 1          */
    out[n++] = (a != b)              ? 1 : 0;            /* BNE  : 1          */
    out[n++] = (a < b)               ? 1 : 0;            /* BLT  : 1          */
    out[n++] = (b >= a)              ? 1 : 0;            /* BGE  : 1          */
    out[n++] = ((uint32_t)a < (uint32_t)b) ? 1 : 0;     /* BLTU : 1          */

    /* JAL + JALR */
    out[n++] = fn_add(3, 7);                             /* JAL+JALR : 10     */

    /* FORWARDING CHAIN EX->EX (dùng fn để tránh fold, kết quả ở reg) */
    {
        int32_t x = fn_add(a, b);   /* x = 17 */
        int32_t y = x + (int32_t)a; /* y = 22, x forwarded từ WB */
        int32_t z = y + x;          /* z = 39, y forwarded từ EX */
        out[n++] = z;                                    /* Forwarding : 39   */
    }

    /* LOOP (backward branch) */
    {
        int32_t cnt = 0;
        for (int32_t i = 0; i < 5; i++) cnt++;
        out[n++] = cnt;                                  /* Loop : 5          */
    }

    /* Halt */
    while (1);
    return 0;
}
