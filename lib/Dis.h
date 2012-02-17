#pragma once

#include <string>
#include <inttypes.h>

class Dis {
public:
	Dis() {}
	~Dis() {} 

	enum disflags {
		DIS_FLAG_SHOWTARGET = 1,
	};

	std::string Dissassemble(uint32_t word, uint flags = 0, uint32_t curaddr = 0);

private:


};
