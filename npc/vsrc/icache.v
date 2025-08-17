module icache(
    input clock,
    input reset,
    input reg [31:0]  IFU_AXI4_araddr,
    input reg         IFU_AXI4_arvalid,
    output reg        IFU_AXI4_arready,
    output reg [31:0] IFU_AXI4_rdata,
    output reg        IFU_AXI4_rvalid,
    input             IFU_AXI4_rready,

    output reg [31:0] ICACHE_AXI4_araddr,
    output reg        ICACHE_AXI4_arvalid,
    input             ICACHE_AXI4_arready,
    input  [31:0]     ICACHE_AXI4_rdata,
    input             ICACHE_AXI4_rvalid,
    output reg        ICACHE_AXI4_rready,
    output reg [7:0]  ICACHE_AXI4_arlen,
    output reg [63:0] ICACHE_hit_count,
    output reg [63:0] ICACHE_miss_count,
    output reg [63:0] total_access,
    output reg [63:0] access_time,
    output reg [63:0] miss_penalty
);

parameter BLOCK_SIZE = 16;      // 4字节块大小
parameter NUM_BLOCKS = 16;     // 16个缓存块
parameter OFFSET_BITS = 4;     // 2^2 = 4字节 (块内偏移)
parameter INDEX_BITS = 4;      // 2^4 = 16个块 (索引位)
parameter TAG_BITS = 24;       // 32 - (2+4) = 26位标签


