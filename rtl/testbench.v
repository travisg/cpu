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

module testbench;

parameter AWIDTH = 16;

reg clk;
assign clk_n = ~clk;

always 
  begin
     clk = 0;
     #12 ;
     clk = 1;
     #12 ;
  end

/*
sram #(AWIDTH) dram(
    .ce(dram_ce),
    .we(dram_we),
    .re(dram_re),
    .addr(dramaddr[AWIDTH-1:0]),
    .datain(dramdata),
    .dataout(dramdata)
    );
*/

/*
IS61LV25616 ram(
    .A(dramaddr[17:0]), 
    .IO(dramdata[15:0]), 
    .CE_(0), 
    .OE_(!dram_re), 
    .WE_(!dram_we), 
    .LB_(0), 
    .UB_(0)
);

IS61LV25616 ram2(
    .A(dramaddr[17:0]), 
    .IO(dramdata[31:16]), 
    .CE_(0), 
    .OE_(!dram_re), 
    .WE_(!dram_we), 
    .LB_(0), 
    .UB_(0)
);
*/

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
initial begin
    rst = 1;
    #40 rst = 0;
end

/*
initial begin
    $readmemb("ram.bank0", ram.bank0);
    $readmemb("ram.bank1", ram.bank1);
    $readmemb("ram.bank2", ram2.bank0);
    $readmemb("ram.bank3", ram2.bank1);
end
*/

initial
begin
//   $monitor("%05t: clk %h, rst %h, memaddr %d, memdata %h, mem_re %d, mem_we %d", 
//      $time, clk, rst, memaddr, memdata, mem_re, mem_we);
end

initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0,testbench);
end

initial #1000 $finish;

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
    $readmemh("test2.asm.hex", rom);
end

always @(posedge clk) begin
    if (re)
        rdata <= rom[addr];
    else
        rdata <= #1 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    if (we)
        rom[addr] <= wdata;
end

endmodule

