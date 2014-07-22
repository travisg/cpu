/*
 * Copyright (c) 2013-2014 Travis Geiselbrecht
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
`define CONTROL_BRANCH_NOTAKE     2'b00
`define CONTROL_BRANCH_COND_Z     2'b01
`define CONTROL_BRANCH_COND_NZ    2'b10

`define ALU_OP_ADD  4'b0000
`define ALU_OP_SUB  4'b0001
`define ALU_OP_AND  4'b0010
`define ALU_OP_OR   4'b0011
`define ALU_OP_XOR  4'b0100
`define ALU_OP_LSL  4'b0101
`define ALU_OP_LSR  4'b0110
`define ALU_OP_ASR  4'b0111
`define ALU_OP_MVB  4'b1000
`define ALU_OP_MVT  4'b1001

`define ALU_OP_SEQ  4'b1010
`define ALU_OP_SLT  4'b1011
`define ALU_OP_SLTE 4'b1100
