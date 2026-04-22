#include <stdint.h>

#define LEDR (*(volatile uint32_t *)0x10000000)
#define HEX  (*(volatile uint32_t *)0x10000004)

int main(void)
{
int count = 0;

while (1)
{
    // =====================
    // Tách số
    // =====================
    int ones = count % 10;        // hàng đơn vị
    int tens = (count / 10) % 10; // hàng chục

    // =====================
    // HEX (raw digit)
    // =====================
    HEX = (ones << 0) |   // HEX0
          (tens << 4);    // HEX1

    // =====================
    // LEDR (debug)
    // =====================
    LEDR = count;

    // =====================
    // tăng count
    // =====================
    count+=2;

    if (count == 100)
        count = 0;

    // =====================
    // delay
    // =====================
    for (volatile int d = 0; d < 2000000; d++);
}

return 0;

}
