/*
 * Copyright (c) 2011 Travis Geiselbrecht
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
#include <cstring>
#include <string>
#include <stdio.h>
#include <assert.h>
#include <arpa/inet.h> // for htons
#include "OutputFile.h"

OutputFile::OutputFile()
:	fp(0),
	pos(0)
{
}

OutputFile::~OutputFile()
{
	if (fp)
		fclose(fp);
}

int OutputFile::OpenFile(const std::string &name)
{
	if (fp)
		return -1;

	fp = fopen(name.c_str(), "w+");
	if (!fp)
		return -1;

	return 0;
}

off_t OutputFile::Append(uint16_t word)
{
	assert(fp);

	word = htons(word);

	fseeko(fp, pos, SEEK_SET);
	fwrite(&word, sizeof(word), 1, fp);

	pos = ftello(fp);

	return pos;
}

off_t OutputFile::Append(uint32_t word)
{
	assert(fp);

	word = htonl(word);

	fseeko(fp, pos, SEEK_SET);
	fwrite(&word, sizeof(word), 1, fp);

	pos = ftello(fp);

	return pos;
}

off_t OutputFile::Append(const std::string &str)
{
	assert(fp);

	fseeko(fp, pos, SEEK_SET);

	const char *s = str.c_str();
	fwrite(s, strlen(s) + 1, 1, fp);

	pos = ftello(fp);

	return pos;
}

int OutputFile::WriteAt(off_t offset, uint16_t word)
{
	assert(fp);

//	printf("WriteAt offset 0x%llx, word 0x%hx\n", offset, word);

	word = htons(word);

	fseeko(fp, offset, SEEK_SET);
	fwrite(&word, sizeof(word), 1, fp);

	return 0;
}

int OutputFile::ReadAt(off_t offset, uint16_t *word)
{
	assert(fp);

//	printf("ReadAt offset 0x%llx, word %p\n", offset, word);

	fseeko(fp, offset, SEEK_SET);
	fread(word, sizeof(*word), 1, fp);

	*word = ntohs(*word);

	return 0;
}

int OutputFile::WriteAt(off_t offset, uint32_t word)
{
	assert(fp);

//	printf("WriteAt offset 0x%llx, word 0x%x\n", offset, word);

	word = htonl(word);

	fseeko(fp, offset, SEEK_SET);
	fwrite(&word, sizeof(word), 1, fp);

	return 0;
}

int OutputFile::ReadAt(off_t offset, uint32_t *word)
{
	assert(fp);

//	printf("ReadAt offset 0x%llx, word %p\n", offset, word);

	fseeko(fp, offset, SEEK_SET);
	fread(word, sizeof(*word), 1, fp);

	*word = ntohl(*word);

	return 0;
}

off_t OutputFile::Align(unsigned int alignment)
{
	assert(fp);

	pos = ((pos + alignment - 1) / alignment) * alignment;

	return pos;
}

