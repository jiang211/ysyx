module dpc(
   
    input [31:0]pc,
    input [31:0] rs1_data,  
    input [6:0] opcode,
    input [31:0] imm,             
    input [31:0] rs2_data,
    input [2:0] funct3,
    
   
    output [31:0] dnpc_d,
    output d_en
    
);



wire I_type_2 = (opcode == 7'b1100111);
wire J_type_1 = (opcode == 7'b1101111);
wire J_type_2 = (opcode == 7'b1011111);
wire B_type = (opcode == 7'b1100011);
wire bne  = (B_type && funct3 == 3'b001);
wire beq  = (B_type && funct3 == 3'b000);
wire bltu = (B_type && funct3 == 3'b110);
wire blt  = (B_type && funct3 == 3'b100);
wire bge  = (B_type && funct3 == 3'b101);
wire bgeu = (B_type && funct3 == 3'b111);
wire jal  = J_type_1;
wire j    = J_type_2;
wire jalr = (I_type_2 && funct3 == 3'b000);
wire signed [31:0] data1 = rs1_data;
wire signed [31:0] data2 = rs2_data;
wire unsigned [31:0] udata1 = rs1_data;
wire unsigned [31:0] udata2 = rs2_data;

assign d_en = jalr | jal | j | bne | beq | bltu | blt | bge;
assign dnpc_d =( ( {32{jalr}} & ((rs1_data + imm ) & 32'hFFFFFFFE) ) |
                     ( {32{jal}} &  (pc + imm) ) |
                     ( {32{j}} &  (pc + imm) ) |
                     ( {32{bne}} &  ((udata1 != udata2) ? pc + imm : pc + 32'h4) ) |
                     ( {32{beq}} &  ((udata1 == udata2) ? pc + imm : pc + 32'h4) ) |
                     ( {32{bltu}} &  ((udata1 < udata2) ? pc + imm : pc + 32'h4) ) |
                     ( {32{blt}} &  ((data1 < data2) ? pc + imm : pc + 32'h4) ) |
                     ( {32{bgeu}} &  ((udata1 < udata2) ? pc + imm : pc + 32'h4) ) |
                     ( {32{bge}} &  ((data1 >= data2) ? pc + imm : pc + 32'h4 ) ));
/*
assign cen = 
import "DPI-C" function void call(input int pc,input int dnpc,input byte cen);
import "DPI-C" function void ret(input int pc,input byte en);
always@(*)
begin

end
*/


endmodule
