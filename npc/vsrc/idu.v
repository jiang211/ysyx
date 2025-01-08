module idu(
    input lw,
    input lh,
    input lb,
    input lbu,
    input lhu,
    input [31:0]alu_out,
    input I_type_3,
    input [31:0]rdata,
    output [31:0] wdata_in
);

wire [31:0]r_data;
wire unsigned [15:0] udata1 = rdata[15:0];
wire unsigned [7:0] udata2 = rdata[7:0];
assign r_data = ( {32{lbu}} & { {24'b0} , rdata[ 7:0] } ) |
                     ( {32{lh}} & { {16'b0} , rdata[15:0] } ) |
                     ( {32{lb}} & { {24'b0} , udata2 } ) |
                     ( {32{lhu}} & { {16'b0} , udata1} ) |
                     ( {32{lw}} & rdata[31:0] ) ;
assign wdata_in = (I_type_3) ? r_data : alu_out;
endmodule
