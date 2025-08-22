module icache(
    input clock,
    input reset,
    input fence_i,
    input flush,
    input reg [31:0]  IFU_AXI4_araddr,
    input reg         IFU_AXI4_arvalid,
    // output reg        IFU_AXI4_rvalid,
    input             IFU_AXI4_rready,

    output    [31:0]  ICACHE_IFU_rdata,
    output    [31:0]  ICACHE_IFU_raddr,
    output            ICACHE_IFU_valid,

    output reg [31:0] ICACHE_AXI4_araddr,
    output reg        ICACHE_AXI4_arvalid,
    input             ICACHE_AXI4_arready,
    input  [31:0]     ICACHE_AXI4_rdata,
    input             ICACHE_AXI4_rvalid,
    input             ICACHE_AXI4_rlast,
    output            ICACHE_IFU_stall,
    output            ICACHE_AXI4_rready,
    output reg [7:0]  ICACHE_AXI4_arlen,
    output reg [63:0] ICACHE_hit_count,
    output reg [63:0] ICACHE_miss_count,
    output reg [63:0] total_access,
    output reg [63:0] access_time,
    output reg [63:0] miss_penalty
);

parameter SDRAM_BLOCK_SIZE = 16;      // 4字节块大小
parameter SDRAM_NUM_BLOCKS = 16;     // 16个缓存块
parameter SDRAM_OFFSET_BITS = 4;     // 2^2 = 4字节 (块内偏移)
parameter SDRAM_INDEX_BITS = 4;      // 2^4 = 16个块 (索引位)
parameter SDRAM_TAG_BITS = 24;       // 32 - (2+4) = 26位标签


reg [SDRAM_TAG_BITS-1:0] tags [0:SDRAM_NUM_BLOCKS-1];  // 标签存储
reg [SDRAM_BLOCK_SIZE * 8-1:0] data [0:SDRAM_NUM_BLOCKS-1];           // 数据存储
reg valid [0:SDRAM_NUM_BLOCKS-1];                 // 有效位

              // 有效位

typedef enum logic [2:0] {
    IDLE,        // 空闲状态
    AXI_WAIT,
    AXI_READ,    // 从FLASH读取
    UPDATED_CACHE, // 更新缓存
    SEND_DATA // 更新缓存
} state_t;


state_t state;


reg [127:0] burst_buffer; 
wire [SDRAM_TAG_BITS-1:0] current_tag = IFU_AXI4_araddr[31:SDRAM_OFFSET_BITS+SDRAM_INDEX_BITS];
wire [SDRAM_INDEX_BITS-1:0] current_index = IFU_AXI4_araddr[SDRAM_OFFSET_BITS+SDRAM_INDEX_BITS-1:SDRAM_OFFSET_BITS];
wire [SDRAM_OFFSET_BITS-1:0] current_offset = IFU_AXI4_araddr[SDRAM_OFFSET_BITS-1:0];


wire hit = (valid[current_index] && (tags[current_index] == current_tag));


reg [1:0] burst_count;
integer i;

reg hit_reg1;
reg [31:0]  pc_reg1;
reg [SDRAM_TAG_BITS-1:0] tag_reg1;
reg [SDRAM_INDEX_BITS-1:0] index_reg1;
reg [SDRAM_OFFSET_BITS-1:0] offset_reg1;
reg reg1_valid;

wire hit_reg2;
reg [31:0] pc_reg2;
reg [SDRAM_TAG_BITS-1:0] tag_reg2;
reg [SDRAM_INDEX_BITS-1:0] index_reg2;
reg [SDRAM_OFFSET_BITS-1:0] offset_reg2;
reg reg2_valid;

reg [31:0] addr_reg3;
reg [31:0] data_reg3;
reg data_valid;

assign hit_reg2 = (valid[index_reg2] && (tags[index_reg2] == tag_reg2));

always @(posedge clock) begin
    if(reset) begin
        pc_reg1 <= 0;
        tag_reg1 <= 0;
        index_reg1 <= 0;
        offset_reg1 <= 0;
        reg1_valid  <= 0;
    end
    else if(flush) begin
        reg1_valid <= 0;
    end
    else if(!stall && IFU_AXI4_rready) begin
        pc_reg1 <= IFU_AXI4_araddr;
        tag_reg1 <= current_tag;
        index_reg1 <= current_index;
        offset_reg1 <= current_offset;
        reg1_valid <= 1'b1;
    end
