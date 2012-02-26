
module uart(
	input clk, 
	input rst,

	// uart lines
	input hwrx, 
	output hwtx, 

	// bus interface
	input addr, // 2 registers
	input we,
	input re,

	input [31:0] wdata,
	output reg [31:0] rdata,

	// latch char on rising edge if dosend set
//	input [7:0] txchar, 
//	input dosend,

	// rx
	output reg [7:0] rxchar,
	output reg rxvalid
	);

initial begin
end

// 24000000 / (115200) == 208.3333
`define BAUD_DIV 208

// tx
reg [7:0] txclkdiv;
reg [9:0] txshift;
reg [3:0] txcount;
assign hwtx = txshift[0];
reg txdone;

always @ (posedge clk)
begin
	if (rst)
	begin
		txdone <= 1;
		txcount <= 0;
		txshift <= 1;
		txclkdiv <= 0;
	end else if (we && txdone) begin
		// start the tx process
		txshift[0] <= 0; // start bit
		txshift[8:1] <= wdata[7:0];
		txshift[9] <= 1; // stop bit
		txcount <= 9;
		// start bit
		txclkdiv <= `BAUD_DIV;
		txdone <= 0;
	end else if (!txdone) begin
		// keep shifting bits out
		if (txclkdiv == 0) begin
			txshift <= txshift >> 1;
			txclkdiv <= `BAUD_DIV;

			if (txcount == 0) begin
				// terminating condition
				txdone <= 1;
			end else begin
				txcount <= txcount - 1;
			end
		end else begin
			txclkdiv <= txclkdiv - 1;
		end
	end
end

always @(posedge clk)
begin
	if (re) begin
		rdata <= txdone;
	end else begin
		rdata <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
	end
end

// XXX rx is disabled for now
initial begin
	rxvalid <= 0;
	rxchar <= 0;
end

/*
// rx
reg [7:0] rxshift;
reg [3:0] rxclkdiv;
integer rxcount;

always @ (posedge clk)
begin
	if (rst)
	begin
		rxchar <= 0;
		rxvalid <= 0;
		rxcount <= 0;
		rxclkdiv <= 0;
	end
	else
	begin
		// rx state machine
		if (rxcount == 0) begin
			if (hwrx == 0) begin
				// possible start bit
				rxcount <= 1;
				rxclkdiv <= 1;
				rxshift <= 0;
			end
		end else begin
			if (rxclkdiv == 8) begin
				if (rxcount >= 1 && rxcount <= 9) begin // rxcount > 0
					// data bits
					rxshift[7:1] <= rxshift[6:0];
					rxshift[0] <= hwrx;
					rxcount <= rxcount + 1;
				end else if (rxcount == 10) begin
					// stop bit
					if (hwrx == 1) begin
						// it's valid
						$display("what");
						rxchar <= rxshift;
						rxvalid <= 1;
					end else begin
						// reject it
						rxcount <= 0;
						rxvalid <= 0;
					end
				end
			end
			rxclkdiv <= rxclkdiv + 1;
		end
	end
end
*/

endmodule // uart
