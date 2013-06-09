/*
 * Copyright (c) 2013 Travis Geiselbrecht
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
module top(
    //////// CLOCK //////////
input                   CLOCK_50,
//input                 CLOCK2_50,
//input                 CLOCK3_50,
//input                 ENETCLK_25,

    //////// Sma //////////
//input                 SMA_CLKIN,
//output                SMA_CLKOUT,

    //////// LED //////////
output          [8:0]   LEDG,
output          [17:0]  LEDR,

    //////// KEY //////////
input           [3:0]   KEY,

    //////// SW //////////
input           [17:0]  SW,

    //////// SEG7 //////////
output          [6:0]   HEX0,
output          [6:0]   HEX1,
output          [6:0]   HEX2,
output          [6:0]   HEX3,
output          [6:0]   HEX4,
output          [6:0]   HEX5,
output          [6:0]   HEX6,
output          [6:0]   HEX7,

    //////// LCD //////////
//output                LCD_BLON,
//inout         [7:0]   LCD_DATA,
//output                LCD_EN,
//output                LCD_ON,
//output                LCD_RS,
//output                LCD_RW,

//////////// RS232 //////////
//output                UART_CTS,
//input                 UART_RTS,
input                   UART_RXD,
output                  UART_TXD,

//////////// PS2 //////////
//inout                 PS2_CLK,
//inout                 PS2_DAT,
//inout                 PS2_CLK2,
//inout                 PS2_DAT2,

//////////// SDCARD //////////
//output                SD_CLK,
//inout                 SD_CMD,
//inout         [3:0]   SD_DAT,
//input                 SD_WP_N,

//////////// VGA //////////
//output        [7:0]   VGA_B,
//output                VGA_BLANK_N,
//output                VGA_CLK,
//output        [7:0]   VGA_G,
//output                VGA_HS,
//output        [7:0]   VGA_R,
//output                VGA_SYNC_N,
//output                VGA_VS,

//////////// Audio //////////
//input                 AUD_ADCDAT,
//inout                 AUD_ADCLRCK,
//inout                 AUD_BCLK,
//output                AUD_DACDAT,
//inout                 AUD_DACLRCK,
//output                AUD_XCK,

//////////// I2C for EEPROM //////////
//output                EEP_I2C_SCLK,
//inout                 EEP_I2C_SDAT,

//////////// I2C for Audio and Tv-Decode //////////
//output                I2C_SCLK,
//inout                 I2C_SDAT,

//////////// Ethernet 0 //////////
//output                ENET0_GTX_CLK,
//input                 ENET0_INT_N,
//output                ENET0_MDC,
//inout                 ENET0_MDIO,
//output                ENET0_RST_N,
//input                 ENET0_RX_CLK,
//input                 ENET0_RX_COL,
//input                 ENET0_RX_CRS,
//input         [3:0]   ENET0_RX_DATA,
//input                 ENET0_RX_DV,
//input                 ENET0_RX_ER,
//input                 ENET0_TX_CLK,
//output        [3:0]   ENET0_TX_DATA,
//output                ENET0_TX_EN,
//output                ENET0_TX_ER,
//input                 ENET0_LINK100,

//////////// Ethernet 1 //////////
//output                ENET1_GTX_CLK,
//input                 ENET1_INT_N,
//output                ENET1_MDC,
//inout                 ENET1_MDIO,
//output                ENET1_RST_N,
//input                 ENET1_RX_CLK,
//input                 ENET1_RX_COL,
//input                 ENET1_RX_CRS,
//input         [3:0]   ENET1_RX_DATA,
//input                 ENET1_RX_DV,
//input                 ENET1_RX_ER,
//input                 ENET1_TX_CLK,
//output        [3:0]   ENET1_TX_DATA,
//output                ENET1_TX_EN,
//output                ENET1_TX_ER,
//input                 ENET1_LINK100,

//////////// TV Decoder 1 //////////
//input                 TD_CLK27,
//input         [7:0]   TD_DATA,
//input                 TD_HS,
//output                TD_RESET_N,
//input                 TD_VS,


//////////// USB OTG controller //////////
//inout         [15:0]  OTG_DATA,
//output        [1:0]   OTG_ADDR,
//output                OTG_CS_N,
//output                OTG_WR_N,
//output                OTG_RD_N,
//input         [1:0]   OTG_INT,
//output                OTG_RST_N,
//input         [1:0]   OTG_DREQ,
//output        [1:0]   OTG_DACK_N,
//inout                 OTG_FSPEED,
//inout                 OTG_LSPEED,

//////////// IR Receiver //////////
//input                 IRDA_RXD,

//////////// SDRAM //////////
//output        [12:0]  DRAM_ADDR,
//output        [1:0]   DRAM_BA,
//output                DRAM_CAS_N,
//output                DRAM_CKE,
//output                DRAM_CLK,
//output                DRAM_CS_N,
//inout         [31:0]  DRAM_DQ,
//output        [3:0]   DRAM_DQM,
//output                DRAM_RAS_N,
//output                DRAM_WE_N,

//////////// SRAM //////////
//output        [19:0]  SRAM_ADDR,
//output                SRAM_CE_N,
//inout         [15:0]  SRAM_DQ,
//output                SRAM_LB_N,
//output                SRAM_OE_N,
//output                SRAM_UB_N,
//output                SRAM_WE_N,

//////////// Flash //////////
//output        [22:0]  FL_ADDR,
//output                FL_CE_N,
//inout         [7:0]   FL_DQ,
//output                FL_OE_N,
//output                FL_RST_N,
//input                 FL_RY,
//output                FL_WE_N,
//output                FL_WP_N,

//////////// GPIO //////////
inout           [35:0]  GPIO,

//////////// HSMC (LVDS) //////////

//input                 HSMC_CLKIN_N1,
//input                 HSMC_CLKIN_N2,
//input                 HSMC_CLKIN_P1,
//input                 HSMC_CLKIN_P2,
//input                 HSMC_CLKIN0,
//output                HSMC_CLKOUT_N1,
//output                HSMC_CLKOUT_N2,
//output                HSMC_CLKOUT_P1,
//output                HSMC_CLKOUT_P2,
//output                HSMC_CLKOUT0,
//inout         [3:0]   HSMC_D,
//input         [16:0]  HSMC_RX_D_N,
//input         [16:0]  HSMC_RX_D_P,
//output        [16:0]  HSMC_TX_D_N,
//output        [16:0]  HSMC_TX_D_P,

//////// EXTEND IO //////////
//inout           [6:0]   EX_IO,

/* put a dummy input here to satisfy the apparent requirement that there be something immediately before ); */
input                   _DUMMY
);

