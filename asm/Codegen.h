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
#ifndef __CODEGEN_H
#define __CODEGEN_H

#include <inttypes.h>
#include <ostream>
#include <list>

class Sym;
class Symtab;
class OutputFile;

struct Reg {
public:
	unsigned int num;

	enum {
		SP = 6,
		LR = 7,
		PC = 8
	};
};

// internal list of labels
struct Label;
typedef std::list<Label *> labelList;
typedef std::list<Label *>::iterator labelIterator;

// internal list of fixups
struct Fixup;
typedef std::list<Fixup *> fixupList;
typedef std::list<Fixup *>::iterator fixupIterator;

class Codegen {
public:
	Codegen();
	virtual ~Codegen();

	void InitSymtab(Symtab *tab);

	void AddLabel(Sym *s);
	void Emit3Addr(Sym *ins, Reg r1, Reg r2, Reg r3);
	void Emit3Addr(Sym *ins, Reg r1, Reg r2, int imm);
	void Emit3Addr(Sym *ins, Reg r1, Reg r2, Sym *identifier);
	void Emit2Addr(Sym *ins, Reg r1, Reg r2);
	void Emit2Addr(Sym *ins, Reg r1, int imm);
	void Emit2Addr(Sym *ins, Reg r1, Sym *identifier);
	void Emit1Addr(Sym *ins, Reg r1);
	void Emit1Addr(Sym *ins, int imm);
	void Emit1Addr(Sym *ins, Sym *identifier);
	void EmitLoadStore2Reg(Sym *ins, Reg r1, Reg r2);
	void EmitLoadStore2RegImm(Sym *ins, Reg r1, Reg r2, int imm);
	void EmitLoadStore2RegImmPostUpdate(Sym *ins, Reg r1, Reg r2, int imm);
	void EmitLoadStore2RegImmPostIndexUpdate(Sym *ins, Reg r1, Reg r2, int imm);

	void SetOutput(OutputFile *f);

	void FixupPass();

	enum fixupType {
		FIXUP_IMM3,
		FIXUP_IMM5,
		FIXUP_IMM9,
		FIXUP_IMM9_REL,
		FIXUP_IMM12_REL,
		FIXUP_IMM12_TOP,
		FIXUP_IMM12_BOTTOM,
	};

protected:
	void EmitInstruction(uint16_t ins);
	
	Label *LookupLabel(const std::string &name);

	Fixup *AddFixup(Sym *identifier, off_t addr, fixupType type);

private:

	Symtab *symtab;
	OutputFile *out;
	off_t curaddr;

	labelList labels;
	fixupList fixups;
};

extern Codegen *gCodegen;

inline std::ostream& operator<<(std::ostream& o, const Reg &r)
{
	if (r.num == 8)
		o << "pc";
	else
		o << "r" << r.num;
	return o;
}

#endif

