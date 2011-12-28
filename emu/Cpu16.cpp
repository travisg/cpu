#include <cstring>
#include <cassert>

#include "Cpu16.h"

/* bit manipulation macros */
#define BIT(x, bit) ((x) & (1 << (bit)))
#define BIT_SHIFT(x, bit) (((x) >> (bit)) & 1)
#define BITS(x, high, low) ((x) & (((1<<((high)+1))-1) & ~((1<<(low))-1)))
#define BITS_SHIFT(x, high, low) (((x) >> (low)) & ((1<<((high)-(low)+1))-1))
#define BIT_SET(x, bit) (((x) & (1 << (bit))) ? 1 : 0)

typedef uint32_t word;
typedef uint16_t hword;
typedef uint8_t byte;

#define SP 6
#define LR 7

Cpu16::Cpu16()
{
}

Cpu16::~Cpu16()
{
}

void Cpu16::Reset()
{
	memset(r, 0, sizeof(r));
	pc = 0;
}

void Cpu16::Run()
{
	uint64_t cycle = 0;

	assert(mem);

	for (;; cycle++) {
		word insword = mem->Read(pc & ~0x3);
		hword ins = (pc & 0x2) ? (insword) : (insword >> 16);
		
//		printf("PC 0x%08x ins 0x%04hx\n", pc, ins);

		pc += 2;

		switch (BITS_SHIFT(ins, 15, 12)) {
			case 0x0:
			case 0x1: { // alu ops
				uint Rd = BITS(ins, 2, 0);
				uint a = r[BITS_SHIFT(ins, 5, 3)];
				uint b = BIT(ins, 9) ? r[BITS_SHIFT(ins, 8, 6)] : BITS_SHIFT(ins, 8, 6);

				switch (BITS_SHIFT(ins, 12, 10)) {
					case 0: // add
						r[Rd] = a + b;
						break;
					case 1: // sub
						r[Rd] = a - b;
						break;
					case 2: // and
						r[Rd] = a & b;
						break;
					case 3: // or
						r[Rd] = a | b;
						break;
					case 4: // xor
						r[Rd] = a ^ b;
						break;
					case 5: // lsl
						r[Rd] = a << b;
						break;
					case 6: // lsr
						r[Rd] = a >> b;
						break;
					case 7: // asr
						// XXX shift in the top bit
						r[Rd] = a >> b;
						break;
				}
				break;
			}
			case 0x4: { // ldr
				uint Rd = BITS(ins, 2, 0);
				uint Ra = BITS_SHIFT(ins, 5, 3);
				uint imm = BITS_SHIFT(ins, 11, 7);
				// sign extend
				if (BIT(imm, 4))
					imm |= 0xffffffff << 5;

				// offsets are in units of 4
				imm <<= 2;

				// do the memory read
				uint32_t addr = r[Ra] + (int32_t)imm;
				word val = mem->Read(addr);

				r[Rd] = val;

				// do writeback
				if (BIT(ins, 6))
					r[Ra] = addr;
				break;
			}
			case 0x5: { // ldr pc relative
				uint Rd = BITS(ins, 2, 0);
				uint imm = BITS_SHIFT(ins, 11, 3);
				// sign extend
				if (BIT(imm, 8))
					imm |= 0xffffffff << 9;

				// offsets are in units of 4
				imm <<= 2;

				// do the memory read
				uint32_t addr = (pc & ~0x3) + (int32_t)imm;
				word val = mem->Read(addr);

				r[Rd] = val;
				break;
			}
			case 0x6: { // str
				uint Rd = BITS(ins, 2, 0);
				uint Ra = BITS_SHIFT(ins, 5, 3);
				uint imm = BITS_SHIFT(ins, 11, 7);
				// sign extend
				if (BIT(imm, 4))
					imm |= 0xffffffff << 5;

				// offsets are in units of 4
				imm <<= 2;

				// do the memory write
				uint32_t addr = r[Ra] + (int32_t)imm;
				mem->Write(addr, r[Rd]);

				// do writeback
				if (BIT(ins, 6))
					r[Ra] = addr;
				break;
			}
			case 0x7: { // li
				uint Rd = BITS(ins, 2, 0);
				uint imm = BITS_SHIFT(ins, 11, 3);
				// sign extend
				if (BIT(imm, 8))
					imm |= 0xffffffff << 9;

				r[Rd] = imm;
				break;
			}
			case 0x8:   // bz imm
				if (r[BITS(ins, 2, 0)] != 0)
					break;
				goto bz_shared;
			case 0x9: { // bnz imm
				if (r[BITS(ins, 2, 0)] == 0)
					break;
bz_shared:
				int imm = BITS_SHIFT(ins, 11, 3);
				// sign extend
				if (BIT(imm, 8))
					imm |= 0xffffffff << 9;

				// offsets are in unts of 2
				imm <<= 1;
				
//				printf("branching offset %d\n", imm);
				pc = pc + imm;
				break;
			}
			case 0xa: { // b imm
				int imm = BITS(ins, 11, 0);

				// sign extend
				if (BIT(imm, 11))
					imm |= 0xffffffff << 11;

				// offsets are in unts of 2
				imm <<= 1;

//				printf("branching offset %d\n", imm);
				pc = pc + imm;
				break;
			}
			case 0xb: { // b(l) r
				uint Rd = BITS(ins, 2, 0);

				word val = r[Rd];
				if (BIT(ins, 11)) { // L is set
					r[LR] = pc;
				}

				pc = val;
				break;
			}
			default:
				fprintf(stderr, "unhandled instruction 0x%hx\n", ins);
				return;
		}

//		printf("\tR0 0x%08x R1 0x%08x R2 0x%08x R3 0x%08x R4 0x%08x R5 0x%08x R6 0x%08x R7 0x%08x\n", 
//			r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7]);

		if (cycle == 1000000000)
			break;
	}
}

