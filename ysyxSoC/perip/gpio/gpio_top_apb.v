module gpio_top_apb(
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

  output [15:0] gpio_out,
  input  [15:0] gpio_in,
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

  reg [31:0] slv_reg[3:0];
  wire ren,wen;
  wire [1:0] addr;
  assign in_pready = in_psel && in_penable;
  assign in_prdata = ren ? slv_reg[addr] : 32'b0;
  assign in_pslverr = 1'b0;
  
  assign wen = in_psel && in_penable && in_pwrite;
  assign ren = in_psel && in_penable && !in_pwrite;
  wire [2:0]  size =  (in_pstrb == 4'b0001) ? 1 :
                      (in_pstrb == 4'b0010) ? 1 :
                      (in_pstrb == 4'b0100) ? 1 :
                      (in_pstrb == 4'b1000) ? 1 :
                      (in_pstrb == 4'b0011) ? 2 :
                      (in_pstrb == 4'b1100) ? 2 :
                      (in_pstrb == 4'b1111) ? 4 : 4;

  assign addr = in_paddr[3:2];

  wire [7:0]  byte0 = (in_pstrb[0])          ? in_pwdata[7:0]   :
                      (in_pstrb[1] & size==1)? in_pwdata[15:8]  :
                      (in_pstrb[2] & size==1)? in_pwdata[23:16] :
                      (in_pstrb[3] & size==1)? in_pwdata[31:24] :
                      (in_pstrb[2] & size==2)? in_pwdata[23:16] :
                    in_pwdata[7:0];

  wire [7:0]  byte1 = (in_pstrb[1])          ? in_pwdata[15:8]  :
                      in_pwdata[31:24];

  wire [7:0]  byte2 = in_pwdata[23:16];

  wire [7:0]  byte3 = in_pwdata[31:24];

  wire [31:0] wdata = {byte3, byte2, byte1, byte0};
  assign gpio_out = slv_reg[0][15:0];
  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin 
      always @(posedge clock) begin
        if (reset) begin
          slv_reg[i] <= 32'b0;
        end else begin 
          if (wen && (addr == i)) begin
            slv_reg[i] <=  wdata;
          end
          if(i == 2) begin
            slv_reg[i] <= {16'b0, gpio_in};
          end
        end
      end
    end
  endgenerate

  assign gpio_seg_0 = ~seg7(slv_reg[1][3:0]);
  assign gpio_seg_1 = ~seg7(slv_reg[1][7:4]);
  assign gpio_seg_2 = ~seg7(slv_reg[1][11:8]);
  assign gpio_seg_3 = ~seg7(slv_reg[1][15:12]);
  assign gpio_seg_4 = ~seg7(slv_reg[1][19:16]);
  assign gpio_seg_5 = ~seg7(slv_reg[1][23:20]);
  assign gpio_seg_6 = ~seg7(slv_reg[1][27:24]);
  assign gpio_seg_7 = ~seg7(slv_reg[1][31:28]);

  function [7:0] seg7(input [3:0] num);
    case(num)
      4'b0000 : seg7 = {7'h7E, 1'b0};
      4'b0001 : seg7 = {7'h30, 1'b0};
      4'b0010 : seg7 = {7'h6D, 1'b0};
      4'b0011 : seg7 = {7'h79, 1'b0};
      4'b0100 : seg7 = {7'h33, 1'b0};          
      4'b0101 : seg7 = {7'h5B, 1'b0};
      4'b0110 : seg7 = {7'h5F, 1'b0};
      4'b0111 : seg7 = {7'h70, 1'b0};
      4'b1000 : seg7 = {7'h7F, 1'b0};
      4'b1001 : seg7 = {7'h7B, 1'b0};
      4'b1010 : seg7 = {7'h77, 1'b0};
      4'b1011 : seg7 = {7'h1F, 1'b0};
      4'b1100 : seg7 = {7'h4E, 1'b0};
      4'b1101 : seg7 = {7'h3D, 1'b0};
      4'b1110 : seg7 = {7'h4F, 1'b0};
      4'b1111 : seg7 = {7'h47, 1'b0};
    endcase
  endfunction

endmodule


