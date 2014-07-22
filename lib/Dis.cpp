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
#include <sys/types.h>
#include <cstring>
#include <cstdio>
#include "Dis.h"
#include "bits.h"
#include "Cpu32Info.h"

using namespace Cpu32Info;

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
    uint aluop = DecodeALUOp(word);
    uint Rd = DecodeRd(word);
    uint Ra = DecodeRa(word);
    uint Rb = DecodeRb(word);
    int imm12_signed = Decodeimm12_signed(word);
    int imm16_signed = Decodeimm16_signed(word);
    int imm21_signed = Decodeimm21_signed(word);

    switch (form) {
        case FORM_IMM_UNSHIFTED: // imm alu/load/store
        case FORM_REG_UNSHIFTED: // reg alu/load/store
            switch (aluop) {
                case OP_ADD_NUM:  ADDSTR("add "); break;
                case OP_SUB_NUM:  ADDSTR("sub "); break;
                case OP_AND_NUM:  ADDSTR("and "); break;
                case OP_OR_NUM:   ADDSTR("or "); break;
                case OP_XOR_NUM:  ADDSTR("xor "); break;
                case OP_LSL_NUM:  ADDSTR("lsl "); break;
                case OP_LSR_NUM:  ADDSTR("lsr "); break;
                case OP_ASR_NUM:  ADDSTR("asr "); break;
                case OP_MVB_NUM:  ADDSTR("mvb "); break;
                case OP_MVT_NUM:  ADDSTR("mvt "); break;
                case OP_SEQ_NUM:  ADDSTR("seq "); break;
                case OP_SLT_NUM:  ADDSTR("slt "); break;
                case OP_SLTE_NUM: ADDSTR("slte "); break;
                case OP_LDR_NUM:  ADDSTR("ldr"); goto loadstore_shared;
                case OP_STR_NUM:  ADDSTR("str"); goto loadstore_shared;
                default: goto undefined;
            }

            ADDREG(Rd);
            ADDSTR(", ");

            ADDREG(Ra);
            ADDSTR(", ");

            if (form == FORM_IMM_UNSHIFTED) { // imm
                ADDSTR("#");
                ADDNUM(imm16_signed);
            } else {
                ADDREG(Rb);
            }
            break;

loadstore_shared:
            switch (DecodeLdrStrSize(word)) {
                case LDRSTR_SIZE_BYTE: ADDSTR("b "); break;
                case LDRSTR_SIZE_HALF: ADDSTR("h "); break;
                case LDRSTR_SIZE_WORD: ADDSTR(" "); break;
                default: goto undefined;
            }

            ADDREG(Rd);
            ADDSTR(" [");
            ADDREG(Ra);
            ADDSTR(" + ");

            if (form == FORM_IMM_UNSHIFTED) { // imm
                ADDSTR("#");
                ADDNUM(imm12_signed);
            } else {
                ADDREG(Rb);
            }
            ADDSTR("]");

            if (DecodeLdrStrW(word)) {
                ADDSTR("!");
            }
            break;
        case FORM_BRANCH_UNSHIFTED: // branch
            ADDSTR("b");
            if (DecodeBranchL(word))
                ADDSTR("l");

            if (DecodeBranchZ(word)) // zero conditional
                ADDSTR("z");
            else
                ADDSTR("nz");

            ADDSTR(" ");
            ADDREG(Rd);
            ADDSTR(", ");

            // register or label
            if (DecodeBranchR(word)) { // register
                ADDREG(Ra);
            } else { // label
                ADDSTR("#");
                ADDNUM(imm21_signed);

                // if they asked us, calculate the address of the target relative to the pc
                if (flags & DIS_FLAG_SHOWTARGET) {
                    uint32_t target;

                    target = curaddr + 4 + imm21_signed;

                    ADDSTR(" (");
                    ADDHEX(target);
                    ADDSTR(")");
                }
            }
            break;
        default: // undefined
            goto undefined;
    }

    return ins_str;

undefined:
    return "undefined";
}


