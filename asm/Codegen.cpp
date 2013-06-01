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
#include <inttypes.h>
#include <iostream>
#include <cstdio>

#include "Codegen.h"
#include "Symtab.h"
#include "Sym.h"
#include "OutputFile.h"
#include "util.h"

#include "Cpu32Info.h"
#include "Dis.h"

#define TRACE 0

using namespace Cpu32Info;

extern void yyerror(const char *str);

enum {
	OP_ADD,
	OP_SUB,
	OP_RSB,
	OP_AND,
	OP_OR,
	OP_XOR,
	OP_LSL,
	OP_LSR,
	OP_ASR,
	OP_MOV,
	OP_MVB,
	OP_MVT,
	OP_SLT,
	OP_SLTE,
	OP_SEQ,
	OP_LDR,
	OP_STR,
	OP_B,
	OP_BL,
	OP_BZ,
	OP_BNZ,
	OP_BLZ,
	OP_BLNZ,

	OP_MVN,
	OP_NOT,
	OP_LI
};

struct Label {
	Sym *sym;
	off_t addr;

	const std::string &GetName() const { return sym->GetName(); }
};

struct Fixup {
	Sym *identifier;
	off_t addr;

	Codegen::fixupType type;
};

Codegen::Codegen()
:	symtab(0),
	out(0),
	curaddr(0)
{
}

Codegen::~Codegen()
{
	labels.clear();
}

void Codegen::InitSymtab(Symtab *tab)
{
	symtab = tab;

	/* instructions */
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "add", OP_ADD));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "sub", OP_SUB));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "rsb", OP_RSB));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "and", OP_AND));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "or", OP_OR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "xor", OP_XOR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "lsl", OP_LSL));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "lsr", OP_LSR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "asr", OP_ASR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "mov", OP_MOV));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "mvb", OP_MVB));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "mvt", OP_MVT));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "slt", OP_SLT));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "slte", OP_SLTE));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "seq", OP_SEQ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "ldr", OP_LDR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "str", OP_STR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "b", OP_B));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "bz", OP_BZ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "bnz", OP_BNZ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "bl", OP_BL));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "blz", OP_BLZ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "blnz", OP_BLNZ));

	/* pseudo instructions */
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "mvn", OP_MVN));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "not", OP_NOT));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "li", OP_LI));
}

void Codegen::SetOutput(OutputFile *f)
{
	if (out)
		delete out;
	out = f;
}

Label *Codegen::LookupLabel(const std::string &name)
{
	for (labelIterator i = labels.begin(); i != labels.end(); i++) {
		if ((*i)->GetName() == name)
			return (*i);
	}

	return NULL;
}

void Codegen::AddLabel(Sym *s)
{
	if (TRACE) std::cout << "Addlabel: " << *s << std::endl;

	Label *lab = LookupLabel(s->GetName());
	if (lab) {
		fprintf(stderr, "label %s already emitted!\n", s->GetName().c_str());
		return;
	}

	lab = new Label();
	lab->sym = s;
	lab->addr = curaddr;

	labels.push_back(lab);
}

void Codegen::AddData(Sym *identifier)
{
	if (TRACE) std::cout << "AddData: " << *identifier << std::endl;

	AddFixup(identifier, curaddr, FIXUP_IMM32);
	curaddr = out->Append((uint32_t)0);
}

void Codegen::AddData(int literal)
{
	if (TRACE) std::cout << "AddData: " << literal << std::endl;

	curaddr = out->Append((uint32_t)literal);
}

void Codegen::AddData(const std::string &str)
{
	if (TRACE) std::cout << "AddData: '" << str << "'" << std::endl;

	curaddr = out->Align(4);
	curaddr = out->Append(str);
	curaddr = out->Align(4);
}

void Codegen::Align(int align)
{
	if (TRACE) std::cout << "Align: " << align << std::endl;

	if (align > 0)
		curaddr = out->Align(align);
}

void Codegen::Skip(int skip)
{
	if (TRACE) std::cout << "Skip: " << skip << std::endl;

	if (skip > 0)
		curaddr = out->Skip(skip);
}

Fixup *Codegen::AddFixup(Sym *identifier, off_t addr, fixupType type)
{
	Fixup *f;

	f = new Fixup();

	f->identifier = identifier;
	f->addr = addr;
	f->type = type;

	fixups.push_back(f);

	return f;
}

