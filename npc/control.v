module idu(
    input wire [31:0] INSTR,
    input clk,
    input rst_n,
    input               IFU_IDU_valid,          // 从IFU到IDU的有效信号
    input               EXU_IDU_ready,          // 从执行单元(EXU)到IDU的就绪信号
    output reg          IDU_EXU_valid,          // IDU到EXU的有效信号
    output reg [1:0]IDU_EXU_alu_op ,       
    output IDU_EXU_u_alu_type    ,
    output IDU_EXU_mul_high      ,
    output IDU_EXU_alu_src1      ,
    output IDU_EXU_alu_src2      ,
    output IDU_EXU_branch        ,
    output IDU_EXU_mem_to_reg    ,
    output IDU_EXU_mem_read      ,
    output IDU_EXU_mem_write     ,
    output IDU_EXU_reg_write     ,
    output IDU_EXU_jal           ,
    output IDU_EXU_jalr          ,
    output IDU_EXU_lw            ,
    output IDU_EXU_lh            ,
    output IDU_EXU_lb            ,
    output IDU_EXU_lbu           ,
    output IDU_EXU_lhu           ,
    output IDU_EXU_sw            ,
    output IDU_EXU_sb            ,
    output IDU_EXU_sh            ,
    output IDU_EXU_csw           ,
    output IDU_EXU_csc           ,
    output IDU_EXU_css           ,
    output IDU_EXU_ebreak        ,
    output IDU_EXU_ecall         ,
    output IDU_EXU_mret          ,
    output IDU_EXU_U_type_1      ,
    output IDU_EXU_J_type_1      ,
    output IDU_EXU_pcsrc         ,
    output IDU_EXU_C_type        
);

