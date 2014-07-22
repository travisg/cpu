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

module  stage5_writeback(
    /* cpu global */
    input clk_i,
    input rst_i,

    /* from stage 4 */
    input do_wb_i,
    input [4:0] wb_reg_i,
    input [31:0] wb_val_i,

    /* back to stage2, writeback to register file */
    output reg do_wb_o,
    output reg [4:0] wb_reg_o,
    output reg [31:0] wb_val_o
);

always @(posedge clk_i)
begin
    if (rst_i) begin
        do_wb_o <= 0;
        wb_reg_o <= 0;
        wb_val_o <= 0;
    end else begin
        do_wb_o <= do_wb_i;
        wb_reg_o <= wb_reg_i;
        wb_val_o <= wb_val_i;
    end
end

endmodule // stage5_writeback