end

always @(posedge clock) begin
    if(reset) begin
        pc_reg2 <= 0;
        tag_reg2 <= 0;
        index_reg2 <= 0;
        offset_reg2 <= 0;
        reg2_valid  <= 0;
    end
    else if(flush) begin
        reg2_valid <= 0;
    end 
    else if(!stall && IFU_AXI4_rready) begin
        pc_reg2 <= pc_reg1;
        tag_reg2 <= tag_reg1;
        index_reg2 <= index_reg1;
        offset_reg2 <= offset_reg1;
        reg2_valid <= reg1_valid;
    end
end

always @(posedge clock) begin
    if(reset) begin
        addr_reg3 <= 0;
        data_reg3 <= 0;
    end
    else if(!stall && IFU_AXI4_rready) begin
        if(reg2_valid && hit_reg2 && state == IDLE) begin
            case (pc_reg2[3:2])
                2'b00: data_reg3 <= data[index_reg2][31:0];
                2'b01: data_reg3 <= data[index_reg2][63:32];
                2'b10: data_reg3 <= data[index_reg2][95:64];
                2'b11: data_reg3 <= data[index_reg2][127:96];
            endcase
            addr_reg3 <= pc_reg2;
        end
    end
    else if(state == UPDATED_CACHE)begin
        case (pc_reg2[3:2])
            2'b00: data_reg3 <= burst_buffer[31:0];
            2'b01: data_reg3 <= burst_buffer[63:32];
            2'b10: data_reg3 <= burst_buffer[95:64];
            2'b11: data_reg3 <= burst_buffer[127:96];
        endcase
        addr_reg3 <= pc_reg2;
    end
end
assign ICACHE_IFU_rdata = data_reg3;
assign ICACHE_IFU_raddr = addr_reg3;
assign ICACHE_IFU_valid = data_valid;

assign ICACHE_IFU_stall = stall;
wire stall;
assign stall = reg2_valid && (~hit_reg2);

always @(posedge clock) begin
    if(reset)begin
        data_valid <= 0;
    end
    else if((state == IDLE && reg2_valid && hit_reg2) || state == UPDATED_CACHE) begin
        data_valid <= 1'b1;
    end
    else begin
        data_valid <= 1'b0;
    end
end



always @(posedge clock) begin
    if(reset) begin
        state <= IDLE;
    end
    else begin
        case (state)
        IDLE: begin
            if(reg2_valid) begin
                if(hit_reg2)begin
                    state <= IDLE;
                end
                else begin
                    state <= AXI_WAIT;
                end
            end
        end
        AXI_WAIT: begin
            if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid) begin
                state <= AXI_READ;
            end
            else begin
                state <= AXI_WAIT;
            end
        end
        AXI_READ: begin
            if(ICACHE_AXI4_rvalid && ICACHE_AXI4_rlast) begin
                state <= UPDATED_CACHE;
            end
            else begin
                state <= AXI_READ;
            end
        end
        UPDATED_CACHE: begin
            state <= IDLE;
        end
        default: begin
            state <= IDLE;
        end
        endcase
    end
end

always @(posedge clock) begin
    if(reset) begin
        ICACHE_hit_count <= 0;
        ICACHE_miss_count <= 0;
        access_time <= 0;
        miss_penalty <= 0;
    end
    else if(hit_reg2)begin
        ICACHE_hit_count <= ICACHE_hit_count + 1;
    end
    else if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid && state == AXI_WAIT)begin
        ICACHE_miss_count <= ICACHE_miss_count + 1;
    end
    else if(state == IDLE && IFU_AXI4_arvalid) begin
        access_time <= access_time + 1'b1;
    end
    else if((state == IDLE && IFU_AXI4_arvalid) && state == AXI_READ && state == AXI_WAIT) begin
        miss_penalty <= miss_penalty + 1'b1;
    end
end

assign ICACHE_AXI4_rready = 1'b1;
assign ICACHE_AXI4_arlen = 2'b11;  // 一次读取4个数据
//assign ICACHE_AXI4_araddr = (is_sdram_reg2) ? {pc_reg2[31:4], 4'b0} : {pc_reg2[31:2], 2'b0};  // 地址对齐到16字节边界

