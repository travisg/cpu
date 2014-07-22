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
`include "defines.v"

module alu(
    input [3:0] op,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] res
);

always @(op or a or b)
begin
    case (op)
        `ALU_OP_ADD: res = a + b;
        `ALU_OP_SUB: res = a - b;
        `ALU_OP_AND: res = a & b;
        `ALU_OP_OR:  res = a | b;
        `ALU_OP_XOR: res = a ^ b;
        `ALU_OP_LSL: res = a << b;
        `ALU_OP_LSR: res = a >> b;
        `ALU_OP_ASR: res = $signed(a) >>> b;
        `ALU_OP_MVT: res = { b[15:0], a[15:0] };

        `ALU_OP_SEQ: res = a == b;
        `ALU_OP_SLT: res = a < b;
        `ALU_OP_SLTE: res = a <= b;
        default: res = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    endcase
end

endmodule

