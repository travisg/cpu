/*
 * Copyright (c) 2011-2014 Travis Geiselbrecht
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

module  cpu(
    input clk,
    input rst,
    output mem_re,
    output mem_we,
    output [29:0] memaddr,
    input [31:0]  rmemdata,
    output [31:0] wmemdata,

    output [31:0] debugout
);

/* unused bits for now */
assign mem_we = 0;
assign wmemdata = 0;
assign debugout = 0;

wire stall_2to1;
wire [31:0] ir_1to2;
wire [29:0] nextpc_1to2;
wire take_branch_3to1;
wire [29:0] branch_pc_3to1;

stage1_fetch stage1(
    .clk_i(clk),
    .rst_i(rst),

    /* inter-stage */
    .take_branch_i(take_branch_3to1),
    .branch_pc_i(branch_pc_3to1),
    .stall_i(stall_2to1),
    .ir_o(ir_1to2),
    .nextpc_o(nextpc_1to2),

    /* memory interface */
    .re_o(mem_re),
    .rmemaddr_o(memaddr),
    .rmemdata_i(rmemdata)
);

wire do_wb_5to2;
wire [4:0] wb_reg_5to2;
wire [31:0] wb_val_5to2;

wire stall_3to2;

wire [29:0] nextpc_2to3;
wire [1:0] control_branch_2to3;
wire control_load_2to3;
wire control_store_2to3;

wire [3:0] aluop_2to3;
wire [31:0] alu_a_2to3;
wire [31:0] alu_b_2to3;
wire [31:0] branch_test_val_2to3;

wire do_wb_2to3;
wire [4:0] wb_reg_2to3;

stage2_decode stage2(
    .clk_i(clk),
    .rst_i(rst),

    /* inter-stage */
    .ir_i(ir_1to2),
    .nextpc_i(nextpc_1to2),
    .stall_i(stall_3to2),

    /* from stage 5 */
    .do_wb_i(do_wb_5to2),
    .wb_reg_i(wb_reg_5to2),
    .wb_val_i(wb_val_5to2),

    /* output to stage3 */
    .stall_o(stall_2to1),
    .control_branch_o(control_branch_2to3),
    .control_load_o(control_load_2to3),
    .control_store_o(control_store_2to3),

    .aluop_o(aluop_2to3),
    .alu_a_o(alu_a_2to3),
    .alu_b_o(alu_b_2to3),
    .branch_test_val_o(branch_test_val_2to3),

    .do_wb_o(do_wb_2to3),
    .wb_reg_o(wb_reg_2to3)
);

wire stall_4to3;

wire control_load_3to4;
wire control_store_3to4;
wire do_wb_3to4;
wire [4:0] wb_reg_3to4;

wire [31:0] alu_3to4;

stage3_execute stage3(
    .clk_i(clk),
    .rst_i(rst),

    .stall_i(stall_4to3),

    .control_branch_i(control_branch_2to3),
    .control_load_i(control_load_2to3),
    .control_store_i(control_store_2to3),
    .aluop_i(aluop_2to3),
    .alu_a_i(alu_a_2to3),
    .alu_b_i(alu_b_2to3),
    .branch_test_val_i(branch_test_val_2to3),

    .do_wb_i(do_wb_2to3),
    .wb_reg_i(wb_reg_2to3),

    .stall_o(stall_3to2),
    .alu_o(alu_3to4),

    .take_branch_o(take_branch_3to1),
    .branch_pc_o(branch_pc_3to1),

    .control_load_o(control_load_3to4),
    .control_store_o(control_store_3to4),
    .do_wb_o(do_wb_3to4),
    .wb_reg_o(wb_reg_3to4)
);

wire do_wb_4to5;
wire [4:0] wb_reg_4to5;
wire [31:0] wb_val_4to5;

stage4_memory stage4(
    .clk_i(clk),
    .rst_i(rst),

    .alu_i(alu_3to4),
    .control_load_i(control_load_3to4),
    .control_store_i(control_store_3to4),
    .do_wb_i(do_wb_3to4),
    .wb_reg_i(wb_reg_3to4),

    .stall_o(stall_4to3),

    .do_wb_o(do_wb_4to5),
    .wb_reg_o(wb_reg_4to5),
    .wb_val_o(wb_val_4to5)
);

stage5_writeback stage5(
    .clk_i(clk),
    .rst_i(rst),

    .do_wb_i(do_wb_4to5),
    .wb_reg_i(wb_reg_4to5),
    .wb_val_i(wb_val_4to5),

    .do_wb_o(do_wb_5to2),
    .wb_reg_o(wb_reg_5to2),
    .wb_val_o(wb_val_5to2)
);


`ifdef UNUSED
assign wmemdata = (mem_we && !mem_re) ? reg_c : 32'bz;
assign debugout = pc;

/* next pc */
reg [29:0] pc;
reg [29:0] nextpc;

reg [3:0] control_branch;
`define CONTROL_BRANCH_NOTAKE     4'b1xxx
`define CONTROL_BRANCH_UNCOND     4'b000?
`define CONTROL_BRANCH_COND_Z     4'b0010
`define CONTROL_BRANCH_COND_NZ    4'b0011
`define CONTROL_BRANCH_RA_UNCOND  4'b010?
`define CONTROL_BRANCH_RA_COND_Z  4'b0110
`define CONTROL_BRANCH_RA_COND_NZ 4'b0111

always @(control_branch or reg_c or aluout or reg_a or pc)
begin
    casex (control_branch)
        `CONTROL_BRANCH_NOTAKE: nextpc = pc;
        `CONTROL_BRANCH_COND_Z: nextpc = (reg_c == 32'd0) ? aluout[29:0] : pc;
        `CONTROL_BRANCH_COND_NZ: nextpc = (reg_c != 32'd0) ? aluout[29:0] : pc;
        `CONTROL_BRANCH_UNCOND: nextpc = aluout[29:0]; 
        `CONTROL_BRANCH_RA_COND_Z: nextpc = (reg_c == 32'd0) ? (reg_a >> 2) : pc;
        `CONTROL_BRANCH_RA_COND_NZ: nextpc = (reg_c != 32'd0) ? (reg_a >> 2) : pc;
        `CONTROL_BRANCH_RA_UNCOND: nextpc = (reg_a >> 2);
    endcase
end

`define STATE_RST   3'd0
`define STATE_FETCH 3'd1
`define STATE_DECODE 3'd2
`define STATE_LOAD  3'd3
`define STATE_STORE 3'd4
reg [2:0] state;

reg control_load;
reg control_store;

/* top level states */
reg [2:0] nextstate;
always @(rst or state or control_load or control_store)
begin
    if (rst)
        nextstate = `STATE_RST;
    else if (state == `STATE_RST || state == `STATE_LOAD || state == `STATE_STORE)
        nextstate = `STATE_FETCH;
    else if (state == `STATE_FETCH)
        nextstate = `STATE_DECODE;
    else if (control_load)
        nextstate = `STATE_LOAD;
    else if (control_store)
        nextstate = `STATE_STORE;
    else
        nextstate = `STATE_FETCH;
end

assign mem_we = (nextstate == `STATE_STORE);
assign mem_re = ((nextstate == `STATE_FETCH) || (nextstate == `STATE_LOAD));

always @(nextstate or pc or nextpc or aluout)
begin
    case (nextstate)
        `STATE_RST: memaddr = pc;
        `STATE_FETCH: memaddr = nextpc;
        `STATE_DECODE: memaddr = 30'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        `STATE_LOAD: memaddr = aluout[31:2];
        `STATE_STORE: memaddr = aluout[31:2];
        default: memaddr = 30'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    endcase
end

always @(posedge clk)
begin
    state <= nextstate;
    case (nextstate)
        `STATE_RST: begin
            pc <= 0;
        end
        `STATE_FETCH: begin
            pc <= nextpc;
        end
        `STATE_DECODE: begin
            pc <= aluout[29:0];
            ir <= rmemdata;
        end
    endcase
end

/* alu */
reg [3:0] aluop;
wire [31:0] aluout;
wire [31:0] aluain;
wire [31:0] alubin;

alu alu0(
    .op(aluop),
    .a(aluain),
    .b(alubin),
    .res(aluout)
);

/* register file */
reg [3:0] reg_a_sel;
reg [3:0] reg_b_sel;
reg [3:0] reg_w_sel;
wire [31:0] reg_a;
wire [31:0] reg_b;
wire [31:0] reg_c;
wire [31:0] reg_wdata;
reg control_reg_wb;

regfile #(32, 4) regs(
    .clk(clk),
    .we(control_reg_wb),
    .wsel(reg_w_sel),
    .wdata(reg_wdata),
    .asel(reg_a_sel),
    .adata(reg_a),
    .bsel(reg_b_sel),
    .bdata(reg_b),
    .csel(decode_rd),
    .cdata(reg_c)
    );

