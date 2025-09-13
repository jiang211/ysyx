module ysyx_24070003_btb(
    input clock,
    input reset,
    input [31:0] cur_pc,
    input [31:0] update_pc,
    input [31:0] target_pc,
    input        update_valid,

    output [31:0] pred_pc,
    output        pred_valid
);


localparam WAY_NUM = 2;
localparam INDEX_WIDTH = 3;
localparam ADDR_WIDTH = 32;
localparam OFFSET_WITH = 2;
localparam TAG_WIDTH = ADDR_WIDTH - OFFSET_WITH - INDEX_WIDTH;

wire [INDEX_WIDTH-1:0] cur_index;
wire [TAG_WIDTH-1:0] cur_tag;
wire [INDEX_WIDTH-1:0] update_index;
wire [TAG_WIDTH-1:0] update_tag;
wire hit;
wire update_hit;
//wire cur_hit;
wire upd_hit;

reg [TAG_WIDTH-1:0] btb_tag [2 ** INDEX_WIDTH -1:0];     // 标签存储
reg [29:0] btb_target [2 ** INDEX_WIDTH -1:0];  // 目标地址存储
reg [2 ** INDEX_WIDTH -1:0]btb_valid;          // 有效位



assign cur_index = cur_pc[INDEX_WIDTH+OFFSET_WITH-1:OFFSET_WITH];
assign cur_tag = cur_pc[ADDR_WIDTH-1:INDEX_WIDTH+OFFSET_WITH];
assign update_index = update_pc[INDEX_WIDTH+OFFSET_WITH-1:OFFSET_WITH];
assign update_tag = update_pc[ADDR_WIDTH-1:INDEX_WIDTH+OFFSET_WITH];

assign hit = (btb_valid[cur_index]) ? (btb_tag[cur_index] == cur_tag) : 0;



assign update_hit = ~btb_valid[update_index] ;



assign pred_pc = (hit) ? {btb_target[cur_index],2'b00} : cur_pc;


always @(posedge clock) begin
    if(reset)begin
        btb_valid <= 8'b0000;
    end
    else if(update_valid)begin
            btb_tag[update_index] <= update_tag;
            btb_target[update_index] <= target_pc[31:2];
            btb_valid[update_index] <= 1;
    
    end
end

endmodule