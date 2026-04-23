#include <stdint.h>

// =====================
// MMIO
// =====================
#define LEDR (*(volatile uint32_t *)0x10000000)
#define HEX  (*(volatile uint32_t *)0x10000004)

// =====================
// delay
// =====================
void delay(void)
{
    for (volatile int i = 0; i < 2000000; i++);
}

// =====================
// hiển thị 2 digit HEX
// =====================
void hex_display(uint8_t val)
{
    uint8_t ones = val % 10;
    uint8_t tens = val / 10;

    HEX = (ones << 0) | (tens << 4);
}

// =====================
// MAIN
// =====================
int main(void)
{
    uint8_t count = 0;

    while (1)
    {
        // hiển thị HEX
        hex_display(count);

        // debug LED
        LEDR = count;

        delay();

        count++;

        if (count >= 100)
            count = 0;
    }

    return 0;
}