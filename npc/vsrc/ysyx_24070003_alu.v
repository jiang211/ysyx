module ysyx_24070003_alu(
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] imm_data,
    input [31:0] pc_data,
    input alu_src1,
    input alu_src2,
    input branch,
    input u_alu_type,
    //input mul_high,
    input U_type_1,
    input J_type_1,
    input [3:0] alu_crtl,
    output reg [31:0] alu_out,
    output reg zero
);
`define ysyx_24070003_OP_ADD         4'b0000 // +
`define ysyx_24070003_OP_SUB         4'b0001 // -
`define ysyx_24070003_OP_SLL         4'b0010 // <<
`define ysyx_24070003_OP_BLT         4'b0011 // <
`define ysyx_24070003_OP_XOR         4'b0100 // ^
`define ysyx_24070003_OP_SRL         4'b0101 // >>
`define ysyx_24070003_OP_SRA         4'b0110 // >>>
`define ysyx_24070003_OP_OR          4'b0111 // |
`define ysyx_24070003_OP_AND         4'b1000 // &
`define ysyx_24070003_OP_BGE         4'b1001 // >=
`define ysyx_24070003_OP_BNE         4'b1010 // !=
`define ysyx_24070003_OP_BEQ         4'b1011 // ==

    wire [31:0] a;
    wire [31:0] b;
    assign a = (alu_src1)? rs1_data : (U_type_1) ? 32'h00000000 : pc_data;
    assign b = (alu_src2)? rs2_data : (J_type_1) ? 32'h00000004 : imm_data;
    wire signed [31:0] signed_a = $signed(a);
    wire signed [31:0] signed_b = $signed(b);
    wire unsigned [31:0] unsigned_a = a;
    wire unsigned [31:0] unsigned_b = b;
    wire [31:0] opdata1;
    wire [31:0] opdata2;
    assign opdata1 = (u_alu_type)? unsigned_a : signed_a;
    assign opdata2 = (u_alu_type)? unsigned_b : signed_b;
    wire chocie;
    wire [31:0] sum;
    ysyx_24070003_add my_add(
        .a                (opdata1),
        .b                (opdata2),
        .b_n              (~opdata2),
        .chocie           (chocie),
        .sum              (sum)
    );
    //assign chocie = (alu_crtl == `ysyx_24070003_OP_SUB || alu_crtl == )

    always @(*) begin
        case (alu_crtl)
            `ysyx_24070003_OP_ADD: begin
                    alu_out = opdata1 + opdata2;
                    zero = 1'b0;
                end
            `ysyx_24070003_OP_SUB: begin
                    alu_out = opdata1 - opdata2;
                    zero = 1'b0;
                end
            `ysyx_24070003_OP_SLL: begin
                    alu_out = opdata1 << opdata2[4:0];
                    zero = 1'b0;
                end
            `ysyx_24070003_OP_BLT: begin
                if(branch)
                    if(u_alu_type) begin
                        if(rs1_data < rs2_data)begin
                            alu_out = pc_data + imm_data;
                            zero = 1'b1;
                        end
                        else begin
                            alu_out = pc_data + 32'h4;
                            zero = 1'b0;
                        end
                    end
                    else begin
                        if($signed(rs1_data) < $signed(rs2_data))begin
                            alu_out = pc_data + imm_data;
                            zero = 1'b1;
                        end
                        else begin
                            alu_out = pc_data + 32'h4;
                            zero = 1'b0;
                        end
                    end
                else begin
                    if(u_alu_type) begin
                        alu_out = (opdata1 < opdata2) ? 1 : 0;
                        zero = 1'b0;
                    end
                    else begin
                        alu_out = ($signed(opdata1) < $signed(opdata2)) ? 1 : 0;
                        zero = 1'b0;
                    end
                end
            end
            `ysyx_24070003_OP_XOR: begin
                    alu_out = opdata1 ^ opdata2;
                    zero = 1'b0;
                end 
            `ysyx_24070003_OP_SRL: begin
                    alu_out = opdata1 >> opdata2[4:0];
                    zero = 1'b0;
            end
            `ysyx_24070003_OP_SRA: begin 
                    alu_out = $signed(opdata1) >>> opdata2[4:0];
                    zero = 1'b0;
            end
            `ysyx_24070003_OP_OR: begin 
                    alu_out = opdata1 | opdata2;
                    zero = 1'b0;
            end
            `ysyx_24070003_OP_AND: begin
                    alu_out = opdata1 & opdata2;
                    zero = 1'b0;
            end
            `ysyx_24070003_OP_BGE:
                if(branch)begin
                    if(u_alu_type) begin
                        if(rs1_data >= rs2_data)begin
                            alu_out = pc_data + imm_data;
                            zero = 1'b1;
                        end
                        else begin
                            alu_out = pc_data + 32'h4;
                            zero = 1'b0;
                        end
                    end
                    else begin
                        if($signed(rs1_data) >= $signed(rs2_data))begin
                            alu_out = pc_data + imm_data;
                            zero = 1'b1;
                        end
                        else begin
                            alu_out = pc_data + 32'h4;
                            zero = 1'b0;
                        end
                    end
                end
                else begin
                    alu_out = (opdata1 >= opdata2) ? 1 : 0;
                    zero = 1'b0;
                end
            `ysyx_24070003_OP_BNE: 
                if(branch)
                    if(rs1_data != rs2_data)begin
                        alu_out = pc_data + imm_data;
                        zero = 1'b1;
                    end
                    else begin
                        alu_out = pc_data + 32'h4;
                        zero = 1'b0;
                    end
                else begin
                    alu_out = (opdata1 != opdata2) ? 1 : 0;
                    zero = 1'b0;
                end
            `ysyx_24070003_OP_BEQ: 
                if(branch)
                    if(rs1_data == rs2_data)begin
                        alu_out = pc_data + imm_data;
                        zero = 1'b1;
                    end
                    else begin
                        alu_out = pc_data + 32'h4;
                        zero = 1'b0;
                    end
                else begin
                    alu_out = (opdata1 == opdata2) ? 1 : 0;
                    zero = 1'b0;
                end
            default: begin
                    alu_out = 32'b0;
                    zero = 1'b0;
                end
        endcase
        
    end
endmodule



module ysyx_24070003_add(
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] b_n,
    input         chocie,
    output [31:0] sum
);

wire [31:0] add_b;

assign add_b = chocie? b : b_n;

assign sum = a + add_b;

endmodule

