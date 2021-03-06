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
#include <cstdio>
#include <cstring>
#include <arpa/inet.h> // for htons
#include <iostream>

#include "Mem.h"

Mem::Mem(size_t _size)
:   size(_size)
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

uint32_t Mem::Read32(uint32_t addr)
{
//  printf("read at addr 0x%x\n", addr);
    if (addr & 0x3) {
        std::cerr << "address " << addr << " is unaligned" << std::endl;
        return 0;
    }

    if (addr > size - 4)
        return 0;

    return ntohl(*((uint32_t *)&mem[addr]));
}

void Mem::Write32(uint32_t addr, uint32_t val)
{
    if (addr & 0x3) {
        std::cerr << "address " << addr << " is unaligned" << std::endl;
        return;
    }

    if (addr == 0x80000000) {
        printf("%c", val & 0xff);
        fflush(stdout);
        return;
    }

    if (addr > size - 4)
        return;

    *((uint32_t *)&mem[addr]) = htonl(val);
}

uint16_t Mem::Read16(uint32_t addr)
{
//  printf("read at addr 0x%x\n", addr);
    if (addr & 0x1) {
        std::cerr << "address " << addr << " is unaligned" << std::endl;
        return 0;
    }

    if (addr > size - 2)
        return 0;

    return ntohs(*((uint16_t *)&mem[addr]));
}

void Mem::Write16(uint32_t addr, uint16_t val)
{
    if (addr & 0x1) {
        std::cerr << "address " << addr << " is unaligned" << std::endl;
        return;
    }

    if (addr == 0x80000000) {
        printf("%c", val & 0xff);
        fflush(stdout);
        return;
    }

    if (addr > size - 2)
        return;

    *((uint16_t *)&mem[addr]) = htons(val);
}

uint8_t Mem::Read8(uint32_t addr)
{
//  printf("read at addr 0x%x\n", addr);
    if (addr > size - 1)
        return 0;

    return *((uint8_t *)&mem[addr]);
}

void Mem::Write8(uint32_t addr, uint8_t val)
{
    if (addr == 0x80000000) {
        printf("%c", val & 0xff);
        fflush(stdout);
        return;
    }

    if (addr > size - 1)
        return;

    *((uint8_t *)&mem[addr]) = val;
}