always @(posedge clock)begin
    if(reset) begin
        burst_buffer <= 128'h0;
    end 
    else if(state == AXI_READ && ICACHE_AXI4_rvalid) begin
        case (burst_count)
            2'b00: burst_buffer[31:0] <= ICACHE_AXI4_rdata;
            2'b01: burst_buffer[63:32] <= ICACHE_AXI4_rdata;
            2'b10: burst_buffer[95:64] <= ICACHE_AXI4_rdata;
            2'b11: burst_buffer[127:96] <= ICACHE_AXI4_rdata;
        endcase
        burst_count <= burst_count + 1;
    end 
    else if(state == IDLE) begin
        burst_count <= 2'b00;
        burst_buffer <= 128'h0;
    end
end

always @(posedge clock) begin
    if(reset) begin
        for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
            valid[i] <= 0;  // 复位时所有块无效
        end
    end
    else if(fence_i) begin
        for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
            valid[i] <= 0;  // 复位时所有块无效
        end
    end
    else if(state == UPDATED_CACHE) begin
        valid[index_reg2] <= 1'b1;
    end
end

always @(posedge clock) begin
    if(state == UPDATED_CACHE) begin
        tags[index_reg2] <= tag_reg2;
        data[index_reg2] <= burst_buffer;
        
    end
end

