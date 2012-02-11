#!/usr/bin/env python

import sys

print sys.argv

try:
	infile = open("ram.txt", "r")
except:
	print "error opening input file"
	sys.exit(1)

out = []
try:
	out.append(open("ram.bank3", "w+"))
	out.append(open("ram.bank2", "w+"))
	out.append(open("ram.bank1", "w+"))
	out.append(open("ram.bank0", "w+"))
except:
	print "error opening output files"
	sys.exit(1)

print infile
print out

for line in infile:

	out[0].write(line[0:8] + '\n')
	out[1].write(line[8:16] + '\n')
	out[2].write(line[16:24] + '\n')
	out[3].write(line[24:32] + '\n')
		

