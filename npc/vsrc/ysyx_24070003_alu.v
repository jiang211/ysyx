module ysyx_24070003_alu(
    input clock,
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
    output  zero
);
`define ysyx_24070003_OP_ADD         4'b0001 // +
`define ysyx_24070003_OP_SUB         4'b0011 // -

`define ysyx_24070003_OP_AND         4'b0100 // &
`define ysyx_24070003_OP_OR          4'b0101 // |
`define ysyx_24070003_OP_XOR         4'b0110 // ^

`define ysyx_24070003_OP_SLL         4'b1100 // <<
`define ysyx_24070003_OP_SRL         4'b1101 // >>
`define ysyx_24070003_OP_SRA         4'b1110 // >>>

`define ysyx_24070003_OP_BLT         4'b1000 // <
`define ysyx_24070003_OP_BGE         4'b1001 // >=
`define ysyx_24070003_OP_BNE         4'b1010 // !=
`define ysyx_24070003_OP_BEQ         4'b1011 // ==
wire [31:0] opdata1;
wire [31:0] opdata2;
assign opdata1 = (alu_src1)? rs1_data : (U_type_1) ? 32'h00000000 : pc_data;
assign opdata2 = (alu_src2)? rs2_data : (J_type_1) ? 32'h00000004 : imm_data;

wire [1:0] logic_ctl;
wire [1:0] shift_ctl;
wire       sub_ctl;
wire [1:0] data_choice;
wire SIGctr;
wire Ovctr;
wire ADD_zero;

assign logic_ctl = alu_crtl[1:0];
assign shift_ctl = alu_crtl[1:0];
assign data_choice = alu_crtl[3:2];
assign sub_ctl = (~ alu_crtl[3]  & ~alu_crtl[2]  & alu_crtl[1]) | ( alu_crtl[3]  & ~alu_crtl[2]);
//*********************logic op***************************
reg [31:0] logic_result;

always@(*) begin
    case(logic_ctl)
	2'b00:logic_result = opdata1 & opdata2;
	2'b01:logic_result = opdata1 | opdata2;
	2'b10:logic_result = opdata1 ^ opdata2;
    2'b11:logic_result = ~(opdata1 | opdata2);
	endcase
end 
//************************shift op************************
wire [5:0]     ALU_SHIFT;
wire [31:0] shift_result;
assign ALU_SHIFT=opdata2[5:0];

Shifter myShifter(.ALU_DA(opdata1),
                .ALU_SHIFT(ALU_SHIFT),
				.Shiftctr(shift_ctl),
				.shift_result(shift_result));

//************************add sub op**********************
wire [31:0] BIT_M,XOR_M;
wire ADD_carry,ADD_OverFlow;
wire [31:0] ADD_result;

assign BIT_M={32{sub_ctl}};
assign XOR_M=BIT_M^opdata2;

Adder Adder(.A(opdata1),
            .B(XOR_M),
			.Cin(sub_ctl),
			.ALU_CTL(alu_crtl),
			.ADD_carry(ADD_carry),
			.ADD_OverFlow(ADD_OverFlow),
			.ADD_zero(ADD_zero),
			.ADD_result(ADD_result));

//assign ALU_OverFlow = ADD_OverFlow & Ovctr;

//********************************************************
//**************************slt op************************
wire [31:0] SLT_result;
wire LESS_M1,LESS_M2,LESS_S,SLT_M;
wire BLT,BGE,BNE,BEQ;

assign BLT = (alu_crtl[3]  & ~alu_crtl[2]  &  ~alu_crtl[1]  & ~alu_crtl[0]);
assign BGE = (alu_crtl[3]  & ~alu_crtl[2]  &  ~alu_crtl[1]  &  alu_crtl[0]);
assign BNE = (alu_crtl[3]  & ~alu_crtl[2]  &   alu_crtl[1]  & ~alu_crtl[0]);
assign BEQ = (alu_crtl[3]  & ~alu_crtl[2]  &   alu_crtl[1]  &  alu_crtl[0]);
assign zero = (BLT & & branch  &  LESS_S)   |
              (BGE & ~LESS_S)   |
              (BNE & ~ADD_zero) |
              (BEQ &  ADD_zero) ;