#define ALUOP_OPTABLE \
		case OP_ADD:  i |= ALU(OP_ADD_NUM); goto alucommon; \
		case OP_SUB:  i |= ALU(OP_SUB_NUM); goto alucommon; \
		case OP_RSB:  i |= ALU(OP_RSB_NUM); goto alucommon; \
		case OP_AND:  i |= ALU(OP_AND_NUM); goto alucommon; \
		case OP_OR:   i |= ALU(OP_OR_NUM); goto alucommon; \
		case OP_XOR:  i |= ALU(OP_XOR_NUM); goto alucommon; \
		case OP_LSL:  i |= ALU(OP_LSL_NUM); goto alucommon; \
		case OP_LSR:  i |= ALU(OP_LSR_NUM); goto alucommon; \
		case OP_ASR:  i |= ALU(OP_ASR_NUM); goto alucommon; \
		case OP_MOV:  i |= ALU(OP_MOV_NUM); goto alucommon; \
		case OP_MVB:  i |= ALU(OP_MVB_NUM); goto alucommon; \
		case OP_MVT:  i |= ALU(OP_MVT_NUM); goto alucommon; \
		case OP_SEQ:  i |= ALU(OP_SEQ_NUM); goto alucommon; \
		case OP_SLT:  i |= ALU(OP_SLT_NUM); goto alucommon; \
		case OP_SLTE: i |= ALU(OP_SLTE_NUM); goto alucommon

void Codegen::Emit3Addr(Sym *ins, Reg r1, Reg r2, Reg r3)
{
	if (TRACE) std::cout << "3addr: " << ins->GetName() << " " << r1 << ", " << r2 << ", " << r3 << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		ALUOP_OPTABLE;
			// common form
alucommon:
			i |= FORM_REG | OP(0) | RD(r1.num) | RA(r2.num) | RB(r3.num);
			break;
		default:
			yyerror("syntax error");
			return;
	}

	EmitInstruction(i);
}

void Codegen::Emit3Addr(Sym *ins, Reg r1, Reg r2, int imm)
{
	if (TRACE) std::cout << "3addr: " << ins->GetName() << " " << r1 << ", " << r2 << ", #" << imm << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		ALUOP_OPTABLE;
			// common form
alucommon:
#if 0
			// patch up lsl/lsr/asr to treat 0 immedate as 32
			switch (ins->GetOpcode()) {
				case OP_LSL:
				case OP_LSR:
				case OP_ASR:
					if (imm == 32)
						imm = 0;
					break;
			}
#endif

			// check range of immediate
			if (!inrange_signed(imm, 16)) {
				yyerror("imm16 out of range");
				return;
			}

			// emit the immediate
			i |= FORM_IMM | OP(0) | RD(r1.num) | RA(r2.num) | IMM16(imm);

			break;
		default:
			yyerror("syntax error");
			return;
	}

	EmitInstruction(i);
}

