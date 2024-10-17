module mmu(
    input [31:0] rs1_data,  
    input [6:0] opcode,
    input [31:0] imm,             
    input [31:0] rs2_data,
    input [2:0] funct3,
    
    output I_type_3,
    output [31:0]raddr,
    output [31:0]waddr,
    output [31:0]wdata,
    output [3:0]wlen,
    output lh,
    output lb,
    output mren,
    output mwen,
    output lw,
    output lhu,
    output lbu
);


assign I_type_3 = (opcode == 7'b0000011);

wire S_type = (opcode == 7'b0100011);

wire sw   = (S_type && funct3 == 3'b010);
wire sb   = (S_type && funct3 == 3'b000);
wire sh   = (S_type && funct3 == 3'b001);
assign lh   = (I_type_3 && funct3 == 3'b001);
assign lw   = (I_type_3 && funct3 == 3'b010);
assign lb   = (I_type_3 && funct3 == 3'b001);
assign lbu  = (I_type_3 && funct3 == 3'b100);
assign lhu  = (I_type_3 && funct3 == 3'b101);


assign mren = lh|lw|lbu|lhu|lb;
assign mwen = (sw | sb |sh) ? 1'b1: 1'b0;

assign  wdata = ( {32{sb}} & {24'b0, rs2_data[7 :0]} ) | 
                  ( {32{sh}} & {16'b0, rs2_data[15:0]} ) |
                  ( {32{sw}} & rs2_data[31:0] ) ;
                  
assign waddr = ({32{sh}}&(rs1_data + imm))|
               ({32{sw}}& (rs1_data + imm))|
               ({32{sb}}&(rs1_data + imm));

assign  wlen = ( {4{sb}} & 4'd1 )  |
                 ( {4{sh}} & 4'd2 )  |
                 ( {4{sw}} & 4'd4 ) ;


assign raddr = ({32{mren}}&(rs1_data + imm));

 
endmodule
