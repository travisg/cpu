#pragma once

/* bit manipulation macros */
#define BIT(x, bit) ((x) & (1 << (bit)))
#define BIT_SHIFT(x, bit) (((x) >> (bit)) & 1)
#define BITS(x, high, low) ((x) & (((1<<((high)+1))-1) & ~((1<<(low))-1)))
#define BITS_SHIFT(x, high, low) (((x) >> (low)) & ((1<<((high)-(low)+1))-1))
#define BIT_SET(x, bit) (((x) & (1 << (bit))) ? 1 : 0)


