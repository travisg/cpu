# vim: ts=4 sw=4 expandtab:

# lexer
tokens = (
    'NUM',
    'REGISTER',
    'DIRECTIVE',
    'ID',
    'STRING',
    'INSTRUCTION'
)

INSTRUCTIONS = (
    "add",
    "sub",
    "rsb",
    "and",
    "or",
    "xor",
    "lsl",
    "lsr",
    "asr",
    "mov",
    "mvb",
    "mvt",
    "slt",
    "slte",
    "seq",
    "ldr",
    "str",
    "b",
    "bz",
    "bnz",
    "bl",
    "blz",
    "blnz",

    # pseudo instructions
    "mvn",
    "not",
    "li",
)

t_ignore_COMMENT = r';.*|^\#.*'
t_ignore = ' \t'

literals = ':,[]'

def t_DIRECTIVE(t):
    r'\.\w+'
    #print "directive %s" % t
    return t

def t_HEXNUM(t):
    r'\#0[xX][A-Fa-f0-9]+'
    t.value = int(t.value[3:], 16)
    #print "hexnum %s" % t
    t.type = 'NUM'
    return t

def t_NUM(t):
    r'\#-?\d+'
    t.value = int(t.value[1:])
    #print "num %s" % t
    return t

def t_REGISTER(t):
    r'[rR]\d+'
    t.value = int(t.value[1:])
    #print "register %s" % t
    return t

def t_ID(t):
    r'[A-Za-z_]\w*'

    if t.value in INSTRUCTIONS:
        t.type = 'INSTRUCTION'
    elif t.value.lower() == 'sp':
        t.type = 'REGISTER'
        t.value = 14;
    elif t.value.lower() == 'lr':
        t.type = 'REGISTER'
        t.value = 15;
    elif t.value.lower() == 'pc':
        t.type = 'REGISTER'
        t.value = 16;

    #print "id %s" % t
    return t

def t_STRING(t):
    r'("(\\"|[^"])*")|(\'(\\\'|[^\'])*\')'
    t.value = t.value.strip('"\'')
    #print "string %s" % t
    return t

def t_newline(t):
    r'\n+'
    t.lexer.lineno += len(t.value)

def t_error(t):
    print "lexer error %s" % t

import ply.lex as lex
lex.lex(debug=False)

# parser
def p_expr(p):
    '''expr         : label
                    | instruction
                    | directive
                    '''
    #print "parser expr %s %s" % (p, p[0])

def p_label(p):
    '''label        : ID ':' '''
    print "parser label %s" % p[1]

def p_instruction(p):
    '''instruction  : instruction_loadstore
                    | instruction_3addr
                    | instruction_2addr
                    | instruction_1addr'''

def p_instruction_loadstore(p):
    '''instruction_loadstore :  INSTRUCTION REGISTER ',' '[' REGISTER ']'
                             |  INSTRUCTION REGISTER ',' '[' REGISTER ',' NUM ']'
                             |  INSTRUCTION REGISTER ',' '[' REGISTER ',' REGISTER ']'
                            '''
    print "parser instruction loadstore %s" % p[1]

def p_instruction_3addr(p):
    '''instruction_3addr    : INSTRUCTION REGISTER ',' REGISTER ',' REGISTER
                            | INSTRUCTION REGISTER ',' REGISTER ',' NUM
                            | INSTRUCTION REGISTER ',' REGISTER ',' ID'''
    print "parser instruction 3addr %s" % p[1]

def p_instruction_2addr(p):
    '''instruction_2addr    : INSTRUCTION REGISTER ',' NUM
                            | INSTRUCTION REGISTER ',' REGISTER
                            | INSTRUCTION REGISTER ',' ID'''
    print "parser instruction 2addr %s" % p[1]

def p_instruction_1addr(p):
    '''instruction_1addr    : INSTRUCTION REGISTER
                            | INSTRUCTION NUM
                            | INSTRUCTION ID'''
    print "parser instruction 1addr %s" % p[1]

def p_directive(p):
    '''directive            : DIRECTIVE
                            | DIRECTIVE ID
                            | DIRECTIVE STRING
                            | DIRECTIVE NUM'''
    print "parser directive %s" % p[1]

#def p_emtpy(p):
    #'empty : '
    #pass

def p_error(p):
    if p != None:
        print "parser error %s" % p

import ply.yacc as yacc
yacc.yacc()

