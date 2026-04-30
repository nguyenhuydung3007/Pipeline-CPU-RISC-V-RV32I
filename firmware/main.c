#include <stdint.h>

#define VGA ((volatile uint32_t*)0x30000000)

/*
=================================================
SAFE VGA STRING TEST
Theo format hiện tại:

[15:12] BG
[11:8]  FG
[7:0]   ASCII

Mục tiêu:
- Không dùng function
- Không dùng pointer string phức tạp
- Chỉ dùng char array + while loop đơn giản
- Tương thích CPU custom RV32I tốt hơn
=================================================
*/

int main()
{
    volatile uint32_t *vga = VGA;
    int i;

    // Clear screen
    i = 0;
    while(i < 2400)
    {
        vga[i] = 0x00000F20;   // trắng nền đen space
        i = i + 1;
    }

    // =====================================
    // HELLO
    // =====================================
    vga[0] = 0x00000F48;   // H
    vga[1] = 0x00000F45;   // E
    vga[2] = 0x00000F4C;   // L
    vga[3] = 0x00000F4C;   // L
    vga[4] = 0x00000F4F;   // O

    // =====================================
    // WORLD (line 2 = row2 = 160)
    // =====================================
    vga[160] = 0x00000A57; // W
    vga[161] = 0x00000A4F; // O
    vga[162] = 0x00000A52; // R
    vga[163] = 0x00000A4C; // L
    vga[164] = 0x00000A44; // D

    // =====================================
    // CPU (line 4 = 320)
    // =====================================
    vga[320] = 0x00000C43; // C
    vga[321] = 0x00000C50; // P
    vga[322] = 0x00000C55; // U

    // =====================================
    // VGA TEST (line 6 = 480)
    // =====================================
    vga[480] = 0x00000E56; // V
    vga[481] = 0x00000E47; // G
    vga[482] = 0x00000E41; // A
    vga[484] = 0x00000E54; // T
    vga[485] = 0x00000E45; // E
    vga[486] = 0x00000E53; // S
    vga[487] = 0x00000E54; // T

    while(1);

    return 0;
}