module sram_inst #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input CLK,
    input wen,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] Q
);
    //reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];


    import "DPI-C" function void vpmem_read(input int raddr,input byte ren,output int rdata);

    /*always @(posedge CLK) begin
        if (wen) begin
            mem[addr] <= data;
        end
    end*/

    always @(posedge CLK) begin
        if (~wen) begin
            //Q <= mem[addr];
            vpmem_read(addr,{7'b0, 1'b1},Q);
        end
        $display("Time=%0t addr=%h instr=%h", $time, addr, Q);
    end

endmodule
