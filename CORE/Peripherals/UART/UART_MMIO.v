// ===================================================
// Module UART Memory Mapping I/O
// + Kết nối BUS <--> UART
// + addr: 0x2000_0000: TX
// + addr: 0x2000_0004: RX
// + addr: 0x2000_0008: STATUS
// ===================================================

module UART_MMIO (

    input clk,
    input reset,

    // BUS
    input [31:0] addr,
    input [31:0] wr_data,
    input        we,
    input        re,
    
    output reg [31:0] rd_data,

    // UART PINS
    input rx,
    output tx
);

    wire tx_full;
    wire rx_empty;
    wire [7:0] rx_data;
    wire [7:0] rx_peek;
    wire rx_irq;

    reg tx_wr_en;
    reg rx_rd_en;

    UART uart_core (

        // Input
        .clk            (clk),
        .reset          (reset),

        .rx             (rx),
        .tx             (tx),

        // TX
        .tx_wr_en       (tx_wr_en),
        .tx_data        (wr_data[7:0]),
        .tx_full        (tx_full),

        // RX
        .rx_rd_en       (rx_rd_en),
        .rx_data        (rx_data),
        .rx_peek        (rx_peek),
        .rx_empty       (rx_empty),

        // Interfaces
        .rx_irq         (rx_irq)
    );

    // ===============================
    // WRITE
    // CPU --> UART
    // =============================== 
    always @(*) begin

        tx_wr_en = 0;

        if (we && addr[3:2] == 2'b00) begin
            if (!tx_full) begin
                tx_wr_en = 1;
            end
        end

    end

    // ===============================
    // READ
    // UART --> CPU
    // =============================== 
    always @(*) begin
        
        rx_rd_en = 0;

        if (re && addr[3:2] == 2'b01) begin
            if (!rx_empty) begin
                rx_rd_en = 1;
            end
        end

    end

    // =============== READ DATA ===============
    always @(*) begin
        
        case (addr[3:2])

            // TX DATA
            2'b00:  rd_data = 32'd0;

            // RX DATA
            2'b01:  rd_data = {24'b0, rx_peek};

            // STATUS
            2'b10:  rd_data = {30'b0, rx_empty, tx_full};

            // DEFAULT
            default: rd_data = 32'b0;

        endcase

    end

endmodule