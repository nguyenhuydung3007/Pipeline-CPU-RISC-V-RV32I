// =============================================================
// Module VGA CONTROL REGISTER
// + Thanh ghi điều khiển VGA dạng Memory Mapping I/O
// + Điều khiển:
//     * Vị trí Cursor (Cursor blink giống terminal)
//     * Scroll màn hình
//     * Select buffer (double buffer)
// =============================================================

module VGA_CTRL_REG (

    input clk_cpu,                  // Clock 50MHz
    input reset,
    input we,                       // Khi CPU ghi đúng địa chỉ MMIO của VGA_CTRL --> we = 1
    input [31:0] data_in,           // Word 32-bit từ CPU gửi vào

    output reg [6:0] cursor_x,      // Vị trí cột cursor
    output reg [4:0] cursor_y,      // Vị trí hàng cursor
    output reg [4:0] row_offset,    // Dùng cho Scroll hardware
    output reg buffer_sel           // Dùng cho double buffer
);

    always @(posedge clk_cpu or negedge reset) begin
        
        if (!reset) begin
            cursor_x    <= 0;
            cursor_y    <= 0;
            row_offset  <= 0;
            buffer_sel  <= 0;
        end
        else if (we) begin
            cursor_x    <= data_in[6:0];
            cursor_y    <= data_in[11:7];
            row_offset  <= data_in[16:12];
            buffer_sel  <= data_in[17];
        end

    end

endmodule