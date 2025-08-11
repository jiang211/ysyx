module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);
  //assign dio = 4'bz;
parameter CMD_RECEIVED = 4'b0001;
parameter ADDR_RECEIVED = 4'b0010;
parameter READ_WAIT = 4'b0100;
parameter READ_DATA = 4'b1000;
parameter WRITE_DATA = 4'b1001;
parameter ERROR = 4'b1111;

reg [3:0] state;
reg [7:0] cmd;
reg o_en;
reg [23:0] addr;

//wire [3:0] wstrb;
wire [31:0] wdata;
wire [31:0] rdata;
wire [3:0] dio_input;
wire [3:0] dio_out;


assign dio_input = dio; 


assign dio        = o_en ? dio_out : 4'bz;
reg         QPI_MODE  = 1;    
always @(posedge ce_n) begin
  if(cmd == 8'h35)begin
    QPI_MODE    <= 1'b1;
  end
end
always @(posedge sck or posedge ce_n) begin
  if(ce_n) begin
    state <= CMD_RECEIVED;
    o_en <= 1'b0;
  end
  else begin
    case(state)
      CMD_RECEIVED: begin
        if(QPI_MODE == 1)begin
          if(receive_count == 4'd1) begin
            state <= ADDR_RECEIVED;
          end
          else if(receive_count == 4'd7) begin
            state <= ADDR_RECEIVED;
          end
        end
      end
      ADDR_RECEIVED: begin
        if(receive_count == 4'd5) begin
          if(cmd == 8'heb)begin
            state <= READ_WAIT;
          end
          else if(cmd == 8'h38) begin
            state <= WRITE_DATA;
          end
          else begin
            state <= ERROR;
          end
        end
      end
      READ_WAIT: begin
        if(receive_count == 4'd6) begin
          state <= READ_DATA;
          o_en <= 1'b1;
        end
      end
      READ_DATA: begin
        state <= state;

      end
      WRITE_DATA: begin
        state <= state;
  
      end
      default: begin
        state <= ERROR;
      end
    endcase
end
end
reg [3:0] receive_count;
always @(posedge sck or posedge ce_n) begin
  if(ce_n) begin
    receive_count <= 0;
  end
  else begin
    case(state)
      CMD_RECEIVED: begin
        if(QPI_MODE == 1) begin
          if(receive_count < 4'd1) begin
            receive_count <= receive_count + 1'b1;
          end
          else begin
            receive_count <= 0;
         end
        end
        else begin
          if(receive_count < 4'd7) begin
            receive_count <= receive_count + 1'b1;
          end
          else begin
            receive_count <= 0;
          end
        end
      end
      ADDR_RECEIVED: begin
        if(receive_count < 4'd5) begin
          receive_count <= receive_count + 1'b1;
        end
        else begin
          receive_count <= 0;
        end
      end
      READ_WAIT: begin
        if(receive_count < 4'd6) begin
          receive_count <= receive_count + 1'b1;
        end
        else begin
          receive_count <= 0;
        end
      end
      READ_DATA: begin
          receive_count <= receive_count + 1'b1;
      end
      WRITE_DATA: begin
          receive_count <= receive_count + 1;
      end
      default: begin
        receive_count <= 0;
      end
    endcase
  end
end

reg [31:0] write_buffer;
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      write_buffer  <= 32'b0;
    end else if (state == WRITE_DATA) begin
      write_buffer  <= {write_buffer[27:0], dio_input};
    end
  end

assign wdata = ({32{(receive_count == 4'd2)}} & {24'b0,write_buffer[7:0]} ) |
               ({32{(receive_count == 4'd4)}} & {16'b0,write_buffer[7:0],write_buffer[15:8]} ) |
               ({32{(receive_count == 4'd8)}} & {write_buffer[7:0],write_buffer[15:8],write_buffer[23:16],write_buffer[31:24]} ) ;
/*
assign wstrb =  (receive_count == 4'd2) ? 4'b0001 :           // 1字节
                  (receive_count == 4'd4) ? 4'b0011 :           // 2字节
                  (receive_count == 4'd8) ? 4'b1111 : 4'b1111;  // 4字节*/
reg [31:0] data;
wire [31:0] data_cache = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
always@(posedge sck or posedge ce_n) begin
  if (ce_n) data <= 32'd0;
  else if (state == READ_DATA) begin
    data <= { {receive_count == 4'd0 ? data_cache : data}[27:0], 4'b0000 };
  end
end
assign dio_out = {(state == READ_DATA && receive_count == 4'b0) ? data_cache : data}[31:28];


always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      cmd   <= 8'b0;
    end else if(state == CMD_RECEIVED) begin
     // cmd   <= {cmd[6:0],dio_input[0]};   // QSPI模式使用SIO0来传输指令
      if(QPI_MODE == 1)begin
        cmd   <= {cmd[3:0], dio_input[3:0]};   // QPI模式使用SIO0_3来传输指令
      end else begin
        cmd   <= {cmd[6:0],dio_input[0]};   // QSPI模式使用SIO0来传输指令
      end
    end
  end

always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      addr   <= 24'b0;
    end else if(state == ADDR_RECEIVED) begin
      addr   <= {addr[19:0],dio_input};  
    end
  end

import "DPI-C" function void psram_read(input int addr, output int data);
import "DPI-C" function void psram_write(input int addr, input int data, input int wstrb);


always @(posedge sck) begin
  if(state == READ_WAIT && receive_count == 4'd6) begin//读取数据
    if(cmd == 8'heb)begin
      psram_read({8'b0,addr}, rdata);
      if(addr >= 24'hef60 && addr <= 24'hefff)begin
        $write("read in psram addr: %08h,data : %08h \n",addr,rdata);
      end
    end
    else begin
      $write("read in psram error,error cmd : %08h\n",cmd);
    end
  end
end

always @(posedge ce_n) begin
  if(state == WRITE_DATA) begin//读取数据
    if(cmd == 8'h38)begin
      psram_write({8'b0,addr}, wdata,{28'b0,receive_count});
      if(addr >= 24'hef60 && addr <= 24'hefff)begin
        $write("write in psram addr: %08h,data : %08h \n",addr,wdata);
      end
      //$write("write in psram addr: %08h,data : %08h \n",addr,wdata);
    end
    else begin
      $write("write in psram error,error cmd : %08h\n",cmd);
    end
  end
end
endmodule