/* global regs */
reg rst;
reg halt;

initial begin
    rst <= 0;
    halt <= 0;
end

always @*
begin
    rst <= !KEY[0];
end

/* latch halt on the negedge of the main clock to keep it from glitching the clock
   if you hit the key in the middle of an up phase */
always @(negedge CLOCK_50)
begin
    if (!KEY[1]) begin
        halt <= 1;
    end else begin
        halt <= 0;
    end
end

/* clock generation */
wire slowclk = !halt ? CLOCK_50 : 0;

/* instantiate the cpu */
wire cpu_re;
wire cpu_we;
wire [29:0] memaddr;
wire [31:0] rmemdata;
wire [31:0] wmemdata;
wire [31:0] cpudebugout;

cpu cpu0(
    .clk(slowclk),
    .rst(rst),
    .mem_re(cpu_re),
    .mem_we(cpu_we),
    .memaddr(memaddr),
    .rmemdata(rmemdata),
    .wmemdata(wmemdata),

    .debugout(cpudebugout)
);

/* main memory */
wire mem_re = cpu_re && (memaddr[29] == 0);
wire mem_we = cpu_we && (memaddr[29] == 0);

syncmem mem0(
    .clk(slowclk),
    .re(mem_re),
    .we(mem_we),
    .addr(memaddr),
    .rdata(rmemdata),
    .wdata(wmemdata)
);

