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

#include <string>
#include <Codegen.h>
#include "Cpu32Info.h"

int enter_string = 0;

%}

%option yylineno
%option nounput

NUM				[0-9]
HEXDIGIT		[A-Fa-f0-9]

%x STRING
%%

\"				{
					BEGIN(STRING); 
					enter_string++; 
					yylval.str = new std::string;
				}

<STRING>\\b			{ *yylval.str += std::string("\b"); }
<STRING>\\n			{ *yylval.str += std::string("\n"); }
<STRING>\\r			{ *yylval.str += std::string("\r"); }
<STRING>\\t			{ *yylval.str += std::string("\t"); }

<STRING>[^\\\n\"]+ 	{ 
					*yylval.str += std::string(yytext);
					}

<STRING>\n		{
					fprintf(stderr, "unterminated string constant\n");
				}

<STRING>\" 		{ 
					if (enter_string) {
						/* printf("string '%s'\n", yytext); */
						/*handle_this_dblquotes(yytext);  */
						BEGIN(INITIAL); /* revert back to normal */
						enter_string--; 
					} 
					return TOK_STRING;
				}

;[^\n\n]*		{ /* comment */ }

[rR]{NUM}+		{
					yylval.reg.num = atoi(yytext + 1);
					//printf("lex: found register %d from string '%s'\n", yylval.regindex, yytext);
					return TOK_REGISTER;
				}
pc|PC			{
					yylval.reg.num = Cpu32Info::PC; // program counter
					return TOK_REGISTER;
				}
lr|LR			{
					yylval.reg.num = Cpu32Info::LR;
					return TOK_REGISTER;
				}
sp|SP			{
					yylval.reg.num = Cpu32Info::SP;
					return TOK_REGISTER;
				}

[\(\)\{\}\~\=\,\[\]\+\-\*\/\&\|\^\<\>\!\#\:]    { return yytext[0]; }

#-?{NUM}+		{
					yylval.intval = atoi(yytext + 1);
					return TOK_INTEGER_LITERAL;
				}
#0x{HEXDIGIT}+   {
					// Hexadecimal string
					yylval.intval = strtoul(yytext + 1, NULL, 16);
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

.word			{ return TOK_WORD; }
.asciiz			{ return TOK_ASCIIZ; }
.align			{ return TOK_ALIGN; }

[ \t\r\n]		{ }