always @(posedge clock) begin
    if(reset)begin
        ICACHE_AXI4_arvalid <= 0;
        ICACHE_AXI4_araddr <= 0;
    end
    else if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid)begin
        ICACHE_AXI4_arvalid <= 1'b0;
    end
    else  if(state == IDLE && (!hit_reg2) && reg2_valid)begin
        ICACHE_AXI4_arvalid <= 1'b1;
        ICACHE_AXI4_araddr <= {pc_reg2[31:4], 4'b0} ; 
    end
    
end

// always @(posedge clock) begin
//     if (reset) begin
//         state <= IDLE;
//         IFU_AXI4_rvalid <= 0;
//         ICACHE_AXI4_arvalid <= 0;
//         sdram_saved_addr <= 0;
//         flash_saved_addr <= 0;
//         sdram_saved_index <= 0;
//         flash_saved_index <= 0;
//         sdram_saved_tag <= 0;
//         flash_saved_tag <= 0;
//         for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
//             sdram_valid[i] <= 0;  // 复位时所有块无效
//             flash_valid[i] <= 0;  // 复位时所有块无效
//         end
//     end else begin
//         case (state)
//             IDLE: begin
//                 IFU_AXI4_rvalid <= 1'b0;

//                 if(fence_i) begin
//                     for (i = 0; i < SDRAM_NUM_BLOCKS; i = i + 1) begin
//                         sdram_valid[i] <= 0;  // 复位时所有块无效
//                         flash_valid[i] <= 0;  // 复位时所有块无效
//                     end
//                 end
//                 if (IFU_AXI4_arvalid) begin
//                     total_access <= total_access + 1'b1;
//                     if(is_sdram) begin
//                         sdram_saved_addr <= IFU_AXI4_araddr;
//                         sdram_saved_index <= sdram_current_index;
//                         sdram_saved_tag <= sdram_current_tag;
//                         if (sdram_valid[sdram_current_index] && (sdram_tags[sdram_current_index] == sdram_current_tag)) begin
//                             access_time <= access_time + 1'b1;
//                             // 根据偏移选择正确的32位数据
//                             case (IFU_AXI4_araddr[3:2])
//                                 2'b00: IFU_AXI4_rdata <= sdram_data[sdram_current_index][31:0];
//                                 2'b01: IFU_AXI4_rdata <= sdram_data[sdram_current_index][63:32];
//                                 2'b10: IFU_AXI4_rdata <= sdram_data[sdram_current_index][95:64];
//                                 2'b11: IFU_AXI4_rdata <= sdram_data[sdram_current_index][127:96];
//                             endcase
//                             IFU_AXI4_rvalid <= (1'b1 && (~flush));
//                             state <= SEND_DATA;
//                             ICACHE_hit_count <= ICACHE_hit_count + 1;
//                         end else begin
//                             // 未命中：启动内存读取
                        
//                             ICACHE_AXI4_arlen <= 2'b11;  // 一次读取4个数据
//                             ICACHE_AXI4_araddr <= {IFU_AXI4_araddr[31:4], 4'b0};
                            
//                             state <= AXI_WAIT;
                            
//                         end
//                     end else begin
//                         flash_saved_addr <= IFU_AXI4_araddr;
//                         flash_saved_index <= flash_current_index;
//                         flash_saved_tag <= flash_current_tag;
//                         if (flash_valid[flash_current_index] && (flash_tags[flash_current_index] == flash_current_tag)) begin
//                             access_time <= access_time + 1'b1;
//                             // 根据偏移选择正确的32位数据
//                             IFU_AXI4_rdata <= flash_data[flash_current_index];
//                             IFU_AXI4_rvalid <= (1'b1 && (~flush));
//                             state <= SEND_DATA;
//                             ICACHE_hit_count <= ICACHE_hit_count + 1;
//                         end else begin
//                             // 未命中：启动内存读取
//                             ICACHE_AXI4_arlen <= 2'b00;  // 一次读取1个数据
//                             ICACHE_AXI4_araddr <= {IFU_AXI4_araddr[31:2], 2'b0};
//                             state <= AXI_WAIT;
//                         end
//                     end
                    
//                 end
//             end
            
//             AXI_WAIT: begin
//                 if(flush_r) begin state <= IDLE; end
//                 else begin
//                 ICACHE_AXI4_arvalid <= 1'b1;
//                             // 地址对齐到16字节边界
//                 if(ICACHE_AXI4_arready && ICACHE_AXI4_arvalid) begin
//                     ICACHE_AXI4_arvalid <= 1'b0;
//                     state <= AXI_READ;
//                 end
//                 else begin
//                     state <= AXI_WAIT;
//                 end
//                 end

//             end
            
            
//             AXI_READ: begin
//                 if(flush_r) state <= IDLE;
//                 if (ICACHE_AXI4_rvalid && ICACHE_AXI4_rready) begin
//                     // 存储接收到的数据
//                     if(is_sdram) begin
//                         case (burst_count)
//                             2'b00: sdram_burst_buffer[31:0] <= ICACHE_AXI4_rdata;
//                             2'b01: sdram_burst_buffer[63:32] <= ICACHE_AXI4_rdata;
//                             2'b10: sdram_burst_buffer[95:64] <= ICACHE_AXI4_rdata;
//                             2'b11: sdram_burst_buffer[127:96] <= ICACHE_AXI4_rdata;
//                         endcase
                        
//                         burst_count <= burst_count + 1;
                        
//                         if (burst_count == 2'b11) begin
//                             // 完成4个数据的接收
//                             state <= UPDATED_CACHE;
//                         end
//                     end else begin
//                         flash_burst_buffer <= ICACHE_AXI4_rdata;
                        
                        
                        
//                             // 完成4个数据的接收
//                             // 更新缓存
//                         state <= UPDATED_CACHE;
                   
//                     end
//                 end else begin
//                     // 等待有效数据
//                 end
//             end
                
//             UPDATED_CACHE : begin
//                 if(is_sdram) begin
//                     case (sdram_saved_addr[3:2])
//                         2'b00: IFU_AXI4_rdata <= sdram_burst_buffer[31:0];
//                         2'b01: IFU_AXI4_rdata <= sdram_burst_buffer[63:32];
//                         2'b10: IFU_AXI4_rdata <= sdram_burst_buffer[95:64];
//                         2'b11: IFU_AXI4_rdata <= sdram_burst_buffer[127:96];
//                     endcase
//                     sdram_tags[sdram_saved_index] <= sdram_saved_tag;
//                     sdram_data[sdram_saved_index] <= sdram_burst_buffer;
//                     sdram_valid[sdram_saved_index] <= 1'b1;
//                 end else begin
//                     IFU_AXI4_rdata <= flash_burst_buffer;
//                     flash_tags[flash_saved_index] <= flash_saved_tag;
//                     flash_data[flash_saved_index] <= flash_burst_buffer;
//                     flash_valid[flash_saved_index] <= 1'b1;
//                 end
//                 state <= SEND_DATA;
//                 IFU_AXI4_rvalid <= 1'b1;
//             end
//             SEND_DATA: begin
//                 if(flush_r) begin state <= IDLE; end
//                 else begin
//                 if (IFU_AXI4_rvalid && IFU_AXI4_rready) begin
//                     // IFU接收数据，完成本次请求
//                     IFU_AXI4_rvalid <= 1'b0;
//                     state <= IDLE;
//                 end
//             end
//             end
//             default: state <= IDLE;
//         endcase
//     end
// end

endmodule