assign LESS_M1 = ADD_carry ^ sub_ctl;
assign LESS_M2 = ADD_OverFlow ^ ADD_result[31];
assign LESS_S = (u_alu_type)?LESS_M1:LESS_M2;
assign SLT_result = (LESS_S)?32'h00000001:32'h00000000;

always @(*) 
begin
  case(data_choice)
     2'b00:alu_out=ADD_result;
     2'b01:alu_out=logic_result;
     2'b10:alu_out=SLT_result;
     2'b11:alu_out=shift_result; 
  endcase
end
 
endmodule

module Shifter(input [31:0] ALU_DA,
               input [5:0] ALU_SHIFT,
			   input [1:0] Shiftctr,
			   output reg [31:0] shift_result);
			
     wire [63:0] tmp_res;
     always@(*) begin
	   case(Shiftctr)
	   2'b00:shift_result = ALU_DA << ALU_SHIFT[4:0];
	   2'b01:shift_result = ALU_DA >> ALU_SHIFT[4:0];
	   2'b10:shift_result = tmp_res[31:0];
	   default:shift_result = ALU_DA;
	   endcase
	 end
assign tmp_res = {{{32{ALU_DA[31]}}, ALU_DA} >> ALU_SHIFT};

endmodule

//*************************************************************
//***********************************adder*********************

