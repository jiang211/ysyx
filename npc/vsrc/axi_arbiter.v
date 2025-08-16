/* verilator lint_off BLKSEQ */
module axi_arbiter #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rstn,
    
    // IFU 接口 (指令获取)
    input  [ADDR_WIDTH-1:0] ifu_araddr,
    input                   ifu_arvalid,
    output                  ifu_arready,
    
    output [DATA_WIDTH-1:0] ifu_rdata,
    output                  ifu_rvalid,
    input                   ifu_rready,
    
    // LSU 接口 (加载/存储)
    input  [ADDR_WIDTH-1:0] lsu_araddr,
    input                   lsu_arvalid,
    output                  lsu_arready,
    
    output [DATA_WIDTH-1:0] lsu_rdata,
    output                  lsu_rvalid,
    input                   lsu_rready,
    
    input  [ADDR_WIDTH-1:0] lsu_awaddr,
    input                   lsu_awvalid,
    output                  lsu_awready,
    
    input  [DATA_WIDTH-1:0] lsu_wdata,
    input  [3:0]            lsu_wstrb,
    input                   lsu_wvalid,
    output                  lsu_wready,
    
    output                  lsu_bvalid,
    input                   lsu_bready,
    
    // SRAM 从设备接口
    output [ADDR_WIDTH-1:0] master_araddr,
    output                  master_arvalid,
    input                   master_arready,
    
    input  [DATA_WIDTH-1:0] master_rdata,
    input                   master_rvalid,
    output                  master_rready,
    
    output [ADDR_WIDTH-1:0] master_awaddr,
    output                  master_awvalid,
    input                   master_awready,
    
    output [DATA_WIDTH-1:0] master_wdata,
    output [3:0]            master_wstrb,
    output                  master_wvalid,
    input                   master_wready,
    
    input                   master_bvalid,
    output                  master_bready
);

// 优先级参数
localparam PRIO_IFU = 1; // IFU优先级高于LSU

// CLINT地址范围检测
wire clint = (lsu_araddr >= 32'h02000000 && lsu_araddr <= 32'h02000004);

//----------------------------------------------------------
// 读通道仲裁 (纯组合逻辑)
//----------------------------------------------------------
// 读请求优先级仲裁
wire ifu_has_priority = PRIO_IFU && ifu_arvalid;
wire lsu_read_eligible = lsu_arvalid && !clint;

// 读地址选择
wire read_selected = ifu_has_priority || lsu_read_eligible;
wire select_ifu = ifu_has_priority;
wire select_lsu = !select_ifu && lsu_read_eligible;

// 读地址通道
assign master_araddr = select_ifu ? ifu_araddr : 
                      select_lsu ? lsu_araddr : 0;
assign master_arvalid = read_selected;

assign ifu_arready = select_ifu && master_arready;
assign lsu_arready = select_lsu && master_arready;

// 读数据通道
assign ifu_rdata = master_rdata;
assign lsu_rdata = master_rdata;

assign ifu_rvalid = select_ifu && master_rvalid;
assign lsu_rvalid = select_lsu && master_rvalid;

assign master_rready = (select_ifu && ifu_rready) || 
                      (select_lsu && lsu_rready);

//----------------------------------------------------------
// 写通道仲裁 (纯组合逻辑)
//----------------------------------------------------------
// 写地址通道
assign master_awaddr = lsu_awaddr;
assign master_awvalid = lsu_awvalid;
assign lsu_awready = master_awready;

// 写数据通道
assign master_wdata = lsu_wdata;
assign master_wstrb = lsu_wstrb;
assign master_wvalid = lsu_wvalid;
assign lsu_wready = master_wready;

// 写响应通道
assign lsu_bvalid = master_bvalid;
assign master_bready = lsu_bready;

endmodule
