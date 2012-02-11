module	cpu(
	input clk,
	input clk_n,
	input rst,
	output mem_re,
	output mem_we,
	output [29:0] memaddr,
	inout [31:0] memdata
);

reg [29:0] memaddr;
reg mem_re;
reg mem_we;

assign memdata = (mem_we && !mem_re) ? aluout : 32'bz;

/* next pc */
reg [29:0] pc;
wire [29:0] nextpc;
`define NEXTPC_SEL_PLUS1 1'b0
`define NEXTPC_SEL_BRANCH 1'b1
reg nextpc_sel;

mux2 #(30) nextpc_mux(
	.sel(nextpc_sel),
	.in0(pc + 30'd1),
	.in1(99),
	.out(nextpc)
	);

`define STATE_FETCH 0
`define STATE_LOAD  1
`define STATE_STORE 2
reg [1:0] state;

reg control_latch_fetch;

/* initial and reset situation */
initial begin
	pc <= 30'b111111111111111111111111111111;
	memaddr <= 0;
	mem_re <= 0;
	mem_we <= 0;
	nextpc_sel = `NEXTPC_SEL_PLUS1;
	state <= `STATE_FETCH;
	control_reg_wb <= 0;
end

always @(posedge clk && rst)
begin
	pc <= 30'b111111111111111111111111111111;
	memaddr <= 0;
	mem_re <= 0;
	mem_we <= 0;
	nextpc_sel = `NEXTPC_SEL_PLUS1;
	state <= `STATE_FETCH;
	control_reg_wb <= 0;
end

/* top level states */
always @(posedge clk && !rst)
begin
	case (state)
		`STATE_FETCH: begin
			memaddr <= nextpc;
			mem_we <= 0;
			mem_re <= 1;
			pc <= nextpc;	
		end
		`STATE_LOAD: begin
			memaddr <= aluout;
			mem_we <= 0;
			mem_re <= 1;
		end
		`STATE_STORE: begin
			memaddr <= aluout;
			mem_re <= 0;
			mem_we <= 0;
		end
	endcase
end

reg [31:0] ir;
wire [1:0] decode_form = ir[31:30];
wire [5:0] decode_op = ir[29:24];
wire [3:0] decode_aluop = ir[27:24];
wire [3:0] decode_rd = ir[23:20];
wire [3:0] decode_ra = ir[19:16];
wire [3:0] decode_rb = ir[15:12];
wire [15:0] decode_imm16 = ir[15:0];
wire [23:0] decode_imm24 = ir[23:0];

/* alu */
wire [31:0] aluout;
wire [31:0] aluain;
wire [31:0] alubin;

alu alu0(
	.op(decode_aluop),
	.a(aluain),
	.b(alubin),
	.res(aluout)
);

/* register file */
wire [31:0] reg_a;
wire [31:0] reg_b;
wire [31:0] reg_wdata;
reg control_reg_wb;

regfile #(32, 4) regs(
	.clk(clk),
	.we(control_reg_wb),
	.wsel(decode_rd),
	.wdata(reg_wdata),
	.asel(decode_ra),
	.adata(reg_a),
	.bsel(decode_rb),
	.bdata(reg_b)
	);

reg control_cr_reg_wb;
wire cr_reg;

regfile_cr #(1, 4) crregs(
	.clk(clk),
	.we(control_cr_reg_wb),
	.wsel(decode_rd),
	.wdata(aluout[0]),
	.asel(0),
	.adata(cr_reg)
	);

/* alu a input mux */
reg alu_a_mux_sel;
`define ALU_A_SEL_REG 1'b0
`define ALU_A_SEL_PC  1'b1

mux2 #(32) alu_a_mux(
	.sel(alu_a_mux_sel),
	.in0(reg_a),
	.in1({ 2'b0, pc }),
	.out(aluain)
	);

/* alu b input mux */
reg alu_b_mux_sel;
`define ALU_B_SEL_REG 1'b0
`define ALU_B_SEL_IMM 1'b1

mux2 #(32) alu_b_mux(
	.sel(alu_b_mux_sel),
	.in0(reg_b),
	.in1({ 16'b0, decode_imm16 }),
	.out(alubin)
	);

/* register file write mux */
reg reg_w_mux_sel;
`define REG_W_SEL_ALU 1'b0
`define REG_W_SEL_MEM 1'b1

mux2 #(32) reg_w_mux(
	.sel(reg_w_mux_sel),
	.in0(aluout),
	.in1(memdata),
	.out(reg_wdata)
	);

/* latch in the instruction from the memory bus */
always @(posedge clk_n)
begin
	if (state == `STATE_FETCH) begin
		ir <= memdata;
	end
end

always @(ir)
begin
	if (state == `STATE_FETCH) begin
		casex (decode_form)
			2'b0?: begin /* form 0 and form 1 are very similar */
				reg_w_mux_sel <= `REG_W_SEL_ALU;
				if (decode_form == 0) begin
					$display("form 0");
					alu_a_mux_sel <= `ALU_A_SEL_REG;
					alu_b_mux_sel <= `ALU_B_SEL_IMM;
				end else begin
					$display("form 1");
					alu_a_mux_sel <= `ALU_A_SEL_REG;
					alu_b_mux_sel <= `ALU_B_SEL_REG;
				end

				casex (decode_op)
					/* pick out slt/seq/sc and make sure we writeback to the cr reg banks */
					6'b0011??: begin
						control_cr_reg_wb <= 1;
						control_reg_wb <= 0;
					end
					default: begin
						control_cr_reg_wb <= 0;
						control_reg_wb <= 1;
					end
					/* load */
					6'b01????: begin
						$display("load");
						control_cr_reg_wb <= 0;
						control_reg_wb <= 0;
						state <= `STATE_LOAD;
					end
					/* store */
					6'b10????: begin
						$display("store");
						control_cr_reg_wb <= 0;
						control_reg_wb <= 0;
						state <= `STATE_STORE;
					end
				endcase
			end
			2'b10: begin
				$display("form 2");

			end
			2'b11: begin
				$display("form 3");

			end
		endcase
	end
end

/* latch in the load data */
always @(posedge clk_n)
begin
	if (state == `STATE_LOAD) begin
		reg_w_mux_sel <= `REG_W_SEL_MEM;
		state <= `STATE_FETCH;
		control_reg_wb <= 1;
	end
end

/* store logic */
always @(posedge clk)
begin
	if (state == `STATE_STORE) begin
		/* hack the ir to drive the alu to pass the store data through */
		ir[19:16] <= decode_rd;
		ir[15:0] <= 0;
		alu_a_mux_sel <= `ALU_A_SEL_REG;
		alu_b_mux_sel <= `ALU_B_SEL_IMM;
		
	end
end

always @(posedge clk_n)
begin
	if (state == `STATE_STORE) begin
		state <= `STATE_FETCH;
		mem_we <= 1;
	end
end

endmodule 

