#include <stdint.h>

int main()
{
    int a = 5;
    int b = 10;
    int c;
    int d;
    int e;

    // =========================
    // TEST 1: ALU
    // =========================
    c = a + b;      // x? = 15
    d = b - a;      // x? = 5
    e = a ^ b;      // x? = 15

    // =========================
    // TEST 2: FORWARDING
    // =========================
    int f = 1;
    int g = f + 2;   // dùng ngay → forward
    int h = g + 3;   // chain forward

    // =========================
    // TEST 3: LOAD / STORE
    // =========================
    int mem[4];

    mem[0] = 100;     // store
    mem[1] = 200;

    int x = mem[0];   // load
    int y = mem[1];

    // =========================
    // TEST 4: LOAD-USE HAZARD
    // =========================
    int z = mem[0];   // lw
    int w = z + 1;    // phải stall

    // =========================
    // TEST 5: BRANCH
    // =========================
    int i = 0;

    while (i < 3)
    {
        i++;
    }

    // =========================
    // DONE (loop vô hạn)
    // =========================
    while (1)
    {
        // giữ CPU sống
    }

    return 0;
}