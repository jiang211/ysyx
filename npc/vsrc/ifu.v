module ifu(
    input clk,
    input rstn,
    input d_en,
    input [31:0] pc_,
    output reg[31:0] pc,
    input [31:0]dnpc_d,
    output [31:0] dnpc
);

assign dnpc = (d_en)? dnpc_d : pc_ + 32'h4;

always@(posedge clk)
begin 
   if(!rstn)begin
    pc<=32'h80000000;
    end
    else begin
    pc<=dnpc;
    end
end

endmodule
