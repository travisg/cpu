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
#include <fcntl.h>
#include <unistd.h>

#include "Sym.h"
#include "Symtab.h"
#include "Codegen.h"
#include "OutputFile.h"

Symtab *gSymtab;
Codegen *gCodegen;

static std::string output_filename;

extern int open_input(int fd, const char *file);
extern int parse_source();
static int preprocess(const std::string &file);

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

    // start preprocessor
    int preprocess_out = preprocess(argv[0]);
    if (preprocess_out < 0) {
        fprintf(stderr, "error starting preprocessor\n");
        return 1;
    }

    if (open_input(preprocess_out, argv[0]) < 0) {
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
    close(preprocess_out);
    delete gCodegen;
    delete gSymtab;
    delete f;

    return err;
}

static int preprocess(const std::string &file)
{

    int fd = open(file.c_str(), O_RDONLY);
//  printf("fd %d\n", fd);
    if (fd < 0)
        return -1;

    int pipes[2];
    if (pipe(pipes) < 0) {
        close(fd);
        return -1;
    }

//  printf("pipes %d %d\n", pipes[0], pipes[1]);

    pid_t pid = fork();
    if (pid == 0) {
        // child
//      printf("child\n");

        close(STDOUT_FILENO);
        close(STDIN_FILENO);

        dup2(fd, STDIN_FILENO);
        dup2(pipes[1], STDOUT_FILENO);

        close(fd);
        close(pipes[0]);
        close(pipes[1]);

        execlp("cpp", "cpp", NULL);

        fprintf(stderr, "error execing preprocessor\n");
        exit(1);
    } else {
        // parent
//      printf("parent\n");

        fflush(stdout);

        close(pipes[1]);
        close(fd);

#if 0
        char buf[64];
        int e;
        while ((e = read(pipes[0], buf, sizeof(buf))) > 0) {
            write(STDOUT_FILENO, buf, e);
        }
#endif
    }

    return pipes[0];
}