/* uart */
wire uart_re = cpu_re && (memaddr[29:14] == 16'b1000000000000000);
wire uart_we = cpu_we && (memaddr[29:14] == 16'b1000000000000000);

uart uart0(
    .clk(slowclk),
    .rst(rst),

    .hwtx(UART_TXD),
    .hwrx(UART_RXD),

    .addr(memaddr[0]),
    .re(uart_re),
    .we(uart_we),
    .wdata(wmemdata),
    .rdata(rmemdata),

    .rxchar(),
    .rxvalid()
    );

/* debug register */
wire debuglatch_we = cpu_we && (memaddr[29:14] == 16'b1000000000000001);

reg[31:0] debuglatch;
always @(posedge slowclk) begin
    if (debuglatch_we) begin
        debuglatch <= wmemdata;
    end
end


//`define WITH_SRAM
`ifdef WITH_SRAM
assign SRAM_UB_N = 0;
assign SRAM_LB_N = 0;

wire read_sync;
wire write_sync;

integer addr;

reg [1:0] retest;
always @(negedge slowclk) begin
    retest <= retest + 1;
end

always @(posedge read_sync or posedge write_sync) begin
    addr <= addr + 1;
end

sramcontroller sram(
    .clk(slowclk),
    .addr(addr),
    .indata(0),
    .re(retest[1]),
    .we(retest[0]),
    .read_sync(read_sync),
    .write_sync(write_sync),

    .memclk(memclk),
    .sram_addr(SRAM_ADDR),
    .sram_data(SRAM_DQ),
    .sram_ce(SRAM_CE_N),
    .sram_re(SRAM_OE_N),
    .sram_we(SRAM_WE_N)
);
`endif

reg[31:0] debugreg;

always @*
begin
    if (SW[1]) begin
        debugreg = cpudebugout;
    end else if (SW[1]) begin
        debugreg = rmemdata[31:0];
    end else if (SW[0]) begin
        debugreg = debuglatch[31:0];
    end else begin
        debugreg = memaddr[29:0];
    end
end

/* debug info */
seven_segment seg0(debugreg[3:0], HEX0);
seven_segment seg1(debugreg[7:4], HEX1);
seven_segment seg2(debugreg[11:8], HEX2);
seven_segment seg3(debugreg[15:12], HEX3);
seven_segment seg4(debugreg[19:16], HEX4);
seven_segment seg5(debugreg[23:20], HEX5);
seven_segment seg6(debugreg[27:24], HEX6);
seven_segment seg7(debugreg[31:28], HEX7);

assign LEDG[0] = rst;
assign LEDG[1] = slowclk;
assign LEDG[2] = mem_re;
assign LEDG[3] = mem_we;

assign LEDG[8:4] = 0;
assign LEDR = 0;

assign GPIO = 0;

//assign GPIO_1[0] = slowclk;
//assign GPIO_1[1] = mem_re;
//assign GPIO_1[2] = mem_we;
//assign GPIO_1[7:3] = memaddr[4:0];

//assign GPIO_1[15:8] = wmemdata[7:0];
//assign GPIO_1[8] = memclk;
//assign GPIO_1[9] = read_sync;
//assign GPIO_1[10] = write_sync;
//assign GPIO_1[11] = SRAM_CE_N;
//assign GPIO_1[12] = SRAM_OE_N;
//assign GPIO_1[15:13] = SRAM_ADDR[2:0];

//assign GPIO_1[0] = UART_TXD;
//assign GPIO_1[1] = UART_RXD;

endmodule

module syncmem(
    input clk,
    input re,
    input we,
    input [29:0] addr,
    output reg [31:0] rdata,
    input [31:0] wdata
);

reg [31:0] mem [0:4096];

initial begin
    $readmemh("../test/test2.asm.hex", mem);
end

always @(posedge clk) begin
    if (re)
        rdata <= mem[addr];
    else
        rdata <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    if (we)
        mem[addr] <= wdata;
end

endmodule
