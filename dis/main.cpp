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
#include <inttypes.h>
#include <getopt.h>
#include <arpa/inet.h> // for htons

#include "Dis.h"

static const char *output_filename = "test.lst";

extern int open_input(const char *file);

FILE *fp;

static void usage(int argc, char **argv)
{
	fprintf(stderr, "usage: %s [-o output file] <input file>\n", argv[0]);
	exit(1);
}

int open_input(const char *file)
{
	fp = fopen(file, "r");
	if (!fp)
		return -1;


	return 0;
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

	Dis d;

	uint32_t addr = 0;
	while (!feof(fp)) {
		uint32_t word;
		
		if (fread(&word, sizeof(word), 1, fp) < 1)
			break;

		word = ntohl(word);

//		printf("0x%08x\n", word);

		std::string str = d.Dissassemble(word);
		printf("0x%08x: %08x  %s\n", addr, word, str.c_str());

		addr += 4;
	}

	fclose(fp);

	err = 0;

err:
	return err;
}
