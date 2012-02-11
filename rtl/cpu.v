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

reg [29:0] pc;
wire [29:0] nextpc;

`define STATE_FETCH 0
`define STATE_LOAD  1
`define STATE_STORE 2
reg [1:0] state;

always @(posedge clk && rst)
begin
	pc <= 29'b11111111111111111111111111100;
	memaddr <= 0;
	mem_re <= 0;
	mem_we <= 0;
	state <= `STATE_FETCH;
end

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

/* next pc */
mux2 #(32) nextpc_mux(
	.sel(0),
	.in0(pc + 4),
	.in1(99),
	.out(nextpc)
	);

endmodule 