//`define ALGORITHM
module Adder(input [31:0] A,
             input [31:0] B,
			 input Cin,
			 input [3:0] ALU_CTL,
			 output ADD_carry,
			 output ADD_OverFlow,
			 output ADD_zero,
			 output [31:0] ADD_result);


    assign {ADD_carry,ADD_result}=A+B+Cin;


   assign ADD_zero = ~(|ADD_result);
   assign ADD_OverFlow=((ALU_CTL==4'b0001) & ~A[31] & ~B[31] & ADD_result[31]) 
                      | ((ALU_CTL==4'b0001) & A[31] & B[31] & ~ADD_result[31])
                      | ((ALU_CTL==4'b0011) & A[31] & ~B[31] & ~ADD_result[31]) 
					  | ((ALU_CTL==4'b0011) & ~A[31] & B[31] & ADD_result[31]);
endmodule



// module ysyx_24070003_alu(
//     input clock,
//     input [31:0] rs1_data,
//     input [31:0] rs2_data,
//     input [31:0] imm_data,
//     input [31:0] pc_data,
//     input alu_src1,
//     input alu_src2,
//     input branch,
//     input u_alu_type,
//     //input mul_high,
//     input U_type_1,
//     input J_type_1,
//     input [3:0] alu_crtl,
//     output reg [31:0] alu_out,
//     output reg zero
// );
// `define ysyx_24070003_OP_ADD         4'b0001 // +
// `define ysyx_24070003_OP_SUB         4'b0011 // -

// `define ysyx_24070003_OP_AND         4'b0100 // &
// `define ysyx_24070003_OP_OR          4'b0101 // |
// `define ysyx_24070003_OP_XOR         4'b0110 // ^

// `define ysyx_24070003_OP_SLL         4'b1100 // <<
// `define ysyx_24070003_OP_SRL         4'b1101 // >>
// `define ysyx_24070003_OP_SRA         4'b1110 // >>>

// `define ysyx_24070003_OP_BLT         4'b1000 // <
// `define ysyx_24070003_OP_BGE         4'b1001 // >=
// `define ysyx_24070003_OP_BNE         4'b1010 // !=
// `define ysyx_24070003_OP_BEQ         4'b1011 // ==

//     wire [31:0] a;
//     wire [31:0] b;
//     assign a = (alu_src1)? rs1_data : (U_type_1) ? 32'h00000000 : pc_data;
//     assign b = (alu_src2)? rs2_data : (J_type_1) ? 32'h00000004 : imm_data;
//     wire signed [31:0] signed_a = $signed(a);
//     wire signed [31:0] signed_b = $signed(b);
//     wire unsigned [31:0] unsigned_a = a;
//     wire unsigned [31:0] unsigned_b = b;
//     wire [31:0] opdata1;
//     wire [31:0] opdata2;
//     assign opdata1 = (u_alu_type)? unsigned_a : signed_a;
//     assign opdata2 = (u_alu_type)? unsigned_b : signed_b;

//     always @(*) begin
//         alu_out = 32'b0;
//         zero = 1'b0;
//         case (alu_crtl)
//             `ysyx_24070003_OP_ADD: begin
//                     alu_out = opdata1 + opdata2;
//                 end
//             `ysyx_24070003_OP_SUB: begin
//                     alu_out = opdata1 - opdata2;
//                 end
//             `ysyx_24070003_OP_SLL: begin
//                     alu_out = opdata1 << (opdata2 & 32'h0000001f);
//                 end
//             `ysyx_24070003_OP_BLT: begin
//                 if(branch)
//                     if(u_alu_type) begin
//                         if(rs1_data < rs2_data)begin
//                             alu_out = pc_data + imm_data;
//                             zero = 1'b1;
//                         end
//                         else begin
//                             alu_out = pc_data + 32'h4;
//                         end
//                     end
//                     else begin
//                         if($signed(rs1_data) < $signed(rs2_data))begin
//                             alu_out = pc_data + imm_data;
//                             zero = 1'b1;
//                         end
//                         else begin
//                             alu_out = pc_data + 32'h4;
//                         end
//                     end
//                 else begin
//                     if(u_alu_type) begin
//                         alu_out = (opdata1 < opdata2) ? 1 : 0;
//                     end
//                     else begin
//                         alu_out = ($signed(opdata1) < $signed(opdata2)) ? 1 : 0;
//                     end
//                 end
//             end
//             `ysyx_24070003_OP_XOR: begin
//                     alu_out = opdata1 ^ opdata2;
//                 end 
//             `ysyx_24070003_OP_SRL: begin
//                     alu_out = opdata1 >> (opdata2 & 32'h0000001f);
//             end
//             `ysyx_24070003_OP_SRA: begin 
//                     alu_out = $signed(opdata1) >>> (opdata2 & 32'h0000001f);
//             end
//             `ysyx_24070003_OP_OR: begin 
//                     alu_out = opdata1 | opdata2;
//             end
//             `ysyx_24070003_OP_AND: begin
//                     alu_out = opdata1 & opdata2;
//             end
//             `ysyx_24070003_OP_BGE:
//                 if(branch)begin
//                     if(u_alu_type) begin
//                         if(rs1_data >= rs2_data)begin
//                             alu_out = pc_data + imm_data;
//                             zero = 1'b1;
//                         end
//                         else begin
//                             alu_out = pc_data + 32'h4;
//                         end
//                     end
//                     else begin
//                         if($signed(rs1_data) >= $signed(rs2_data))begin
//                             alu_out = pc_data + imm_data;
//                             zero = 1'b1;
//                         end
//                         else begin
//                             alu_out = pc_data + 32'h4;
//                         end
//                     end
//                 end
//                 else begin
//                     alu_out = (opdata1 >= opdata2) ? 1 : 0;
//                 end
//             `ysyx_24070003_OP_BNE: 
//                 if(branch)
//                     if(rs1_data != rs2_data)begin
//                         alu_out = pc_data + imm_data;
//                         zero = 1'b1;
//                     end
//                     else begin
//                         alu_out = pc_data + 32'h4;
//                     end
//                 else begin
//                     alu_out = (opdata1 != opdata2) ? 1 : 0;
//                 end
//             `ysyx_24070003_OP_BEQ: 
//                 if(branch)
//                     if(rs1_data == rs2_data)begin
//                         alu_out = pc_data + imm_data;
//                         zero = 1'b1;
//                     end
//                     else begin
//                         alu_out = pc_data + 32'h4;
//                     end
//                 else begin
//                     alu_out = (opdata1 == opdata2) ? 1 : 0;
//                 end
//             default: begin
//                     alu_out = 32'b0;
//                     zero = 1'b0;
//                 end
//         endcase
        
//     end
// endmodule




