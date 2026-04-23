// =====================================
// Module TOP kết nối DE10 Lite
// =====================================

module DE10_CORE (

    input CLOCK_50,

    input [1:0] KEY,
    input [9:0] SW,

    // UART (Nối chân Tx của CP2102 --> GPIO_0 của kit DE)
    input GPIO_0,

    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,
    
    // UART (Nối chân Rx của CP2102 --> GPIO_1 của kit DE)
    output GPIO_1
);

    CORE core_soc (

        // Input 
        .clk               (CLOCK_50),
        .reset             (KEY[0]),
        .SW                (SW),
        .GPIO_0            (GPIO_0),

        // Output
        .LEDR              (LEDR),
        .HEX0              (HEX0),
        .HEX1              (HEX1),
        .HEX2              (HEX2),
        .HEX3              (HEX3),
        .HEX4              (HEX4),
        .HEX5              (HEX5),
        .GPIO_1            (GPIO_1)
    );
endmodule