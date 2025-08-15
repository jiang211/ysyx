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
    output reg [63:0] ICACHE_hit_count,
    output reg [63:0] ICACHE_miss_count,
    output reg [63:0] total_access
);

parameter BLOCK_SIZE = 4;      // 4字节块大小
parameter NUM_BLOCKS = 16;     // 16个缓存块
parameter OFFSET_BITS = 2;     // 2^2 = 4字节 (块内偏移)
parameter INDEX_BITS = 4;      // 2^4 = 16个块 (索引位)
parameter TAG_BITS = 26;       // 32 - (2+4) = 26位标签


reg [TAG_BITS-1:0] tags [0:NUM_BLOCKS-1];  // 标签存储
reg [31:0] data [0:NUM_BLOCKS-1];           // 数据存储
reg valid [0:NUM_BLOCKS-1];                 // 有效位

typedef enum logic [1:0] {
    IDLE,        // 空闲状态
    CHECK_CACHE, // 检查缓存
    AXI_READ,    // 从内存读取
    SEND_DATA // 更新缓存
} state_t;

reg [1:0] state;
reg [31:0] saved_addr;  // 保存当前请求地址
reg [INDEX_BITS-1:0] saved_index;  // 保存当前索引
reg [TAG_BITS-1:0] saved_tag;

wire [TAG_BITS-1:0] current_tag = IFU_AXI4_araddr[31:OFFSET_BITS+INDEX_BITS];
wire [INDEX_BITS-1:0] current_index = IFU_AXI4_araddr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
wire [OFFSET_BITS-1:0] current_offset = IFU_AXI4_araddr[OFFSET_BITS-1:0];

integer i;


always @(posedge clock) begin
    if (reset) begin
        state <= IDLE;
        IFU_AXI4_arready <= 0;
        IFU_AXI4_rvalid <= 0;
        ICACHE_AXI4_arvalid <= 0;
        ICACHE_AXI4_rready <= 0;
        saved_addr <= 0;
        saved_tag <= 0;
        ICACHE_hit_count <= 0;
        ICACHE_miss_count <= 0;
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
            valid[i] <= 0;  // 复位时所有块无效
        end
    end else begin
        case (state)
            IDLE: begin
                IFU_AXI4_arready <= 1'b1;
                IFU_AXI4_rvalid <= 1'b0;
                if (IFU_AXI4_arvalid && IFU_AXI4_arready) begin
                    total_access <= total_access + 1;
                    IFU_AXI4_arready <= 1'b0;
                    saved_addr <= IFU_AXI4_araddr;
                    saved_index <= current_index;
                    saved_tag <= current_tag;
                    state <= CHECK_CACHE;
                end
            end
            
            CHECK_CACHE: begin
                // 检查是否命中：有效且标签匹配
                if (valid[saved_index] && (tags[saved_index] == saved_tag)) begin
                    // 命中：直接返回数据
                    IFU_AXI4_rdata <= data[saved_index];
                    IFU_AXI4_rvalid <= 1'b1;
                    state <= SEND_DATA;
                    ICACHE_hit_count <= ICACHE_hit_count + 1;
                end else begin
                    // 未命中：启动内存读取
                    ICACHE_AXI4_arvalid <= 1'b1;
                    ICACHE_AXI4_araddr <= saved_addr; // 对齐地址
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
                ICACHE_AXI4_rready <= 1'b1;
                if (ICACHE_AXI4_rvalid && ICACHE_AXI4_rready) begin
                    ICACHE_AXI4_rready <= 1'b0;
                    // 更新缓存
                    tags[saved_index] <= saved_addr[31:OFFSET_BITS+INDEX_BITS];
                    data[saved_index] <= ICACHE_AXI4_rdata;
                    valid[saved_index] <= 1;
                    
                    // 返回数据给IFU
                    IFU_AXI4_rdata <= ICACHE_AXI4_rdata;
                    IFU_AXI4_rvalid <= 1'b1;
                    state <= SEND_DATA;
                end
                // 否则保持等待状态
            end
            
            SEND_DATA: begin
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

