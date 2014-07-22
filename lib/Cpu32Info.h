/*
 * Copyright (c) 2011-2013 Travis Geiselbrecht
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
        ZERO = 0,
        SP = 30,
        LR = 31,
        PC = 32
    };

    static const uint REG_COUNT = 32;

    static const uint FORM_SHIFT = 30;
    static const uint ALUOP_SHIFT = 26;
    static const uint RD_SHIFT = 21;
    static const uint RA_SHIFT = 16;
    static const uint RB_SHIFT = 11;
    static const uint IMM12_SHIFT = 4;
    static const uint IMM16_SHIFT = 0;
    static const uint IMM21_SHIFT = 0;
    static const uint LDRSTR_SIZE_SHIFT = 2;

    static const uint FORM_WIDTH = 2;
    static const uint ALUOP_WIDTH = 4;
    static const uint RD_WIDTH = 5;
    static const uint RA_WIDTH = 5;
    static const uint RB_WIDTH = 5;
    static const uint IMM12_WIDTH = 12;
    static const uint IMM16_WIDTH = 16;
    static const uint IMM21_WIDTH = 21;
    static const uint LDRSTR_SIZE_WIDTH = 2;

    static const uint FORM_IMM_UNSHIFTED = 0;
    static const uint FORM_REG_UNSHIFTED = 1;
    static const uint FORM_BRANCH_UNSHIFTED = 2;

    static const uint FORM_IMM = FORM_IMM_UNSHIFTED << FORM_SHIFT;
    static const uint FORM_REG = FORM_REG_UNSHIFTED << FORM_SHIFT;
    static const uint FORM_BRANCH = FORM_BRANCH_UNSHIFTED << FORM_SHIFT;

    static const uint OP_ALU_UNSHIFTED = 0;

#define FORM(x) ((x) << FORM_SHIFT)
#define ALU(x)  ((x) << ALUOP_SHIFT)
#define RD(x)   ((x) << RD_SHIFT)
#define RA(x)   ((x) << RA_SHIFT)
#define RB(x)   ((x) << RB_SHIFT)
#define IMM12(x)   (((unsigned int)(x) & ((1 << IMM12_WIDTH) - 1)) << IMM12_SHIFT)
#define IMM16(x)   (((unsigned int)(x) & ((1 << IMM16_WIDTH) - 1)) << IMM16_SHIFT)
#define IMM21(x)   (((unsigned int)(x) & ((1 << IMM21_WIDTH) - 1)) << IMM21_SHIFT)

    static const uint LDRSTR_W_BITPOS = 0;

    /* branch bits */
    static const uint BRANCH_R_BITPOS = 28;
    static const uint BRANCH_L_BITPOS = 27;
    static const uint BRANCH_Z_BITPOS = 26;

    static const uint BRANCH_R = 1<<BRANCH_R_BITPOS;
    static const uint BRANCH_L = 1<<BRANCH_L_BITPOS;
    static const uint BRANCH_Z = 1<<BRANCH_Z_BITPOS;

    static inline bool DecodeBranchR(uint32_t word) { return !!BIT(word, BRANCH_R_BITPOS); }
    static inline bool DecodeBranchL(uint32_t word) { return !!BIT(word, BRANCH_L_BITPOS); }
    static inline bool DecodeBranchZ(uint32_t word) { return !!BIT(word, BRANCH_Z_BITPOS); }

    static inline uint DecodeForm(uint32_t word) { return BITS_SHIFT(word, FORM_WIDTH + FORM_SHIFT - 1, FORM_SHIFT); }
    static inline uint DecodeALUOp(uint32_t word) { return BITS_SHIFT(word, ALUOP_WIDTH + ALUOP_SHIFT - 1, ALUOP_SHIFT); }
    static inline uint DecodeRd(uint32_t word) { return BITS_SHIFT(word, RD_WIDTH + RD_SHIFT - 1, RD_SHIFT); }
    static inline uint DecodeRa(uint32_t word) { return BITS_SHIFT(word, RA_WIDTH + RA_SHIFT - 1, RA_SHIFT); }
    static inline uint DecodeRb(uint32_t word) { return BITS_SHIFT(word, RB_WIDTH + RB_SHIFT - 1, RB_SHIFT); }
    static inline uint Decodeimm12(uint32_t word) { return BITS(word, IMM12_WIDTH + IMM12_SHIFT - 1, IMM12_SHIFT); }
    static inline int Decodeimm12_signed(uint32_t word) { uint imm12 = Decodeimm12(word); return (BIT(imm12, 11)) ? (0xfffff000 | imm12) : imm12; }
    static inline uint Decodeimm16(uint32_t word) { return BITS(word, IMM16_WIDTH + IMM16_SHIFT - 1, IMM16_SHIFT); }
    static inline int Decodeimm16_signed(uint32_t word) { uint imm16 = Decodeimm16(word); return (BIT(imm16, 15)) ? (0xffff0000 | imm16) : imm16; }
    static inline uint Decodeimm21(uint32_t word) { return BITS(word, IMM21_WIDTH + IMM21_SHIFT - 1, IMM21_SHIFT) << 2; }
    static inline int Decodeimm21_signed(uint32_t word) { uint imm21 = Decodeimm21(word); return (BIT(imm21, 21)) ? (0xffc00000 | imm21) : imm21; }
    static inline bool DecodeLdrStrW(uint32_t word) { return !!BIT(word, LDRSTR_W_BITPOS); }
    static inline uint DecodeLdrStrSize(uint32_t word) { return BITS(word, LDRSTR_SIZE_WIDTH + LDRSTR_SIZE_SHIFT - 1, LDRSTR_SIZE_SHIFT); }

    enum ALU_OPS {
        OP_ADD_NUM = 0b0000,
        OP_SUB_NUM = 0b0001,
        OP_AND_NUM = 0b0010,
        OP_OR_NUM  = 0b0011,
        OP_XOR_NUM = 0b0100,
        OP_LSL_NUM = 0b0101,
        OP_LSR_NUM = 0b0110,
        OP_ASR_NUM = 0b0111,
        OP_MVB_NUM = 0b1000,
        OP_MVT_NUM = 0b1001,
        OP_SEQ_NUM = 0b1010,
        OP_SLT_NUM = 0b1011,
        OP_SLTE_NUM = 0b1100,

        OP_LDR_NUM  = 0b1110,
        OP_STR_NUM  = 0b1111,
    };

    enum LDRSTR_SIZES {
        LDRSTR_SIZE_BYTE = 0b00,
        LDRSTR_SIZE_HALF = 0b01,
        LDRSTR_SIZE_WORD = 0b10,
    };
};

