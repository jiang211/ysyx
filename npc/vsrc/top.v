module top(
    input clk,
    input rstn,
    //input [31:0] instr1,
    output [31:0] instr,
    //output reg[31:0] pc,
    output [31:0] dnpc,
    output [31:0] pc,
    output ebreak
);


//wire [6:0] opcode;
wire [2:0] funct3;
wire [5:0] funct7;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;
wire [31:0] imm;
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire [31:0] alu_out;
//wire [31:0] rdata;
reg  [31:0] csr_data;
wire [31:0] inst_addr_o;
//wire        pcsrc;
//wire [31:0] dnpc;
//wire ebreak;
wire branch;

wire mem_read;
wire mem_write;
wire reg_write;

wire [1:0] alu_op;

wire     u_alu_type;
wire     mul_high;
wire     alu_src1;
wire     alu_src2;

wire     U_type_1;
wire     J_type_1;
assign pc = IFU_IDU_PC ;

wire IDU_EXU_valid;
wire IFU_IDU_valid;
wire EXU_IDU_ready;
wire IDU_IFU_ready;
wire WBU_IFU_ready;
wire WBU_IFU_valid;
wire LSU_WBU_ready;
wire LSU_WBU_valid;
wire LSU_EXU_ready;
wire EXU_LSU_valid;
//wire EXU_IFU_STALL_done;
//wire [31:0] instr;
wire [31:0] WBU_IFU_pc,IFU_IDU_PC;
ifu my_ifu(
    .WBU_IFU_JUMP  (WBU_IFU_JUMP),
    .IFU_IDU_valid  (IFU_IDU_valid), 
    .IDU_IFU_ready  (IDU_IFU_ready),
    .WBU_IFU_ready  (WBU_IFU_ready),
    .WBU_IFU_valid  (WBU_IFU_valid),
    .clk            (clk        ),
    .rstn           (rstn       ),
   //.pcsrc          (pcsrc     ),
    .WBU_IFU_pc     (WBU_IFU_pc),
    //.EXU_IFU_STALL_done (EXU_IFU_STALL_done),
    //.imm            (imm        ),
    //.rs1_data       (rs1_data   ),
    //.alu_out        (alu_out    ),
    //.zero           (EXU_IFU_zero       ),
    //.jal            (EXU_IFU_jal        ),
    //.jalr           (EXU_IFU_jalr       ),
    //.ecall          (LSU_WBU_ecall      ),
    //.mret           (LSU_WBU_mret       ),
    //.csr_data       (csr_data   ),
    //.stall          (IFU_IDU_STALL),
    .IFU_dnpc           (dnpc       ),
    .inst_addr_o    (inst_addr_o),
    .IFU_IDU_PC     (IFU_IDU_PC),
    .instr          (instr)
);
wire [31:0] IDU_EXU_PC;
wire IDU_EXU_lw, IDU_EXU_lh, IDU_EXU_lb, IDU_EXU_lbu, IDU_EXU_lhu, IDU_EXU_sw, IDU_EXU_sb, IDU_EXU_sh;
wire IDU_EXU_csw, IDU_EXU_csc, IDU_EXU_css, IDU_EXU_ecall, IDU_EXU_mret, IDU_EXU_jal, IDU_EXU_jalr,IDU_EXU_C_type;
wire [1:0] IDU_EXU_csr_rst;
idu my_idu(
   // .EXU_IFU_flush          (EXU_IFU_flush),
    .clk                    (clk        ),
    .IFU_IDU_PC             (IFU_IDU_PC),
    .rst_n                   (rstn       ),
   // .IFU_IDU_STALL           (IFU_IDU_STALL),
    .IFU_IDU_valid          (IFU_IDU_valid),
    .IDU_IFU_ready           (IDU_IFU_ready),
    .EXU_IDU_ready             (EXU_IDU_ready), 
    .IDU_EXU_valid          (IDU_EXU_valid),
    .INSTR          (instr      ),
   // .IDU_EXU_opcode         (opcode     ),
    .IDU_EXU_funct3         (funct3     ),
    .IDU_EXU_funct7         (funct7     ),
    .IDU_EXU_rd             (rd         ),
    .IDU_EXU_rs1            (rs1        ),
    .IDU_EXU_rs2            (rs2        ),
    .IDU_EXU_csr_rst        (IDU_EXU_csr_rst    ),
    .IDU_EXU_imm            (imm        ),
    .IDU_EXU_alu_op         (alu_op    ),
    .IDU_EXU_u_alu_type     (u_alu_type  ),
    .IDU_EXU_mul_high       (mul_high     ),
    .IDU_EXU_alu_src1       (alu_src1     ),
    .IDU_EXU_alu_src2       (alu_src2     ),
    .IDU_EXU_branch         (branch       ),
   // .IDU_EXU_mem_to_reg     (mem_to_reg   ),
    .IDU_EXU_mem_read       (mem_read     ),
    .IDU_EXU_mem_write      (mem_write    ),    
    .IDU_EXU_reg_write      (reg_write    ),
    .IDU_EXU_jal            (IDU_EXU_jal          ),
    .IDU_EXU_jalr           (IDU_EXU_jalr   ),
    .IDU_EXU_lw             (IDU_EXU_lw       ),
    .IDU_EXU_lh             (IDU_EXU_lh     ),  
    .IDU_EXU_lb             (IDU_EXU_lb         ),
    .IDU_EXU_lbu            (IDU_EXU_lbu    ),
    .IDU_EXU_lhu            (IDU_EXU_lhu         ),
    .IDU_EXU_sw             (IDU_EXU_sw        ),
    .IDU_EXU_sb             (IDU_EXU_sb     ),
    .IDU_EXU_sh             (IDU_EXU_sh     ),
    .IDU_EXU_csw            (IDU_EXU_csw       ),
    .IDU_EXU_csc            (IDU_EXU_csc      ),
    .IDU_EXU_css            (IDU_EXU_css         ),
    .IDU_EXU_ebreak         (IDU_EXU_ebreak    ),
    .IDU_EXU_ecall          (IDU_EXU_ecall       ),
    .IDU_EXU_mret           (IDU_EXU_mret        ),
    .IDU_EXU_U_type_1       (U_type_1  ),
    .IDU_EXU_J_type_1       (J_type_1  ),
   // .IDU_EXU_pcsrc          (pcsrc       ),
    .IDU_EXU_C_type         (IDU_EXU_C_type    ),
    //.IDU_EXU_STALL          (IDU_EXU_STALL),
    .IDU_EXU_PC             (IDU_EXU_PC)
);  



