module wbu(
    input clk,
    input rst_n,
    input LSU_WBU_JUMP,
    output reg WBU_IFU_JUMP,
    input [31:0] LSU_WBU_pc,
    output reg [31:0] WBU_IFU_pc,
    output reg WBU_IFU_valid,
    input LSU_WBU_valid,
    output LSU_WBU_ready,
    input WBU_IFU_ready,
    input LSU_WBU_reg,
    input [31:0] LSU_WBU_csr_data,
    input [31:0] LSU_WBU_csr_in,
    input [1:0]  LSU_WBU_csr_rst,
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
    output reg [1:0]WBU_CSR_ADDR,
    output reg WBU_wen,
    output reg WBU_CSR_WEN,
    output reg WBU_ECALL
);

//wire [4:0] csr_addr;
wire csr_en;

//assign csr_addr = (LSU_WBU_ecall) ? 'd3 : (LSU_WBU_mret) ? 'd0 :LSU_WBU_csr_rst;

assign csr_en = LSU_WBU_C_type&(~LSU_WBU_mret)&(~LSU_WBU_ecall);
always @(posedge clk) begin
    if(!rst_n)begin
        WBU_REG_DATA <= 32'b0;
        WBU_REG_ADDR <= 5'b0;
        WBU_CSR_DATA <= 32'b0;
        WBU_CSR_ADDR <= 2'b0;
        WBU_CSR_WEN <= 1'b0;
        WBU_wen <= 1'b0;
        WBU_ECALL <= 1'b0;
        WBU_IFU_JUMP <= 1'b0;
        WBU_IFU_pc <= 32'b0;
    end else if(LSU_WBU_C_type && WBU_IFU_ready && WBU_IFU_valid) begin
        WBU_REG_DATA <= LSU_WBU_csr_data;
        WBU_REG_ADDR   <= addr;
        WBU_CSR_ADDR   <= LSU_WBU_csr_rst;
        WBU_CSR_DATA   <= LSU_WBU_csr_in;
        WBU_wen <= LSU_WBU_reg;
        WBU_CSR_WEN    <= csr_en;
        WBU_ECALL      <= LSU_WBU_ecall;
        WBU_IFU_JUMP   <= LSU_WBU_JUMP;
        WBU_IFU_pc     <= LSU_WBU_pc;
    end else if(WBU_IFU_ready && WBU_IFU_valid) begin
        WBU_REG_DATA <= LSU_WBU_result;
        WBU_REG_ADDR   <= addr;
        WBU_CSR_ADDR   <= LSU_WBU_csr_rst;
        WBU_CSR_DATA   <= LSU_WBU_csr_in;
        WBU_wen <= LSU_WBU_reg;
        WBU_CSR_WEN    <= csr_en;
        WBU_ECALL      <= LSU_WBU_ecall;
        WBU_IFU_JUMP   <= LSU_WBU_JUMP;
        WBU_IFU_pc     <= LSU_WBU_pc;
    end else begin
        
        WBU_REG_DATA <= 32'b0;
        WBU_REG_ADDR <= 5'b0;
        WBU_CSR_DATA <= 32'b0;
        WBU_CSR_ADDR <= 2'b0;
        WBU_CSR_WEN <= 1'b0;
        WBU_wen <= 1'b0;
        WBU_ECALL <= 1'b0;
        WBU_IFU_JUMP <= 1'b0;
        WBU_IFU_pc <= 32'b0;
    end
end
assign LSU_WBU_ready = ~WBU_IFU_valid;
always @(posedge clk) begin
    if(!rst_n)begin
        WBU_IFU_valid <= 1'b0;
    end else if(LSU_WBU_valid && LSU_WBU_ready)
        WBU_IFU_valid <= 1'b1;
    else if(WBU_IFU_valid && WBU_IFU_ready)
        WBU_IFU_valid <= 1'b0;
    else 
        WBU_IFU_valid <= 1'b0;
end


endmodule