reg [31:0]instr;
wire    [31:0]    immI_num ;
wire    [31:0]    immS_num ;
wire    [31:0]    immB_num ;
wire    [31:0]    immU_num ;
wire    [31:0]    immJ_num ;
wire    [1:0]     immC_num ;
wire    [6:0]     opcode   ;
wire    [2:0]     funct3   ; 
wire    [6:0]     funct7   ; 
wire    [4:0]     rd       ;     
wire    [4:0]     rs1      ; 
wire    [4:0]     rs2      ; 
wire    [1:0]     csr_rst  ; 
wire    [31:0]    imm      ; 
wire U_type;
wire J_type;
wire I_type;
wire S_type;
wire R_type;
wire B_type;
wire C_type;
wire I_type_1 = (opcode == 7'b0010011);

assign funct3 = (R_type || I_type || S_type || B_type|| C_type) ? instr[14:12] : 3'b0;
assign funct7 = (R_type || I_type_1) ? instr[31:25] : 7'b0;
assign opcode = instr[6:0];
assign I_type = (opcode == 7'b0010011 || opcode == 7'b1100111 || opcode == 7'b0000011 || opcode == 7'b1010011);
assign R_type = (opcode == 7'b0110011);
assign S_type = (opcode == 7'b0100011);
assign U_type = (opcode == 7'b0110111 || opcode == 7'B0010111);
assign B_type = (opcode == 7'b1100011);
assign J_type = (opcode == 7'b1101111 || opcode == 7'b1011111);
assign C_type = (opcode == 7'b1110011);

assign  immI_num = { {21{instr[31]}}, instr[30:20] };
assign  immS_num = { {21{instr[31]}}, instr[30:25], instr[11:7] };
assign  immB_num = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0 };
assign  immU_num = { instr[31], instr[30:12], 12'b0 };
assign  immJ_num = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };
assign  immC_num =   (instr[31:20] == 'h341) ? 2'd0 :
                    (instr[31:20] == 'h300) ? 2'd1 :
                    (instr[31:20] == 'h342) ? 2'd2 :
                    (instr[31:20] == 'h305) ? 2'd3 : 2'd0;
assign rs2 = (R_type || S_type || B_type) ? instr[24:20] :5'b0;
assign csr_rst = (C_type) ? immC_num : 2'd0;
assign rs1 = (R_type || S_type || B_type || I_type || C_type) ? instr[19:15] : 5'b0;

assign rd = (R_type || I_type || U_type || J_type || C_type) ? instr[11:7] : 5'b0;



assign imm = ( {32{I_type}} & immI_num ) |
                     ( {32{S_type}} & immS_num ) |
                     ( {32{B_type}} & immB_num ) |
                     ( {32{U_type}} & immU_num ) |
                     ( {32{J_type}} & immJ_num ) ;
wire J_type_1,C_type;
wire [1:0] alu_op;
assign J_type_1 = (opcode == 7'b1101111) || I_type_2; 
assign C_type = (opcode == 7'b1110011);
wire I_type_1 = (opcode == 7'b0010011);
wire I_type_2 = (opcode == 7'b1100111);
wire I_type_3 = (opcode == 7'b0000011);
wire I_type_4 = (opcode == 7'b1010011);
wire jalr = (opcode == 7'b1100111);
wire jal  = (opcode == 7'b1101111);
wire U_type_1 = (opcode == 7'b0110111);

wire csw = ( C_type && funct3 == 3'b001 );
wire csc = ( C_type && funct3 == 3'b011 );
wire css = ( C_type && funct3 == 3'b010 );

assign lh   = (I_type_3 && funct3 == 3'b001);
assign lw   = (I_type_3 && funct3 == 3'b010);
assign lb   = (I_type_3 && funct3 == 3'b000);
assign lbu  = (I_type_3 && funct3 == 3'b100);
assign lhu  = (I_type_3 && funct3 == 3'b101);

assign sw   = (S_type && funct3 == 3'b010);
assign sb   = (S_type && funct3 == 3'b000);
assign sh   = (S_type && funct3 == 3'b001);


wire remu = (R_type && funct7 == 7'b0000001 && funct3 == 3'b111);
wire mulh = (R_type && funct7 == 7'b0000001 && funct3 == 3'b001);
wire mulhu= (R_type && funct7 == 7'b0000001 && funct3 == 3'b011);
wire divu = (R_type && funct7 == 7'b0000001 && funct3 == 3'b101);
wire sltu = (R_type && funct7 == 7'b0000000 && funct3 == 3'b011);
wire mul  = (R_type && funct7 == 7'b0000001 && funct3 == 3'b000);
wire sltiu= (I_type_1 && funct3 == 3'b011);
wire bltu = (B_type && funct3 == 3'b110);
wire bgeu = (B_type && funct3 == 3'b111);

wire u_alu_type = (mulhu | divu | sltu | mul | sltiu | bltu | bgeu | remu | lbu | lhu ) ? 1'b1 : 1'b0;
wire mul_high = mulh | mulhu;
wire jump = J_type | I_type_2;
wire mem_read = I_type_3;
wire mem_write = S_type;
wire  ebreak = ( instr == 32'b00000000000100000000000001110011 ) ;
wire ecall  = ( instr == 32'b00000000000000000000000001110011)  ;
wire mret   = ( instr == 32'b00110000001000000000000001110011 ) ;
wire reg_write = !B_type;
wire alu_src1 = R_type | I_type_1 | I_type_3 | I_type_4 | S_type;
wire alu_src2 = R_type;
wire mem_to_reg = (mem_read|mem_write);
wire branch = B_type;
assign alu_op = (R_type) ? 2'b10 :
                (B_type) ? 2'b01 :
                (S_type | U_type | I_type_3 | J_type) ? 2'b00 :
                2'b11;
assign pcsrc = (branch & zero) | jump | ecall | mret;


//always @(*) begin IDU_IFU_ready = (EXU_IDU_ready | ~IDU_EXU_valid);  end  // 设置IDU到IFU的就绪信号
always@(posedge clk) begin
    if(!rst_n) instr <= 32'b0;
    else if(IFU_IDU_valid)instr <= INSTR;
    else instr <= instr;
end
always @(posedge clk) begin IDU_EXU_valid <= (IFU_IDU_valid);  end

always@(posedge clk)
begin 
   if(!rst_n)begin
    IDU_EXU_alu_op              <=        2'b0;     
    IDU_EXU_u_alu_type          <=        1'b0;   
    IDU_EXU_mul_high            <=        1'b0;
    IDU_EXU_alu_src1            <=        1'b0;
    IDU_EXU_alu_src2            <=        1'b0;  
    IDU_EXU_branch              <=        1'b0;
    IDU_EXU_mem_to_reg          <=        1'b0;    
    IDU_EXU_mem_read            <=        1'b0;
    IDU_EXU_mem_write           <=        1'b0;     
    IDU_EXU_reg_write           <=        1'b0;   
    IDU_EXU_jal                 <=        1'b0;
    IDU_EXU_jalr                <=        1'b0;
    IDU_EXU_lw                  <=        1'b0;  
    IDU_EXU_lh                  <=        1'b0;
    IDU_EXU_lb                  <=        1'b0;    
    IDU_EXU_lbu                 <=        1'b0;
    IDU_EXU_lhu                 <=        1'b0;     
    IDU_EXU_sw                  <=        1'b0;   
    IDU_EXU_sb                  <=        1'b0;
    IDU_EXU_sh                  <=        1'b0;
    IDU_EXU_csw                 <=        1'b0;  
    IDU_EXU_csc                 <=        1'b0;
    IDU_EXU_css                 <=        1'b0;    
    IDU_EXU_ebreak              <=        1'b0;
    IDU_EXU_ecall               <=        1'b0;     
    IDU_EXU_mret                <=        1'b0;   
    IDU_EXU_U_type_1            <=        1'b0;
    IDU_EXU_J_type_1            <=        1'b0;
    IDU_EXU_pcsrc               <=        1'b0;  
    IDU_EXU_C_type              <=        1'b0;
    end
    else if(IDU_EXU_valid && EXU_IDU_ready)begin
    IDU_EXU_alu_op              <=        alu_op;     
    IDU_EXU_u_alu_type          <=        u_alu_type;   
    IDU_EXU_mul_high            <=        mul_high     ;
    IDU_EXU_alu_src1            <=        alu_src1     ;
    IDU_EXU_alu_src2            <=        alu_src2     ;  
    IDU_EXU_branch              <=        branch       ;
    IDU_EXU_mem_to_reg          <=        mem_to_reg   ;    
    IDU_EXU_mem_read            <=        mem_read     ;
    IDU_EXU_mem_write           <=        mem_write    ;     
    IDU_EXU_reg_write           <=        reg_write    ;   
    IDU_EXU_jal                 <=        jal          ;
    IDU_EXU_jalr                <=        jalr   ;
    IDU_EXU_lw                  <=        lw     ;  
    IDU_EXU_lh                  <=        lh     ;
    IDU_EXU_lb                  <=        lb     ;    
    IDU_EXU_lbu                 <=        lbu    ;
    IDU_EXU_lhu                 <=        lhu    ;     
    IDU_EXU_sw                  <=        sw     ;   
    IDU_EXU_sb                  <=        sb     ;
    IDU_EXU_sh                  <=        sh     ;
    IDU_EXU_csw                 <=        csw       ;  
    IDU_EXU_csc                 <=        csc       ;
    IDU_EXU_css                 <=        css       ;    
    IDU_EXU_ebreak              <=        ebreak    ;
    IDU_EXU_ecall               <=        ecall     ;     
    IDU_EXU_mret                <=        mret      ;   
    IDU_EXU_U_type_1            <=        U_type_1  ;
    IDU_EXU_J_type_1            <=        J_type_1  ;
    IDU_EXU_pcsrc               <=        pcsrc     ;  
    IDU_EXU_C_type              <=        C_type    ;
    end
end


endmodule