wire [4:0] EXU_LSU_rd,LSU_WBU_rd;
wire EXU_LSU_ren,EXU_LSU_wen,EXU_LSU_reg,LSU_WBU_reg,EXU_LSU_ebreak,IDU_EXU_ebreak;
wire EXU_LSU_lw,EXU_LSU_lh,EXU_LSU_lb,EXU_LSU_lbu,EXU_LSU_lhu,EXU_LSU_sw,EXU_LSU_sb,EXU_LSU_sh;
wire EXU_LSU_ecall,EXU_LSU_mret,EXU_LSU_C_type;
wire [1:0] EXU_LSU_csr_rst;
wire [31:0] EXU_LSU_csr_data,EXU_LSU_csr_in;
wire EXU_IFU_JUMP;
wire [31:0] EXU_IFU_pc;
exu my_exu(
    .IDU_EXU_rd(rd),
    .clk(clk),
    .rstn(rstn),
    //.IDU_EXU_STALL(IDU_EXU_STALL),
    .IDU_EXU_ebreak(IDU_EXU_ebreak),
    .IDU_EXU_csr_rst(IDU_EXU_csr_rst),
    .IDU_EXU_ren(mem_read),
    .IDU_EXU_wen(mem_write),
    .IDU_EXU_reg(reg_write),
    .IDU_EXU_jal(IDU_EXU_jal),
    .IDU_EXU_jalr(IDU_EXU_jalr),
    .IDU_EXU_lw(IDU_EXU_lw),
    .IDU_EXU_lh(IDU_EXU_lh),
    .IDU_EXU_lb(IDU_EXU_lb),
    .IDU_EXU_lbu(IDU_EXU_lbu),
    .IDU_EXU_lhu(IDU_EXU_lhu),
    .IDU_EXU_sw(IDU_EXU_sw),
    .IDU_EXU_sb(IDU_EXU_sb),
    .IDU_EXU_sh(IDU_EXU_sh),
    .IDU_EXU_csw(IDU_EXU_csw),
    .IDU_EXU_csc(IDU_EXU_csc),
    .IDU_EXU_css(IDU_EXU_css),
    .csr_data(csr_data),
    .IDU_EXU_ecall(IDU_EXU_ecall),
    .IDU_EXU_mret(IDU_EXU_mret),
    .IDU_EXU_C_type(IDU_EXU_C_type),
    .EXU_IDU_ready(EXU_IDU_ready),
    .IDU_EXU_valid(IDU_EXU_valid),
    .LSU_EXU_ready(LSU_EXU_ready),
    .EXU_LSU_valid(EXU_LSU_valid),
    .rs1_data       (rs1_data   ),
    .rs2_data       (rs2_data   ),
    .imm_data       (imm        ),
    .pc_data        (IDU_EXU_PC   ),
    .alu_src1       (alu_src1   ),
    .alu_src2       (alu_src2   ),
    .branch         (branch     ),   
    .J_type_1       (J_type_1   ),
    .u_alu_type     (u_alu_type ),
    .mul_high       (mul_high   ),
    .U_type_1       (U_type_1   ),
    
    .EXU_LSU_alu_out        (alu_out    ),
    //.EXU_IFU_zero           (EXU_IFU_zero       ),
    .funct3         (funct3),
    .funct7         (funct7[5:0]),
    .alu_op         (alu_op),
    .EXU_LSU_rd(EXU_LSU_rd),
    .EXU_LSU_ren(EXU_LSU_ren),
    .EXU_LSU_wen(EXU_LSU_wen),
    .EXU_LSU_reg(EXU_LSU_reg),
    .EXU_LSU_ebreak(EXU_LSU_ebreak),
    //.EXU_IFU_jal(EXU_IFU_jal),
    //.EXU_IFU_jalr(EXU_IFU_jalr),
    .EXU_LSU_lw(EXU_LSU_lw),
    .EXU_LSU_lh(EXU_LSU_lh),
    .EXU_LSU_lb(EXU_LSU_lb),
    .EXU_LSU_lbu(EXU_LSU_lbu),
    .EXU_LSU_lhu(EXU_LSU_lhu),
    .EXU_LSU_sw(EXU_LSU_sw),
    .EXU_LSU_sb(EXU_LSU_sb),
    .EXU_LSU_sh(EXU_LSU_sh),
    .EXU_LSU_csr_data(EXU_LSU_csr_data),
    .EXU_LSU_ecall(EXU_LSU_ecall),
    .EXU_LSU_mret(EXU_LSU_mret),
    .EXU_LSU_csr_rst(EXU_LSU_csr_rst),
    .EXU_LSU_C_type(EXU_LSU_C_type),
    .EXU_LSU_csr_in(EXU_LSU_csr_in),
    .EXU_IFU_pc   (EXU_IFU_pc),
    //.EXU_IFU_STALL_done  (EXU_IFU_STALL_done),
    .EXU_IFU_JUMP       (EXU_IFU_JUMP)
);
wire [31:0] LSU_WBU_result;
wire [31:0] LSU_WBU_csr_data,LSU_WBU_csr_in,WBU_CSR_DATA;
wire [1:0] WBU_CSR_ADDR;
wire [1:0]LSU_WBU_csr_rst;
wire LSU_WBU_ecall,LSU_WBU_mret,LSU_WBU_C_type;
wire LSU_WBU_JUMP;
wire [31:0] LSU_WBU_pc;
lsu my_lsu(
    .EXU_IFU_pc      (EXU_IFU_pc),
    .LSU_WBU_pc      (LSU_WBU_pc),
    .EXU_LSU_JUMP   (EXU_IFU_JUMP),
    .LSU_WBU_JUMP   (LSU_WBU_JUMP),
    .EXU_LSU_lw     (EXU_LSU_lw),
    .EXU_LSU_lh     (EXU_LSU_lh),
    .EXU_LSU_lb     (EXU_LSU_lb),
    .EXU_LSU_lbu    (EXU_LSU_lbu),
    .EXU_LSU_lhu    (EXU_LSU_lhu),
    .EXU_LSU_sw     (EXU_LSU_sw),
    .EXU_LSU_sb     (EXU_LSU_sb),
    .EXU_LSU_sh     (EXU_LSU_sh),
    .EXU_LSU_csr_data(EXU_LSU_csr_data),
    .EXU_LSU_csr_in(EXU_LSU_csr_in),
    .EXU_LSU_ecall  (EXU_LSU_ecall),
    .EXU_LSU_mret   (EXU_LSU_mret),
    .EXU_LSU_C_type (EXU_LSU_C_type),
    .EXU_LSU_csr_rst(EXU_LSU_csr_rst),
    .EXU_LSU_ren    (EXU_LSU_ren),
    .EXU_LSU_wen    (EXU_LSU_wen),
    .EXU_LSU_reg    (EXU_LSU_reg),
    .EXU_LSU_ebreak(EXU_LSU_ebreak),
    .EXU_LSU_rd     (EXU_LSU_rd),
    .EXU_LSU_result (alu_out   ),
    .LSU_EXU_ready  (LSU_EXU_ready),
    .EXU_LSU_valid  (EXU_LSU_valid),
    .LSU_WBU_valid  (LSU_WBU_valid),
    .LSU_WBU_ready  (LSU_WBU_ready),
    .clk            (clk         ),
    .rst_n          (rstn        ),
    
    .alu_result     (alu_out     ),
    .rs2_data       (rs2_data    ),
   // .rdata          (rdata       ),
    .LSU_WBU_csr_data(LSU_WBU_csr_data),
    .LSU_WBU_ecall  (LSU_WBU_ecall),
    .LSU_WBU_mret   (LSU_WBU_mret),
    .LSU_WBU_C_type (LSU_WBU_C_type),
    .LSU_WBU_result (LSU_WBU_result),
    .LSU_WBU_reg    (LSU_WBU_reg),
    .LSU_WBU_rd     (     LSU_WBU_rd       ),
    .LSU_WBU_ebreak(ebreak),
    .LSU_WBU_csr_rst(LSU_WBU_csr_rst),
    .LSU_WBU_csr_in (LSU_WBU_csr_in)
);
wire WBU_ECALL;
wire WBU_IFU_JUMP;
wbu my_wbu(
    .clk                (clk),
    .LSU_WBU_pc         (LSU_WBU_pc),
    .WBU_IFU_pc         (WBU_IFU_pc),
    .LSU_WBU_JUMP       (LSU_WBU_JUMP),
    .WBU_IFU_JUMP       (WBU_IFU_JUMP),
    .LSU_WBU_reg        (LSU_WBU_reg),
    .WBU_IFU_ready      (WBU_IFU_ready),
    .WBU_IFU_valid      (WBU_IFU_valid),
    .LSU_WBU_result     (LSU_WBU_result),
    .LSU_WBU_csr_data   (LSU_WBU_csr_data),
    .LSU_WBU_csr_in     (LSU_WBU_csr_in),
    .LSU_WBU_ecall      (LSU_WBU_ecall),
    .LSU_WBU_mret       (LSU_WBU_mret),
    .LSU_WBU_C_type     (LSU_WBU_C_type),
   // .LSU_WBU_jal        (LSU_WBU_jal),
    //.LSU_WBU_jalr       (LSU_WBU_jalr),
    .LSU_WBU_csr_rst    (LSU_WBU_csr_rst),
    .rst_n              (rstn),
   // .wbu_en             (),
    .LSU_WBU_valid      (LSU_WBU_valid),
    .LSU_WBU_ready      (LSU_WBU_ready),
    //.data_in            (rdata),
    .addr               (LSU_WBU_rd),
    .WBU_REG_DATA       (wbu_data),
    .WBU_REG_ADDR       (wbu_addr),
    .WBU_wen            (WBU_wen),
    .WBU_CSR_DATA       (WBU_CSR_DATA),
    .WBU_CSR_ADDR       (WBU_CSR_ADDR),
    .WBU_CSR_WEN        (WBU_CSR_WEN),
    .WBU_ECALL          (WBU_ECALL)
);


wire [31:0] wbu_data;
wire [4:0] wbu_addr;
wire WBU_wen,WBU_CSR_WEN;
RegisterFile #(.ADDR_WIDTH(5), .DATA_WIDTH(32)) rf1(
        .clk(clk),
        .wdata(wbu_data),
        .waddr(wbu_addr),
        .wen(WBU_wen),
        .rdata1(rs1_data),
        .raddr1(rs1),
        .rdata2(rs2_data),
        .raddr2(rs2)
    );
wire [1:0] WBU_CSR_RADDR;
assign WBU_CSR_RADDR = (IDU_EXU_ecall) ? 'd3 : (IDU_EXU_mret) ? 'd0 :IDU_EXU_csr_rst;
csr_reg #(.ADDR_WIDTH(2), .DATA_WIDTH(32)) csr1(
        .clk(clk),
        .wdata(WBU_CSR_DATA),
        .ecall(WBU_ECALL),
        .pc(inst_addr_o),
        .waddr(WBU_CSR_ADDR),
        .wen(WBU_CSR_WEN),
        .rdata1(csr_data),
        .raddr1(WBU_CSR_RADDR)
    );


endmodule


 




