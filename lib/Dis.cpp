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
#include <sys/types.h>
#include <cstring>
#include <cstdio>
#include "Dis.h"
#include "bits.h"
#include "Cpu.h"

using namespace Cpu32;

std::string Dis::Dissassemble(uint32_t word, uint flags, uint32_t curaddr)
{
	char ins_str[256];
	memset(ins_str, 0, sizeof(ins_str));

#define ADDSTR(str) strncat(ins_str, str, sizeof(ins_str) - 1)
#define ADDNUM(num) do { \
	char _temp[16]; \
	snprintf(_temp, sizeof(_temp), "%d", num); \
	ADDSTR(_temp); \
} while(0)
#define ADDHEX(num) do { \
	char _temp[16]; \
	snprintf(_temp, sizeof(_temp), "0x%x", num); \
	ADDSTR(_temp); \
} while(0)
#define ADDREG(num) do { ADDSTR("r"); ADDNUM(num); } while (0)

	// decode the instruction
	uint form = DecodeForm(word);
	uint op = DecodeOp(word);
	uint Rd = DecodeRd(word);
	uint aluop = DecodeALUOp(word);
	uint Ra = DecodeRa(word);
	uint Rb = DecodeRb(word);
	int imm16_signed = Decodeimm16_signed(word);
	int imm22_signed = Decodeimm22_signed(word);

	switch (form) {
		case 0: // imm alu/load/store
		case 1: // reg alu/load/store
			if (op == 0) { // aluops
				switch (aluop) {
					case 0: ADDSTR("add "); break;
					case 1: ADDSTR("sub "); break;
					case 2: ADDSTR("rsb "); break;
					case 3: ADDSTR("and "); break;
					case 4: ADDSTR("or "); break;
					case 5: ADDSTR("xor "); break;
					case 6: ADDSTR("lsl "); break;
					case 7: ADDSTR("lsr "); break;
					case 8: ADDSTR("asr "); break;
					case 9: ADDSTR("mov "); break;
					case 10: ADDSTR("mvb "); break;
					case 11: ADDSTR("mvt "); break;
					case 12: ADDSTR("slt "); break;
					case 13: ADDSTR("slte "); break;
					case 14: ADDSTR("seq "); break;
					default: goto undefined;
				}

				ADDREG(Rd);
				ADDSTR(", ");

				// don't display this on mov and mvb
				if (aluop != 9 && aluop != 10) {
					ADDREG(Ra);
					ADDSTR(", ");
				}

				if (form == 0) { // imm
					ADDSTR("#");
					ADDNUM(imm16_signed);
				} else {
					ADDREG(Rb);
				}
			} else if (op == 1) { // load/store
				ADDSTR("ldr ");
				goto loadstore_shared;
			} else if (op == 2) { // store
				ADDSTR("str ");

loadstore_shared:
				ADDREG(Rd);
				ADDSTR(", [");
				ADDREG(Ra);
				ADDSTR(", ");

				if (form == 0) { // imm
					ADDSTR("#");
					ADDNUM(imm16_signed);
				} else {
					ADDREG(Rb);
				}
				ADDSTR("]");
			} else { // undefined
				goto undefined;
			}
			break;
		case 2: // branch
			ADDSTR("b");
			if (BIT(word, 28))
				ADDSTR("l");

			if (BIT(word, 23)) { // conditional
				if (BIT(word, 22)) // negative conditional
					ADDSTR("nz");
				else
					ADDSTR("z");

				ADDSTR(" ");
				ADDREG(Rd);
				ADDSTR(", ");
			} else {
				ADDSTR(" ");
			}

			// register or label
			if (BIT(word, 29)) { // register
				ADDREG(Ra);
			} else { // label
				ADDSTR("#");
				ADDNUM(imm22_signed);

				// if they asked us, calculate the address of the target relative to the pc
				if (flags & DIS_FLAG_SHOWTARGET) {
					uint32_t target;

					target = curaddr + 4 + imm22_signed;

					ADDSTR(" (");
					ADDHEX(target);
					ADDSTR(")");
				}
			}
			break;
		case 3: // undefined
			goto undefined;
	}

	return ins_str;

undefined:
	return "undefined";
}


