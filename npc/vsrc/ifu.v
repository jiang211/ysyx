module ifu(
    input clk,
    input rstn,
    input WBU_IFU_JUMP,
    input WBU_IFU_valid,
    output  WBU_IFU_ready, //IFU是否准备好接收WBU的指令
     //IDU是否准备好接收IFU的指令
    output reg IFU_IDU_valid, //IFU传递给IDU的指令是否有效
    input  IDU_IFU_ready, //IDU是否准备好接收IFU的指令
    input [31:0]WBU_IFU_pc,
    //input       EXU_IFU_STALL_done,
    //input pcsrc,
    //input [31:0] imm,
    //input [31:0] rs1_data,
    //input [31:0] alu_out,
    //input zero,
    //input jalr,
    //input jal,
    //input ecall,
    //input mret,
    //input [31:0] csr_data,
    //output reg stall,
    output  reg[31:0] IFU_dnpc,
    output [31:0] inst_addr_o,
    output [31:0]instr,
    output reg [31:0] IFU_IDU_PC
);
reg [31:0] pc;
//wire [31:0] d_pc;
/*
wire I_type_2 = (instr[6:0] == 7'b1100111);
wire B_type = (instr[6:0] == 7'b1100011);
wire J_type_1 = (instr[6:0] == 7'b1101111) || I_type_2; 
wire ecall  = ( instr == 32'b00000000000000000000000001110011)  ;
wire mret   = ( instr == 32'b00110000001000000000000001110011 ) ;
wire pcsrc = (B_type /*& zero*/// | J_type_1 | ecall | mret;
//assign d_pc = (ecall)? csr_data : (mret) ? csr_data : (jal) ? pc + imm : (jalr) ? rs1_data + imm : (zero) ? alu_out : pc + 4;
/*
always @(pc) begin
    case(EXU_IFU_flush)
        1'b0: begin dnpc <= pc + 32'h4; end
        1'b1: begin dnpc <= EXU_IFU_pc; end
        default: dnpc <= pc + 32'h4;
    endcase
end
*/
wire [31:0] dnpc;
assign dnpc = (WBU_IFU_JUMP)? WBU_IFU_pc :pc + 4;
assign inst_addr_o = pc ;
wire [31:0] inst_addr;
assign inst_addr   = pc;
always@(posedge clk)
begin 
   if(!rstn)begin
    pc<=32'h80000000 ;
    end
    else if(WBU_IFU_JUMP)begin 
    pc <= WBU_IFU_pc;
    end
    else if(WBU_IFU_valid)begin
    pc <= pc + 32'h4;
    end
end
assign WBU_IFU_ready = ~IFU_IDU_valid;
always@(posedge clk)
begin 
   if(!rstn)begin
    IFU_IDU_valid <= 1'b1;
    end
    else if(IFU_IDU_valid && IDU_IFU_ready)
    begin
    IFU_IDU_valid <= 1'b0;
    end
    else if(WBU_IFU_valid && WBU_IFU_ready)begin 
    IFU_IDU_valid <= 1'b1;
    end
end

sram_inst inst_sram(
    .CLK(clk),
    .wen(1'b0),
    .addr(inst_addr),
    .Q(instr)
);
always@(posedge clk)
begin
    if(!rstn)begin
        IFU_IDU_PC <= 32'h80000000;
        IFU_dnpc <= 32'h80000000;
    end
    else begin
        IFU_IDU_PC <= inst_addr;
        IFU_dnpc <= dnpc;
    end
end
endmodule

