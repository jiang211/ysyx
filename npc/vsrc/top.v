module top(
    input clk,
    input rstn,
    input [31:0] pc_,
    input [31:0] instr,
    output reg[31:0] pc,
    output [31:0] dnpc,
    output [31:0] waste,
    output ebreak,
    
    output [31:0]rs1_data
);


wire [31:0]dnpc_d;
 
wire [2:0] funct3;
wire [6:0] funct7;
wire [6:0] opcode;
wire [31:0] imm;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [31:0]rs2_data;
wire d_en;
//wire n;
wire wen;
wire [31:0] alu_out;


ifu my_ifu(
    .clk(clk),
    .rstn(rstn),
    .d_en(d_en),
    .pc(pc),
    .dnpc_d(dnpc_d),
    .pc_(pc_),
    .dnpc(dnpc)
);
wire [4:0] shamt;
Decoder my_decoder(
        .instr(instr),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .wen(wen),
        .shamt(shamt),
        .ebreak(ebreak)
    );


RegisterFile #(.ADDR_WIDTH(5), .DATA_WIDTH(32)) rf1(
        .clk(clk),
        .wdata(wdata_in),
        .waddr(rd),
        .wen(wen),
        .rdata1(rs1_data),
        .raddr1(rs1),
        .rdata2(rs2_data),
        .raddr2(rs2)
    );

dpc my_dpc(
        .pc(pc_), 
        .rs1_data(rs1_data),
        .opcode(opcode),
        .imm(imm),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .dnpc_d(dnpc_d),
        .d_en(d_en)
    );

alu my_alu(
        .pc(pc_), 
        .shamt(shamt),
        .rs1_data(rs1_data),
        .opcode(opcode),
        .imm(imm),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .funct7(funct7), 
        .alu_out(alu_out),
        .waste(waste)
    );

wire [31:0]raddr,waddr,wdata,wdata_in;
wire [3:0]wlen;
wire lh,lw,lb,lbu,lhu,I_type_3,mren,mwen;
mmu mu_mmu(
    .rs1_data(rs1_data),
    .opcode(opcode),
    .imm(imm),
    .rs2_data(rs2_data),
    .funct3(funct3),
    .raddr(raddr),
    .waddr(waddr),
    .wdata(wdata),
    .wlen(wlen),
    .I_type_3(I_type_3),
    .mwen(mwen),
    .mren(mren),
    .lh(lh),
    .lw(lw),
    .lb(lb),
    .lhu(lhu),
    .lbu(lbu)
);

idu my_idu(
    .lh(lh),
    .lw(lw),
    .lb(lb),
    .lbu(lbu),
    .lhu(lhu),
    .I_type_3(I_type_3),
    .alu_out(alu_out),
    .rdata(rdata),
    .wdata_in(wdata_in)
);
import "DPI-C" function void vpmem_read(input int raddr,input byte ren,output int rdata);
import "DPI-C" function void vpmem_write(input int waddr, input byte wmask,input int wdata,input byte wen);


reg [31:0] rdata;

always @(*) begin
    vpmem_read(raddr,{7'b0, mren&~clk},rdata);

    vpmem_write(waddr, {4'b0, wlen},wdata,{7'b0, mwen&~clk});
    
end
 
endmodule


 



