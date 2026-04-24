#include <stdint.h>

#define HEX         (*(volatile uint32_t *)0x10000004)
#define LEDR        (*(volatile uint32_t *)0x10000000)

#define UART_TX     (*(volatile uint32_t *)0x20000000)
#define UART_RX     (*(volatile uint32_t *)0x20000004)
#define UART_STATUS (*(volatile uint32_t *)0x20000008)

#define TX_FULL     (1 << 0)
#define RX_EMPTY    (1 << 1)

// =====================
// delay nhỏ
// =====================
void delay(void)
{
    for (volatile int i = 0; i < 100000; i++);
}

// =====================
// gửi 1 byte + debug
// =====================
void uart_send_char_debug(char c)
{
    // hiển thị trạng thái trước khi gửi
    LEDR = UART_STATUS;

    // chờ TX rảnh
    while (UART_STATUS & TX_FULL);

    UART_TX = (uint32_t)c;

    // hiển thị lại status sau khi gửi
    LEDR = UART_STATUS;

    delay();
}

// =====================
// gửi chuỗi (debug từng ký tự)
// =====================
void uart_send_string_debug(const char *s)
{
    while (*s)
    {
        uart_send_char_debug(*s);
        s++;
    }
}

// =====================
// MAIN
// =====================
int main(void)
{
    while (1)
    {
        // chờ nhận từ PC
        while (UART_STATUS & RX_EMPTY);

        char c = (char)(UART_RX & 0xFF);

        // hiển thị ASCII lên HEX
        uint8_t lo = c & 0x0F;
        uint8_t hi = (c >> 4) & 0x0F;
        HEX = (lo << 0) | (hi << 4);

        // =====================
        // TEST 1: gửi 1 byte
        // =====================
        if (c == '1')
        {
            uart_send_char_debug('A');
        }

        // =====================
        // TEST 2: gửi 2 byte
        // =====================
        if (c == '2')
        {
            uart_send_char_debug('H');
            uart_send_char_debug('E');
            uart_send_char_debug('L');
            uart_send_char_debug('L');
            uart_send_char_debug('O');
        }

        // =====================
        // TEST 3: gửi chuỗi
        // =====================
        if (c == '3')
        {
            uart_send_string_debug("Hello\n");
        }

        // =====================
        // TEST 4: đọc STATUS
        // =====================
        if (c == '4')
        {
            LEDR = UART_STATUS;
        }
    }

    return 0;
}