module axi4_delayer(
  input         clock,
  input         reset,

  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);

  assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  // assign out_rready = in_rready;
  // assign in_rvalid = out_rvalid;
  // assign in_rid = out_rid;
  // assign in_rdata = out_rdata;
  // assign in_rresp = out_rresp;
  // assign in_rlast = out_rlast;
  assign in_awready = out_awready;
  assign out_awvalid = in_awvalid;
  assign out_awid = in_awid;
  assign out_awaddr = in_awaddr;
  assign out_awlen = in_awlen;
  assign out_awsize = in_awsize;
  assign out_awburst = in_awburst;
  assign in_wready = out_wready;
  assign out_wvalid = in_wvalid;
  assign out_wdata = in_wdata;
  assign out_wstrb = in_wstrb;
  assign out_wlast = in_wlast;
  // assign out_bready = in_bready;
  // assign in_bvalid = out_bvalid;
  assign in_bid = out_bid;
  assign in_bresp = out_bresp;


typedef enum logic [2:0] {
    WRITE_IDLE,
    WRITE_WAIT,
    WRITE_DELAY
} state_w;

state_w state0;

typedef enum logic [2:0] {
    READ_IDLE,
    READ_WAIT,
    READ_DELAY
} state_r;

state_r state1;

 /////////////////////////////  fmax = 784   r = 7.8 s = 32  (7.8-1) * 32 = 217 ////////////

reg [31:0] write_count;
reg [31:0] read_count;
reg [31:0] rdata_cahce;
reg [1:0]   rresp_cahce;
reg [3:0]   rid_cahce;
reg         rlast_cahce;
reg         out_rvalid_reg;
reg         out_bvalid_reg;
  always @(posedge clock) begin
    if (reset) begin
        state0 <= WRITE_IDLE;
        write_count <= 0;
    end 
    else begin
        case (state0)
            WRITE_IDLE: begin
              if(in_awvalid | in_wvalid) begin
                write_count <= write_count + 32'd217;
                state0 <= WRITE_WAIT;
              end
            end
            WRITE_WAIT: begin
              if(out_bvalid) begin
                out_bvalid_reg <= out_bvalid;
                state0 <= WRITE_DELAY;
                write_count <= (write_count + 32'd217) >> 5;
              end
              else begin
                write_count <= write_count + 32'd217;
              end
            end
            WRITE_DELAY: begin
              if(write_count == 1) begin
                state0 <= WRITE_IDLE;
                write_count <= 0;
              end
              else begin
                write_count <= write_count - 1'b1;
              end
            end
          default: state0 <= WRITE_IDLE;
        endcase
    end
  end

  always @(posedge clock) begin
    if (reset) begin
        state1 <= READ_IDLE;
        read_count <= 0;
    end 
    else begin
        case (state1)
            READ_IDLE: begin
              if(in_arvalid | out_rvalid) begin
                read_count <= read_count + 32'd217;
                state1 <= READ_WAIT;
              end
            end
            READ_WAIT: begin
              if(out_rvalid) begin
                out_rvalid_reg <= out_rvalid;
                rdata_cahce <= out_rdata;
                rresp_cahce <= out_rresp;
                rid_cahce <= out_rid;
                rlast_cahce <= out_rlast;
                state1 <= READ_DELAY;
                read_count <= (read_count + 32'd217) >> 5;
              end
              else begin
                read_count <= read_count + 32'd217;
              end
            end
            READ_DELAY: begin
              if(read_count == 1) begin
                state1 <= READ_IDLE;
                read_count <= 0;
              end
              else begin
                read_count <= read_count - 1'b1;
              end
            end
          default: state1 <= READ_IDLE;
        endcase
    end
  end

  assign out_rready = in_rready & read_count == 1'b1;
  assign in_rvalid = out_rvalid_reg & read_count == 1'b1;
  assign in_rid = rid_cahce;
  assign in_rdata = rdata_cahce;
  assign in_rresp = rresp_cahce;
  assign in_rlast = rlast_cahce;
  assign out_bready = in_bready & write_count == 1'b1;
  assign in_bvalid = out_bvalid_reg & write_count == 1'b1;
endmodule
