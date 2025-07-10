module exu(
    input clk,
    input rstn,
    output      reg       EXU_IDU_ready,          // 从执行单元(EXU)到IDU的就绪信号
    input               IDU_EXU_valid,          // IDU到EXU的有效信号
    input       WBU_EXU_ready,
    output      reg EXU_WBU_valid,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] imm_data,
    input [31:0] pc_data,
    input alu_src1,
    input alu_src2,
    input branch,
    input u_alu_type,
    input mul_high,
    input U_type_1,
    input J_type_1,
    
    output  [31:0] EXU_LSU_alu_out,
    output  EXU_LSU_zero,
    input [2:0]  funct3,
    input [5:0]  funct7,
    input [1:0]  alu_op
    
);
wire [3:0]aluop;
wire zero;
wire [31:0] alu_out;
alu_ctrl my_alu_crtl(
    .funct3         (funct3),
    .funct7         (funct7[5:0]),
    .alu_op         (alu_op),
    .aluOp          (aluop)
);

alu my_alu(
    .rs1_data       (rs1_data   ),
    .rs2_data       (rs2_data   ),
    .imm_data       (imm_data        ),
    .pc_data        (pc_data       ),
    .alu_src1       (alu_src1   ),
    .alu_src2       (alu_src2   ),
    .branch         (branch     ),   
    .J_type_1       (J_type_1   ),
    .u_alu_type     (u_alu_type ),
    .mul_high       (mul_high   ),
    .U_type_1       (U_type_1   ),
    .alu_crtl       (aluop      ),
    .alu_out        (alu_out    ),
    .zero           (zero       )
);

always @(posedge clk) begin EXU_IDU_ready = (WBU_EXU_ready | ~EXU_WBU_valid);  end  

always @(posedge clk) begin EXU_WBU_valid = (IDU_EXU_valid & EXU_IDU_ready);  end


always@(posedge clk)
begin 
   if(!rstn)begin
    EXU_LSU_zero              <=        1'b0;
    EXU_LSU_alu_out           <=        32'b0;
    end
    else if(EXU_IDU_ready & IDU_EXU_valid)begin
    EXU_LSU_alu_out           <=        alu_out;
    EXU_LSU_zero              <=        zero;

    end
    else begin
    EXU_LSU_alu_out           <=        EXU_LSU_alu_out;
    EXU_LSU_zero              <=        EXU_LSU_zero;

    end
end
endmodule
