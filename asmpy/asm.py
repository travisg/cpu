#!/usr/bin/env python

import sys
import lexparse

def main():
    infile = sys.stdin

    print "starting parser"
    for line in infile:
        lexparse.yacc.parse(line,debug=False)

if __name__ == "__main__":
    main()

# vim: ts=4 sw=4 expandtab:
