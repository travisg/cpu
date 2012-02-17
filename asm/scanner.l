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
%{

#include <Codegen.h>
#include "Cpu.h"

%}

%option yylineno
%option nounput

NUM				[0-9]
HEXDIGIT		[A-Fa-f0-9]

%%

;[^\n\n]*		{ /* comment */ }

[rR]{NUM}+		{
					yylval.reg.num = atoi(yytext + 1);
					//printf("lex: found register %d from string '%s'\n", yylval.regindex, yytext);
					return TOK_REGISTER;
				}
pc|PC			{
					yylval.reg.num = Cpu32::PC; // program counter
					return TOK_REGISTER;
				}
lr|LR			{
					yylval.reg.num = Cpu32::LR;
					return TOK_REGISTER;
				}
sp|SP			{
					yylval.reg.num = Cpu32::SP;
					return TOK_REGISTER;
				}

[\(\)\{\}\~\=\,\[\]\+\-\*\/\&\|\^\<\>\!\#\:]    { return yytext[0]; }

-?{NUM}+		{
					yylval.intval = atoi(yytext);
					return TOK_INTEGER_LITERAL;
				}
0x{HEXDIGIT}+   {
					// Hexadecimal string
					yylval.intval = strtoul(yytext, NULL, 16);
					return TOK_INTEGER_LITERAL;
                }

[_[:alpha:]][_[:alnum:]]*	{
					//printf("lex: matching '%s'\n", yytext);
					Sym *s = gSymtab->Lookup(yytext);

					yylval.sym = s;
					if (s->GetType() == Sym::KEYWORD)
						return TOK_KEYWORD;
					else
						return TOK_IDENTIFIER;
				}


[ \t\r\n]		{ }

