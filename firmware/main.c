#include <stdint.h>

// =====================
// MMIO
// =====================
#define LEDR        (*(volatile uint32_t *)0x10000000)
#define HEX         (*(volatile uint32_t *)0x10000004)

#define UART_TX     (*(volatile uint32_t *)0x20000000)
#define UART_RX     (*(volatile uint32_t *)0x20000004)
#define UART_STATUS (*(volatile uint32_t *)0x20000008)

#define TX_FULL     (1 << 0)
#define RX_EMPTY    (1 << 1)

// =====================
// Delay
// =====================
void delay(volatile int d)
{
    while (d--);
}

// =====================
// UART TX
// =====================
void uart_send_char(char c)
{
    while (UART_STATUS & TX_FULL);
    UART_TX = (uint32_t)c;
}

void uart_send_string(const char *s)
{
    while (*s)
        uart_send_char(*s++);
}

// =====================
// Main
// =====================
int main(void)
{
    delay(500000);
    uart_send_string("READY\n");

    while (1)
    {
        LEDR ^= 1;
        delay(100000);

        if (!(UART_STATUS & RX_EMPTY))
        {
            char c = (char)(UART_RX & 0xFF);

            if (c == '1')
                uart_send_string("Hello World!\n");
            else
                uart_send_char(c);
        }
    }

    return 0;
}
