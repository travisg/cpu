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
#include <cstring>
#include <cstdio>
#include <cassert>

#include "Cpu32.h"
#include "bits.h"
#include "Cpu32Info.h"
#include "Dis.h"

#define TRACE 1
#define TRACEF(x...) do { if (TRACE) printf(x); } while (0)

#define CYCLE_TERM 20

typedef uint32_t word;
typedef uint16_t hword;
typedef uint8_t byte;

using namespace Cpu32Info;

Cpu32::Cpu32()
:   cycleLimit(0),
    verbose(false)
{
}

Cpu32::~Cpu32()
{
}

void Cpu32::Reset()
{
    memset(r, 0, sizeof(r));
    pc = 0;
    memset(dirtyReg, 0, sizeof(dirtyReg));
}

void Cpu32::SetCycleLimit(uint64_t limit)
{
    cycleLimit = limit;
}

void Cpu32::SetVerbose(bool _verbose)
{
    verbose = _verbose;
}


void Cpu32::Run()
{
    uint64_t cycle = 0;

    assert(mem);

    bool done = false;
    while (!done) {
        cycle++;
        word ins = mem->Read32(pc & ~0x3);

        if (verbose)
            printf("PC 0x%08x ins 0x%08x %s\n", pc, ins, Dis::Dissassemble(ins).c_str());

        pc += 4;

        switch (DecodeForm(ins)) {
            case FORM_IMM_UNSHIFTED: {
                word res;
                word b;

                b = Decodeimm16_signed(ins);
                goto alucommon;
            case FORM_REG_UNSHIFTED:

                b = r[DecodeRb(ins)];
alucommon:
                word a = r[DecodeRa(ins)];
                word Rd = DecodeRd(ins);
                switch (DecodeALUOp(ins)) {
                    case OP_ADD_NUM: res = a + b; break;
                    case OP_SUB_NUM: res = a - b; break;
                    case OP_AND_NUM: res = a & b; break;
                    case OP_OR_NUM:  res = a | b; break;
                    case OP_XOR_NUM: res = a ^ b; break;
                    case OP_LSL_NUM: res = a << b; break;
                    case OP_LSR_NUM: res = a >> b; break;
                    case OP_ASR_NUM: res = (int)a >> b; break;
                    case OP_MVB_NUM: res = a | (b & 0xffff); break;
                    case OP_MVT_NUM: res = a | (b << 16); break;
                    case OP_SEQ_NUM: res = (a == b) ? 1 : 0; break;
                    case OP_SLT_NUM: res = (a < b) ? 1 : 0; break;
                    case OP_SLTE_NUM: res = (a <= b) ? 1 : 0; break;
                    case OP_LDR_NUM:
                    case OP_STR_NUM: {
                        /* shared address generation and writeback */
                        if (DecodeForm(ins) == FORM_IMM_UNSHIFTED)
                            b = Decodeimm12_signed(ins);

                        /* look for PC as base */
                        if (DecodeRa(ins) == ZERO) {
                            a = pc;
                            if (DecodeLdrStrW(ins)) {
                                goto undefined;
                            }
                        }

                        word addr = a + b;

                        /* writeback */
                        if (DecodeLdrStrW(ins)) {
                            r[DecodeRa(ins)] = addr;
                            dirtyReg[DecodeRa(ins)] = true;
                        }

                        /* specific ldr/str behavior */
                        if (DecodeALUOp(ins) == OP_LDR_NUM) {
                            switch (DecodeLdrStrSize(ins)) {
                                case LDRSTR_SIZE_WORD: res = mem->Read32(addr); break;
                                case LDRSTR_SIZE_HALF: res = mem->Read16(addr); break;
                                case LDRSTR_SIZE_BYTE: res = mem->Read8(addr); break;
                                default: goto undefined;
                            }
                        } else {
                            switch (DecodeLdrStrSize(ins)) {
                                case LDRSTR_SIZE_WORD: mem->Write32(addr, r[Rd]); break;
                                case LDRSTR_SIZE_HALF: mem->Write16(addr, r[Rd]); break;
                                case LDRSTR_SIZE_BYTE: mem->Write8(addr, r[Rd]); break;
                                default: goto undefined;
                            }
                            Rd = 0; /* keeps it from writing back below */
                        }
                        break;
                    }
                    default:
                        goto undefined;
                }

                /* writeback, except for r0 */
                if (Rd != 0) {
                    r[Rd] = res;
                    dirtyReg[Rd] = true;
                }
                break;
            }

            case FORM_BRANCH_UNSHIFTED: {
                word target;

                if (DecodeBranchR(ins)) {
                    target = r[DecodeRa(ins)];
                } else {
                    target = pc + Decodeimm21_signed(ins);
                }
//              TRACEF("branch, target 0x%x\n", target);

                // test and drop out if it fails
                bool take = true;
                word test = r[DecodeRd(ins)];
                if (DecodeBranchZ(ins)) {
                    take = test == 0;
                } else {
                    take = test != 0;
                }


                if (take) {
//                  TRACEF("taking branch\n");
                    if (DecodeBranchL(ins)) {
                        r[LR] = pc;
                        dirtyReg[LR] = true;
                    }

                    /* look for infinite loop */
                    if (target == pc - 4) {
                        printf("infinite loop detected, exiting\n");
                        done = true;
                    }

                    pc = target;
                }

                break;
            }
            default:
                goto undefined;
        }

        if (verbose) {
            for (int i = 0; i < Cpu32Info::REG_COUNT; i++) {
                if ((i % 8) == 0)
                    TRACEF("\t");
                if (dirtyReg[i]) {
                    TRACEF("\x1b[1;34m");
                }
                TRACEF("R%-2d 0x%08x ", i, r[i]);
                if (dirtyReg[i]) {
                    TRACEF("\x1b[0m");
                }
                if (((i + 1) % 8) == 0)
                    TRACEF("\n");
                dirtyReg[i] = false;
            }
        }

//      if ((cycle % 1000000) == 0)
//          printf("%lld cycles\n", cycle);

        if (cycleLimit > 0 && cycle == cycleLimit)
            done = true;

        continue;

undefined:
        printf("UNDEFINED!\n");
    }
}

