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
			mem_re <= 1;
			pc <= nextpc;	
		end
		`STATE_LOAD: begin

		end
		`STATE_STORE: begin

		end
	endcase
end

wire [31:0] ir = memdata;
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
reg control_reg_wb;

regfile #(32, 4) regs(
	.clk(clk),
	.we(control_reg_wb),
	.wsel(decode_rd),
	.wdata(aluout),
	.asel(decode_ra),
	.adata(reg_a),
	.bsel(decode_rb),
	.bdata(reg_b)
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

always @(ir)
begin
	case (ir[31:30])
		2'b00: begin
			$display("form 0");
			alu_a_mux_sel <= `ALU_A_SEL_REG;
			alu_b_mux_sel <= `ALU_B_SEL_REG;
			control_reg_wb <= 1;
		end
		2'b01: begin
			$display("form 1");
			alu_a_mux_sel <= `ALU_A_SEL_REG;
			alu_b_mux_sel <= `ALU_B_SEL_IMM;
			control_reg_wb <= 1;
		end
		2'b10: begin

		end
		2'b11: begin

		end
	endcase
end


endmodule 

