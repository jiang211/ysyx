module ifu(
    input clk,
    input rstn,
    input d_en,
    output reg[31:0] pc,
    input [31:0]dnpc_d,
    output [31:0] dnpc,
    output [31:0] inst_addr_o
);

assign dnpc = (d_en)? dnpc_d : pc + 32'h4;
assign inst_addr_o = pc;
reg den_1;
wire pos_den;
always@(posedge clk)
begin 
   if(!rstn)begin
    den_1<='b0;
    end
    else begin
    den_1<=d_en;
    end
end
assign pos_den = (~d_en) & den_1;
always@(posedge clk)
begin 
   if(!rstn)begin
    pc<=32'h80000000 - 32'h4;
    end
    else if(pos_den)begin
    pc<=dnpc;
    end
    else begin
    pc<=pc+32'h4;
    end
end

endmodule
