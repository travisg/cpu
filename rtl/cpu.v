module	cpu(
	input clk,
	input rst,
	output mem_re,
	output mem_we,
	output reg [29:0] memaddr,
	input [31:0]  rmemdata,
	output [31:0] wmemdata,

	output [31:0] debugout
);

assign wmemdata = (mem_we && !mem_re) ? reg_c : 32'bz;
assign debugout = pc;

/* next pc */
reg [29:0] pc;
wire [29:0] pcplus1 = pc + 30'd1;
reg [29:0] nextpc;

reg [2:0] control_branch;
`define CONTROL_BRANCH_NOTAKE 3'b1xx
`define CONTROL_BRANCH_UNCOND 3'b00?
`define CONTROL_BRANCH_COND_Z 3'b010
`define CONTROL_BRANCH_COND_NZ 3'b011

always @(control_branch or reg_c or aluout or pcplus1)
begin
	casex (control_branch)
		`CONTROL_BRANCH_NOTAKE: nextpc = pcplus1;
		`CONTROL_BRANCH_COND_Z: nextpc = (reg_c == 32'd0) ? aluout[29:0] : pcplus1;
		`CONTROL_BRANCH_COND_NZ: nextpc = (reg_c != 32'd0) ? aluout[29:0] : pcplus1;
		`CONTROL_BRANCH_UNCOND: nextpc = aluout[29:0]; 
	endcase
end

`define STATE_RST   3'd0
`define STATE_FETCH 3'd1
`define STATE_DECODE 3'd2
`define STATE_LOAD  3'd3
`define STATE_STORE 3'd4
reg [2:0] state;
reg goto_fetch_state;
reg goto_decode_state;

reg control_load;
reg control_store;

/* top level states */
reg [2:0] nextstate;
always @(goto_fetch_state or goto_decode_state or control_load or control_store)
begin
	if (goto_fetch_state)
		nextstate = `STATE_FETCH;
	else if (goto_decode_state)
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

always @(nextstate or nextpc or aluout)
begin
	case (nextstate)
		`STATE_RST: memaddr = nextpc;
		`STATE_FETCH: memaddr = nextpc;
		`STATE_DECODE: memaddr = 30'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
		`STATE_LOAD: memaddr = aluout[31:2];
		`STATE_STORE: memaddr = aluout[31:2];
		default: memaddr = 30'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
	endcase
end

always @(posedge clk)
begin
	if (rst) begin
		pc <= 30'b111111111111111111111111111111;
		state <= `STATE_RST;
	end else begin
		state <= nextstate;
		case (nextstate)
			`STATE_FETCH: begin
				pc <= nextpc;
			end
			`STATE_DECODE: begin
				ir <= rmemdata;
			end
		endcase
	end
end

always @(negedge clk)
begin
	if (rst) begin
		goto_fetch_state <= 1;
	end else begin
		/* negative side of clk */
		case (state)
			`STATE_FETCH: begin
				goto_fetch_state <= 0;
				goto_decode_state <= 1;
			end
			`STATE_DECODE: begin
				goto_fetch_state <= 0;
				goto_decode_state <= 0;
			end
			`STATE_LOAD: begin
				goto_fetch_state <= 1;
				goto_decode_state <= 0;
			end
			`STATE_STORE: begin
				goto_fetch_state <= 1;
				goto_decode_state <= 0;
			end
			`STATE_RST: begin
				goto_fetch_state <= 1;
				goto_decode_state <= 0;
			end
		endcase
	end
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
`define ALU_A_SEL_PCPLUS1  1'b1

mux2 #(32) alu_a_mux(
	.sel(alu_a_mux_sel),
	.in0(reg_a),
	.in1({ 2'b0, pcplus1 }),
	.out(aluain)
	);

/* alu b input mux */
reg [1:0] alu_b_mux_sel;
`define ALU_B_SEL_DC    2'bxx
`define ALU_B_SEL_REG   2'b00
`define ALU_B_SEL_IMM16 2'b01
`define ALU_B_SEL_IMM22 2'b10
`define ALU_B_SEL_ZERO  2'b11

mux4 #(32) alu_b_mux(
	.sel(alu_b_mux_sel),
	.in0(reg_b),
	.in1(decode_imm16_signed),
	.in2(decode_imm22_signed),
	.in3(0),
	.out(alubin)
	);

/* register file write mux */
reg [1:0] reg_w_mux_sel;
`define REG_W_SEL_DC  2'bxx
`define REG_W_SEL_ALU 2'b00
`define REG_W_SEL_MEM 2'b01
`define REG_W_SEL_PCPLUS1  2'b10
`define REG_W_SEL_ZERO 2'b11

mux4 #(32) reg_w_mux(
	.sel(reg_w_mux_sel),
	.in0(aluout),
	.in1(rmemdata),
	.in2({ pcplus1, 2'b0 }),
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
					aluop = 0; // add
					control_branch = { 1'b0, ir[23], ir[22] };
					alu_a_mux_sel = `ALU_A_SEL_PCPLUS1;
					alu_b_mux_sel = `ALU_B_SEL_IMM22;

					// branch and link
					if (ir[28]) begin
						reg_w_sel = 15; // LR
						reg_w_mux_sel = `REG_W_SEL_PCPLUS1;
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
		`STATE_STORE: begin
		end
		default: begin
		end
	endcase
end

endmodule 

