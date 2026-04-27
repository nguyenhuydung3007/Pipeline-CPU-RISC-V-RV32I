// ============================================================
// Module VGA Text
// + Render nội dung CPU ghi vào RAM thành nội dung hiển thị
// + Nhận tọa độ (x, y) từ VGA Control
// + Nhận nội dung hiển thị từ VGA_RAM
// + Nhận Font chữ từ Font_ROM
// + Xuất dữ liệu dưới dạng R, G, B
// ==> Render Text
// ============================================================

module VGA_Text (

    input clk_vga,                  // Clock 25MHz
    input reset,

    input video_on,
    input [9:0] x,
    input [9:0] y,

    // VGA RAM
    input [15:0] text_data,         // Một ô text đọc từ VGA_RAM (màu chữ, màu nền, ASCII)
    output reg [11:0] text_addr,        // Địa chỉ trong VGA_RAM

    // FONT ROM
    input [7:0] font_data,
    output reg [11:0] font_addr,

    // VGA CONTROL REGISTER
    input [6:0] cursor_x,
    input [4:0] cursor_y,
    input [4:0] row_offset,

    output reg [3:0] R,
    output reg [3:0] G,
    output reg [3:0] B
);

    // =============== COLUMN / ROW ===============
    wire [6:0] col      = x[9:3];   // x/8
    wire [4:0] row_raw  = y[8:4];   // y/16

    // =======================================================================
    // Cơ chế SCROLL bằng địa chỉ 
    // + row_raw: hàng text mà màn hình đang quét thực tế
    // + row_offset: số dòng muốn cuộn
    // + row: hàng thực sự lấy dữ liệu từ VGA_RAM
    // --> Màn hình vẫn quét từ dòng 0 -> 29, nhưng lấy dữ liệu từ dòng khác
    // ========================================================================
    wire [4:0] row = row_raw + row_offset;

    // ===============================================
    // TEXT ADDRESS
    // + Tạo ra địa chỉ để truy cập vào VGA_RAM
    // + Chuyển địa chỉ thành mảng 1 chiều
    // -----------------------------------------------
    // - CÔNG THỨC MA TRẬN, LƯU TUYẾN TÍNH
    // + Phần tử [row][col] lưu tuyến tính:
    //      addr = row x N(col) + col
    // + row % 30: Dùng trong scroll
    //   * Nếu row > 30: lấy phần dư của %30
    //   text_addr = (row % 30) * 80 + col;
    // ===============================================
    wire [4:0] row_wrap;
    wire [11:0] row_base;
    wire [11:0] text_addr_next;

    assign row_wrap         = (row >= 5'd30) ? (row - 5'd30) : row;

    // row * 80 = row * (64 + 16)
    assign row_base         = (row_wrap << 6) + (row_wrap << 4);

    assign text_addr_next   = row_base + col;

    // =============== PIPELINE STAGE 1 ===============
    reg [2:0] x_s1;
    reg [3:0] y_s1;
    reg [6:0] col_s1;
    reg [4:0] row_s1;
    reg video_on_s1;

    always @(posedge clk_vga or negedge reset) begin
        
        if (!reset) begin
            text_addr   <= 0;
            x_s1        <= 0;
            y_s1        <= 0;
            col_s1      <= 0;
            row_s1      <= 0;
            video_on_s1 <= 0;
        end

        else begin
            text_addr   <= text_addr_next;
            x_s1        <= x[2:0];
            y_s1        <= y[3:0];
            col_s1      <= col;
            row_s1      <= row_wrap;
            video_on_s1 <= video_on;
        end

    end

    // =============== FONT ADDRESS ===============
    wire [7:0] char_code = text_data[7:0];

    always @(posedge clk_vga or negedge reset) begin
        
        if (!reset) begin
            font_addr <= 0;
        end

        else begin
            font_addr <= {char_code, y_s1};
        end

    end

    // =============== PIPELINE STAGE 2 ===============
    reg [2:0] x_s2;
    reg [15:0] text_s2;
    reg [7:0] font_s2;
    reg [6:0] col_s2;
    reg [4:0] row_s2;
    reg video_on_s2;

    always @(posedge clk_vga or negedge reset) begin
        
        if (!reset) begin
            x_s2        <= 0;
            text_s2     <= 0;
            font_s2     <= 0;
            col_s2      <= 0;
            row_s2      <= 0;
            video_on_s2 <= 0;
        end

        else begin
            x_s2        <= x_s1;
            text_s2     <= text_data;
            font_s2     <= font_data;
            col_s2      <= col_s1;
            row_s2      <= row_s1;
            video_on_s2 <= video_on_s1;
        end     

    end

    // =============== CURSOR BLINK ===============
    reg [23:0] blink_cnt;
    reg blink;

    always @(posedge clk_vga or negedge reset) begin
        
        if (!reset) begin
            blink_cnt   <= 0;
            blink       <= 0;
        end

        else begin
            blink_cnt   <= blink_cnt + 1'b1;
            blink       <= blink_cnt[23];
        end

    end

    // =============== PIXEL GENERATE ===============
    wire pixel      = font_s2[7 - x_s2];

    wire cursor_hit = (col_s2 == cursor_x) && (row_s2 == cursor_y);

    wire pixel_final = (cursor_hit && blink) ? ~pixel : pixel;

    // =============== COLOR ===============
    wire [3:0] fg = text_s2[15:12];
    wire [3:0] bg = text_s2[11:8];

    // =============== OUTPUT REGISTER ===============
    always @(posedge clk_vga or negedge reset) begin
        
        if (!reset) begin
            R <= 0;
            G <= 0;
            B <= 0;
        end

        else begin
            if (video_on_s2) begin
                if (pixel_final) begin
                    R <= fg;
                    G <= fg;
                    B <= fg;
                end
                else begin
                    R <= bg;
                    G <= bg;
                    B <= bg;
                end
            end
            else begin
                R <= 0;
                G <= 0;
                B <= 0;
            end
        end

    end

endmodule