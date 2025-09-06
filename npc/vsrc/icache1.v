module icache1(
    input clock,
    input reset,
    input fence_i,
    input flush,
    input reg [31:0]  IFU_AXI4_araddr,
    input reg         IFU_AXI4_arvalid,
    // output reg        IFU_AXI4_rvalid,
    input             IFU_AXI4_rready,
    input  [31:0]     BTB_pre_DNPC,
    input             IDU_IFU_STALL,
    input             LSU_IFU_stall,

    output    [31:0]  ICACHE_IFU_rdata,
    output    [31:0]  ICACHE_IFU_raddr,
    output    [31:0]  ICACHE_IFU_pre_dnpc,
    output            ICACHE_IFU_valid,

    // output reg [63:0] ICACHE_hit_count,
    // output reg [63:0] ICACHE_miss_count,
    // output reg [63:0] total_access,
    // output reg [63:0] access_time,
    // output reg [63:0] miss_penalty,
    // output reg [63:0] ifu_during_count,

    output reg [31:0] ICACHE_AXI4_araddr,
    output reg        ICACHE_AXI4_arvalid,
    input             ICACHE_AXI4_arready,
    input  [31:0]     ICACHE_AXI4_rdata,
    input             ICACHE_AXI4_rvalid,
    input             ICACHE_AXI4_rlast,
    output            ICACHE_IFU_stall,
    output            ICACHE_AXI4_rready,
    output reg [7:0]  ICACHE_AXI4_arlen
    
);

parameter SDRAM_BLOCK_SIZE = 16;      // 4字节块大小
parameter SDRAM_NUM_BLOCKS = 4;     // 16个缓存块
parameter SDRAM_OFFSET_BITS = 4;     // 2^2 = 4字节 (块内偏移)
parameter SDRAM_INDEX_BITS = 2;      // 2^4 = 16个块 (索引位)
parameter SDRAM_TAG_BITS = 26;       // 32 - (2+4) = 26位标签


reg [SDRAM_TAG_BITS-1:0] tags [0:SDRAM_NUM_BLOCKS-1];  // 标签存储
reg [SDRAM_BLOCK_SIZE * 8-1:0] data [0:SDRAM_NUM_BLOCKS-1];           // 数据存储
reg valid [0:SDRAM_NUM_BLOCKS-1];                 // 有效位

              // 有效位

typedef enum logic [2:0] {
    IDLE,        // 空闲状态
    JUDGE,
    AXI_READ,    // 从FLASH读取
    UPDATED_CACHE, // 更新缓存
    SEND_DATA // 更新缓存
} state_t;


state_t state;


reg [127:0] burst_buffer; 
reg [31:0] addr_buffer,pre_pc_buffer;
reg [SDRAM_TAG_BITS - 1:0] tag_buffer;
reg [SDRAM_INDEX_BITS - 1:0] index_buffer;
wire [SDRAM_TAG_BITS-1:0] tag_reg1 = pc_reg1[31:SDRAM_OFFSET_BITS+SDRAM_INDEX_BITS];
wire [SDRAM_INDEX_BITS-1:0] index_reg1 = pc_reg1[SDRAM_OFFSET_BITS+SDRAM_INDEX_BITS-1:SDRAM_OFFSET_BITS];

reg [1:0] burst_count;
integer i;

//reg hit_reg1;
reg [31:0]  pc_reg1;
reg reg1_valid;
reg [31:0] reg1_pre_dnpc;



reg [31:0] addr_reg3;
reg [31:0] data_reg3;
reg [31:0] per_pc_reg3;
reg data_valid;

reg flush_r;

assign hit_reg1 = (valid[index_reg1] && (tags[index_reg1] == tag_reg1));

wire icache_stall = stall || LSU_IFU_stall || IDU_IFU_STALL;
always @(posedge clock) begin
    if(reset) begin
        pc_reg1 <= 0;
        reg1_valid  <= 0;
        reg1_pre_dnpc <= 0;
    end
    else if(flush) begin
        reg1_valid <= 0;
    end
    else if(!icache_stall && IFU_AXI4_rready && !fence_i ) begin
        pc_reg1 <= IFU_AXI4_araddr;
        reg1_valid <= 1'b1;
        reg1_pre_dnpc <= BTB_pre_DNPC;
    end
end



// always @(posedge clock) begin
//     if(reset) begin
//         addr_reg3 <= 0;
//         data_reg3 <= 0;
//         per_pc_reg3 <= 0;
//     end
//     else if(!icache_stall && IFU_AXI4_rready) begin
//         if(reg1_valid && hit_reg1 && state == IDLE) begin
//             case (pc_reg1[3:2])
//                 2'b00: data_reg3 <= data[index_reg1][31:0];
//                 2'b01: data_reg3 <= data[index_reg1][63:32];
//                 2'b10: data_reg3 <= data[index_reg1][95:64];
//                 2'b11: data_reg3 <= data[index_reg1][127:96];
//             endcase
//             addr_reg3 <= pc_reg1;
//             per_pc_reg3 <= reg1_pre_dnpc;
//         end
//     end
//     else if((!(LSU_IFU_stall || IDU_IFU_STALL)) && state == UPDATED_CACHE)begin
//         case (addr_buffer[3:2])
//             2'b00: data_reg3 <= burst_buffer[31:0];
//             2'b01: data_reg3 <= burst_buffer[63:32];
//             2'b10: data_reg3 <= burst_buffer[95:64];
//             2'b11: data_reg3 <= burst_buffer[127:96];
//         endcase
//         addr_reg3 <= addr_buffer;
//         per_pc_reg3 <= pre_pc_buffer;
//     end
// end

