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
#ifndef __MEM_H
#define __MEM_H

#include <sys/types.h>
#include <stdint.h>
#include <string>

class Mem {
public:
    Mem(size_t size);
    ~Mem();

    int LoadFile(const std::string &file, uint32_t addr);

    uint32_t Read32(uint32_t addr);
    uint16_t Read16(uint32_t addr);
    uint8_t Read8(uint32_t addr);

    void Write32(uint32_t addr, uint32_t val);
    void Write16(uint32_t addr, uint16_t val);
    void Write8(uint32_t addr, uint8_t val);

private:
    size_t size;
    uint8_t *mem;
};


#endif

