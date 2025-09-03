// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
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

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

  parameter   SPI_BASE     = 32'h10001000;
  wire        is_flash     = (in_paddr>=32'h30000000)&(in_paddr<=32'h3fffffff)&in_penable;
  wire        is_spi       = (in_paddr>=32'h10001000)&(in_paddr<=32'h10001fff)&in_penable;
  reg         wb_psel    ;
  reg         wb_penable ;   
  reg [2:0]   wb_pprot   ; 
  reg         wb_pwrite  ; 
  reg [31:0]  wb_pwdata  ; 
  reg [3:0]   wb_pstrb   ; 
  wire        wb_pready  ; 
  wire [31:0] wb_prdata  ; 
  wire        wb_pslverr ;
  reg [31:0]  wb_paddr   ; 
  //normal addr 0x10001000--0x10001fff;
  reg [31:0] mspi_paddr   ;  
  reg        mspi_psel    ;
  reg        mspi_penable ;   
  reg [2:0]  mspi_pprot   ; 
  reg        mspi_pwrite  ; 
  reg [31:0] mspi_pwdata  ; 
  reg [3:0]  mspi_pstrb   ; 
  
    //flash read
  //XIP addr
  reg  [31:0] flash_paddr   ; 
  //
  wire        flash_psel    ;
  wire        flash_penable ;   
  wire [2:0]  flash_pprot   ; 
  wire        flash_pwrite  ; 
  wire [31:0] flash_pwdata  ; 
  wire [3:0]  flash_pstrb   ; 
  wire        flash_pready  ; 
  wire [31:0] flash_prdata  ; 
  wire        flash_pslverr ;  
  reg[2:0]    state;
  parameter   IDLE        = 3'b000;
  parameter   XIP_WREG    = 3'b001;
  parameter   XIP_WAIT    = 3'b010;
  parameter   XIP_RETURN  = 3'b011;
  parameter   XIP_CLOSE   = 3'b100;


always @(posedge clock or posedge reset) begin
    if(reset)begin
      state_r <= 'b0;
    end
    else begin
      state_r <= state;
    end
  end


  always @(*) begin
    case (state)
      IDLE       :begin
        wb_paddr  = 'b0;
        wb_psel   = 'b0; 
        wb_penable= 'b0; 
        wb_pprot  = 'b0; 
        wb_pwrite = 'b0; 
        wb_pwdata = 'b0; 
        wb_pstrb  = 'b0; 
      end
      XIP_WREG   :begin
        wb_paddr =({32{(w_cnt=='b0)}}&(SPI_BASE+32'h4)
                  |{32{(w_cnt=='d1)}}&(SPI_BASE+32'h14)
                  |{32{(w_cnt=='d2)}}&(SPI_BASE+32'h18)
                  |{32{(w_cnt=='d3)}}&(SPI_BASE+32'h10));
        wb_psel   = 'b1; 
        wb_penable= 'b1;
        wb_pprot  = 'b1  ; 
        wb_pwrite = 'b1;
        wb_pwdata = ({32{(w_cnt=='b0)}}&({8'h03,flash_paddr[23:2],2'b0})
                  |{32{(w_cnt=='d1)}}&(32'h1)
                  |{32{(w_cnt=='d2)}}&(32'h1)
                  |{32{(w_cnt=='d3)}}&(32'h540));
        wb_pstrb  = 'hf; 
      end
      XIP_WAIT   :begin
        wb_paddr   = SPI_BASE+32'h10;
        wb_psel    = 'b1;
        wb_penable = 'b1;
        wb_pprot   = 'b1;
        wb_pwrite  = 'b0;
        wb_pwdata  = 'b0;
        wb_pstrb   = 'b0;
      end
      XIP_CLOSE:begin
        wb_paddr   = (SPI_BASE+32'h18);
        wb_psel    = 'b1;
        wb_penable = 'b1;
        wb_pprot   = 'b1;
        wb_pwrite  = 'b1;
        wb_pwdata  = 'b0;
        wb_pstrb   = 'h1;
      end
      XIP_RETURN :begin
        wb_paddr   = SPI_BASE;
        wb_psel    = 'b1;
        wb_penable = 'b1;
        wb_pprot   = 'b1;
        wb_pwrite  = 'b0;
        wb_pwdata  = 'b0;
        wb_pstrb   = 'b0;
      end
      default:begin
        wb_paddr  = 'b0;
        wb_psel   = 'b0; 
        wb_penable= 'b0; 
        wb_pprot  = 'b0; 
        wb_pwrite = 'b0; 
        wb_pwdata = 'b0; 
        wb_pstrb  = 'b0; 
      end 
    endcase
  end
  

 

  always @(posedge clock or posedge reset) begin
    if(reset)begin
      flash_paddr <='b0;
    end
    else if(is_flash)begin
      flash_paddr <= in_paddr;
    end
  end
  //fsm
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      state <= IDLE;
    end
    else begin
      case (state)
          IDLE:begin
              if(is_spi)begin
                state <= state;
              end
              else if(is_flash)begin
                state <= XIP_WREG;
              end
              else begin
                state <= IDLE;
              end
          end
          XIP_WREG: begin
            if(w_cnt==3'd4)begin
              state <= XIP_WAIT;
            end
            else begin
              state <= state;
            end
          end
          XIP_WAIT:begin
            if((wb_prdata[8]=='b0)&&wb_pready)begin
              state <= XIP_CLOSE;
            end
            else begin
              state <= state ;
            end
          end
          XIP_CLOSE:begin
            if(wb_pready)begin
              state <= XIP_RETURN;
            end
            else begin
              state <= state;
            end
          end
          XIP_RETURN:begin
            if(wb_pready)begin
              state <= IDLE;
            end
            else begin
              state <= state;
            end
          end
        default:state <= IDLE; 
      endcase
    end
  end

  //XIP_WREG
  reg[2:0]  w_cnt;
  
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      w_cnt<='b0;
    end
    else if(state==XIP_WREG)begin
      if(wb_pwrite&wb_psel&wb_penable&wb_pready)begin
        w_cnt <= w_cnt + 1;
      end
      else begin
        w_cnt <= w_cnt;
      end
    end
    else begin
      w_cnt <= 'b0;
    end
  end
  

  
////////////////////////////////////////////////////////////////////////////
  reg[2:0]  state_r;
  wire[31:0] data_return = (state==XIP_RETURN)?{wb_prdata[7:0],wb_prdata[15:8],wb_prdata[23:16],wb_prdata[31:24]}:wb_prdata;
  
assign in_pready  = ((is_flash&(state==XIP_RETURN))
                  |(is_spi&(state==IDLE)))
                  &(wb_pready)
                  ;
assign in_prdata  = data_return;
assign in_pslverr = 'b0;
spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(wb_paddr[4:0] ),
  .wb_dat_i(wb_pwdata     ),
  .wb_dat_o(wb_prdata     ),
  .wb_sel_i(wb_pstrb      ),
  .wb_we_i (wb_pwrite     ),
  .wb_stb_i(wb_psel       ),
  .wb_cyc_i(wb_penable    ),
  .wb_ack_o(wb_pready     ),
  .wb_err_o(wb_pslverr    ),
  .wb_int_o(spi_irq_out   ),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

`endif // FAST_FLASH

endmodule
