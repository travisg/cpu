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
#include <cstdio>
#include <cstring>
#include <getopt.h>

#include "Mem.h"
#include "Cpu32.h"

#include "Cpu.h"

static int64_t cycle_limit = 0;
static bool verbose = false;

static void usage(int argc, char **argv)
{
	fprintf(stderr, "usage: %s [-c cycle limit] -v <binary>\n", argv[0]);
}

int main(int argc, char **argv)
{
	// read in any overriding configuration from the command line
	for(;;) {
		int c;
		int option_index = 0;

		static struct option long_options[] = {
			{"cycles", 1, 0, 'c'},
			{"verbose", 0, 0, 'v'},
			{0, 0, 0, 0},
		};

		c = getopt_long(argc, argv, "c:v", long_options, &option_index);
		if(c == -1)
			break;

		switch(c) {
			case 'c':
				cycle_limit = atoll(optarg);
				break;
			case 'v':
				verbose = true;
				break;
			default:
				usage(argc, argv);
				break;
		}
	}

	if (argc - optind < 1) {
		usage(argc, argv);
		return 1;
	}

	argc -= optind;
	argv += optind;

	Mem *m = new Mem(4*1024*1024);

	if (m->LoadFile(argv[0], 0) < 0) {
		fprintf(stderr, "error loading file\n");
		return 1;
	}
	
	Cpu32 *c = new Cpu32();

	c->SetMem(m);
	if (cycle_limit > 0)
		c->SetCycleLimit(cycle_limit);
	c->SetVerbose(verbose);

	c->Reset();
	c->Run();
	
	delete m;

	return 0;
}
