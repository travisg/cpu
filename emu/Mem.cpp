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
#include <iostream>

#include "Mem.h"

Mem::Mem(size_t _size)
:	size(_size)
{
	mem = new uint8_t[size];
	memset(mem, 0x99, size);
}

Mem::~Mem()
{
	delete[] mem;
}

int Mem::LoadFile(const std::string &file, uint32_t addr)
{
	FILE *fp = fopen(file.c_str(), "rb");
	if (!fp)
		return -1;

	uint8_t *buf = mem + addr;
	while (!feof(fp)) {
		int err = fread(buf, 1, 512, fp);
		buf += err;
	}

	fclose(fp);

	return 0;
}

uint32_t Mem::Read(uint32_t addr)
{
//	printf("read at addr 0x%x\n", addr);
	if (addr & 0x3) {
		std::cerr << "address " << addr << " is unaligned" << std::endl;
		return 0;
	}

	if (addr > size - 4)
		return 0;

	return ntohl(*((uint32_t *)&mem[addr]));
}

void Mem::Write(uint32_t addr, uint32_t val)
{
	if (addr & 0x3) {
		std::cerr << "address " << addr << " is unaligned" << std::endl;
		return;
	}

	if (addr > size - 4)
		return;

	*((uint32_t *)&mem[addr]) = htonl(val);
}

