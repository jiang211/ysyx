module ysyx_24070003_wbu(
    input clock,
    input rst_n,
    //input LSU_WBU_JUMP,
    //output reg WBU_IFU_JUMP,
    input [31:0] LSU_WBU_PC,
    input [31:0] LSU_WBU_dnpc,
    input        LSU_WBU_skip,
   // output reg [31:0] WBU_IFU_pc,

    input LSU_WBU_valid,
    output LSU_WBU_ready,
    input LSU_WBU_reg,
    input [31:0] LSU_WBU_csr_data,
    input [31:0] LSU_WBU_csr_in,
    input [2:0]  LSU_WBU_csr_rst,
    input LSU_WBU_ecall,
    input LSU_WBU_mret,
    input LSU_WBU_C_type,
 //   input LSU_WBU_jal,
   // input LSU_WBU_jalr,
    //input [31:0]data_in,
    input [31:0] LSU_WBU_result,
    input [4:0] addr,
    output reg [31:0]WBU_REG_DATA,
    output reg [4:0]WBU_REG_ADDR,
    output reg [31:0]WBU_CSR_DATA,
    output reg [2:0]WBU_CSR_ADDR,
    output reg WBU_wen,
    output reg WBU_CSR_WEN,
    output reg WBU_ECALL,
    output reg [31:0] PC_DATA,
    output reg [31:0] DNPC_DATA,
    output reg WBU_TOP_skip
);

//wire [4:0] csr_addr;
wire csr_en;

//assign csr_addr = (LSU_WBU_ecall) ? 'd3 : (LSU_WBU_mret) ? 'd0 :LSU_WBU_csr_rst;


assign csr_en = LSU_WBU_C_type&(~LSU_WBU_mret)&(~LSU_WBU_ecall);
assign WBU_wen = LSU_WBU_reg;
assign WBU_REG_DATA = (LSU_WBU_C_type) ? LSU_WBU_csr_data : LSU_WBU_result;
assign WBU_REG_ADDR = addr;
assign WBU_CSR_DATA = LSU_WBU_csr_in;
assign WBU_CSR_ADDR = LSU_WBU_csr_rst;
assign WBU_CSR_WEN    = csr_en;
assign WBU_ECALL      = LSU_WBU_ecall;
assign PC_DATA        = LSU_WBU_PC;
assign DNPC_DATA      = LSU_WBU_dnpc;
assign WBU_TOP_skip   = LSU_WBU_skip;

assign LSU_WBU_ready = 1'b1;


endmodule
