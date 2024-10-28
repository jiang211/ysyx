module PC(
    input clk,
    input rstn,
    input pcsrc,
    input [31:0] alu_out,
    output reg[31:0] dnpc,
    output [31:0] inst_addr_o
);
reg [31:0] pc;
always @(pc) begin
    case(pcsrc)
        1'b0: dnpc <= pc + 32'h4;
        1'b1: dnpc <= alu_out;
        default: dnpc <= pc + 32'h4;
    endcase
end

assign inst_addr_o = pc;

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

