module Decoder(
    input [31:0] instr,
    output [4:0] rd,     
    output [4:0] rs1,  
    output [4:0] rs2,
    output [31:0] imm,   
    output [2:0] funct3,
    output [6:0] funct7,
    output [6:0] opcode,
    output [4:0]shamt,
    output wen,
    output ebreak
);
assign opcode = instr[6:0];


wire    [31:0]    immI_num ;
wire    [31:0]    immS_num ;
wire    [31:0]    immB_num ;
wire    [31:0]    immU_num ;
wire    [31:0]    immJ_num ;
wire U_type;
wire J_type;
wire I_type;
wire S_type;
wire R_type;
wire B_type;

assign  ebreak = ( opcode==7'b1110011 ) & ( funct7==7'b0 ) & ( instr[24:20]==5'b00001 ) ;
assign funct3 = (R_type || I_type || S_type || B_type) ? instr[14:12] : 3'b0;
assign funct7 = (R_type) ? instr[31:25] : 7'b0;
assign shamt = instr[24:20];

assign I_type = (opcode == 7'b0010011 || opcode == 7'b1100111 || opcode == 7'b0000011 || opcode == 7'b1010011);
assign R_type = (opcode == 7'b0110011);
assign S_type = (opcode == 7'b0100011);
assign U_type = (opcode == 7'b0110111 || opcode == 7'B0010111);
assign B_type = (opcode == 7'b1100011);
assign J_type = (opcode == 7'b1101111 || opcode == 7'b1011111);

assign  immI_num = { {21{instr[31]}}, instr[30:20] };
assign  immS_num = { {21{instr[31]}}, instr[30:25], instr[11:7] };
assign  immB_num = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0 };
assign  immU_num = { instr[31], instr[30:12], 12'b0 };
assign  immJ_num = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };

assign rs2 = (R_type || S_type || B_type) ? instr[24:20] :5'b0;

assign rs1 = (R_type || S_type || B_type || I_type) ? instr[19:15] : 5'b0;

assign rd = (R_type || I_type || U_type || J_type) ? instr[11:7] : 5'b0;
assign wen = (R_type || I_type || U_type || J_type)  ? 1'b1 :1'b0;


assign imm = ( {32{I_type}} & immI_num ) |
                     ( {32{S_type}} & immS_num ) |
                     ( {32{B_type}} & immB_num ) |
                     ( {32{U_type}} & immU_num ) |
                     ( {32{J_type}} & immJ_num ) ;

endmodule
