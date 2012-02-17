#include <sys/types.h>
#include <cstring>
#include <cstdio>
#include "Dis.h"
#include "bits.h"

std::string Dis::Dissassemble(uint32_t word)
{
	char ins_str[256];
	memset(ins_str, 0, sizeof(ins_str));
	

#define ADDSTR(str) strncat(ins_str, str, sizeof(ins_str) - 1)
#define ADDNUM(num) do { \
	char _temp[16]; \
	snprintf(_temp, sizeof(_temp), "%d", num); \
	ADDSTR(_temp); \
} while(0)
#define ADDREG(num) do { ADDSTR("r"); ADDNUM(num); } while (0)

	// decode the instruction
	uint form = BITS_SHIFT(word, 31, 30);
	uint op = BITS_SHIFT(word, 29, 28);
	uint Rd = BITS_SHIFT(word, 27, 24);
	uint aluop = BITS_SHIFT(word, 23, 20);
	uint Ra = BITS_SHIFT(word, 19, 16);
	uint Rb = BITS_SHIFT(word, 15, 12);
	uint imm16 = BITS(word, 15, 0);
	int imm16_signed = (BIT(imm16, 15)) ? (0xffff0000 | imm16) : imm16;
	uint imm22 = BITS(word, 21, 0) << 2;
	int imm22_signed = (BIT(imm22, 21)) ? (0xffc00000 | imm22) : imm22;

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

				// XXX dont display this on mov and mvb
				ADDREG(Ra);
				ADDSTR(", ");
				if (form == 0) { // imm
					ADDSTR("#");
					ADDNUM(imm16_signed);
				} else {
					ADDREG(Rb);
				}
			} else if (op == 1 || op == 2) { // load/store
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
			}
			break;
		case 3: // undefined
			goto undefined;
	}



	return ins_str;

undefined:
	return "undefined";
}


