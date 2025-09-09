module ram(
   input clk,
   input rst,
   
//read
   input  [31:0]araddr,
   input  [7:0]arlen,
   input  [2:0]arsize,
   input  [1:0]arburst,
   input  arvalid,
   output  arready,

   output [31:0]rdata,
   output reg [1:0]rresp,
   output  rlast,
   output reg rvalid,
   input  rready,

//write
   input [31:0]awaddr,
   input [7:0]awlen,
   input [2:0]awsize,
   input [1:0]awburst,
   input awvalid,
   output awready,

   input [31:0]wdata,
   input [ 3:0]wstrb,
   input wlast,
   input wvalid,
   output reg wready,

   output [1:0]bresp,
   output bvalid,
   input bready
   
);
// ==========================================================
//  行为级存储本体，仅仿真用
// ==========================================================
reg [31:0] mem [0:1024*1024*4-1];   // 16 MB，按 32-bit word 寻址
reg rst_q;
always @(posedge clk) rst_q <= rst;

wire rst_negedge = rst_q & ~rst;   // 复位释放沿


wire [31:0] data21 = mem[32'h21];
wire [31:0] data22 = mem[32'h22];
wire [31:0] data23 = mem[32'h23];
wire [31:0] data24 = mem[32'h24];
wire [31:0] data25 = mem[32'h25];
wire [31:0] data26 = mem[32'h26];
wire [31:0] data27 = mem[32'h27];
wire [31:0] data28 = mem[32'h28];
wire [31:0] data29 = mem[32'h29];
wire [31:0] data2a = mem[32'h2a];
wire [31:0] data2b = mem[32'h2b];
wire [31:0] data2c = mem[32'h2c];
wire [31:0] data2d = mem[32'h2d];
wire [31:0] data2e = mem[32'h2e];
wire [31:0] data2f = mem[32'h2f];
wire [31:0] data30 = mem[32'h30];
wire [31:0] data31 = mem[32'h31];
wire [31:0] data32 = mem[32'h32];
wire [31:0] data33 = mem[32'h33];
wire [31:0] data34 = mem[32'h34];
wire [31:0] data35 = mem[32'h35];
wire [31:0] data36 = mem[32'h36];
wire [31:0] data37 = mem[32'h37];
wire [31:0] data38 = mem[32'h38];
wire [31:0] data39 = mem[32'h39];
wire [31:0] data3a = mem[32'h3a];
wire [31:0] data3b = mem[32'h3b];
wire [31:0] data3c = mem[32'h3c];
wire [31:0] data3d = mem[32'h3d];
wire [31:0] data3e = mem[32'h3e];
wire [31:0] data3f = mem[32'h3f];
wire [31:0] data40 = mem[32'h40];
wire [31:0] data41 = mem[32'h41];
wire [31:0] data42 = mem[32'h42];
wire [31:0] data43 = mem[32'h43];
wire [31:0] data44 = mem[32'h44];
wire [31:0] data45 = mem[32'h45];
wire [31:0] data46 = mem[32'h46];
wire [31:0] data47 = mem[32'h47];
wire [31:0] data48 = mem[32'h48];
wire [31:0] data49 = mem[32'h49];
wire [31:0] data4a = mem[32'h4a];
wire [31:0] data4b = mem[32'h4b];
wire [31:0] data4c = mem[32'h4c];
wire [31:0] data4d = mem[32'h4d];
wire [31:0] data4e = mem[32'h4e];
wire [31:0] data4f = mem[32'h4f];
wire [31:0] data50 = mem[32'h50];
wire [31:0] data51 = mem[32'h51];
wire [31:0] data52 = mem[32'h52];
wire [31:0] data53 = mem[32'h53];
wire [31:0] data54 = mem[32'h54];
wire [31:0] data55 = mem[32'h55];
wire [31:0] data56 = mem[32'h56];
wire [31:0] data57 = mem[32'h57];
wire [31:0] data58 = mem[32'h58];
wire [31:0] data59 = mem[32'h59];
wire [31:0] data5a = mem[32'h5a];
initial rst_q = 1;
// 上电装载镜像
always @(posedge clk) begin
    if (rst) begin
        // 1. 复位期清零（可选，仿真可省）
        integer k;
        for (k = 0; k < 1024 * 1024 * 4; k = k + 1)
            mem[k] <= 32'h0;
    end
    else if (rst_negedge) begin
        // 2. 复位一结束就重新装镜像
        $readmemh("ram.hex", mem);
        $display("=== $readmemh loaded after rst ===");

		
        $display("mem[0] = %08x", mem[0]);
    end
end
// 辅助：字节地址 -> word 索引
function [31:0] addr2w;
input [31:0] a;
begin
    addr2w = (a - 32'h80000000) >> 2;
end
endfunction

//************** read  *******************
reg [1:0]read_current_state, read_next_state;

localparam read_idle       = 2'b00;        //waiting for arvalid
localparam read_send_rdata = 2'b01;        //sending read data after read address handshake
//localparam read_last_send  = 2'b11;        //sending the last data and 'rlast'

reg [31:0]r_addr;
reg  [7:0]r_len;
reg  [2:0]r_size;
reg  [1:0]r_burst;
reg  [7:0]r_count;

always @(posedge clk) begin
	if(rst == 1'b1) read_current_state <= read_idle;
	else            read_current_state <= read_next_state;

	if(arvalid&&arready&&(read_current_state==read_idle)) begin
		r_addr  <= araddr;
		r_len   <= arlen;
		r_size  <= arsize;
		r_burst <= arburst;

		r_count <= 8'b0;
	end
	else if(read_current_state == read_send_rdata) begin
        r_addr <= r_addr + 4'h4;
		r_count <= r_count + 8'h1;
	end
end

reg [63:0]r_data;
wire [31:0] a = addr2w(r_addr);
assign rdata = {mem[addr2w(r_addr)][7:0], mem[addr2w(r_addr)][15:8], mem[addr2w(r_addr)][23:16], mem[addr2w(r_addr)][31:24]};
assign arready = read_current_state == read_idle;
assign rlast  = (r_count == r_len) && (read_current_state == read_send_rdata);


always @(*) begin
	case(read_current_state)
		read_idle: begin
			rvalid = 1'b0;
			rresp  = 2'b0;
			read_next_state = (arvalid == 1'b1)? read_send_rdata : read_idle;
		end
		read_send_rdata: begin
			rvalid = 1'b1;
			rresp  = 2'b0;
			read_next_state = (r_count == r_len) ? read_idle : read_send_rdata;
		end
		default: begin
			rvalid = 1'b0;
			rresp  = 2'b0;
			read_next_state = read_idle;
		end
	endcase
end





//************** write *******************
reg [1:0]write_current_state, write_next_state;

localparam write_idle  = 2'b00;
localparam write_receive_wdata = 2'b01;        //receive wdata and write it to memory
localparam write_w_rsp = 2'b11;                //write respone

reg [31:0]w_addr;
reg  [7:0]w_len;
reg  [2:0]w_size;
reg  [1:0]w_burst;
reg  [7:0]w_count;

always @(posedge clk) begin
	if(rst == 1'b1) write_current_state <= write_idle;
	else            write_current_state <= write_next_state;

	if(awvalid&&awready&&(write_current_state==write_idle)) begin
		w_addr  <= awaddr;
		w_len   <= awlen;
		w_size  <= awsize;
		w_burst <= awburst;

		w_count <= 8'b0;
	end
	else if(write_current_state == write_receive_wdata) begin
		w_count <= w_count + 8'h1;
	end
end


always @(posedge clk) begin
	if(rst == 1'b1) write_current_state <= write_idle;
	else            write_current_state <= write_next_state;


end

assign awready = write_current_state==write_idle;
assign bresp   = 2'b0;
assign bvalid  = write_current_state==write_w_rsp;

always @(*) begin
	case(write_current_state)
		write_idle: begin
			wready  = 1'b0;
			write_next_state = (awvalid && awready) ? write_receive_wdata : write_idle;
		end
		write_receive_wdata: begin
			wready  = 1'b1;
			write_next_state = (w_count == w_len) ? write_w_rsp : write_receive_wdata;
		end
		write_w_rsp: begin
			wready  = 1'b0;
			write_next_state = write_idle;
		end
		default: begin
			wready  = 1'b0;
			write_next_state = write_idle;
		end
	endcase
end
reg [31:0] w_data_cache;
integer byte_idx;
always @(posedge clk) begin
    if (wvalid && wready) begin
        if(w_addr != 32'ha00003f8)begin
            if(wstrb[0]) mem[addr2w(w_addr)][7:0] <= wdata[31:24];
            if(wstrb[1]) mem[addr2w(w_addr)][15:8] <= wdata[23:16];
            if(wstrb[2]) mem[addr2w(w_addr)][23:16] <= wdata[15:8];
            if(wstrb[3]) mem[addr2w(w_addr)][31:24] <= wdata[7:0];
        end
        else begin
            $write("%c",wdata[7:0]);
        end
    end
end


endmodule