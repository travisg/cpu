// Copyright 2009, Brian Swetland.  Use at your own risk.
// Hacked by Travis Geiselbrecht, 2009-2012

module regfile #(parameter WIDTH=32, parameter RSELWIDTH=4) (
	input clk, 
	input we, 
	input [RSELWIDTH-1:0] wsel, input  [WIDTH-1:0] wdata,
	input [RSELWIDTH-1:0] asel, output [WIDTH-1:0] adata,
	input [RSELWIDTH-1:0] bsel, output [WIDTH-1:0] bdata,
	input [RSELWIDTH-1:0] csel, output [WIDTH-1:0] cdata
	);

reg [WIDTH-1:0] R[0:2**RSELWIDTH-1];

integer k;
initial begin
	for (k = 0; k < RSELWIDTH**2; k = k + 1) R[k] = 0;
end

always @ (posedge clk)
begin
	if (we)
	begin
		R[wsel] <= wdata;
		$display("reg write %h data %h", wsel, wdata);
	end
end

assign adata = R[asel];
assign bdata = R[bsel];
assign cdata = R[csel];
   
endmodule

module regfile1out #(parameter WIDTH=32, parameter RSELWIDTH=4) (
	input clk, 
	input we, input [RSELWIDTH-1:0] wsel, input  [WIDTH-1:0] wdata,
	input [RSELWIDTH-1:0] asel, output [WIDTH-1:0] adata
	);

reg [WIDTH-1:0] R[0:2**RSELWIDTH-1];

integer k;
initial begin
	for (k = 0; k < RSELWIDTH**2; k = k + 1) R[k] = 0;
end

always @ (posedge clk)
begin
	if (we)
	begin
		R[wsel] <= wdata;
		$display("reg write %h data %h", wsel, wdata);
	end
end

assign adata = R[asel];
   
endmodule

module regfile_cr #(parameter WIDTH=32, parameter RSELWIDTH=4) (
	input clk, 
	input we, input [RSELWIDTH-1:0] wsel, input  [WIDTH-1:0] wdata,
	input [RSELWIDTH-1:0] asel, output [WIDTH-1:0] adata
	);

reg [WIDTH-1:0] R[0:2**RSELWIDTH-1];

integer k;
initial begin
	for (k = 0; k < RSELWIDTH**2; k = k + 1) R[k] = 0;
end

always @ (posedge clk)
begin
	if (we)
	begin
		if (wsel[RSELWIDTH-1]) begin
			R[wsel[RSELWIDTH-2:0]] <= ~wdata;
		end else begin
			R[wsel[RSELWIDTH-2:0]] <= wdata;
		end

		$display("reg write %h data %h", wsel, wdata);
	end
end

assign adata = (asel[RSELWIDTH-1] ? ~R[asel[RSELWIDTH-2:0]] : R[asel]);
   
endmodule
