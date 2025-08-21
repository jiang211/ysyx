module icache(
    input clock,
    input reset,
    input fence_i,
    input flush,
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
reg flush_r;
always@(posedge clock)begin
    flush_r <= flush;
end

parameter SDRAM_BLOCK_SIZE = 16;      // 4字节块大小
parameter SDRAM_NUM_BLOCKS = 16;     // 16个缓存块
parameter SDRAM_OFFSET_BITS = 4;     // 2^2 = 4字节 (块内偏移)
parameter SDRAM_INDEX_BITS = 4;      // 2^4 = 16个块 (索引位)
parameter SDRAM_TAG_BITS = 24;       // 32 - (2+4) = 26位标签

parameter FLASH_BLOCK_SIZE = 4;      // 4字节块大小
parameter FLASH_NUM_BLOCKS = 16;     // 16个缓存块
parameter FLASH_OFFSET_BITS = 2;     // 2^1 = 1字节 (块内偏移)
parameter FLASH_INDEX_BITS = 4;      // 2^4 = 16个块 (索引位)
parameter FLASH_TAG_BITS = 26;       // 32 - (2+4) = 26位标签

reg [SDRAM_TAG_BITS-1:0] sdram_tags [0:SDRAM_NUM_BLOCKS-1];  // 标签存储
reg [SDRAM_BLOCK_SIZE * 8-1:0] sdram_data [0:SDRAM_NUM_BLOCKS-1];           // 数据存储
reg sdram_valid [0:SDRAM_NUM_BLOCKS-1];                 // 有效位

reg [FLASH_TAG_BITS-1:0] flash_tags [0:FLASH_NUM_BLOCKS-1];  // 标签存储
reg [FLASH_BLOCK_SIZE * 8-1:0] flash_data [0:FLASH_NUM_BLOCKS-1];           // 数据存储
reg flash_valid [0:FLASH_NUM_BLOCKS-1];                 // 有效位

wire is_sdram = (IFU_AXI4_araddr >= 32'ha0000000);
typedef enum logic [2:0] {
    IDLE,        // 空闲状态
    AXI_WAIT,
    AXI_READ,    // 从FLASH读取
    UPDATED_CACHE, // 更新缓存
    SEND_DATA // 更新缓存
} state_t;


state_t state;
reg [31:0] sdram_saved_addr;  // 保存当前请求地址
reg [SDRAM_INDEX_BITS-1:0] sdram_saved_index;  // 保存当前索引
reg [SDRAM_TAG_BITS-1:0] sdram_saved_tag;

reg [31:0] flash_saved_addr;  // 保存当前请求地址
reg [FLASH_INDEX_BITS-1:0] flash_saved_index;  // 保存当前索引
reg [FLASH_TAG_BITS-1:0] flash_saved_tag;

reg [127:0] sdram_burst_buffer; 
reg [31:0] flash_burst_buffer;
wire [SDRAM_TAG_BITS-1:0] sdram_current_tag = IFU_AXI4_araddr[31:SDRAM_OFFSET_BITS+SDRAM_INDEX_BITS];
wire [SDRAM_INDEX_BITS-1:0] sdram_current_index = IFU_AXI4_araddr[SDRAM_OFFSET_BITS+SDRAM_INDEX_BITS-1:SDRAM_OFFSET_BITS];
wire [SDRAM_OFFSET_BITS-1:0] sdram_current_offset = IFU_AXI4_araddr[SDRAM_OFFSET_BITS-1:0];

wire [FLASH_TAG_BITS-1:0] flash_current_tag = IFU_AXI4_araddr[31:FLASH_OFFSET_BITS+FLASH_INDEX_BITS];
wire [FLASH_INDEX_BITS-1:0] flash_current_index = IFU_AXI4_araddr[FLASH_OFFSET_BITS+FLASH_INDEX_BITS-1:FLASH_OFFSET_BITS];
wire [FLASH_OFFSET_BITS-1:0] flash_current_offset = IFU_AXI4_araddr[FLASH_OFFSET_BITS-1:0];

reg [1:0] burst_count;
integer i;


always @(posedge clock) begin
    if (reset) begin
        state <= IDLE;
        IFU_AXI4_arready <= 0;
        IFU_AXI4_rvalid <= 0;
        ICACHE_AXI4_arvalid <= 0;
        ICACHE_AXI4_rready <= 0;
        sdram_saved_addr <= 0;
        flash_saved_addr <= 0;
        sdram_saved_index <= 0;
        flash_saved_index <= 0;
        sdram_saved_tag <= 0;
        flash_saved_tag <= 0;
        ICACHE_AXI4_arlen <= 0;
        ICACHE_hit_count <= 0;
        ICACHE_miss_count <= 0;
        access_time <= 0;
        miss_penalty <= 0;
        ICACHE_AXI4_araddr <= 0;
        sdram_burst_buffer <= 128'h0;
        flash_burst_buffer <= 0;
        for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
            sdram_valid[i] <= 0;  // 复位时所有块无效
            flash_valid[i] <= 0;  // 复位时所有块无效
        end
    end else begin
        case (state)
            IDLE: begin
                IFU_AXI4_arready <= 1'b1;
                IFU_AXI4_rvalid <= 1'b0;
                sdram_burst_buffer <= 128'h0;
                if(fence_i) begin
                    for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
                        sdram_valid[i] <= 0;  // 复位时所有块无效
                        flash_valid[i] <= 0;  // 复位时所有块无效
                    end
                end
                if (IFU_AXI4_arvalid && IFU_AXI4_arready) begin
                    access_time <= access_time + 1'b1;
                    total_access <= total_access + 1'b1;
                    miss_penalty <= miss_penalty + 1'b1;
                    IFU_AXI4_arready <= 1'b0;
                    if(is_sdram) begin
                        sdram_saved_addr <= IFU_AXI4_araddr;
                        sdram_saved_index <= sdram_current_index;
                        sdram_saved_tag <= sdram_current_tag;
                        if (sdram_valid[sdram_current_index] && (sdram_tags[sdram_current_index] == sdram_current_tag)) begin
                            access_time <= access_time + 1'b1;
                            // 根据偏移选择正确的32位数据
                            case (IFU_AXI4_araddr[3:2])
                                2'b00: IFU_AXI4_rdata <= sdram_data[sdram_current_index][31:0];
                                2'b01: IFU_AXI4_rdata <= sdram_data[sdram_current_index][63:32];
                                2'b10: IFU_AXI4_rdata <= sdram_data[sdram_current_index][95:64];
                                2'b11: IFU_AXI4_rdata <= sdram_data[sdram_current_index][127:96];
                            endcase
                            IFU_AXI4_rvalid <= 1'b1;
                            state <= SEND_DATA;
                            ICACHE_hit_count <= ICACHE_hit_count + 1;
                        end else begin
                            // 未命中：启动内存读取
                        
                            ICACHE_AXI4_arlen <= 2'b11;  // 一次读取4个数据
                            ICACHE_AXI4_araddr <= {IFU_AXI4_araddr[31:4], 4'b0};
                            
                            miss_penalty <= miss_penalty + 1'b1;
                            state <= AXI_WAIT;
                            
                        end
                    end else begin
                        flash_saved_addr <= IFU_AXI4_araddr;
                        flash_saved_index <= flash_current_index;
                        flash_saved_tag <= flash_current_tag;
                        if (flash_valid[flash_current_index] && (flash_tags[flash_current_index] == flash_current_tag)) begin
                            access_time <= access_time + 1'b1;
                            // 根据偏移选择正确的32位数据
                            IFU_AXI4_rdata <= flash_data[flash_current_index];
                            IFU_AXI4_rvalid <= 1'b1;
                            state <= SEND_DATA;
                            ICACHE_hit_count <= ICACHE_hit_count + 1;
                        end else begin
                            // 未命中：启动内存读取
                            ICACHE_AXI4_arlen <= 2'b00;  // 一次读取1个数据
                            ICACHE_AXI4_araddr <= {IFU_AXI4_araddr[31:2], 2'b0};
                            miss_penalty <= miss_penalty + 1'b1;
                            state <= AXI_WAIT;
                        end
                    end
                    
                end
            end
            
            AXI_WAIT: begin
                if(flush_r) begin state <= IDLE; end
                else begin
                ICACHE_AXI4_arvalid <= 1'b1;
                            // 地址对齐到16字节边界
                if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid) begin
                    ICACHE_AXI4_rready <= 1'b1;
                    ICACHE_AXI4_arvalid <= 1'b0;
                    ICACHE_miss_count <= ICACHE_miss_count + 1;
                    state <= AXI_READ;
                end
                else begin
                    state <= AXI_WAIT;
                end
                end

            end
            
            
            AXI_READ: begin
                if(flush_r) state <= IDLE;
                if (ICACHE_AXI4_rvalid && ICACHE_AXI4_rready) begin
                    // 存储接收到的数据
                    if(is_sdram) begin
                        case (burst_count)
                            2'b00: sdram_burst_buffer[31:0] <= ICACHE_AXI4_rdata;
                            2'b01: sdram_burst_buffer[63:32] <= ICACHE_AXI4_rdata;
                            2'b10: sdram_burst_buffer[95:64] <= ICACHE_AXI4_rdata;
                            2'b11: sdram_burst_buffer[127:96] <= ICACHE_AXI4_rdata;
                        endcase
                        
                        burst_count <= burst_count + 1;
                        miss_penalty <= miss_penalty + 1;
                        
                        if (burst_count == 2'b11) begin
                            // 完成4个数据的接收
                            ICACHE_AXI4_rready <= 1'b0;
                            state <= UPDATED_CACHE;
                            ICACHE_miss_count <= ICACHE_miss_count + 1;
                        end
                    end else begin
                        flash_burst_buffer <= ICACHE_AXI4_rdata;
                        
                        miss_penalty <= miss_penalty + 1;
                        
                        
                            // 完成4个数据的接收
                        ICACHE_AXI4_rready <= 1'b0;
                            // 更新缓存
                        state <= UPDATED_CACHE;
                        ICACHE_miss_count <= ICACHE_miss_count + 1;
                   
                    end
                end else begin
                    // 等待有效数据
                    miss_penalty <= miss_penalty + 1;
                end
            end
                
            UPDATED_CACHE : begin
                if(is_sdram) begin
                    case (sdram_saved_addr[3:2])
                        2'b00: IFU_AXI4_rdata <= sdram_burst_buffer[31:0];
                        2'b01: IFU_AXI4_rdata <= sdram_burst_buffer[63:32];
                        2'b10: IFU_AXI4_rdata <= sdram_burst_buffer[95:64];
                        2'b11: IFU_AXI4_rdata <= sdram_burst_buffer[127:96];
                    endcase
                    sdram_tags[sdram_saved_index] <= sdram_saved_tag;
                    sdram_data[sdram_saved_index] <= sdram_burst_buffer;
                    sdram_valid[sdram_saved_index] <= 1'b1;
                end else begin
                    IFU_AXI4_rdata <= flash_burst_buffer;
                    flash_tags[flash_saved_index] <= flash_saved_tag;
                    flash_data[flash_saved_index] <= flash_burst_buffer;
                    flash_valid[flash_saved_index] <= 1'b1;
                end
                ICACHE_miss_count <= ICACHE_miss_count + 1;
                state <= SEND_DATA;
                IFU_AXI4_rvalid <= 1'b1;
            end
            SEND_DATA: begin
                if(flush_r) begin state <= IDLE; end
                else begin
                access_time <= access_time + 1'b1;
                miss_penalty <= miss_penalty + 1'b1;
                if (IFU_AXI4_rvalid && IFU_AXI4_rready) begin
                    // IFU接收数据，完成本次请求
                    IFU_AXI4_rvalid <= 1'b0;
                    state <= IDLE;
                end
            end
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule

