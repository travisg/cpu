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

module  stage2_decode(
    /* cpu global */
    input clk_i,
    input rst_i,

    /* from stage 1 */
    input [31:0] ir_i,
    input [29:0] nextpc_i,

    /* from stage 2 */
    input stall_i,

    /* from stage 5 */
    input do_wb_i,
    input [3:0] wb_reg_i,
    input [31:0] wb_val_i,

    /* output to stage3 */
    output stall_o,
    output reg [1:0] control_branch_o,
    output reg control_load_o,
    output reg control_store_o,

    output reg [3:0] aluop_o,
    output [31:0] alu_a_o,
    output [31:0] alu_b_o,
    output [31:0] branch_test_val_o,

    output reg do_wb_o,
    output reg [3:0] wb_reg_o
);

reg [31:0] ir;
`define REG_W_SEL_DC  2'bxx
`define REG_W_SEL_ALU 2'b00
`define REG_W_SEL_MEM 2'b01
`define REG_W_SEL_PC  2'b10
`define REG_W_SEL_ZERO 2'b11

reg [29:0] nextpc;
assign stall_o = stall_i;

/*
initial begin
    input [31:0] alu_i,
    input control_load_i,
    input control_store_i,
    input control_take_branch_i,
    ir <= 0;
    nextpc <= 0;
end
*/

always @(posedge clk_i)
begin
    if (rst_i) begin
        ir <= 0;
        nextpc <= 0;
    end if (!stall_i) begin
        ir <= ir_i;
        nextpc <= nextpc_i;
    end
end

reg [3:0] control_branch;

/* register file */
reg [3:0] reg_a_sel;
reg [3:0] reg_b_sel;
wire [31:0] reg_a;
wire [31:0] reg_b;
wire [31:0] reg_wdata;

regfile #(32, 4) regs(
    .clk(clk_i),
    .we(do_wb_i),
    .wsel(wb_reg_i),
    .wdata(wb_val_i),
    .asel(reg_a_sel),
    .adata(reg_a),
    .bsel(reg_b_sel),
    .bdata(reg_b),
    .csel(decode_rd),
    .cdata(branch_test_val_o)
    );

/* alu a input mux */
reg alu_a_mux_sel;

mux2 #(32) alu_a_mux(
    .sel(alu_a_mux_sel),
    .in0(reg_a),
    .in1({ 2'b0, nextpc }),
    .out(alu_a_o)
    );

/* alu b input mux */
reg [1:0] alu_b_mux_sel;

mux4 #(32) alu_b_mux(
    .sel(alu_b_mux_sel),
    .in0(reg_b),
    .in1(decode_imm16_signed),
    .in2(decode_imm22_signed),
    .in3(32'd2),
    .out(alu_b_o)
    );

/* decoder */
wire [1:0] decode_form = ir[31:30];
wire [5:0] decode_op = ir[29:24];
wire [3:0] decode_rd = ir[27:24];
wire [3:0] decode_aluop = ir[23:20];
wire [3:0] decode_ra = ir[19:16];
wire [3:0] decode_rb = ir[15:12];
wire [31:0] decode_imm16_signed = (ir[15]) ? { 16'b1111111111111111, ir[15:0] } : { 16'b0000000000000000, ir[15:0] };
wire [31:0] decode_imm22_signed = (ir[21]) ? { 10'b1111111111, ir[21:0] } : { 10'b0000000000, ir[21:0] };

always @(ir or decode_form or decode_op or decode_rd or decode_aluop or decode_ra or decode_rb or decode_imm16_signed or decode_imm22_signed)
begin
    /* undefined state */
    aluop_o = 4'bxxxx;
    control_load_o = 0;
    control_store_o = 0;
    control_branch_o = `CONTROL_BRANCH_NOTAKE;
    reg_a_sel = 4'bxxxx;
    reg_b_sel = 4'bxxxx;
    alu_a_mux_sel = `ALU_A_SEL_DC;
    alu_b_mux_sel = `ALU_B_SEL_DC;
    do_wb_o = 0;
    wb_reg_o = 4'bxxxx;

    casex (decode_form)
        2'b0?: begin /* form 0 and form 1 are very similar */
            aluop_o = decode_aluop;
            reg_a_sel = decode_ra;
            reg_b_sel = decode_rb;
            if (decode_form == 0) begin
                $display("form 0");
                alu_a_mux_sel = `ALU_A_SEL_REG;
                alu_b_mux_sel = `ALU_B_SEL_IMM16;
            end else begin
                $display("form 1");
                alu_a_mux_sel = `ALU_A_SEL_REG;
                alu_b_mux_sel = `ALU_B_SEL_REG;
            end

            casex (decode_op)
                default: begin
                    do_wb_o = 1;
                    wb_reg_o = decode_rd;
                end
                /* load */
                6'b01????: begin
                    $display("load");
                    control_load_o = 1;
                end
                /* store */
                6'b10????: begin
                    $display("store");
                    control_store_o = 1;
                end
            endcase
        end
        2'b10: begin
            $display("form 2 - branch");
            if (ir[29] == 0) begin
                // pc relative branch
                aluop_o = `ALU_OP_ADD; // add
                alu_a_mux_sel = `ALU_A_SEL_PC;
                alu_b_mux_sel = `ALU_B_SEL_IMM22;
            end else begin
                // branch to reg
                aluop_o = `ALU_OP_LSR; // shift
                reg_a_sel = decode_ra;
                alu_a_mux_sel = `ALU_A_SEL_REG;
                alu_b_mux_sel = `ALU_B_SEL_TWO;
            end

            // conditions 
            if (!ir[28]) begin
                control_branch_o = `CONTROL_BRANCH_TAKE;
            end else if (ir[22]) begin
                control_branch_o = `CONTROL_BRANCH_COND_Z;
            end else begin
                control_branch_o = `CONTROL_BRANCH_COND_NZ;
            end

            // branch and link
            if (ir[23]) begin
                wb_reg_o = 15; // LR
                do_wb_o = 1;
            end
        end
        2'b11: begin
            $display("form 3 - undefined");
        end
    endcase
end

endmodule // stage2_decode