void Codegen::Emit3Addr(Sym *ins, Reg r1, Reg r2, Sym *identifier)
{
	if (TRACE) std::cout << "3addr: " << ins->GetName() << " " << r1 << ", " << r2 << ", " << *identifier << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		ALUOP_OPTABLE;
			// common form
alucommon:
			// emit the instruction, fix it up later
			i |= FORM_IMM | OP(0) | RD(r1.num) | RA(r2.num) | IMM16(0);

			// add fixup
			AddFixup(identifier, curaddr, FIXUP_IMM16);

			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::Emit2Addr(Sym *ins, Reg r1, Reg r2)
{
	if (TRACE) std::cout << "2addr: " << ins->GetName() << " " << r1 << ", " << r2 << std::endl;

	// MOV
	// MVB
	// MVN (pseudo)
	// NOT (pseudo)

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_MOV:
			i |= FORM_REG | OP(0) | ALU(OP_MOV_NUM) | RD(r1.num) | RA(0) | RB(r2.num);
			break;
		case OP_MVB:
			i |= FORM_REG | OP(0) | ALU(OP_MVB_NUM) | RD(r1.num) | RA(0) | RB(r2.num);
			break;
		case OP_MVN:
			i |= FORM_IMM | OP(0) | ALU(OP_RSB_NUM) | RD(r1.num) | RA(r2.num) | IMM16(0);
			break;
		case OP_NOT:
			i |= FORM_IMM | OP(0) | ALU(OP_XOR_NUM) | RD(r1.num) | RA(r2.num) | IMM16(0);
			break;
		case OP_BLNZ: // blnz r, r
			i |= BRANCH_L;
			goto shared_b;
		case OP_BLZ: // blz r, r
			i |= BRANCH_L;
		case OP_BZ: // bz  r, r
			i |= BRANCH_Z;
		case OP_BNZ: // bnz r, r
shared_b:
			i |= FORM_BRANCH | BRANCH_R | BRANCH_C | RD(r1.num) | RA(r2.num);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

static int fixup_branch_immediate(int *imm, unsigned int bitsize)
{
	if (*imm & 3) {
		yyerror("branch target not multiple of 4");
		return -1;
	}

	// make sure immediate is in range & aligned on powers of 4
	*imm /= 4;
	*imm -= 1;

	if (!inrange_signed(*imm, bitsize)) {
		yyerror("branch target out of bit range");
		return -1;
	}

	return 0;
}

void Codegen::Emit2Addr(Sym *ins, Reg r1, int imm)
{
	if (TRACE) std::cout << "2addr: " << ins->GetName() << " " << r1 << ", #" << imm << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_MOV:
			i |= FORM_IMM | OP(0) | ALU(OP_MOV_NUM) | RD(r1.num) | RA(0);

			// make sure immediate is in range
			if (!inrange_signed(imm, 16)) {
				yyerror("imm16 out of range");
				return;
			}

			i |= IMM16(imm);
			break;
		case OP_LI:
			if (inrange_signed(imm, 16)) {
				// we can use just mov
				i |= FORM_IMM | OP(0) | ALU(OP_MOV_NUM) | RD(r1.num) | RA(0);
				i |= IMM16(imm);
			} else if (inrange_unsigned(imm, 16)) {
				// we can use just mvb
				i |= FORM_IMM | OP(0) | ALU(OP_MVB_NUM) | RD(r1.num) | RA(0);
				i |= IMM16(imm);
			} else {
				// two instruction mvb/mvt
				i |= FORM_IMM | OP(0) | ALU(OP_MVB_NUM) | RD(r1.num) | RA(0);
				i |= IMM16(imm);
				EmitInstruction(i);

				i = FORM_IMM | OP(0) | ALU(OP_MVT_NUM) | RD(r1.num) | RA(r1.num);
				i |= IMM16(imm >> 16);
			}
			break;
		case OP_BLNZ: // blnz r, #imm
			i |= BRANCH_L;
			goto shared_b;
		case OP_BLZ: // blz r, #imm
			i |= BRANCH_L;
		case OP_BZ: // bz  r, #imm
			i |= BRANCH_Z;
		case OP_BNZ: // bnz r, #imm
shared_b:
			i |= FORM_BRANCH | BRANCH_C | RD(r1.num);
			if (fixup_branch_immediate(&imm, 22) < 0)
				return;

			i |= IMM22(imm);
			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::Emit2Addr(Sym *ins, Reg r1, Sym *identifier)
{
	if (TRACE) std::cout << "2addr: " << ins->GetName() << " " << r1 << ", " << *identifier << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_MOV:
			i |= FORM_IMM | OP(0) | ALU(OP_MOV_NUM) | RD(r1.num) | RA(0);

			AddFixup(identifier, curaddr, FIXUP_IMM16);
			break;
		case OP_LI:
			// two instruction mvb/mvt
			i |= FORM_IMM | OP(0) | ALU(OP_MVB_NUM) | RD(r1.num) | RA(0);
			AddFixup(identifier, curaddr, FIXUP_IMM32_BOT);
			EmitInstruction(i);

			i = FORM_IMM | OP(0) | ALU(OP_MVT_NUM) | RD(r1.num) | RA(r1.num);
			AddFixup(identifier, curaddr, FIXUP_IMM32_TOP);
			break;
		case OP_BLNZ: // blnz r, identifier
			i |= BRANCH_L;
			goto shared_b;
		case OP_BLZ: // blz r, identifier
			i |= BRANCH_L;
		case OP_BZ: // bz  r, identifier
			i |= BRANCH_Z;
		case OP_BNZ: // bnz r, identifier
shared_b:
			i |= FORM_BRANCH | BRANCH_C | RD(r1.num);
			AddFixup(identifier, curaddr, FIXUP_IMM22_REL);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::Emit1Addr(Sym *ins, Reg r1)
{
	if (TRACE) std::cout << "1addr: " << ins->GetName() << " " << r1 << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_BL:
			i |= BRANCH_L;
		case OP_B:
			i |= FORM_BRANCH | BRANCH_R | RA(r1.num);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::Emit1Addr(Sym *ins, int imm)
{
	if (TRACE) std::cout << "1addr: " << ins->GetName() << " #" << imm << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_BL:
			i |= BRANCH_L;
		case OP_B:
			if (fixup_branch_immediate(&imm, 22) < 0)
				return;

			i |= FORM_BRANCH | IMM22(imm);
			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::Emit1Addr(Sym *ins, Sym *identifier)
{
	if (TRACE) std::cout << "1addr: " << ins->GetName() << " " << *identifier << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_BL:
			i |= BRANCH_L;
		case OP_B:
			i |= FORM_BRANCH;

			AddFixup(identifier, curaddr, FIXUP_IMM22_REL);
			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

static int fixup_loadstore_immediate(int *imm, unsigned int bitsize)
{
#if 0
	if (*imm & 3) {
		yyerror("load/store immediate not multiple of 4");
		return -1;
	}

	*imm /= 4;
#endif
	if (!inrange_signed(*imm, bitsize)) {
		yyerror("load/store immediate out of bit range");
		return -1;
	}

	return 0;
}

void Codegen::EmitLoadStore2RegImm(Sym *ins, Reg r1, Reg r2, int imm)
{
	if (TRACE) std::cout << "loadstore: " << *ins << " " << r1 << ",[" << r2 << ", #" << imm << "]" << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_LDR:
			i |= OP(OP_LOAD_UNSHIFTED);
			goto ldrstr_common;
		case OP_STR:
			i |= OP(OP_STORE_UNSHIFTED);
ldrstr_common:
			i |= FORM_IMM | ALU(0) | RD(r1.num) | RA(r2.num);

			if (fixup_loadstore_immediate(&imm, 16) < 0)
				return;

			i |= IMM16(imm);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::EmitLoadStore3Reg(Sym *ins, Reg r1, Reg r2, Reg r3)
{
	if (TRACE) std::cout << "loadstore: " << *ins << " " << r1 << ",[" << r2 << ", " << r3 << "]" << std::endl;

	uint32_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_LDR:
			i |= OP(OP_LOAD_UNSHIFTED);
			goto ldrstr_common;
		case OP_STR:
			i |= OP(OP_STORE_UNSHIFTED);
ldrstr_common:
			i |= FORM_REG | ALU(0) | RD(r1.num) | RA(r2.num) | RB(r3.num);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::EmitInstruction(uint32_t ins)
{
//	printf("0x%08llx: 0x%08x\n", (unsigned long long)curaddr, ins);

	curaddr = out->Append(ins);
}

void Codegen::FixupPass()
{
//	printf("fixup pass...\n");

	for (fixupIterator i =  fixups.begin(); i != fixups.end(); i++) {
		Fixup *f = *i;

//		printf("\tfixup %p: type %d, addr 0x%llx, identifier '%s'\n", f, f->type, (unsigned long long)f->addr, f->identifier->GetName().c_str());
		Label *lab = LookupLabel(f->identifier->GetName());
		if (!lab) {
			fprintf(stderr, "error looking up label %s\n", f->identifier->GetName().c_str());
			continue;
		}
//		printf("\t\tlabel at address 0x%llx\n", (unsigned long long)lab->addr);

		uint32_t ins;
		uint32_t imm;

		// most cases, the immediate is the label of the address
		imm = lab->addr;

		switch (f->type) {
			case FIXUP_IMM16:
				// can imm fit
				if (!inrange_signed(imm, 16)) {
					fprintf(stderr, "imm16 out of range\n");
					break;
				}

				out->ReadAt(f->addr, &ins);
				ins |= IMM16(imm);
				out->WriteAt(f->addr, ins);
				break;
			case FIXUP_IMM22_REL:
				imm = imm - f->addr - 2; // calculate the relative address
				imm = (int32_t)imm >> 2; // all of the imm22 rels are aligned on boundaries of 4

				// can imm fit
				if (!inrange_signed(imm, 22)) {
					fprintf(stderr, "imm22 out of range\n");
					break;
				}

				out->ReadAt(f->addr, &ins);
				ins |= IMM22(imm);
				out->WriteAt(f->addr, ins);
				break;
			case FIXUP_IMM32:
				out->WriteAt(f->addr, imm);
				break;
			case FIXUP_IMM32_BOT:
				out->ReadAt(f->addr, &ins);
				ins |= IMM16(imm);
				out->WriteAt(f->addr, ins);
				break;
			case FIXUP_IMM32_TOP:
				out->ReadAt(f->addr, &ins);
				ins |= IMM16(imm >> 16);
				out->WriteAt(f->addr, ins);
				break;
			default:
				fprintf(stderr, "unhandled fixup type %d\n", f->type);
		}
	}

//	printf("done with fixup pass\n");
}

