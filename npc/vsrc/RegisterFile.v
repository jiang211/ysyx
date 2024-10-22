module RegisterFile #(
    parameter ADDR_WIDTH = 5,  
    parameter DATA_WIDTH = 32
) (
    input clk,
    input [DATA_WIDTH-1:0] wdata,
    input [ADDR_WIDTH-1:0] waddr,
    input wen,
    
    output [DATA_WIDTH-1:0] rdata1,
    
    input [ADDR_WIDTH-1:0] raddr1,
    
    output [DATA_WIDTH-1:0] rdata2,
    
    input [ADDR_WIDTH-1:0] raddr2
);

    reg [DATA_WIDTH-1:0] rf[31:0];
    import "DPI-C" function void set_gpr_ptr(input logic [31:0] a []);
    initial set_gpr_ptr(rf); 

    
    always @(posedge clk) begin
        if (wen & waddr != 0) rf[waddr] <= wdata; 
    end
    
    assign rdata1 = rf[raddr1];
    assign rdata2 = rf[raddr2];
/*
    wire[31:0] ra = rf[1];
    wire[31:0] sp = rf[2];
    wire[31:0] gp = rf[3];
    wire[31:0] tp = rf[4];
    wire[31:0] t0 = rf[5];
    wire[31:0] t1 = rf[6];
    wire[31:0] t2 = rf[7];
    wire[31:0] s0 = rf[8];
    wire[31:0] fp = rf[8];
    wire[31:0] s1 = rf[9];
    wire[31:0] a0 = rf[10];
    wire[31:0] a1 = rf[11];
    wire[31:0] a2 = rf[12];
    wire[31:0] a3 = rf[13];
    wire[31:0] a4 = rf[14];
    wire[31:0] a5 = rf[15];
    wire[31:0] a6 = rf[16];
    wire[31:0] a7 = rf[17];
    wire[31:0] s2 = rf[18];
    wire[31:0] s3 = rf[19];
    wire[31:0] s4 = rf[20];
    wire[31:0] s5 = rf[21];
    wire[31:0] s6 = rf[22];
    wire[31:0] s7 = rf[23];
    wire[31:0] s8 = rf[24];
    wire[31:0] s9 = rf[25];
    wire[31:0] s10 = rf[26];
    wire[31:0] s11 = rf[27];
    wire[31:0] t3 = rf[28];
    wire[31:0] t4 = rf[29];
    wire[31:0] t5 = rf[30];
    wire[31:0] t6 = rf[31];
*/
endmodule
