#include <stdint.h>

/*
 * CPU Pipeline Test Firmware
 * Kết quả lưu tại OUT[n] = mem[0x100 + n*4]
 * Data_RAM word index = (0x100 + n*4) >> 2 = 64 + n
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
 * OUT[11] mem[75]  = 99          LW/SW + load-use hazard (basic)
 * OUT[12] mem[76]  = 1           BEQ   taken (5 == 5)
 * OUT[13] mem[77]  = 1           BNE   taken (5 != 12)
 * OUT[14] mem[78]  = 1           BLT   taken (5 < 12)
 * OUT[15] mem[79]  = 1           BGE   taken (12 >= 5)
 * OUT[16] mem[80]  = 1           BLTU  taken (5 < 12 unsigned)
 * OUT[17] mem[81]  = 10          JAL + JALR (function call)
 * OUT[18] mem[82]  = 39          Forwarding chain (original)
 * OUT[19] mem[83]  = 5           Loop backward branch (cnt++)
 *
 * --- NEW TESTS ---
 * OUT[20] mem[84]  = 1           Branch NOT-taken: x!=y, BEQ not taken, body executes
 * OUT[21] mem[85]  = 4           AUIPC: consecutive AUIPC difference = 4 bytes
 * OUT[22] mem[86]  = 33          Forwarding chain 3 dep. instr: EX->EX + MEM->EX
 * OUT[23] mem[87]  = 50          Load-use hazard: LW then immediate ADDI (stall + MEM->EX)
 * OUT[24] mem[88]  = 10          Loop: sum 1+2+3+4 = 10 (backward branch)
 */

#define OUT ((volatile uint32_t *)0x00000100)

/* noinline buộc compiler sinh JAL+JALR thay vì inline */
__attribute__((noinline))
static int32_t fn_add(int32_t a, int32_t b) { return a + b; }

int main(void)
{
    volatile uint32_t *out = OUT;
    int n = 0;

    /* volatile buộc load từ memory mỗi lần đọc → tránh constant folding */
    volatile int32_t a = 5;
    volatile int32_t b = 12;

    /* --- R-TYPE --- */
    out[n++] = a + b;                                    /* ADD  : 17         */
    out[n++] = b - a;                                    /* SUB  : 7          */
    out[n++] = a & b;                                    /* AND  : 4          */
    out[n++] = a | b;                                    /* OR   : 13         */
    out[n++] = a ^ b;                                    /* XOR  : 9          */

    /* --- SHIFT --- */
    out[n++] = a << 2;                                   /* SLL  : 20         */
    out[n++] = (uint32_t)b >> 1;                         /* SRL  : 6          */
    { int32_t t = -8; out[n++] = t >> 1; }               /* SRA  : 0xFFFFFFFC */

    /* --- SET LESS THAN --- */
    out[n++] = (a < b) ? 1 : 0;                          /* SLT  : 1          */
    out[n++] = ((uint32_t)a < (uint32_t)b) ? 1 : 0;     /* SLTU : 1          */

    /* --- LUI --- */
    { int32_t t = 0x12000000; out[n++] = t; }            /* LUI  : 0x12000000 */

    /* --- LW/SW + LOAD-USE HAZARD (basic) --- */
    { volatile int32_t t = 99; out[n++] = t; }           /* LW after SW : 99  */

    /* --- BRANCH TAKEN --- */
    out[n++] = (a == 5)                    ? 1 : 0;      /* BEQ  : 1          */
    out[n++] = (a != b)                    ? 1 : 0;      /* BNE  : 1          */
    out[n++] = (a < b)                     ? 1 : 0;      /* BLT  : 1          */
    out[n++] = (b >= a)                    ? 1 : 0;      /* BGE  : 1          */
    out[n++] = ((uint32_t)a < (uint32_t)b) ? 1 : 0;     /* BLTU : 1          */

    /* --- JAL + JALR --- */
    out[n++] = fn_add(3, 7);                             /* JAL+JALR : 10     */

    /* --- FORWARDING CHAIN (original) --- */
    {
        int32_t x = fn_add(a, b);    /* x = 17 */
        int32_t y = x + (int32_t)a;  /* y = 22 */
        int32_t z = y + x;           /* z = 39 */
        out[n++] = z;                                    /* Forwarding : 39   */
    }

    /* --- LOOP backward branch (cnt++) --- */
    {
        int32_t cnt = 0;
        for (int32_t i = 0; i < 5; i++) cnt++;
        out[n++] = cnt;                                  /* Loop : 5          */
    }

    /* ================================================================
     * NEW TESTS
     * ================================================================ */

    /* --- a) BRANCH NOT-TAKEN ---
     * x=5, y=12: x != y → compiler sinh BEQ(x,y) để skip body
     * Vì x != y → BEQ NOT taken → fallthrough → body thực thi
     * Kiểm tra: instruction ngay sau branch (nt = 1) phải execute đúng */
    {
        volatile int32_t x = 5, y = 12;
        int32_t nt = 0;
        if (x != y) {    /* BEQ x,y: NOT taken vì x != y → body chạy */
            nt = 1;
        }
        out[n++] = nt;   /* expected: 1 */
    }

    /* --- b) AUIPC ---
     * Hai AUIPC liên tiếp: pc_b - pc_a = 4 (mỗi instruction = 4 bytes)
     * Verify PC-relative: auipc rd, 0 → rd = PC + 0 = PC của instruction đó */
    {
        uint32_t pc_a, pc_b;
        asm volatile (
            "auipc %0, 0\n\t"
            "auipc %1, 0"
            : "=r"(pc_a), "=r"(pc_b)
        );
        out[n++] = pc_b - pc_a;   /* expected: 4 */
    }

    /* --- c) FORWARDING CHAIN (3 dependent instructions) ---
     * Pipeline timing:
     *   r1: IF ID EX  MEM WB
     *   r2:    IF ID  EX  MEM WB    ← r1 từ EX/MEM  → EX→EX forwarding
     *   r3:       IF  ID  EX  MEM WB ← r2 từ EX/MEM → EX→EX forwarding
     *                                  r1 từ MEM/WB  → MEM→EX forwarding  */
    {
        volatile int32_t base = 10;
        int32_t r1 = base + 5;    /* r1 = 15 */
        int32_t r2 = r1 + 3;      /* r2 = 18  (EX→EX: r1 forwarded từ EX/MEM)  */
        int32_t r3 = r1 + r2;     /* r3 = 33  (MEM→EX: r1, EX→EX: r2)          */
        out[n++] = r3;             /* expected: 33 */
    }

    /* --- d) LOAD-USE HAZARD + MEM→EX FORWARDING ---
     * LW ngay sau đó dùng kết quả → pipeline stall 1 cycle
     * Sau stall: giá trị forwarded từ MEM/WB → EX (MEM→EX forwarding) */
    {
        volatile int32_t mem_src = 42;
        int32_t loaded = mem_src;    /* LW: nạp 42 */
        int32_t used   = loaded + 8; /* ADDI ngay sau LW → load-use stall + MEM→EX fwd */
        out[n++] = used;             /* expected: 50 */
    }

    /* --- e) LOOP sum 1+2+3+4 ---
     * Backward branch lặp 4 lần, kiểm tra branch target đúng mỗi iteration */
    {
        int32_t sum = 0;
        for (int32_t i = 1; i <= 4; i++) sum += i;
        out[n++] = sum;   /* expected: 10 */
    }

    while (1);
    return 0;
}
