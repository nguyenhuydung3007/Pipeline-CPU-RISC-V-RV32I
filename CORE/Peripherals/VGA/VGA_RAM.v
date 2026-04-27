// ========================================================================
// Module VGA_RAM (Text Buffer - 32bit)
// + Bộ nhớ chưa nội dung sẽ hiển thị trên màn hình
// + Nội dung hiển thị (CPU) --> VGA_RAM --> Display
// 
// ------------------------------------------------------------------------
// CPU Port
// + Dùng để ghi dữ liệu firmware muốn hiển thị
// + Điều khiển bởi firmware
// 
// ------------------------------------------------------------------------
// VGA Port
// + Dùng để đọc dữ liệu muốn hiển thị ra display
// + Quét theo pixel clock (25MHz)
// + Điều khiển bởi VGA
//
// ------------------------------------------------------------------------
// Sử dụng dual port
// + CPU ghi và VGA đọc hoàn toàn độc lập, tránh lỗi timing
// 
// ------------------------------------------------------------------------
// Sử dụng dual buffer ảo (Tách từ 1 buffer M9K)
// + CPU ghi vào một buffer, VGA đọc một buffer
// --> Trong cùng một thời điểm CPU và VGA không làm việc trên 1 buffer
// + Chuyển đổi qua lại giữa các buffer bằng swap
// ========================================================================

module VGA_RAM (

    // CPU PORT
    input clk_cpu,                  // Clock 50MHz
    input we_cpu,                   // Tín hiệu cho phép CPU ghi dữ liệu vào buffer
    input [11:0] addr_cpu,          // Địa chỉ CPU muốn ghi vào buffer
    input [15:0] data_in_cpu,       // Dữ liệu CPU muốn ghi vào buffer

    // VGA PORT
    input clk_vga,                  // Clock 25MHz
    input [11:0] addr_vga,          // Địa chỉ VGA muốn đọc ở buffer
    output reg [15:0] data_out_vga, // Dữ liệu VGA đọc ra

    input buffer_sel                // Chọn buffer để CPU và VGA xử lý dữ liệu
);

    (* ramstyle = "M9K" *) 
    reg [15:0] mem [0:4799];       

    // =============== REAL ADDRESS MAPPING ===============
    reg [12:0] cpu_addr_real;
    reg [12:0] vga_addr_real;

    always @(*) begin
        
        // CPU WRITE BACK BUFFER
        if (buffer_sel == 1'b0) begin
            cpu_addr_real = {1'b0, addr_cpu} + 13'd2400;    
        end
        else begin
            cpu_addr_real = addr_cpu;
        end

        // VGA READ FRONT BUFFER
        if (buffer_sel == 1'b0) begin
            vga_addr_real = addr_vga;
        end
        else begin
            vga_addr_real = {1'b0, addr_vga} + 13'd2400;
        end

    end


    // =============== CPU WRITE ===============
    always @(posedge clk_cpu) begin
        
        if (we_cpu) begin
            mem[cpu_addr_real] <= data_in_cpu;
        end

    end

    // =============== VGA READ ===============
    always @(posedge clk_vga) begin
        
        data_out_vga <= mem[vga_addr_real];

    end

endmodule