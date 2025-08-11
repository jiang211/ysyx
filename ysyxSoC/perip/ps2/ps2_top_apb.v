module ps2_top_apb(
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

  input         ps2_clk,
  input         ps2_data
);

  wire [7:0] data;
  reg empty;
  reg [1:0] state;
  localparam [1:0] IDLE = 'd0;
  localparam [1:0] READ = 'd1;

  assign in_pready  = (state == READ) ? 1'b1 : 1'b0;
  assign in_prdata  = (state == READ) ? (empty ? {24'd0, data} : 'd0) : 'd0;
  assign in_pslverr = 1'b0;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (in_psel && !in_pwrite) begin
            state <= READ;
          end
        end
        READ: begin
          state <= IDLE;
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  reg [9:0] buffer;        // ps2_data bits
    reg [7:0] fifo[7:0];     // data fifo
    reg [2:0] w_ptr,r_ptr;   // fifo write and read pointers
    reg [3:0] count;  // count ps2_data bits
    // detect falling edge of ps2_clk
    reg [2:0] ps2_clk_sync;
    always @(posedge clock) begin
        ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
    end

    wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

    always @(posedge clock) begin
    if (reset) begin
      count <= 'd0; w_ptr   <= 'd0; r_ptr   <= 'd0;
      empty   <= 'd0;
    end else begin
      if (sampling) begin
        if (count == 4'd10) begin
          if ((buffer[0] == 0) && (ps2_data) && (^buffer[9:1])) begin
            fifo[w_ptr] <= buffer[8:1];
            w_ptr       <= w_ptr + 1;
            empty       <= 'd1;
          end
          count <= 'd0;
        end else begin
          buffer[count] <= ps2_data;
          count <= count + 1;
        end
      end

      if (in_penable & in_pready & empty) begin
        r_ptr <= r_ptr + 3'b1;
        if (w_ptr == (r_ptr + 1'b1)) begin
          empty <= 'd0;
        end
      end
    end
  end
    assign data = fifo[r_ptr];
endmodule
