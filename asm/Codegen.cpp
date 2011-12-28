/*
 * Copyright (c) 2011 Travis Geiselbrecht
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

extern void yyerror(const char *str);

enum {
	OP_ADD,
	OP_SUB,
	OP_AND,
	OP_OR,
	OP_XOR,
	OP_LSL,
	OP_LSR,
	OP_ASR,
	OP_SLT,
	OP_CLT,
	OP_SLTE,
	OP_CLTE,
	OP_SEQ,
	OP_CEQ,
	OP_LI,
	OP_LDR,
	OP_STR,
	OP_BZ,
	OP_BNZ,
	OP_B,
	OP_BL,

	OP_MOV,
	OP_PUSH,
	OP_POP
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
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "and", OP_AND));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "or", OP_OR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "xor", OP_XOR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "lsl", OP_LSL));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "lsr", OP_LSR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "asr", OP_ASR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "slt", OP_SLT));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "clt", OP_CLT));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "slte", OP_SLTE));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "clte", OP_CLTE));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "seq", OP_SEQ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "ceq", OP_CEQ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "li", OP_LI));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "ldr", OP_LDR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "str", OP_STR));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "bz", OP_BZ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "bnz", OP_BNZ));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "b", OP_B));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "bl", OP_BL));

	/* pseudo instructions */
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "mov", OP_MOV));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "push", OP_PUSH));
	symtab->AddSymbol(new Sym(Sym::KEYWORD, "pop", OP_POP));
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
	std::cout << "Addlabel: " << *s << std::endl;

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
		case OP_ADD:  i |= (0x0 << 10); goto alucommon; \
		case OP_SUB:  i |= (0x1 << 10); goto alucommon; \
		case OP_AND:  i |= (0x2 << 10); goto alucommon; \
		case OP_OR:   i |= (0x3 << 10); goto alucommon; \
		case OP_XOR:  i |= (0x4 << 10); goto alucommon; \
		case OP_LSL:  i |= (0x5 << 10); goto alucommon; \
		case OP_LSR:  i |= (0x6 << 10); goto alucommon; \
		case OP_ASR:  i |= (0x7 << 10); goto alucommon; \
		case OP_CLT:  i |= (0x8 << 10); goto alucommon; \
		case OP_SLT:  i |= (0x9 << 10); goto alucommon; \
		case OP_CLTE: i |= (0xa << 10); goto alucommon; \
		case OP_SLTE: i |= (0xb << 10); goto alucommon; \
		case OP_CEQ:  i |= (0xc << 10); goto alucommon; \
		case OP_SEQ:  i |= (0xd << 10); goto alucommon

void Codegen::Emit3Addr(Sym *ins, Reg r1, Reg r2, Reg r3)
{
	std::cout << "3addr: " << ins->GetName() << " " << r1 << ", " << r2 << ", " << r3 << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		ALUOP_OPTABLE;
			// common form
alucommon:
			i |= (1 << 9) | (r1.num << 0) | (r2.num << 3) | (r3.num << 6);
			break;
		default:
			yyerror("syntax error");
			return;
	}

	EmitInstruction(i);
}

void Codegen::Emit3Addr(Sym *ins, Reg r1, Reg r2, int imm)
{
	std::cout << "3addr: " << ins->GetName() << " " << r1 << ", " << r2 << ", #" << imm << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		ALUOP_OPTABLE;
			// common form
alucommon:
			// patch up lsl/lsr/asr to treat 0 immedate as 8
			switch (ins->GetOpcode()) {
				case OP_LSL:
				case OP_LSR:
				case OP_ASR:
					if (imm == 8)
						imm = 0;
					break;
			}

			// check range of immediate
			if (!inrange_unsigned(imm, 3)) {
				yyerror("imm3 out of range");
				return;
			}

			// emit the immediate
			i |= (0 << 9) | (r1.num << 0) | (r2.num << 3) | ((imm & 0x7) << 6);

			break;
		default:
			yyerror("syntax error");
			return;
	}

	EmitInstruction(i);
}

