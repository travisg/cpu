/*
 * Copyright (c) 2011-2012 Travis Geiselbrecht
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
`timescale 1ns/1ns

module testbench(
    input clk
);

parameter AWIDTH = 16;

reg [31:0] count;

initial
	count <= 0;

always @(posedge clk)
	count <= count + 1;

always @(count)
begin
	if (count == 1000)
		$finish;

end

reg rst;

wire [29:0] memaddr;
wire [31:0] rmemdata;
wire [31:0] wmemdata;
wire mem_oe;
wire mem_we;

cpu cpu0(
    .clk(clk),
    .rst(rst),
    .mem_re(mem_oe),
    .mem_we(mem_we),
    .memaddr(memaddr),
    .rmemdata(rmemdata),
    .wmemdata(wmemdata)
    );

rom rom0(
    .clk(clk),
    .re(mem_oe),
    .we(mem_we),
    .addr(memaddr),
    .rdata(rmemdata),
    .wdata(wmemdata)
);

/* hold the cpu in reset for a few clocks */
always @(count)
	if (count < 10)
		rst = 1;
	else
		rst = 0;

endmodule

module rom(
    input clk,
    input re,
    input we,
    input [29:0] addr,
    output reg [31:0] rdata,
    input [31:0] wdata
);

reg [31:0] rom [0:255];

initial begin
    $readmemh("../test2.asm.hex", rom);
end

always @(posedge clk) begin
    rdata <= rom[addr];
    if (we)
        rom[addr] <= wdata;
end

endmodule

