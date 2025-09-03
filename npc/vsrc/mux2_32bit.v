module mux2_32bit(
    input [1:0] sel,
    input [31:0] a, 
    input [31:0] b,
    input [31:0] default_data,
    output reg [31:0] out
);
    always @(*) begin
        case(sel)
            2'b01: out = b;
            2'b10: out = a;
            2'b11: out = a;
            default: out = default_data; // 或者可以是其他默认值，如32'b0
        endcase
    end
endmodule
