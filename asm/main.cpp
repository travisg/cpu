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
#include <cstdlib>
#include <getopt.h>

#include "Sym.h"
#include "Symtab.h"
#include "Codegen.h"
#include "OutputFile.h"

Symtab *gSymtab;
Codegen *gCodegen;

static std::string output_filename;

extern int open_input(const char *file);
extern int parse_source();

static void usage(int argc, char **argv)
{
	fprintf(stderr, "usage: %s [-o output file] <input file>\n", argv[0]);
	exit(1);
}

int main(int argc, char **argv)
{
	int err;

	// read in any overriding configuration from the command line
	for(;;) {
		int c;
		int option_index = 0;

		static struct option long_options[] = {
			{"output", 1, 0, 'o'},
			{0, 0, 0, 0},
		};
		
		c = getopt_long(argc, argv, "o:", long_options, &option_index);
		if(c == -1)
			break;

		switch(c) {
			case 'o':
				output_filename = optarg;
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

	if (open_input(argv[0]) < 0) {
		fprintf(stderr, "error opening input file\n");
		return 1;
	}

	if (output_filename == "") {
		// build one out of the input file
		output_filename = std::string(argv[0]) + ".bin";
		printf("output file %s\n", output_filename.c_str());
	}

	OutputFile *f = new OutputFile();
	if (f->OpenFile(output_filename) < 0) {
		fprintf(stderr, "error opening output file\n");
		return 1;
	}

	gSymtab = new Symtab();
	gCodegen = new Codegen();
	gCodegen->InitSymtab(gSymtab);
	gCodegen->SetOutput(f);

	err = parse_source();
	if (err < 0)
		goto err;
	
	gCodegen->FixupPass();

err:
	delete gCodegen;
	delete gSymtab;
	delete f;

	return err;
}
