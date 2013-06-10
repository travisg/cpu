// Copyright 2009, Brian Swetland.  Use at your own risk.
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

module decoder2 (
    input [1:0] in,
    output out0, out1, out2, out3
    );

reg [3:0] out;

assign out0 = out[0];
assign out1 = out[1];
assign out2 = out[2];
assign out3 = out[3];

always @ (*)
    case (in)
    2'b00: out = 4'b0001;
    2'b01: out = 4'b0010;
    2'b10: out = 4'b0100;
    2'b11: out = 4'b1000;
    endcase

endmodule


module decoder8 (input [2:0] in, output reg [7:0] out);
always @ (*)
  case (in)
    3'b000: out = 8'b00000001;
    3'b001: out = 8'b00000010;
    3'b010: out = 8'b00000100;
    3'b011: out = 8'b00001000;
    3'b100: out = 8'b00010000;
    3'b101: out = 8'b00100000;
    3'b110: out = 8'b01000000;
    3'b111: out = 8'b10000000;
  endcase
endmodule

module decoder8en (input [2:0] in, input en, output reg [7:0] out);
always @ (*)
  if (en)
    case (in)
      3'b000: out = 8'b00000001;
      3'b001: out = 8'b00000010;
      3'b010: out = 8'b00000100;
      3'b011: out = 8'b00001000;
      3'b100: out = 8'b00010000;
      3'b101: out = 8'b00100000;
      3'b110: out = 8'b01000000;
      3'b111: out = 8'b10000000;
    endcase
  else
    out = 8'b00000000;
endmodule

 
module mux2 #(parameter WIDTH=32)
    (
    input sel,
    input [WIDTH-1:0] in0, in1,
    output [WIDTH-1:0] out
    );

assign out = sel ? in1 : in0 ;

endmodule

module mux4 #(parameter WIDTH=32)
   (
    input [1:0] sel,
    input [WIDTH-1:0] in0,in1,in2,in3,
    output reg [WIDTH-1:0] out
    );
always @ (*)
  case (sel)
    2'b00: out = in0;
    2'b01: out = in1;
    2'b10: out = in2;
    2'b11: out = in3;
  endcase
endmodule


module mux8 #(parameter WIDTH=32) (
    input [2:0] sel,
    input [WIDTH-1:0] in0,in1,in2,in3,in4,in5,in6,in7,
    output reg [WIDTH-1:0] out
    );
always @ (*)
    case (sel)
    3'b000: out = in0;
    3'b001: out = in1;
    3'b010: out = in2;
    3'b011: out = in3;
    3'b100: out = in4;
    3'b101: out = in5;
    3'b110: out = in6;
    3'b111: out = in7;
    endcase
endmodule

module mux16 #(parameter WIDTH=32) (
    input [3:0] sel,
    input [WIDTH-1:0] in00,in01,in02,in03,in04,in05,in06,in07,
    input [WIDTH-1:0] in08,in09,in10,in11,in12,in13,in14,in15,
    output reg [WIDTH-1:0] out
    );
always @ (*)
    case (sel)
    4'b0000: out = in00;
    4'b0001: out = in01;
    4'b0010: out = in02;
    4'b0011: out = in03;
    4'b0100: out = in04;
    4'b0101: out = in05;
    4'b0110: out = in06;
    4'b0111: out = in07;
    4'b1000: out = in08;
    4'b1001: out = in09;
    4'b1010: out = in10;
    4'b1011: out = in11;
    4'b1100: out = in12;
    4'b1101: out = in13;
    4'b1110: out = in14;
    4'b1111: out = in15;
    endcase
endmodule
module register #(parameter WIDTH=32) (
    input clk,
    input en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
    );

reg [WIDTH-1:0] data;
initial data = 0;
always @ (posedge clk)
    if (en)
        data <= din;
assign dout = data;
endmodule

