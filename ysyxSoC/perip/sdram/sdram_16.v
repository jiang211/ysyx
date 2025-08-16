module sdram_16(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 1:0] dqm,
  inout [15:0] dq
);
//The address bits registered coincident with the ACTIVE
//command are used to select the bank and row to be accessed (BA0 and BA1 select the
//bank, A[12:0] select the row). 
localparam CMD_NOP = 3'b111;
localparam CMD_ACTIVE = 3'b011;
localparam CMD_READ = 3'b101;
localparam CMD_WRITE = 3'b100;
localparam CMD_TERMINATE = 3'b110;
localparam CMD_LOAD_MODE = 3'b000;

localparam BANK_SIZE = 8192 * 512;

reg [15:0] bank [0:3][BANK_SIZE-1 :0];
  assign dq = 16'bz;
wire [2:0] cmd = {ras, cas, we};

reg [12:0] Line_Address[0:3];

  // assign dq = 16'bz;
  wire [15:0] dout_en;
  reg [15:0] dout;
  wire [15:0] din;
  assign din = dq;
  
  assign dq = (dout_en == 16'hffff) ? dout : 16'bz;
  reg [2:0] CAS;
  reg [2:0] Brust_Length;


  reg [1:0] L_Bank;
  reg [1:0] dqm_buf1;


  reg [3:0] rcount;
  reg [3:0] W_Counter;
  reg read_flag;
  reg [8:0] R_Address;
  reg [8:0] W_Address;
  reg [15:0] W_Data;
  wire [21:0] raddr = {Line_Address[L_Bank], R_Address};
  wire [21:0] waddr = {Line_Address[L_Bank], W_Address};
  wire [3:0] Length = (Brust_Length == 3'b011) ? 4'd8 :
                    (Brust_Length == 3'b010) ? 4'd4 :
                    (Brust_Length == 3'b001) ? 4'd2 :4'd1;

  assign dout_en = read_flag ? 16'hffff : 16'd0;

  always @(posedge clk) begin
    if (!cke) begin
      Line_Address[0] <= 'd0;
      Line_Address[1] <= 'd0;
      Line_Address[2] <= 'd0;
      Line_Address[3] <= 'd0;
    end else if (!cs & (cmd == CMD_ACTIVE)) begin
      Line_Address[ba] <= a;
    end
  end

  always @(posedge clk) begin
    if (!cke) begin
      L_Bank <= 'd0;
    end else if (!cs & (cmd == CMD_ACTIVE | cmd == CMD_READ | cmd == CMD_WRITE)) begin
      L_Bank <= ba;
    end
  end


  always @(posedge clk) begin
    if (!cke) begin
      CAS  <= 3'd0;
      Brust_Length <= 3'd0;
    end else if (!cs & (cmd == CMD_LOAD_MODE)) begin
      CAS  <= a[6:4];
      Brust_Length <= a[2:0];
    end
  end

  always @(posedge clk) begin
    if (!cke) begin
      dqm_buf1 <= 'd0;
    end else if (!cs) begin
      dqm_buf1 <= dqm;
    end
  end

  always @(posedge clk) begin
    if (!cke) begin
      rcount <= 'd0;
      R_Address <= 'd0;
      read_flag <= 'd0;
    end else if (!cs) begin
      if (cmd == CMD_READ) begin
        rcount <= rcount + 1;
        R_Address <= a[8:0];
        read_flag <= 'd1;
      end else if ((rcount > 0) && (rcount < {1'b0, CAS} - 1)) begin
        rcount <= rcount + 1;
        read_flag <= 'd1;
      end else if (rcount >= {1'b0, CAS} - 1) begin
        rcount <= (rcount < Length + CAS - 1) ? rcount + 1 : 'd0;
        R_Address <= R_Address + 1;
        read_flag <= 'd1;
      end else begin
        rcount <= 'd0;
        R_Address <= 'd0;
        read_flag <= 'd0;
      end
    end else begin
      rcount <= 'd0;
      R_Address <= 'd0;
      dout <= 'd0;
      read_flag <= 'd0;
    end
  end
  
  always @(posedge clk) begin
    if (!cke) begin
      dout <= 'd0;
    end else if (!cs) begin
      if (rcount >= {1'b0, CAS} - 1) begin
        dout <= bank[L_Bank][raddr];
      end else begin
        dout <= 'd0;
      end

      if (W_Counter > 0) begin
        bank[L_Bank][waddr][15:8] <= (!dqm_buf1[1]) ? W_Data[15:8] : bank[L_Bank][waddr][15:8];
        bank[L_Bank][waddr][7:0]  <= (!dqm_buf1[0]) ? W_Data[7:0]  : bank[L_Bank][waddr][7:0];
      end
    end else begin
      dout <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (!cke) begin
      W_Counter <= 'd0;
      W_Address <= 'd0;
      W_Data    <= 'd0;
    end else if (!cs) begin
      if (cmd == CMD_WRITE) begin
        W_Counter <= W_Counter + 1;
        W_Address <= a[8:0];
        W_Data    <= din;
      end else if (W_Counter > 0) begin
        W_Counter <= (W_Counter < Length) ? W_Counter + 1 : 'd0;
        W_Address <= W_Address + 1;
        W_Data    <= din;
      end else begin
        W_Counter <= 'd0;
        W_Address <= 'd0;
        W_Data    <= 'd0;
      end
    end
  end

endmodule
