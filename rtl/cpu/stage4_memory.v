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

module  stage4_memory(
    /* cpu global */
    input clk_i,
    input rst_i,

    /* inter-stage */
    input [31:0] alu_i,
    input control_load_i,
    input control_store_i,
    input control_take_branch_i,
    input do_wb_i,
    input [3:0] wb_reg_i,

    output stall_o,

    /* to stage1 */
    output reg take_branch_o,
    output [29:0] branch_pc_o,

    /* to stage5 */
    output reg do_wb_o,
    output reg [3:0] wb_reg_o,
    output reg [31:0] wb_val_o
);

reg [31:0] alu_r;
reg control_load;
reg control_store;

assign stall_o = 0;
assign branch_pc_o = alu_r[29:0];

/*
initial begin
    ir <= 0;
    nextpc_o <= 0;
end
*/

always @(posedge clk_i)
begin
    if (rst_i) begin
        alu_r <= 0;
        control_load <= 0;
        control_store <= 0;
        take_branch_o <= 0;
        do_wb_o <= 0;
        wb_reg_o <= 0;
    end else begin
        alu_r <= alu_i;
        control_load <= control_load_i;
        control_store <= control_store_i;
        take_branch_o <= control_take_branch_i;
        do_wb_o <= do_wb_i;
        wb_reg_o <= wb_reg_i;
    end
end

always @*
begin
    if (control_load) begin
        wb_val_o = 99; // XXX result of load
    end else if (control_store) begin
        wb_val_o = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    end else begin
        wb_val_o = alu_r;
    end
end

endmodule // stage4_memory