void Codegen::Emit3Addr(Sym *ins, Reg r1, Reg r2, Sym *identifier)
{
	std::cout << "3addr: " << ins->GetName() << " " << r1 << ", " << r2 << ", " << *identifier << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		ALUOP_OPTABLE;
			// common form
alucommon:
			// emit the instruction, fix it up later
			i |= (0 << 9) | (r1.num << 0) | (r2.num << 3) | ((0 & 0x7) << 6);

			// add fixup
			AddFixup(identifier, curaddr, FIXUP_IMM3);

			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::Emit2Addr(Sym *ins, Reg r1, Reg r2)
{
	std::cout << "2addr: " << ins->GetName() << " " << r1 << ", " << r2 << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_MOV: // add r1, r2, #0
			i |= (0x0 << 10) | (0 <<9) | (0 << 6) | (r2.num << 3) | (r1.num << 0);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

static int fixup_branch_immediate(int *imm, unsigned int bitsize)
{
	if (*imm & 1) {
		yyerror("branch target not multiple of 2");
		return -1;
	}

	// make sure immediate is in range & aligned on powers of 2
	*imm /= 2;
	*imm -= 1;

	if (!inrange_signed(*imm, bitsize)) {
		yyerror("branch target out of bit range");
		return -1;
	}

	return 0;
}

void Codegen::Emit2Addr(Sym *ins, Reg r1, int imm)
{
	std::cout << "2addr: " << ins->GetName() << " " << r1 << ", #" << imm << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_LI:
			i |= (0x7 << 12) | (r1.num << 0);

			// make sure immediate is in range
			if (!inrange_signed(imm, 9)) {
				yyerror("imm9 out of range");
				return;
			}

			i |= ((unsigned int)imm & 0x1ff) << 3;
			break;
		case OP_BZ:
			i |= (0x8 << 12);
			goto shared_bz;
		case OP_BNZ:
			i |= (0x9 << 12);
shared_bz:
			i |= (r1.num << 0);

			if (fixup_branch_immediate(&imm, 9) < 0)
				return;

			i |= ((unsigned int )imm & 0x1ff) << 3;
			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::Emit2Addr(Sym *ins, Reg r1, Sym *identifier)
{
	std::cout << "2addr: " << ins->GetName() << " " << r1 << ", " << *identifier << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_LI:
			i |= (0x7 << 12) | (r1.num << 0);

			AddFixup(identifier, curaddr, FIXUP_IMM9);
			break;
		case OP_BZ:
			i |= (0x8 << 12);
			goto shared_bz;
		case OP_BNZ:
			i |= (0x9 << 12);
shared_bz:
			i |= (r1.num << 0);

			AddFixup(identifier, curaddr, FIXUP_IMM9_REL);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::Emit1Addr(Sym *ins, Reg r1)
{
	std::cout << "1addr: " << ins->GetName() << " " << r1 << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_PUSH: {
			Reg sp; sp.num = Reg::SP;
			Sym s(Sym::KEYWORD, "str", OP_STR);

			EmitLoadStore2RegImmPostUpdate(&s, r1, sp, -4);
			break;
		}
		case OP_POP: {
			Reg sp; sp.num = Reg::SP;
			Sym s(Sym::KEYWORD, "ldr", OP_LDR);

			EmitLoadStore2RegImmPostIndexUpdate(&s, r1, sp, 4);
			break;
		}
		case OP_B:
		case OP_BL:
			i |= (0xb << 12) | (r1.num << 0);

			if (ins->GetOpcode() == OP_BL)
				i |= (1 << 11);
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::Emit1Addr(Sym *ins, int imm)
{
	std::cout << "1addr: " << ins->GetName() << " #" << imm << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_B:
			i |= (0xa << 12);

			if (fixup_branch_immediate(&imm, 12) < 0)
				return;
	
			i |= ((unsigned int)imm & 0xfff);
			break;
		case OP_BL:
			if (fixup_branch_immediate(&imm, 24) < 0)
				return;

			// top half of bl
			i |= (0xc << 12);
			i |= ((imm >> 12) & 0xfff); 
			EmitInstruction(i);

			// bottom half
			i = (0xd << 12);
			i |= (imm & 0xfff); 
			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::Emit1Addr(Sym *ins, Sym *identifier)
{
	std::cout << "1addr: " << ins->GetName() << " " << *identifier << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_B:
			i |= (0xa << 12);

			AddFixup(identifier, curaddr, FIXUP_IMM12_REL);
			break;
		case OP_BL:
			
			// top half of bl
			i |= (0xc << 12);
			AddFixup(identifier, curaddr, FIXUP_IMM12_TOP);

			// bottom half
			i = (0xd << 12);
			AddFixup(identifier, curaddr, FIXUP_IMM12_BOTTOM);
			break;
		default:
			yyerror("syntax error");
			return;
	}
	EmitInstruction(i);
}

void Codegen::EmitLoadStore2Reg(Sym *ins, Reg r1, Reg r2)
{
//	std::cout << "loadstore: " << *ins << " " << r1 << ",[" << r2 << "]" << std::endl;

	// these are just a special case of the immediate form with immediate 0
	EmitLoadStore2RegImm(ins, r1, r2, 0);
}

static int fixup_loadstore_immediate(int *imm, unsigned int bitsize)
{
	if (*imm & 3) {
		yyerror("load/store immediate not multiple of 4");
		return -1;
	}

	*imm /= 4;

	if (!inrange_signed(*imm, bitsize)) {
		yyerror("load/store immediate out of bit range");
		return -1;
	}

	return 0;
}

void Codegen::EmitLoadStore2RegImm(Sym *ins, Reg r1, Reg r2, int imm)
{
	std::cout << "loadstore: " << *ins << " " << r1 << ",[" << r2 << ", #" << imm << "]" << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_LDR:
			if (r2.num != Reg::PC) {
				// usual case
				i |= (0x4 << 12);
				goto ldrstr_common;
			}

			// special case for PC
			i |= (0x5 << 12);

			if (fixup_loadstore_immediate(&imm, 12) < 0)
				return;

			i |= (imm & 0x1ff) << 3;
			break;
		case OP_STR:
			i |= (0x6 << 12);
ldrstr_common:
			i |= (0 << 6) | (r2.num << 3) | (r1.num << 0);
			
			if (fixup_loadstore_immediate(&imm, 5) < 0)
				return;

			i |= (imm & 0x1f) << 7;
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::EmitLoadStore2RegImmPostUpdate(Sym *ins, Reg r1, Reg r2, int imm)
{
	std::cout << "loadstore: " << *ins << " " << r1 << ",[" << r2 << ", #" << imm << "]+" << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_STR:
			i |= (0x6 << 12);
			i |= (1 << 6) | (r2.num << 3) | (r1.num << 0);
			
			if (fixup_loadstore_immediate(&imm, 5) < 0)
				return;

			i |= (imm & 0x1f) << 7;
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::EmitLoadStore2RegImmPostIndexUpdate(Sym *ins, Reg r1, Reg r2, int imm)
{
	std::cout << "loadstore: " << *ins << " " << r1 << ",[" << r2 << "], #" << imm << "+" << std::endl;

	uint16_t i = 0;
	switch (ins->GetOpcode()) {
		case OP_LDR:
			i |= (0x4 << 12);
			i |= (1 << 6) | (r2.num << 3) | (r1.num << 0);
			
			if (fixup_loadstore_immediate(&imm, 5) < 0)
				return;

			i |= (imm & 0x1f) << 7;
			break;
		default:
			yyerror("syntax error");
			return;

	}

	EmitInstruction(i);
}

void Codegen::EmitInstruction(uint16_t ins)
{
//	printf("0x%08llx: 0x%04hx\n", curaddr, ins);

	curaddr = out->Append(ins);
}

void Codegen::FixupPass()
{
	printf("fixup pass...\n");

	for (fixupIterator i =  fixups.begin(); i != fixups.end(); i++) {
		Fixup *f = *i;

		printf("\tfixup %p: type %d, addr 0x%llx, identifier '%s'\n", f, f->type, f->addr, f->identifier->GetName().c_str());
		Label *lab = LookupLabel(f->identifier->GetName());
		if (!lab) {
			fprintf(stderr, "error looking up label %s\n", f->identifier->GetName().c_str());
			continue;
		}
		printf("\t\tlabel at address 0x%llx\n", lab->addr);

		uint16_t ins;
		uint32_t imm;

		// most cases, the immediate is the label of the address
		imm = lab->addr;

		switch (f->type) {
			case FIXUP_IMM3:
				// can imm fit
				if ((imm & 0x7) != imm) {
					fprintf(stderr, "imm3 out of range\n");
					break;
				}

				out->ReadAt(f->addr, &ins);
				ins |= ((imm & 0x7) << 6);
				out->WriteAt(f->addr, ins);
				break;
			case FIXUP_IMM9_REL:
				imm = imm - f->addr - 2; // calculate the relative address
				imm = (int32_t)imm >> 1; // all of the imm9 rels are aligned on boundaries of 2
				// fallthrough
			case FIXUP_IMM9:
				// can imm fit
				if (!inrange_signed(imm, 9)) {
					fprintf(stderr, "imm9 out of range\n");
					break;
				}

				out->ReadAt(f->addr, &ins);
				ins |= ((imm & 0x1ff) << 3);
				out->WriteAt(f->addr, ins);
				break;
			case FIXUP_IMM12_REL:
//				printf("IMM12_REL: faddr 0x%x, imm 0x%x\n", f->addr, imm);
				imm = imm - f->addr - 2; // calculate the relative address
				imm = (int32_t)imm >> 1; // all of the imm12 rels are aligned on boundaries of 2
				goto imm12;
			case FIXUP_IMM12_TOP:
				imm = imm >> 12;
				goto imm12;
			case FIXUP_IMM12_BOTTOM:
				imm = imm & 0xfff;
				goto imm12;
imm12:
				// can imm fit
				if (!inrange_signed(imm, 12)) {
					fprintf(stderr, "imm12 out of range\n");
					break;
				}

				out->ReadAt(f->addr, &ins);
				ins |= (imm & 0xfff);
				out->WriteAt(f->addr, ins);
				break;
			default:
				fprintf(stderr, "unhandled fixup type %d\n", f->type);
		}
	}

	printf("done with fixup pass\n");
}


