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
#include <string>

#include "Symtab.h"

Symtab::Symtab()
{
}

Symtab::~Symtab()
{
	for (symIterator i = symlist.begin(); i != symlist.end(); i++) {
		delete (*i);
		symlist.erase(i);
	}
}

Sym *Symtab::Lookup(const std::string &str)
{
	Sym *s;

	// see if it's already in the list
	for (symIterator i = symlist.begin(); i != symlist.end(); i++) {
		s = (*i);
		if (s->GetName() == str) {	
			return s;
		}
	}

	// if it's not in the list, it must be a new identifier
	s = new Sym(Sym::IDENTIFIER, str);

	symlist.push_back(s);

	return s;
}

void Symtab::AddSymbol(Sym *s)
{
	symlist.push_back(s);
}
