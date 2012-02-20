/*
 * Copyright (c) 2011-2012 Travis Geiselbrecht
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
module alu(
	input [3:0] op,
	input [31:0] a,
	input [31:0] b,
	output reg [31:0] res
);

always @(op or a or b)
begin
	case (op)
		4'b0000: res = a + b;
		4'b0001: res = a - b;
		4'b0010: res = b - a;
		4'b0011: res = a & b;
		4'b0100: res = a | b;
		4'b0101: res = a ^ b;
		4'b0110: res = a << b;
		4'b0111: res = a >> b;
		4'b1000: res = a >>> b;
		4'b1001: res = b;
		4'b1010: res = { 16'd0, b[15:0] };
		4'b1011: res = a | (b << 16);

		4'b1100: res = a < b;
		4'b1101: res = a <= b;
		4'b1110: res = a == b;
		4'b1111: res = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
	endcase
end

endmodule

