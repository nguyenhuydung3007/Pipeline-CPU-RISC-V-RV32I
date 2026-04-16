#include <stdint.h>

// =========================
// PERIPHERAL MAP
// =========================
#define VGA   ((volatile uint16_t *)0x20000000)
#define LEDS  (*(volatile uint32_t *)0x10000000)

// =========================
// VGA FORMAT
// =========================
static inline uint16_t VGA_CHAR(char c, uint8_t fg, uint8_t bg)
{
    return (fg << 12) | (bg << 8) | (uint8_t)c;
}

// =========================
// DELAY (simple)
// =========================
void delay()
{
    for (volatile int i = 0; i < 200000; i++);
}

// =========================
// CLEAR SCREEN
// =========================
void vga_clear(uint8_t bg)
{
    for (int i = 0; i < 2400; i++)
        VGA[i] = VGA_CHAR(' ', 0x0, bg);
}

// =========================
// PUT STRING
// =========================
void vga_put_string(int x, int y, const char *str, uint8_t fg, uint8_t bg)
{
    int base = y * 80 + x;

    while (*str)
        VGA[base++] = VGA_CHAR(*str++, fg, bg);
}

// =========================
// PRINT NUMBER (0 → 9999)
// =========================
void vga_put_number(int x, int y, int num, uint8_t fg, uint8_t bg)
{
    char buf[6];
    int i = 0;

    if (num == 0)
    {
        buf[i++] = '0';
    }
    else
    {
        while (num > 0)
        {
            buf[i++] = '0' + (num % 10);
            num /= 10;
        }
    }

    // đảo chuỗi
    for (int j = 0; j < i / 2; j++)
    {
        char tmp = buf[j];
        buf[j] = buf[i - j - 1];
        buf[i - j - 1] = tmp;
    }

    buf[i] = '\0';

    vga_put_string(x, y, buf, fg, bg);
}

// =========================
// DRAW COLOR BLOCKS
// =========================
void vga_draw_color_blocks()
{
    // nửa dưới: y = 15 → 29
    for (int y = 15; y < 30; y++)
    {
        for (int x = 0; x < 80; x++)
        {
            uint8_t color = (x / 10) & 0xF; // chia cột thành block màu

            VGA[y * 80 + x] = VGA_CHAR(' ', 0x0, color);
        }
    }
}

// =========================
// MAIN
// =========================
int main(void)
{
    int count = 0;

    vga_clear(0x0);

    vga_put_string(20, 2, "VGA COUNTER DEMO", 0xE, 0x0);

    // vẽ nền màu
    vga_draw_color_blocks();

    while (1)
    {
        // =====================
        // LED COUNTER
        // =====================
        LEDS = count;

        // =====================
        // VGA DISPLAY COUNTER
        // =====================
        vga_put_string(30, 6, "COUNT:", 0xF, 0x0);
        vga_put_number(37, 6, count, 0xA, 0x0);

        // =====================
        // tăng counter
        // =====================
        count++;

        if (count > 9999)
            count = 0;

        delay();
    }

    return 0;
}