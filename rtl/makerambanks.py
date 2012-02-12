#!/usr/bin/env python

import sys

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

def readfield (f, line, count, index):
	while count > 0:
		c = line[index];
		index = index + 1;
		if c not in { '0', '1' }:
			continue
		f.write(c)
		count = count - 1;
	
	f.write('\n');
	return index

for line in infile:
	if line[0] in { '#', ';' }:
		continue

	index = 0;
	index = readfield(out[0], line, 8, index)
	index = readfield(out[1], line, 8, index)
	index = readfield(out[2], line, 8, index)
	index = readfield(out[3], line, 8, index)

