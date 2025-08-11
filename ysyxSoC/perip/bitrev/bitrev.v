module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output reg miso
);




reg [7:0] rx_data;      // 接收数据寄存器
reg [7:0] tx_data;      // 发送数据寄存器
reg [3:0] bit_count;    // 位计数器（0-15）
reg       received;     // 接收完成标志

// 位翻转函数
function [7:0] reverse_bits;
    input [7:0] data;
    integer i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            reverse_bits[i] = data[7-i];
        end
    end
endfunction

always @(posedge sck or posedge ss) begin
    if (ss) begin
        // 片选无效时复位
        bit_count <= 4'd0;
        received  <= 1'b0;
        rx_data   <= 8'b0;
    end else begin
        // 上升沿：接收数据
        if (bit_count < 8) begin
            rx_data <= {rx_data[6:0], mosi};  // 右移接收
        end
        bit_count <= bit_count + 1;
        
        // 第8位接收完成
        if (bit_count == 7) begin
            tx_data <= reverse_bits({rx_data[6:0], mosi}); // 组合最后一位并翻转
            received <= 1'b1;
        end
    end
end

always @(posedge sck) begin
    if (!ss) begin
        if (received) begin
            if (bit_count < 15) begin
                miso <= tx_data[15 - bit_count];  // 从高位开始发送
            end else begin
                miso <= 1'b1;  // 超16位后保持高电平
            end
        end else begin
            miso <= 1'b1;  // 接收阶段保持高电平
        end
    end
    else begin
        miso <= 1'b1;  // 片选无效时保持高电平
    end
end

endmodule