reg [TAG_BITS-1:0] tags [0:NUM_BLOCKS-1];  // 标签存储
reg [BLOCK_SIZE * 8-1:0] data [0:NUM_BLOCKS-1];           // 数据存储
reg valid [0:NUM_BLOCKS-1];                 // 有效位
wire is_sdram = (IFU_AXI4_araddr >= 32'ha0000000);
typedef enum logic [2:0] {
    IDLE,        // 空闲状态
    CHECK_CACHE, // 检查缓存
    AXI_READ,    // 从内存读取
    UPDATED_CACHE, // 更新缓存
    SEND_DATA // 更新缓存
} state_t;

reg [2:0] state;
reg [31:0] saved_addr;  // 保存当前请求地址
reg [INDEX_BITS-1:0] saved_index;  // 保存当前索引
reg [TAG_BITS-1:0] saved_tag;
reg [127:0] burst_buffer; 

wire [TAG_BITS-1:0] current_tag = IFU_AXI4_araddr[31:OFFSET_BITS+INDEX_BITS];
wire [INDEX_BITS-1:0] current_index = IFU_AXI4_araddr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
wire [OFFSET_BITS-1:0] current_offset = IFU_AXI4_araddr[OFFSET_BITS-1:0];
reg [1:0] burst_count;
integer i;


always @(posedge clock) begin
    if (reset) begin
        state <= IDLE;
        IFU_AXI4_arready <= 0;
        IFU_AXI4_rvalid <= 0;
        ICACHE_AXI4_arvalid <= 0;
        ICACHE_AXI4_rready <= 0;
        saved_addr <= 0;
        ICACHE_AXI4_arlen <= 0;
        saved_tag <= 0;
        ICACHE_hit_count <= 0;
        ICACHE_miss_count <= 0;
        access_time <= 0;
        miss_penalty <= 0;
        ICACHE_AXI4_araddr <= 0;
        burst_buffer <= 128'h0;
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
            valid[i] <= 0;  // 复位时所有块无效
        end
    end else begin
        case (state)
            IDLE: begin
                IFU_AXI4_arready <= 1'b1;
                IFU_AXI4_rvalid <= 1'b0;
                burst_buffer <= 128'h0;
                if (IFU_AXI4_arvalid && IFU_AXI4_arready) begin
                    access_time <= access_time + 1'b1;
                    total_access <= total_access + 1'b1;
                    miss_penalty <= miss_penalty + 1'b1;
                    IFU_AXI4_arready <= 1'b0;
                    saved_addr <= IFU_AXI4_araddr;
                    saved_index <= current_index;
                    saved_tag <= current_tag;
                    state <= CHECK_CACHE;
                end
            end
            
            CHECK_CACHE: begin
                // 检查是否命中：有效且标签匹配
                if (valid[saved_index] && (tags[saved_index] == saved_tag) && is_sdram) begin
                    access_time <= access_time + 1'b1;
                    // 根据偏移选择正确的32位数据
                    case (saved_addr[3:2])
                        2'b00: IFU_AXI4_rdata <= data[saved_index][31:0];
                        2'b01: IFU_AXI4_rdata <= data[saved_index][63:32];
                        2'b10: IFU_AXI4_rdata <= data[saved_index][95:64];
                        2'b11: IFU_AXI4_rdata <= data[saved_index][127:96];
                    endcase
                    IFU_AXI4_rvalid <= 1'b1;
                    state <= SEND_DATA;
                    ICACHE_hit_count <= ICACHE_hit_count + 1;
                end else begin
                    // 未命中：启动内存读取
                    if(is_sdram) begin
                        ICACHE_AXI4_arlen <= 2'b11;  // 一次读取4个数据
                        ICACHE_AXI4_araddr <= {saved_addr[31:4], 4'b0};
                    end else begin
                        ICACHE_AXI4_arlen <= 2'b00;  // 一次读取1个数据
                        ICACHE_AXI4_araddr <= {saved_addr[31:2], 2'b0};
                    end
                    miss_penalty <= miss_penalty + 1'b1;
                    ICACHE_AXI4_arvalid <= 1'b1;
                    // 地址对齐到16字节边界
                    if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid) begin
                        ICACHE_AXI4_rready <= 1'b1;
                        ICACHE_AXI4_arvalid <= 1'b0;
                        ICACHE_miss_count <= ICACHE_miss_count + 1;
                        state <= AXI_READ;
                    end
                    else begin
                        state <= CHECK_CACHE;
                    end
                end
            end
                
            
            AXI_READ: begin
                if (ICACHE_AXI4_rvalid && ICACHE_AXI4_rready) begin
                    // 存储接收到的数据
                    if(is_sdram) begin
                        case (burst_count)
                            2'b00: burst_buffer[31:0] <= ICACHE_AXI4_rdata;
                            2'b01: burst_buffer[63:32] <= ICACHE_AXI4_rdata;
                            2'b10: burst_buffer[95:64] <= ICACHE_AXI4_rdata;
                            2'b11: burst_buffer[127:96] <= ICACHE_AXI4_rdata;
                        endcase
                        
                        burst_count <= burst_count + 1;
                        miss_penalty <= miss_penalty + 1;
                        
                        if (burst_count == 2'b11) begin
                            // 完成4个数据的接收
                            ICACHE_AXI4_rready <= 1'b0;
                            // 更新缓存
                            tags[saved_index] <= saved_tag;
                            data[saved_index] <= burst_buffer;
                            valid[saved_index] <= 1'b1;
                            
                        // 选择请求的数据
                        case (saved_addr[3:2])
                            2'b00: IFU_AXI4_rdata <= burst_buffer[31:0];
                            2'b01: IFU_AXI4_rdata <= burst_buffer[63:32];
                            2'b10: IFU_AXI4_rdata <= burst_buffer[95:64];
                            2'b11: IFU_AXI4_rdata <= burst_buffer[127:96];
                        endcase
                        
                        IFU_AXI4_rvalid <= 1'b1;
                        state <= UPDATED_CACHE;
                        ICACHE_miss_count <= ICACHE_miss_count + 1;
                    end
                    end else begin
                        case (saved_addr[3:2])
                            2'b00: burst_buffer[31:0] <= ICACHE_AXI4_rdata;
                            2'b01: burst_buffer[63:32] <= ICACHE_AXI4_rdata;
                            2'b10: burst_buffer[95:64] <= ICACHE_AXI4_rdata;
                            2'b11: burst_buffer[127:96] <= ICACHE_AXI4_rdata;
                        endcase
                        
                        miss_penalty <= miss_penalty + 1;
                        
                        IFU_AXI4_rdata <= ICACHE_AXI4_rdata;
                            // 完成4个数据的接收
                        ICACHE_AXI4_rready <= 1'b0;
                            // 更新缓存
                            
                        // 选择请求的数据
                        
                        
                        IFU_AXI4_rvalid <= 1'b1;
                        state <= UPDATED_CACHE;
                        ICACHE_miss_count <= ICACHE_miss_count + 1;
                   
                    end
                end else begin
                    // 等待有效数据
                    miss_penalty <= miss_penalty + 1;
                end
            end
                
            UPDATED_CACHE : begin
                tags[saved_index] <= saved_tag;
                data[saved_index] <= burst_buffer;
                ICACHE_miss_count <= ICACHE_miss_count + 1;
                valid[saved_index] <= 1'b1;
                state <= SEND_DATA;

            end
            SEND_DATA: begin
                access_time <= access_time + 1'b1;
                miss_penalty <= miss_penalty + 1'b1;
                if (IFU_AXI4_rvalid && IFU_AXI4_rready) begin
                    // IFU接收数据，完成本次请求
                    IFU_AXI4_rvalid <= 1'b0;
                    state <= IDLE;
                end
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule

