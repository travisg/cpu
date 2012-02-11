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

wire [29:0] dramaddr;
wire [31:0] dramdata;
wire dram_oe;
wire dram_we;

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

reg	rst;

cpu cpu0(
	.clk(clk),
	.clk_n(clk_n),
	.rst(rst),
	.mem_re(dram_re),
	.mem_we(dram_we),
	.memaddr(dramaddr),
	.memdata(dramdata)
	);

/* hold the cpu in reset for a few clocks */
initial begin
	rst = 1;
	#40 rst = 0;
end

initial begin
	$readmemb("ram.bank0", ram.bank0);
	$readmemb("ram.bank1", ram.bank1);
	$readmemb("ram.bank2", ram2.bank0);
	$readmemb("ram.bank3", ram2.bank1);
end

initial
begin
	 $monitor("%05t: clk %h, rst %h, dramaddr %d, dramdata %h, dram_re %d, dram_we %d", 
		$time, clk, rst, dramaddr, dramdata, dram_re, dram_we);
end

initial begin
	$dumpfile("testbench.vcd");
	$dumpvars(0,testbench);
end

initial #500 $finish;

endmodule

