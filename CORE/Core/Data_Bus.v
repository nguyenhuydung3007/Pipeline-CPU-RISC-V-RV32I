module Data_Bus (

    input [31:0] addr,
    input [31:0] wr_data,
    input        write_en,
    input        read_en,

    // RAM
    input [31:0] ram_rd_data,
    output       ram_we,
    output       ram_re,

    // GPIO
    input [31:0] gpio_rd_data,
    output       gpio_we,
    output       gpio_re,

    // UART
    input [31:0] uart_rd_data,
    output       uart_we,
    output       uart_re,

    // CPU Read data
    output reg [31:0] rd_data
);

    // ===============================================
    // MEMORY MAPPING
    // ===============================================

    // =============== GPIO MEMORY ===============
    parameter GPIO_ADDR         = 32'h1000_0000;
    parameter GPIO_SIRE_ADDR    = 32'h0000_0100;

    // =============== UART MEMORY ===============
    parameter UART_ADDR         = 32'h2000_0000;
    parameter UART_SIZE_ADDR    = 32'h0000_0100;

    // ===============================
    // Address Mapp
    // ===============================
    wire sel_ram    = (addr < GPIO_ADDR);
    wire sel_gpio   = (addr >= GPIO_ADDR && addr < (GPIO_ADDR + GPIO_SIRE_ADDR));
    wire sel_uart   = (addr >= UART_ADDR && addr < (UART_ADDR + UART_SIZE_ADDR));

    // ==============================
    // Write Enable
    // ==============================
    assign ram_we   = write_en && sel_ram;
    assign gpio_we  = write_en && sel_gpio;
    assign uart_we  = write_en && sel_uart;

    // =============================
    // Read Enable
    // =============================
    assign ram_re   = read_en && sel_ram;
    assign gpio_re  = read_en && sel_gpio;
    assign uart_re  = read_en  && sel_uart;

    // ============================
    // Read Data MUX
    // ============================
    always @(*) begin
        
        if (sel_ram) begin
             rd_data    = ram_rd_data;
        end

        else if (sel_gpio) begin
            rd_data     = gpio_rd_data;
        end

        else if (sel_uart) begin
            rd_data     = uart_rd_data;
        end

        else begin
            rd_data     = 32'd0;
        end

    end 

endmodule