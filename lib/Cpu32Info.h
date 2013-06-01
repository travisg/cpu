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
#pragma once

#include <inttypes.h>
#include <sys/types.h>
#include "bits.h"

/* info and helper routines for the cpu32 */
namespace Cpu32Info {
	// special registers
	enum {
		SP = 14,
		LR = 15,
		PC = 16
	};

	static const uint FORM_SHIFT = 30;
	static const uint OP_SHIFT = 28;
	static const uint RD_SHIFT = 24;
	static const uint ALUOP_SHIFT = 20;
	static const uint RA_SHIFT = 16;
	static const uint RB_SHIFT = 12;
	static const uint IMM16_SHIFT = 0;
	static const uint IMM22_SHIFT = 0;

	static const uint FORM_WIDTH = 2;
	static const uint OP_WIDTH = 2;
	static const uint RD_WIDTH = 4;
	static const uint ALUOP_WIDTH = 4;
	static const uint RA_WIDTH = 4;
	static const uint RB_WIDTH = 4;
	static const uint IMM16_WIDTH = 16;
	static const uint IMM22_WIDTH = 22;

	static const uint FORM_IMM_UNSHIFTED = 0;
	static const uint FORM_REG_UNSHIFTED = 1;
	static const uint FORM_BRANCH_UNSHIFTED = 2;

	static const uint FORM_IMM = FORM_IMM_UNSHIFTED << FORM_SHIFT;
	static const uint FORM_REG = FORM_REG_UNSHIFTED << FORM_SHIFT;
	static const uint FORM_BRANCH = FORM_BRANCH_UNSHIFTED << FORM_SHIFT;

	static const uint OP_ALU_UNSHIFTED = 0;
	static const uint OP_LOAD_UNSHIFTED = 2;
	static const uint OP_STORE_UNSHIFTED = 3;

#define FORM(x) ((x) << FORM_SHIFT)
#define OP(x)   ((x) << OP_SHIFT)
#define RD(x)   ((x) << RD_SHIFT)
#define ALU(x)  ((x) << ALUOP_SHIFT)
#define RA(x)   ((x) << RA_SHIFT)
#define RB(x)   ((x) << RB_SHIFT)
#define IMM16(x)   (((unsigned int)(x) & ((1 << IMM16_WIDTH) - 1)) << IMM16_SHIFT)
#define IMM22(x)   (((unsigned int)(x) & ((1 << IMM22_WIDTH) - 1)) << IMM22_SHIFT)

	static const uint BRANCH_R_BITPOS = 29;
	static const uint BRANCH_C_BITPOS = 28;
	static const uint BRANCH_L_BITPOS = 23;
	static const uint BRANCH_Z_BITPOS = 22;

	static const uint BRANCH_R = 1<<BRANCH_R_BITPOS;
	static const uint BRANCH_C = 1<<BRANCH_C_BITPOS;
	static const uint BRANCH_L = 1<<BRANCH_L_BITPOS;
	static const uint BRANCH_Z = 1<<BRANCH_Z_BITPOS;

    static inline bool DecodeBranchR(uint32_t word) { return !!BIT(word, BRANCH_R_BITPOS); }
    static inline bool DecodeBranchC(uint32_t word) { return !!BIT(word, BRANCH_C_BITPOS); }
    static inline bool DecodeBranchL(uint32_t word) { return !!BIT(word, BRANCH_L_BITPOS); }
    static inline bool DecodeBranchZ(uint32_t word) { return !!BIT(word, BRANCH_Z_BITPOS); }

	static const uint LOADSTORE_PC_BITPOS = 16;

	static const uint LOADSTORE_PC = 1<<LOADSTORE_PC_BITPOS;

    static inline bool DecodeLoadStorePC(uint32_t word) { return !!BIT(word, LOADSTORE_PC_BITPOS); }

	static inline uint DecodeForm(uint32_t word) { return BITS_SHIFT(word, FORM_WIDTH + FORM_SHIFT - 1, FORM_SHIFT); }
	static inline uint DecodeOp(uint32_t word) { return BITS_SHIFT(word, OP_WIDTH + OP_SHIFT - 1, OP_SHIFT); }
	static inline uint DecodeRd(uint32_t word) { return BITS_SHIFT(word, RD_WIDTH + RD_SHIFT - 1, RD_SHIFT); }
	static inline uint DecodeALUOp(uint32_t word) { return BITS_SHIFT(word, ALUOP_WIDTH + ALUOP_SHIFT - 1, ALUOP_SHIFT); }
	static inline uint DecodeRa(uint32_t word) { return BITS_SHIFT(word, RA_WIDTH + RA_SHIFT - 1, RA_SHIFT); }
	static inline uint DecodeRb(uint32_t word) { return BITS_SHIFT(word, RB_WIDTH + RB_SHIFT - 1, RB_SHIFT); }
	static inline uint Decodeimm16(uint32_t word) { return BITS(word, IMM16_WIDTH + IMM16_SHIFT - 1, IMM16_SHIFT); }
	static inline int Decodeimm16_signed(uint32_t word) { uint imm16 = Decodeimm16(word); return (BIT(imm16, 15)) ? (0xffff0000 | imm16) : imm16; }
	static inline uint Decodeimm22(uint32_t word) { return BITS(word, IMM22_WIDTH + IMM22_SHIFT - 1, IMM22_SHIFT) << 2; }
	static inline int Decodeimm22_signed(uint32_t word) { uint imm22 = Decodeimm22(word); return (BIT(imm22, 21)) ? (0xffc00000 | imm22) : imm22; }

	enum ALU_OPS {
		OP_ADD_NUM = 0,
		OP_SUB_NUM,
		OP_RSB_NUM,
		OP_AND_NUM,
		OP_OR_NUM,
		OP_XOR_NUM,
		OP_LSL_NUM,
		OP_LSR_NUM,
		OP_ASR_NUM,
		OP_MOV_NUM,
		OP_MVB_NUM,
		OP_MVT_NUM,
		OP_SEQ_NUM,
		OP_SLT_NUM,
		OP_SLTE_NUM,
		OP_UNUSED_NUM,
	};
};

