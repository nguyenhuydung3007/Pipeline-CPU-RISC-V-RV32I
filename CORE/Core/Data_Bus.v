// ==========================================================
// Module Data_Bus
// CPU System Bus
//
// Memory Map
// ----------------------------------------------------------
// 0x0000_0000 ~ 0x0FFF_FFFF -- RAM
// 0x1000_0000 ~ 0x1000_00FF -- GPIO
// 0x2000_0000 ~ 0x2000_00FF -- UART
// 0x3000_0000 ~ 0x3000_2FFF -- VGA
// ==========================================================

module Data_Bus (

    input [31:0] addr,
    input [31:0] wr_data,
    input        write_en,
    input        read_en,

    // =============== RAM ===============
    input [31:0] ram_rd_data,
    output       ram_we,
    output       ram_re,

    // =============== GPIO ===============
    input [31:0] gpio_rd_data,
    output       gpio_we,
    output       gpio_re,

    // =============== UART ===============
    input [31:0] uart_rd_data,
    output       uart_we,
    output       uart_re,

    // =============== VGA ===============
    input [31:0] vga_rd_data,
    output       vga_we,
    output       vga_re,

    // =============== CPU READ ===============
    output reg [31:0] rd_data
);

    // ===============================================
    // MEMORY MAPPING
    // ===============================================

    // =============== GPIO MEMORY ===============
    localparam GPIO_ADDR    = 32'h1000_0000;
    localparam GPIO_SIRE    = 32'h0000_0100;

    // =============== UART MEMORY ===============
    localparam UART_ADDR    = 32'h2000_0000;
    localparam UART_SIZE    = 32'h0000_0100;

    // =============== VGA MEMORY ===============
    localparam VGA_ADDR     = 32'h3000_0000;
    localparam VGA_SIZE     = 32'h3000_3000;    // 12KB

    // ===============================
    // Address Mapp
    // ===============================
    wire sel_ram;
    wire sel_gpio;
    wire sel_uart;
    wire sel_vga;

    assign sel_ram    = (addr < GPIO_ADDR);
    assign sel_gpio   = (addr >= GPIO_ADDR && addr < (GPIO_ADDR + GPIO_SIRE));
    assign sel_uart   = (addr >= UART_ADDR && addr < (UART_ADDR + UART_SIZE));
    assign sel_vga    = (addr >= VGA_ADDR  && addr < (VGA_ADDR  + VGA_SIZE));

    // ==============================
    // Write Enable
    // ==============================
    assign ram_we   = write_en && sel_ram;
    assign gpio_we  = write_en && sel_gpio;
    assign uart_we  = write_en && sel_uart;
    assign vga_we   = write_en && sel_vga;

    // =============================
    // Read Enable
    // =============================
    assign ram_re   = read_en && sel_ram;
    assign gpio_re  = read_en && sel_gpio;
    assign uart_re  = read_en && sel_uart;
    assign vga_re   = read_en && sel_vga;

    // ============================
    // Read Data MUX
    // ============================
    always @(*) begin
        
        if (sel_ram) begin
             rd_data = ram_rd_data;
        end

        else if (sel_gpio) begin
            rd_data = gpio_rd_data;
        end

        else if (sel_uart) begin
            rd_data = uart_rd_data;
        end

        else if (sel_vga) begin
            rd_data = vga_rd_data;
        end

        else begin
            rd_data = 32'd0;
        end

    end 

endmodule