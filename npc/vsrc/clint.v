module clint #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input CLK,
    input rstn,
    //input wen,
    //input ren,
    //input [ADDR_WIDTH-1:0] addr,
    //input [3:0] wlen,
    //input [DATA_WIDTH-1:0] data,
    //output reg [DATA_WIDTH-1:0] Q,


    // AXI-Lite4 Read Address Channel
    input [ADDR_WIDTH-1:0] AXI4_CLINT_ARADDR,
    input                  AXI4_CLINT_ARVALID,
    output reg             AXI4_CLINT_ARREADY,
    
    // AXI-Lite4 Read Data Channel
    output reg [DATA_WIDTH-1:0] AXI4_CLINT_RDATA,
    output reg                  AXI4_CLINT_RVALID,
    input                       AXI4_CLINT_RREADY
    //output reg [1:0]       AXI4_SRAM_BRESP 
);
    //reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];


//import "DPI-C" function void vpmem_read(input int raddr,input byte ren,output int rdata);
//import "DPI-C" function void vpmem_write(input int waddr, input byte wmask,input int wdata,input byte wen);

reg [63:0] mtime;
always @(posedge CLK) begin
    if (rstn) begin
        mtime <= 64'b0;
    end else begin
        mtime <= mtime + 64'b1;
    end
end
wire [31:0] rdata_low = mtime[31:0];
wire [31:0] rdata_high = mtime[63:32];
wire [31:0] rdata;
assign rdata = (read_addr_reg == 32'ha0000048) ? rdata_low : (read_addr_reg == 32'ha000004c) ? rdata_high : 32'b0;
localparam RIDLE        = 2'b00;
localparam READ_DATA  = 2'b01;
localparam READ_WAIT   = 2'b10;


reg [1:0] state_read, state_write;
reg [ADDR_WIDTH-1:0] read_addr_reg;

// DPI-C interface for instruction read
//import "DPI-C" function void vpmem_read(input int raddr, output int rdata);

// State machine
always @(posedge CLK) begin
    if (rstn) begin
        state_read <= RIDLE;
        AXI4_CLINT_ARREADY <= 1'b0;
        AXI4_CLINT_RVALID <= 1'b0;
        
        read_addr_reg <= 'b0;
    end
    else begin
        case (state_read)
            RIDLE: begin
                AXI4_CLINT_ARREADY <= 1'b1;
                if (AXI4_CLINT_ARVALID) begin
                    // Latch read address
                    read_addr_reg <= AXI4_CLINT_ARADDR;
                    AXI4_CLINT_ARREADY <= 1'b0;
                    state_read <= READ_DATA;
                end
            end
            
            READ_DATA: begin
                // Perform read operation using DPI-C
                //vpmem_read(read_addr_reg, {7'b0, 1'b1}, AXI4_CLINT_RDATA);
                AXI4_CLINT_RDATA <= rdata;
                AXI4_CLINT_RVALID <= 1'b1;
                state_read <= READ_WAIT;
            end
            
            READ_WAIT: begin
                if (AXI4_CLINT_RREADY) begin
                    AXI4_CLINT_RVALID <= 1'b0;
                    state_read <= RIDLE;
                end
            end
            
            default: state_read <= RIDLE;
        endcase
    end
end
/*
reg [31:0] write_addr_reg, write_data;
reg [3:0] wirte_wstrb;
always @(posedge CLK) begin
    if (rstn) begin
        state_write <= WIDLE;
        AXI4_CLINT_AWREADY <= 1'b0;
        AXI4_CLINT_WREADY <= 1'b0;
        AXI4_CLINT_BVALID <= 1'b0;
        //LSU_AXI4_BRESP <= 2'b0;
        write_addr_reg <= 'b0;
        write_data <= 'b0;
        wirte_wstrb <= 'b0;
    end
    else begin
        case (state_write)
            WIDLE: begin
                AXI4_CLINT_AWREADY <= 1'b1;
                AXI4_CLINT_WREADY <= 1'b1;
                //LSU_AXI4_BRESP <= 2'b0;
                AXI4_CLINT_BVALID <= 1'b0;
                if (AXI4_CLINT_AWVALID && AXI4_CLINT_WVALID) begin
                    // Latch read address
                    write_addr_reg <= AXI4_CLINT_AWADDR;
                    write_data <= AXI4_CLINT_WDATA;
                    wirte_wstrb <= AXI4_CLINT_WSTRB;
                    AXI4_CLINT_AWREADY <= 1'b0;
                    AXI4_CLINT_WREADY <= 1'b0;
                    state_write <= WRITE_DATA;
                end

                else if (AXI4_CLINT_AWVALID ) begin
                    // Latch read address
                    write_addr_reg <= AXI4_CLINT_AWADDR;
                    AXI4_CLINT_AWREADY <= 1'b0;
                    state_write <= WRITE_WAIT_1;
                end

                else if (AXI4_CLINT_WVALID ) begin
                    // Latch read address
                    write_data <= AXI4_CLINT_WDATA;
                    wirte_wstrb <= AXI4_CLINT_WSTRB;
                    AXI4_CLINT_WREADY <= 1'b0;
                    state_write <= WRITE_WAIT_2;
                end
            end
            
            WRITE_WAIT_1: begin
                if (AXI4_CLINT_WVALID ) begin
                    // Latch read address
                    write_data <= AXI4_CLINT_WDATA;
                    wirte_wstrb <= AXI4_CLINT_WSTRB;
                    AXI4_CLINT_WREADY <= 1'b0;
                    state_write <= WRITE_DATA;
                end
            end
            
            WRITE_WAIT_2: begin
                if (AXI4_CLINT_AWVALID ) begin
                    // Latch read address
                    write_addr_reg <= AXI4_CLINT_ARADDR;
                    AXI4_CLINT_AWREADY <= 1'b0;
                    state_write <= WRITE_DATA;
                end
            end
            
            WRITE_DATA: begin
                AXI4_CLINT_BVALID <= 1'b1;
                vpmem_write(write_addr_reg, {4'b0, wirte_wstrb},write_data,{7'b0, 1'b1});
                
                if(AXI4_CLINT_BVALID && AXI4_CLINT_BREADY) begin
                    AXI4_CLINT_BVALID <= 1'b0;
                    state_write <= WIDLE;
                end
            end
            default: state_write <= WIDLE;
        endcase
    end
end

*/

endmodule
