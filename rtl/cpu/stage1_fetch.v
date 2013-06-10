/*
 * Copyright (c) 2013 Travis Geiselbrecht
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

module  stage1_fetch(
    /* cpu global */
    input clk_i,
    input rst_i,

    /* inter-stage */
    input stall_i,
    input take_branch_i,
    input [29:0] branch_pc_i,
    output [31:0] ir_o,
    output [29:0] nextpc_o,

    /* memory interface */
    output reg re_o,
    output [29:0] rmemaddr_o,
    input [31:0] rmemdata_i
);

reg [29:0] pc;

/*
initial begin
    pc <= 0;
end
*/

assign nextpc_o = take_branch_i ? branch_pc_i : pc + 1;
assign rmemaddr_o = nextpc_o;
assign ir_o = rmemdata_i;

always @(posedge clk_i)
begin
    re_o <= 1;
    if (rst_i) begin
        pc <= 30'b111111111111111111111111111111;
        //re_o <= 0;
    end else if (!stall_i) begin
        pc <= nextpc_o;
        //re_o <= 1;
    end
end


endmodule // stage1_fetch