/* alu a input mux */
reg alu_a_mux_sel;
`define ALU_A_SEL_DC  1'bx
`define ALU_A_SEL_REG 1'b0
`define ALU_A_SEL_PC  1'b1

mux2 #(32) alu_a_mux(
    .sel(alu_a_mux_sel),
    .in0(reg_a),
    .in1({ 2'b0, pc }),
    .out(aluain)
    );

/* alu b input mux */
reg [1:0] alu_b_mux_sel;
`define ALU_B_SEL_DC    2'bxx
`define ALU_B_SEL_REG   2'b00
`define ALU_B_SEL_IMM16 2'b01
`define ALU_B_SEL_IMM22 2'b10
`define ALU_B_SEL_ONE   2'b11

mux4 #(32) alu_b_mux(
    .sel(alu_b_mux_sel),
    .in0(reg_b),
    .in1(decode_imm16_signed),
    .in2(decode_imm22_signed),
    .in3(32'd1),
    .out(alubin)
    );

/* register file write mux */
reg [1:0] reg_w_mux_sel;
`define REG_W_SEL_DC  2'bxx
`define REG_W_SEL_ALU 2'b00
`define REG_W_SEL_MEM 2'b01
`define REG_W_SEL_PC  2'b10
`define REG_W_SEL_ZERO 2'b11

mux4 #(32) reg_w_mux(
    .sel(reg_w_mux_sel),
    .in0(aluout),
    .in1(rmemdata),
    .in2({ pc, 2'b0 }),
    .in3(0),
    .out(reg_wdata)
    );

/* decoder */
reg [31:0] ir;
wire [1:0] decode_form = ir[31:30];
wire [5:0] decode_op = ir[29:24];
wire [3:0] decode_rd = ir[27:24];
wire [3:0] decode_aluop = ir[23:20];
wire [3:0] decode_ra = ir[19:16];
wire [3:0] decode_rb = ir[15:12];
wire [31:0] decode_imm16_signed = (ir[15]) ? { 16'b1111111111111111, ir[15:0] } : { 16'b0000000000000000, ir[15:0] };
wire [31:0] decode_imm22_signed = (ir[21]) ? { 10'b1111111111, ir[21:0] } : { 10'b0000000000, ir[21:0] };

always @(ir or state or decode_form or decode_op or decode_rd or decode_aluop or decode_ra or decode_rb or decode_imm16_signed or decode_imm22_signed)
begin
    /* undefined state */
    aluop = 4'bxxxx;
    control_load = 0;
    control_store = 0;
    control_branch = `CONTROL_BRANCH_NOTAKE;
    control_reg_wb = 0;
    reg_a_sel = 4'bxxxx;
    reg_b_sel = 4'bxxxx;
    reg_w_sel = 4'bxxxx;
    alu_a_mux_sel = `ALU_A_SEL_DC;
    alu_b_mux_sel = `ALU_B_SEL_DC;
    reg_w_mux_sel = `REG_W_SEL_DC;

    case (state)
        `STATE_FETCH: begin
            /* use the alu to calculate the next pc */
            aluop = 4'b0000; // add
            alu_a_mux_sel = `ALU_A_SEL_PC;
            alu_b_mux_sel = `ALU_B_SEL_ONE;
        end
        `STATE_DECODE: begin
            casex (decode_form)
                2'b0?: begin /* form 0 and form 1 are very similar */
                    aluop = decode_aluop;
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
                            control_reg_wb = 1;
                            reg_w_sel = decode_rd;
                            reg_w_mux_sel = `REG_W_SEL_ALU;
                        end
                        /* load */
                        6'b01????: begin
                            $display("load");
                            control_load = 1;
                        end
                        /* store */
                        6'b10????: begin
                            $display("store");
                            control_store = 1;
                        end
                    endcase
                end
                2'b10: begin
                    $display("form 2 - branch");
                    if (ir[29] == 0) begin
                        // pc relative branch
                        aluop = 0; // add
                        control_branch = { 1'b0, 1'b0, ir[23], ir[22] };
                        alu_a_mux_sel = `ALU_A_SEL_PC;
                        alu_b_mux_sel = `ALU_B_SEL_IMM22;
                    end else begin
                        // branch to reg
                        control_branch = { 1'b0, 1'b1, ir[23], ir[22] };
                        reg_a_sel = decode_ra;
                    end

                    // branch and link
                    if (ir[28]) begin
                        reg_w_sel = 15; // LR
                        reg_w_mux_sel = `REG_W_SEL_PC;
                        control_reg_wb = 1;
                    end
                end
                2'b11: begin
                    $display("form 3 - undefined");
                end
            endcase
        end
        `STATE_LOAD: begin
            control_reg_wb = 1;
            reg_w_sel = decode_rd;
            reg_w_mux_sel = `REG_W_SEL_MEM;
        end
        default: begin
        end
    endcase
end
`endif

endmodule 

