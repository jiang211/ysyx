module apb_delayer(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

  assign out_paddr   = in_paddr;
  assign out_psel    = in_psel && (state != DELAY);
  assign out_penable = in_penable && (state != DELAY);
  assign out_pprot   = in_pprot;
  assign out_pwrite  = in_pwrite;
  assign out_pwdata  = in_pwdata;
  assign out_pstrb   = in_pstrb;
  //assign in_pready   = out_pready;
  // assign in_prdata   = out_prdata;
  // assign in_pslverr  = out_pslverr;

  /////////////////////////////  fmax = 630   r = 630 s = 32  (6.3-1) * 32 ////////////
  //localparam DELAY_COUNT = 169;
  localparam DELAY_COUNT = 32;
  reg [31:0] count;
  reg [1:0] state;
  parameter IDLE = 2'b00, WAIT = 2'b01, DELAY = 2'b10;
  always @(posedge clock) begin
    if(reset) begin
      count <= 0;
      state <= IDLE;
    end
    else begin
      case(state)
        IDLE: begin
          if(in_psel) begin
            state <= WAIT;
            count <= count + DELAY_COUNT;
          end
        end
        WAIT: begin
          if(out_pready) begin
            state <= DELAY;
            count <= (count + DELAY_COUNT) >> 5;
          end
          else begin
            count <= count + DELAY_COUNT;
          end
        end
        DELAY: begin
          if(count == 1) begin
            state <= IDLE;
            count <= 0;
          end
          else begin
            count <= count - 1;
          end
        end
        default : state <= IDLE;
      endcase
    end
  end
  reg [31:0] rdata_cache;
  reg        slver_cache;
  always @(posedge clock) begin
    if(reset) begin
      rdata_cache <= 32'b0;
      slver_cache <= 1'b0;
    end else if(out_pready) begin
      rdata_cache <= out_prdata;
      slver_cache <= out_pslverr;
    end
  end

  assign in_pready = (state == DELAY && count == 32'd1);
  assign in_prdata = (state == DELAY && count == 32'd1) ? rdata_cache : 32'b0;
  assign in_pslverr = (state == DELAY && count == 32'd1) ? slver_cache : 1'b0;
endmodule
