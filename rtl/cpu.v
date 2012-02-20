module	cpu(
	input clk,
	input rst,
	output mem_re,
	output mem_we,
	output reg [29:0] memaddr,
	inout [31:0] memdata,

	output [31:0] debugout
);

assign memdata = (mem_we && !mem_re) ? aluout : 32'bz;
assign debugout = pc;

/* next pc */
reg [29:0] pc;
wire [29:0] pcplus1 = pc + 30'd1;
reg [29:0] nextpc;

always @(control_branch or control_branch_neg or reg_a or aluout or pcplus1)
begin
	if (control_branch) begin
		if (control_branch_neg) begin
			nextpc = (reg_a == 32'd0) ? aluout[29:0] : pcplus1;
		end else begin
			nextpc = (reg_a != 32'd0) ? aluout[29:0] : pcplus1;
		end
	end else begin
		nextpc = pcplus1;
	end
end


`define STATE_RST   2'd0
`define STATE_FETCH 2'd1
`define STATE_LOAD  2'd2
`define STATE_STORE 2'd3
reg [1:0] state;
reg goto_fetch_state;

reg control_load;
reg control_store;
reg control_branch;
reg control_branch_neg;

/* top level states */
reg [1:0] nextstate;
always @(goto_fetch_state or control_load or control_store)
begin
	if (goto_fetch_state)
		nextstate = `STATE_FETCH;
	else if (control_load)
		nextstate = `STATE_LOAD;
	else if (control_store)
		nextstate = `STATE_STORE;
	else
		nextstate = `STATE_FETCH;
end

assign mem_we = (state == `STATE_STORE) && !clk;
assign mem_re = ((state == `STATE_FETCH) || (state == `STATE_LOAD));

always @(posedge clk)
begin
	if (rst) begin
		pc <= 30'b111111111111111111111111111111;
		memaddr <= 0;
		state <= `STATE_RST;
	end else begin
		state <= nextstate;
		case (nextstate)
			`STATE_FETCH: begin
				memaddr <= nextpc;
				pc <= nextpc;
			end
			`STATE_LOAD: begin
				memaddr <= aluout[29:0];
			end
			`STATE_STORE: begin
				memaddr <= aluout[29:0];
			end
			default: begin
				memaddr <= 30'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			end
		endcase
	end
end

always @(negedge clk)
begin
	if (rst) begin
		ir <= 0;
		goto_fetch_state <= 1;
	end else begin
		/* negative side of clk */
		case (state)
			`STATE_FETCH: begin
				ir <= memdata;
				goto_fetch_state <= 0;
			end
			`STATE_LOAD: begin
				goto_fetch_state <= 1;
			end
			`STATE_STORE: begin
				goto_fetch_state <= 1;
			end
			`STATE_RST: begin
				goto_fetch_state <= 1;
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
	.bdata(reg_b)
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
`define ALU_B_SEL_IMM24 2'b10
`define ALU_B_SEL_ZERO  2'b11

mux4 #(32) alu_b_mux(
	.sel(alu_b_mux_sel),
	.in0(reg_b),
	.in1(decode_imm16_signed),
	.in2(decode_imm24_signed),
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
	.in1(memdata),
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
wire [31:0] decode_imm24_signed = (ir[23]) ? { 8'b11111111, ir[23:0] } : { 8'b00000000, ir[23:0] };

always @(ir or state)
begin
	/* undefined state */
	aluop = 4'bxxxx;
	control_load = 0;
	control_store = 0;
	control_branch = 0;
	control_branch_neg = 1'bx;
	control_reg_wb = 0;
	reg_a_sel = 4'bxxxx;
	reg_b_sel = 4'bxxxx;
	reg_w_sel = 4'bxxxx;
	alu_a_mux_sel = `ALU_A_SEL_DC;
	alu_b_mux_sel = `ALU_B_SEL_DC;
	reg_w_mux_sel = `REG_W_SEL_DC;

	case (state)
		`STATE_FETCH: begin
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
					control_branch = 1;
					control_branch_neg = ir[29];
					reg_a_sel = decode_rd;
					alu_a_mux_sel = `ALU_A_SEL_PCPLUS1;
					alu_b_mux_sel = `ALU_B_SEL_IMM24;

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
			/* drive the Rd register through the alu */
			aluop = 4'b0000; // add
			alu_a_mux_sel = `ALU_A_SEL_REG;
			alu_b_mux_sel = `ALU_B_SEL_ZERO;
			reg_a_sel = decode_rd;
		end
		default: begin
		end
	endcase
end

endmodule 

