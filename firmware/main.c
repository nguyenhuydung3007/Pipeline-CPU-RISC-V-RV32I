#include <stdint.h>

#define LED (*(volatile uint32_t*)0x10000000)
#define VGA (*(volatile uint32_t*)0x30000000)

int main()
{
    LED = 0x001;   // báo đã vào main

    VGA = 0x00000A20;

    LED = 0x3FF;   // báo chạy qua VGA write

    while(1);
}