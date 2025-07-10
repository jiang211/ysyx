module sram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input CLK,
    input wen,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data,
    output reg [DATA_WIDTH-1:0] Q
);
    reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];


    import "DPI-C" function void vpmem_read(input int raddr,input byte ren,output int rdata);
    import "DPI-C" function void vpmem_write(input int waddr, input byte wmask,input int wdata,input byte wen);
    
    always@(posedge CLK)
    begin 
        clk_reg <= clk;
    end
  
    assign clk_neg = ~CLK & clk_reg;

    always @(posedge CLK) begin
        if (wen) begin
            mem[addr] <= data;
        end
    end

    always @(posedge CLK) begin
        if (~wen) begin
            //Q <= mem[addr];
            vpmem_read(addr,{7'b0, 1'b1},Q);
        end
    end

endmodule