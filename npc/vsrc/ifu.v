module ifu(
    input clk,
    input rstn,
    input WBU_IFU_JUMP,
     //IDU是否准备好接收IFU的指令
    output reg IFU_IDU_valid, //IFU传递给IDU的指令是否有效
    input  IDU_IFU_ready, //IDU是否准备好接收IFU的指令
    input [31:0]EXU_IFU_pc,
    input       EXU_IFU_flush,
    input [1:0] resp,
    output  reg[31:0] IFU_dnpc,
    //output [31:0] inst_addr_o,
    output [31:0]IFU_IDU_INSTR,
    //input  [31:0] instr_in,
    output reg [31:0] IFU_IDU_PC,
    input  EXU_LSU_valid,

    input  fence_i,
    input  stall,
    // AXI-Lite4 Interface
    output reg [31:0] IFU_AXI4_araddr,
    output reg        IFU_AXI4_arvalid,
    input             IFU_AXI4_arready,
    input  [31:0]     IFU_AXI4_rdata,
    input             IFU_AXI4_rvalid,
    output reg        IFU_AXI4_rready,
    input  [31:0]     ICACHE_IFU_raddr,
    input             ICACHE_IFU_stall,
    output reg [63:0] ifu_count,
    output reg [63:0] ifu_during_count
);
reg [31:0] pc;
assign IFU_IDU_INSTR = instr;//(fence_i) ? 32'b0 : instr;


localparam IDLE        = 2'b00;
localparam READ  = 2'b01;
reg [1:0] state;

//reg [63:0] ifu_count;

wire [31:0] dnpc;
assign dnpc = (EXU_IFU_flush)? EXU_IFU_pc :pc + 4;
//assign inst_addr_o = pc ;
wire [31:0] inst_addr;
assign inst_addr   = pc;


always@(posedge clk)
begin 
   if(rstn | (resp != 2'b00))begin
    pc<=32'h30000000 ;
    end
    else if(stall) begin
    pc <= pc;
    end
    else if(EXU_IFU_flush)begin 
    pc <= EXU_IFU_pc;
    end
    else if(IDU_IFU_ready && (~ICACHE_IFU_stall))begin
    pc <= pc + 32'h4;
    end
    
end


always@(posedge clk)
begin
    if(rstn)begin
        IFU_dnpc <= 32'h80000000;
    end
    else begin
        IFU_dnpc <= dnpc;
    end
end
reg [31:0] instr;

assign IFU_IDU_valid = 1'b1;

assign IFU_AXI4_araddr = pc;
always @(posedge clk) begin
    if (rstn) begin
        IFU_AXI4_arvalid <= 1'b0;
    end else if (!stall && !EXU_IFU_flush) begin
        IFU_AXI4_arvalid <= 1'b1;
    end else begin
        IFU_AXI4_arvalid <= 1'b0;
    end
end

always @(posedge clk) begin
    if (rstn) begin
        instr <= 32'h0;
        IFU_IDU_PC   <= 32'h0;
    end else if (IFU_AXI4_rvalid && IFU_AXI4_rready) begin
        instr <= IFU_AXI4_rdata;
        IFU_IDU_PC   <= ICACHE_IFU_raddr;   // 早就发出的地址
    end
end

assign IFU_AXI4_rready = !IFU_IDU_valid || IDU_IFU_ready;

// always @(posedge clk) begin
//     if (rstn) begin
//         state <= IDLE;
//         IFU_AXI4_rready <= 1'b0;
//         instr <= 32'h0;
//         ifu_count <= 64'h0;
//         ifu_during_count <= 64'h0;
//     end
//     else begin
//         // State Machine
        
        
//         case (state)
//             IDLE: begin
//                 IFU_AXI4_rready <= 1'b0;
//                 if(IFU_AXI4_arvalid && IFU_AXI4_arready) begin
//                     ifu_during_count <= ifu_during_count + 1'b1;
//                     IFU_AXI4_rready <= 1'b1;
//                     state <= READ;
                    
//                 end
//                 else begin
//                     state <= IDLE;
                    
                    
//                 end
//             end

//             READ: begin
//                 IFU_AXI4_rready <= 1'b1;
//                 if (IFU_AXI4_rready && IFU_AXI4_rvalid) begin
//                     ifu_count <= ifu_count + 1'b1;
//                     instr <= IFU_AXI4_rdata;
//                     IFU_AXI4_rready <= 1'b0;
//                     state <= IDLE;
//                 end
//                 else begin
//                     ifu_during_count <= ifu_during_count + 1'b1;
//                     instr <= instr;
//                     state <= READ;
//                 end
//             end
//         default: begin
//             state <= IDLE;
//             IFU_AXI4_rready <= 1'b0;
//             instr <= 32'h0;
//         end   
//         endcase
//     end
// end

/*
sram_inst inst_sram(
    .CLK(clk),
    .wen(1'b0),
    .addr(inst_addr),
    .Q(instr)
);*/
endmodule

