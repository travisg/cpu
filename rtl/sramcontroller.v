module sramcontroller(
	input clk,
	input [29:0] addr,
	input [31:0] indata,
	output reg [31:0] outdata,
	input re,
	input we,
	output read_sync,
	output write_sync,

	// sram port
	input memclk,
	output reg [17:0] sram_addr,
	inout      [15:0] sram_data,
	output reg sram_ce,
	output reg sram_re,
	output reg sram_we
);

reg [29:0] latched_addr;

reg[1:0] state;
`define STATE_START 0
`define STATE_READ 1
`define STATE_WRITE 2

initial begin
	sram_addr = 18'bzzzzzzzzzzzzzzzzzz;
	sram_ce = 1;
	sram_re = 1;
	sram_we = 1;
	state = `STATE_START;
end

assign read_sync = (state == `STATE_READ && memdone);
assign write_sync = (state == `STATE_WRITE && memdone);

reg [2:0] nextstate;
always @(re or we or memdone) begin
	if (re)
		nextstate = `STATE_READ;
	else if (we)
		nextstate = `STATE_WRITE;
	else
		nextstate = `STATE_START;
end

/* slow clock domain */
always @(posedge clk) begin
	state <= nextstate;
	case (nextstate)
		`STATE_READ: begin
			latched_addr <= addr;
		end
		`STATE_WRITE: begin
			latched_addr <= addr;
		end
	endcase
end

/* fast (memclk) domain */
reg memdone;
wire sameaddr = (sram_addr >> 1 == latched_addr);
wire [15:0] writedata = (memstate == 1) ? indata[15:0] : indata[31:16];
assign sram_data = (!sram_we) ? writedata : 16'bzzzzzzzzzzzzzzzz;

reg [2:0] memstate;
`define MEMSTATE_START 0
`define MEMSTATE_READ1 1
`define MEMSTATE_READ2 2
`define MEMSTATE_READ_DONE 3
`define MEMSTATE_WRITE1 4
`define MEMSTATE_WRITE_DONE 5

initial begin
	sram_addr <= 18'bzzzzzzzzzzzzzzzzzz;
	memdone <= 0;
	memstate <= 0;
end

/* read logic */
always @(posedge memclk) begin
	case (state)
		`STATE_START: begin
			memstate <= `MEMSTATE_START;
			memdone <= 0;
			sram_ce <= 1;
			sram_re <= 1;
			sram_we <= 1;
		end
		`STATE_READ: begin
			case (memstate)
				default: begin
					sram_addr <= latched_addr << 1;
					memdone <= 0;
					sram_ce <= 0;
					sram_re <= 0;
					sram_we <= 1;
					memdone <= 0;
					memstate <= `MEMSTATE_READ1;
				end
				`MEMSTATE_READ1: begin
					outdata[15:0] <= sram_data;
					memstate <= `MEMSTATE_READ2;
					sram_addr <= sram_addr + 1;
				end 
				`MEMSTATE_READ2: begin
					outdata[31:16] <= sram_data; // XXX is this a hold time hazard?
					sram_ce <= 1;
					sram_re <= 1;
					memdone <= 1;
					if (sameaddr)
						memstate <= `MEMSTATE_READ_DONE;
					else
						memstate <= `MEMSTATE_START;
				end
				`MEMSTATE_READ_DONE: begin
					if (!sameaddr)
						memstate <= `MEMSTATE_START;
				end
			endcase
		end
		`STATE_WRITE: begin
			case (memstate)
				default: begin
					sram_addr <= addr;
					memdone <= 0;
					sram_ce <= 0;
					sram_we <= 0;
					sram_re <= 1;
					memstate <= `MEMSTATE_WRITE1;
				end
				`MEMSTATE_WRITE1: begin
					sram_addr <= sram_addr + 1;
					memstate <= `MEMSTATE_WRITE_DONE;
				end
				`MEMSTATE_WRITE_DONE: begin
					memdone <= 1;
					sram_ce <= 1;
					sram_we <= 1;
					if (!sameaddr)
						memstate <= `MEMSTATE_START;
				end
			endcase
		end
	endcase
end

endmodule
