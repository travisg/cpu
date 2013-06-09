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
module seven_segment
(
	input [3:0] in,
	output reg [6:0] led
);

	always @ (in)
	begin
		case (in)
			0: led = 7'b1000000;
			1: led = 7'b1111001;
			2: led = 7'b0100100;
			3: led = 7'b0110000;
			4: led = 7'b0011001;
			5: led = 7'b0010010;
			6: led = 7'b0000010;
			7: led = 7'b1111000;
			8: led = 7'b0000000;
			9: led = 7'b0011000;
			10: led = 7'b0001000;
			11: led = 7'b0000011;
			12: led = 7'b1000110;
			13: led = 7'b0100001;
			14: led = 7'b0000110;
			15: led = 7'b0001110;
		endcase
	end
endmodule // led
