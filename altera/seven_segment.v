module seven_segment
(
	input [3:0] in,
	output reg [6:0] led
);

	always @ (in)
	begin
		case (in)
			0: led = 7'b1000000;
			1: led = 7'b1111001;
			2: led = 7'b0100100;
			3: led = 7'b0110000;
			4: led = 7'b0011001;
			5: led = 7'b0010010;
			6: led = 7'b0000010;
			7: led = 7'b1111000;
			8: led = 7'b0000000;
			9: led = 7'b0011000;
			10: led = 7'b0001000;
			11: led = 7'b0000011;
			12: led = 7'b1000110;
			13: led = 7'b0100001;
			14: led = 7'b0000110;
			15: led = 7'b0001110;
		endcase
	end
endmodule // led