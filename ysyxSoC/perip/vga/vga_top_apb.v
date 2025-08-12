module vga_top_apb (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [ 2:0] in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [ 3:0] in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [7:0] vga_r,
  output [7:0] vga_g,
  output [7:0] vga_b,
  output       vga_hsync,
  output       vga_vsync,
  output       vga_valid
);
  
  reg [31:0] data[0:2 ** 21-1];
  integer i;
  reg sync_reg;

  localparam h_frontporch = 96;
  localparam h_active = 144;
  localparam h_backporch = 784;
  localparam h_total = 800;

  localparam v_frontporch = 2;
  localparam v_active = 35;
  localparam v_backporch = 515;
  localparam v_total = 525;

  reg [9:0] x_cnt;
  reg [9:0] y_cnt;
  reg [20:0] counter;
  wire h_valid;
  wire v_valid;

  always @(posedge clock) begin
    if (reset == 1'b1) begin
      x_cnt <= 0;
    end else begin
      if (x_cnt == h_total) begin
        if (y_cnt == v_total) begin  //完成一次传输等待sync_reg
          x_cnt <= 0;
        end else begin
          x_cnt <= 1;
        end
      end else if (x_cnt > 0) begin
        x_cnt <= x_cnt + 1;
      end else begin
        if (sync_reg) begin
          x_cnt <= 1;
        end
      end
    end
  end

  always @(posedge clock) begin
    if (reset == 1'b1) begin
      y_cnt <= 1;
    end else begin
      if (x_cnt == h_total) begin
        if (y_cnt == v_total) begin
          y_cnt <= 1;
        end else begin
          y_cnt <= y_cnt + 1;
        end
      end
    end
  end

  always @(posedge clock) begin
    if (reset == 1'b1) begin
      counter <= 0;
    end else begin
      if (y_cnt == v_total) begin
        counter <= 0;
      end else if (vga_valid) begin
        counter <= counter + 1;
      end else begin
        counter <= counter;
      end
    end
  end

  reg ready;
  assign in_pready  = (ready) ? 1'b1 : 1'b0;
  assign in_prdata  = 'd0;
  assign in_pslverr = 1'b0;

  always@(posedge clock) begin
    if (reset) begin
      ready <= 1'b0;
    end else begin
      if (in_psel && in_pwrite) begin
        ready <= 1'b1;
      end else begin
        ready <= 1'b0;
      end
    end
  end


  always @(posedge clock or posedge reset) begin
    if (reset) begin
      sync_reg <= 'd0;
    end else begin
      if (in_penable) begin
        if (in_paddr == 32'h211FFFF4) begin
          sync_reg <= in_pwdata[0];
        end else begin
          data[in_paddr[22:2]] <= in_pwdata;
          sync_reg <= 'd0;
        end
      end
    end
  end

  assign vga_hsync = (x_cnt > h_frontporch);
  assign vga_vsync = (y_cnt > v_frontporch);

  assign h_valid   = (x_cnt > h_active) & (x_cnt <= h_backporch);
  assign v_valid   = (y_cnt > v_active) & (y_cnt <= v_backporch);
  assign vga_valid = h_valid & v_valid;
  //计算当前有效像素坐标
  // assign h_addr = h_valid ? (x_cnt - 10'd145) : {10{1'b0}};
  // assign v_addr = v_valid ? (y_cnt - 10'd36) : {10{1'b0}};

  assign vga_r     = vga_valid ? data[counter][23:16] : 8'h00;
  assign vga_g     = vga_valid ? data[counter][15:8] : 8'h00;
  assign vga_b     = vga_valid ? data[counter][7:0] : 8'h00;



endmodule

