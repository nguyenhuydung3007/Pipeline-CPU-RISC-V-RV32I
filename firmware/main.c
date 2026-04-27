#include <stdint.h>

// =====================
// MMIO
// =====================
#define UART_TX     (*(volatile uint32_t *)0x20000000)
#define UART_RX     (*(volatile uint32_t *)0x20000004)
#define UART_STATUS (*(volatile uint32_t *)0x20000008)

// =====================
// STATUS BIT
// =====================
#define TX_READY    (1 << 2)
#define RX_EMPTY    (1 << 1)

// =====================
// UART DRIVER
// =====================
void uart_putc(char c)
{
    while (!(UART_STATUS & TX_READY));
    UART_TX = (uint32_t)c;
}

char uart_getc(void)
{
    while (UART_STATUS & RX_EMPTY);
    return (char)(UART_RX & 0xFF);
}

void uart_puts(const char *s)
{
    while (*s)
    {
        uart_putc(*s);
        s++;
    }
}

// =====================
// SEND HEX BYTE (DEBUG)
// =====================
void uart_put_hex(uint8_t val)
{
    const char hex[] = "0123456789ABCDEF";
    uart_putc(hex[(val >> 4) & 0xF]);
    uart_putc(hex[val & 0xF]);
}

// =====================
// TEST FUNCTIONS
// =====================

// Echo test
void test_echo(void)
{
    uart_puts("ECHO MODE\n");

    while (1)
    {
        char c = uart_getc();
        uart_putc(c);
    }
}

// Send string test
void test_string(void)
{
    uart_puts("STRING TEST\n");

    while (1)
    {
        uart_puts("Hello UART\n");
        for (volatile int i = 0; i < 200000; i++);
    }
}

// Binary test
void test_binary(void)
{
    uart_puts("BINARY TEST\n");

    while (1)
    {
        for (int i = 0; i < 256; i++)
        {
            uart_putc((char)i);
        }
    }
}

// RX -> HEX debug
void test_rx_hex(void)
{
    uart_puts("RX HEX MODE\n");

    while (1)
    {
        char c = uart_getc();

        uart_puts("0x");
        uart_put_hex((uint8_t)c);
        uart_putc('\n');
    }
}

// =====================
// MAIN MENU
// =====================
int main(void)
{
    uart_puts("\nUART TEST READY\n");
    uart_puts("1: Echo\n");
    uart_puts("2: String\n");
    uart_puts("3: Binary\n");
    uart_puts("4: RX HEX\n");

    while (1)
    {
        char cmd = uart_getc();

        if (cmd == '1')
        {
            test_echo();
        }
        else if (cmd == '2')
        {
            test_string();
        }
        else if (cmd == '3')
        {
            test_binary();
        }
        else if (cmd == '4')
        {
            test_rx_hex();
        }
    }

    return 0;
}