assign ICACHE_IFU_rdata = (state == IDLE) ? data[index_reg1][32*pc_reg1[3:2]+:32] : (pc_reg1[3:2] == 2'b11) ? ICACHE_AXI4_rdata : data[index_reg1][32*pc_reg1[3:2]+:32];
assign ICACHE_IFU_raddr = pc_reg1;
assign ICACHE_IFU_pre_dnpc  = reg1_pre_dnpc;
assign ICACHE_IFU_valid = (state == IDLE && reg1_valid && hit_reg1 && (~flush)) | (state == AXI_READ && ICACHE_AXI4_rlast & ~(flush | flush_r));

assign ICACHE_IFU_stall = icache_stall;
wire stall;
assign stall = (state != IDLE);

always @(posedge clock) begin
    if(reset)begin
        data_valid <= 0;
    end
    else if(flush || flush_r || fence_i) begin
        data_valid <= 0;
    end
    else if(LSU_IFU_stall || IDU_IFU_STALL) begin
        data_valid <= data_valid;
    end
    else if((state == IDLE && reg1_valid && hit_reg1 && (~flush))) begin
        data_valid <= 1'b1;
    end
    else begin
        data_valid <= 1'b0;
    end
end

always @(posedge clock) begin
    if(reset) begin
        flush_r <= 0;
    end
    else if(state != IDLE && flush) begin
        flush_r <= flush;
    end
    else if(state == IDLE) begin
        flush_r <= 0;
    end
end


always @(posedge clock) begin
    if(reset) begin
        state <= IDLE;
    end
    else begin
        case (state)
        IDLE: begin
            if(reg1_valid &&  IFU_AXI4_rready) begin
                if(hit_reg1)begin
                    state <= IDLE;
                end
                else if(!flush)begin
                    state <= JUDGE;
                end
            end
        end
        JUDGE: begin
            if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid) begin
                state <= AXI_READ;
            end
            else begin
                state <= JUDGE;
            end
        end
        AXI_READ: begin
            if(ICACHE_AXI4_rvalid && ICACHE_AXI4_rlast) begin
                if(!(LSU_IFU_stall || IDU_IFU_STALL)) begin state <= IDLE; end
                //state <= UPDATED_CACHE;
            end
            else begin
                state <= AXI_READ;
            end
        end
        // UPDATED_CACHE: begin
        //     if(!(LSU_IFU_stall || IDU_IFU_STALL)) begin state <= IDLE; end
        // end
        default: begin
            state <= IDLE;
        end
        endcase
    end
end



assign ICACHE_AXI4_rready = 1'b1;
assign ICACHE_AXI4_arlen = 8'b11;  // 一次读取4个数据
//assign ICACHE_AXI4_araddr = (is_sdram_reg2) ? {pc_reg2[31:4], 4'b0} : {pc_reg2[31:2], 2'b0};  // 地址对齐到16字节边界

always @(posedge clock)begin
    if(reset) begin
        burst_buffer <= 128'h0;
    end 
    else if(state == AXI_READ && ICACHE_AXI4_rvalid) begin
        case (burst_count)
            2'b00: data[index_reg1][31:0] <= ICACHE_AXI4_rdata;
            2'b01: data[index_reg1][63:32] <= ICACHE_AXI4_rdata;
            2'b10: data[index_reg1][95:64] <= ICACHE_AXI4_rdata;
            2'b11: data[index_reg1][127:96] <= ICACHE_AXI4_rdata;
        endcase
        
    end
end

always @(posedge clock)begin
    if(reset) begin
        burst_count <= 0;
    end 
    else if(state == AXI_READ && ICACHE_AXI4_rvalid) begin
        burst_count <= burst_count + 1;
    end
end

// always @(posedge clock)begin
//     if(reset) begin
//         index_buffer <= 0;
//         addr_buffer <= 32'h0;
//         pre_pc_buffer <= 32'h0;
//         tag_buffer <= 0;
//     end 
//     else if(state == IDLE && (!hit_reg1) && reg1_valid) begin
//         index_buffer <= index_reg1;
//         addr_buffer <= pc_reg1;
//         pre_pc_buffer <= reg1_pre_dnpc;
//         tag_buffer <= tag_reg1;
//     end 
// end

always @(posedge clock) begin
    if(fence_i) begin
        for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
            valid[i] <= 0;  // 复位时所有块无效
        end
    end
    else if(state == AXI_READ) begin
        valid[index_reg1] <= 1'b1;
        tags[index_reg1] <= tag_buffer;
    end
end

// always @(posedge clock) begin
//     if(state == UPDATED_CACHE) begin
//         tags[index_buffer] <= tag_buffer;
//         data[index_buffer] <= burst_buffer;
        
//     end
// end

always @(posedge clock) begin
    if(reset)begin
        ICACHE_AXI4_arvalid <= 0;
        ICACHE_AXI4_araddr <= 0;
    end
    else if((ICACHE_AXI4_arready && ICACHE_AXI4_arvalid))begin
        ICACHE_AXI4_arvalid <= 1'b0;
    end
    else  if(state == IDLE && (!hit_reg1) && reg1_valid && (!flush) && IFU_AXI4_rready)begin
        ICACHE_AXI4_arvalid <= 1'b1;
        ICACHE_AXI4_araddr <= {pc_reg1[31:4], 4'b0} ; 
    end
    
end



endmodule
