module lsu(
    input           clk,
    input           rst_n,
    input           EXU_LSU_JUMP,
    output        reg  LSU_WBU_JUMP,
    input  [31:0]   EXU_IFU_pc,
    output reg [31:0]   LSU_WBU_pc,

    input           EXU_LSU_valid,
    output           LSU_EXU_ready,
    output     reg      LSU_WBU_valid,
    input           LSU_WBU_ready,
    input           EXU_LSU_lw,
    input           EXU_LSU_lh,
    input           EXU_LSU_lb,
    input           EXU_LSU_lbu,
    input           EXU_LSU_lhu,
    input           EXU_LSU_sw,
    input           EXU_LSU_sb,
    input           EXU_LSU_sh,
    input      [31:0] EXU_LSU_csr_data,
    input      [31:0] EXU_LSU_csr_in,
    input           EXU_LSU_ecall,
    input           EXU_LSU_mret,
    input           EXU_LSU_C_type,
    input      [1:0] EXU_LSU_csr_rst,

    input           EXU_LSU_ren,
    input           EXU_LSU_wen,
    input           EXU_LSU_reg,
    input           EXU_LSU_ebreak,
    input      [31:0] EXU_LSU_result,
    output      [31:0] LSU_WBU_DATA,

    input    [4:0]  EXU_LSU_rd,
    input    [31:0] alu_result,
    input    [31:0] rs2_data,
    output   reg    LSU_WBU_reg,
    output   reg    LSU_WBU_ebreak,
    //output   [31:0] rdata,
    output   reg [4:0]  LSU_WBU_rd,
    output   reg [31:0] LSU_WBU_csr_data,
    output   reg [31:0] LSU_WBU_csr_in,
    output   reg    LSU_WBU_ecall,
    output   reg    LSU_WBU_mret,
    output   reg    LSU_WBU_C_type,
    output   reg [1:0] LSU_WBU_csr_rst
);
    reg LSU_REN;
    wire [3:0]  wlen;
    wire [31:0] addr;
    wire [31:0] wdata;
    reg  [31:0]rdata_in,rdata;
    assign wdata = ( {32{EXU_LSU_sb}} & {24'b0,rs2_data[7:0]}) |
                   ( {32{EXU_LSU_sh}} & {16'b0,rs2_data[15:0]}) |
                   ( {32{EXU_LSU_sw}} & rs2_data);

    assign rdata = ( {32{EXU_LSU_lb}} & {{24{rdata_in[7]}},rdata_in[7:0]}) |
                   ( {32{EXU_LSU_lh}} & {{16{rdata_in[15]}}, (rdata_in[15:0])}) |
                   ( {32{EXU_LSU_lw}} & rdata_in) |
                   ( {32{EXU_LSU_lbu}} & {24'b0,rdata_in[7:0]}) |
                   ( {32{EXU_LSU_lhu}} & {16'b0,rdata_in[15:0]});

    assign  wlen = ( {4{EXU_LSU_sb}} & 4'd1 )  |
                   ( {4{EXU_LSU_sh}} & 4'd2 )  |
                   ( {4{EXU_LSU_sw}} & 4'd4 ) ;
    
    
    //wire [31:0] LSU_WBU_DATA;
    reg [31:0] LSU_WBU_result;
    assign LSU_WBU_DATA = (LSU_REN) ? rdata : LSU_WBU_result;


    assign addr = alu_result;

//import "DPI-C" function void vpmem_read(input int raddr,input byte ren,output int rdata);
//import "DPI-C" function void vpmem_write(input int waddr, input byte wmask,input int wdata,input byte wen);
//reg [31:0] RDATAIN,WDATA;
always @(posedge clk) begin
    if(!rst_n)begin
        //RDATAIN <= 32'b0;
        //WDATA   <= 32'b0;
        LSU_WBU_rd <= 5'b0;
        LSU_WBU_result <= 32'b0;
        LSU_WBU_reg <= 1'b0;
        LSU_WBU_ebreak <= 1'b0;
        LSU_WBU_csr_data <= 32'b0;
        LSU_WBU_ecall <= 1'b0;
        LSU_WBU_mret <= 1'b0;
        LSU_WBU_C_type <= 1'b0;
        LSU_WBU_csr_rst <= 2'b0;
        LSU_WBU_csr_in <= 32'b0;
        LSU_WBU_JUMP <= 1'b0;
        LSU_WBU_pc <= 32'b0;
        LSU_REN      <= 1'b0;
    end else if(LSU_WBU_ready && LSU_WBU_valid) begin
        //RDATAIN <= rdata_in;
        //WDATA   <= wdata;
        LSU_WBU_result <= EXU_LSU_result;
        LSU_REN      <= EXU_LSU_ren;
        LSU_WBU_rd <= EXU_LSU_rd;
        LSU_WBU_reg<= EXU_LSU_reg;
        LSU_WBU_ebreak<= EXU_LSU_ebreak;
        LSU_WBU_csr_data <= EXU_LSU_csr_data;
        LSU_WBU_ecall <= EXU_LSU_ecall;
        LSU_WBU_mret <= EXU_LSU_mret;
        LSU_WBU_C_type <= EXU_LSU_C_type;
        LSU_WBU_csr_rst <= EXU_LSU_csr_rst;
        LSU_WBU_csr_in <= EXU_LSU_csr_in;
        LSU_WBU_JUMP <= EXU_LSU_JUMP;
        LSU_WBU_pc <= EXU_IFU_pc;
    end else begin
        //RDATAIN <= 32'b0;
        //WDATA   <= 32'b0;
        LSU_WBU_rd <= 5'b0;
        LSU_WBU_result <= 32'b0;
        LSU_WBU_reg <= 1'b0;
        LSU_WBU_ebreak <= 1'b0;
        LSU_WBU_csr_data <= 32'b0;
        LSU_WBU_ecall <= 1'b0;
        LSU_WBU_mret <= 1'b0;
        LSU_WBU_C_type <= 1'b0;
        LSU_WBU_csr_rst <= 2'b0;
        LSU_WBU_csr_in <= 32'b0;
        LSU_WBU_JUMP <= 1'b0;
        LSU_WBU_pc <= 32'b0;
        LSU_REN      <= 1'b0;
    end
end

always @(posedge clk) begin
    if(!rst_n)
        LSU_WBU_valid <= 1'b0;
    else if(EXU_LSU_valid && LSU_EXU_ready)
        LSU_WBU_valid <= 1'b1;
    else if(LSU_WBU_ready && LSU_WBU_valid) 
        LSU_WBU_valid <= 1'b0;
    else
        LSU_WBU_valid <= 1'b0;
end
assign LSU_EXU_ready = ~LSU_WBU_valid;

sram_data data_sram(
    .CLK(clk),
    .wen(EXU_LSU_wen),
    .ren(EXU_LSU_ren),
    .wlen(wlen),
    .addr(addr),
    .data(wdata),
    .Q(rdata_in)
);
/*
always @(posedge clk) begin
    vpmem_read(addr,{7'b0, ren},rdata_in);
end

always @(posedge clk) begin

    vpmem_write(addr, {4'b0, wlen},wdata,{7'b0, wen});
    
end
*/
endmodule
