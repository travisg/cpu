module alu(
	input [3:0] op,
	input [31:0] a,
	input [31:0] b,
	output [31:0] res
);

reg [31:0] res;

always @(op or a or b)
begin
	case (op)
		4'b0000: res <= a + b;
		4'b0001: res <= a - b;
		4'b0010: res <= b - a;
		4'b0011: res <= a & b;
		4'b0100: res <= a | b;
		4'b0101: res <= a ^ b;
		4'b0110: res <= a << b;
		4'b0111: res <= a >> b;
		4'b1000: res <= a >> b; // sign extend
		4'b1001: res <= ~b;
		4'b1010: res <= b;
		4'b1011: res <= a | (b << 16);

		4'b1100: res <= a < b;
		4'b1101: res <= a <= b;
		4'b1110: res <= a == b;
		4'b1111: res <= 1;
	endcase
end

endmodule

