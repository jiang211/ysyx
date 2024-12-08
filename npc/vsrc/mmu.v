module mmu(
    input           lw,
    input           lh,
    input           lb,
    input           lbu,
    input           lhu,
    input           sw,
    input           sb,
    input           sh,
    input    [31:0] alu_result,
    input    [31:0] rs2_data,
    output   [31:0] rdata,
    output   [3:0] wlen,
    input    [31:0] rdata_in,    
    output   [31:0] wdata,
    output   [31:0] addr
);
    assign wdata = ( {32{sb}} & {24'b0,rs2_data[7:0]}) |
                   ( {32{sh}} & {16'b0,rs2_data[15:0]}) |
                   ( {32{sw}} & rs2_data);

    assign rdata = ( {32{lb}} & {{24{rdata_in[7]}},rdata_in[7:0]}) |
                   ( {32{lh}} & {{16{$signed(rdata_in[31])}}, $signed(rdata_in[15:0])}) |
                   ( {32{lw}} & rdata_in) |
                   ( {32{lbu}} & {24'b0,rdata_in[7:0]}) |
                   ( {32{lhu}} & {16'b0,rdata_in[15:0]});

    assign  wlen = ( {4{sb}} & 4'd1 )  |
                   ( {4{sh}} & 4'd2 )  |
                   ( {4{sw}} & 4'd4 ) ;
    
    always @(*) begin
    $display("Value of signal rdata_in is %032b", rdata_in);
    $display("Value of signal rdata_in is %032b", $signed(rdata_in));
    $display("Value of signal data is %032b", {{16{$signed(rdata_in[31])}}, $signed(rdata_in[15:0])});
    end
    
    assign addr = alu_result;

endmodule
