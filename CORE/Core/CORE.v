// ==============================================
// Module CORE
// CPU + BUS + RAM + GPIO + HEX display + VGA
// ==============================================

module CORE (

    input clk,
    input reset,

    // ========== DE10 - Lite I/O ==========
    input [9:0] SW,
    input GPIO_0,          

    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,

    output GPIO_1,

    output VGA_HS,
    output VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B
);

    // ========================================
    // CPU <--> BUS Interface
    // ========================================
    wire [31:0] addr;
    wire [31:0] wdata;
    wire [31:0] rdata;
    wire we;
    wire re;

    CPU cpu (

        // Input
        .clk                (clk),
        .reset              (reset),
        .read_dataM         (rdata),

        // Output
        .addrM               (addr),
        .write_dataM         (wdata),
        .mem_writeM          (we),
        .mem_readM           (re)
    );

    // =============== BUS WIRES ===============
    // RAM
    wire [31:0] ram_rd;
    wire ram_we;
    wire ram_re;

    // GPIO
    wire [31:0] gpio_rd;
    wire gpio_we;
    wire gpio_re;

    // UART
    wire [31:0] uart_rd;
    wire uart_we;
    wire uart_re;

    // VGA
    wire [31:0] vga_rd;
    wire vga_we;
    wire vga_re;

    // =============== DATA BUS ===============
    Data_Bus bus (

        // Input
        .addr               (addr),
        .wr_data            (wdata),
        .write_en           (we),
        .read_en            (re),

        // RAM
        .ram_rd_data        (ram_rd),
        .ram_we             (ram_we),
        .ram_re             (ram_re),

        // GPIO
        .gpio_rd_data       (gpio_rd),
        .gpio_we            (gpio_we),
        .gpio_re            (gpio_re),

        // UART
        .uart_rd_data       (uart_rd),
        .uart_we            (uart_we),
        .uart_re            (uart_re),

        // VGA
        .vga_rd_data        (vga_rd),
        .vga_we             (vga_we),
        .vga_re             (vga_re),

        // Trả về CPU
        .rd_data            (rdata)
    );

    // =============== DATA RAM ===============
    Data_RAM ram (

        // Input
        .clk                (clk),
        .addr               (addr),
        .write_data         (wdata),
        .read_en            (ram_re),
        .write_en           (ram_we),

        // Output
        .read_data          (ram_rd)
    );

    // =============== GPIO ===============
    wire [23:0] hex_data;

    GPIO gpio (

        // Input
        .clk                (clk),
        .reset              (reset),

        // Bus Interface
        .addr               (addr),
        .wr_data            (wdata),
        .write_en           (gpio_we),
        .read_en            (gpio_re),

        .SW                 (SW),

        .LEDR               (LEDR),
        .hex_data_out       (hex_data),
        .rd_data            (gpio_rd)
    );
            
    // =============== HEX DISPLAY ===============
    Hex7_Seg hex_display (

        // Input
        .clk                (clk),
        .reset              (reset),
        .write_en           (1'b1),
        .wr_data            ({8'b0, hex_data}),

        // Output
        .HEX0               (HEX0),
        .HEX1               (HEX1),
        .HEX2               (HEX2),
        .HEX3               (HEX3),
        .HEX4               (HEX4),
        .HEX5               (HEX5)
    );

    // =============== UART ===============
    UART_MMIO uart (

        // Input
        .clk                (clk),
        .reset              (reset),

        .addr               (addr),
        .wr_data            (wdata),
        .we                 (uart_we),
        .re                 (uart_re),

        .rx                 (GPIO_0),

        // Ouput
        .rd_data            (uart_rd),
        .tx                 (GPIO_1)
    );

    // =============== VGA ===============
    VGA_MMIO vga (

        // Input
        .clk_cpu            (clk),
        .reset              (reset),

        .addr               (addr),
        .wr_data            (wdata),
        .we                 (vga_we),
        .re                 (vga_re),

        // Output
        .rd_data            (vga_rd),

        .VGA_HS             (VGA_HS),
        .VGA_VS             (VGA_VS),
        .VGA_R              (VGA_R),
        .VGA_G              (VGA_G),
        .VGA_B              (VGA_B)
    );
    
endmodule