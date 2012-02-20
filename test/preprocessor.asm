#define CONST 99

#define MACRO(x) \
	li	r0, #x \
	add r0, r0, #1

label:
	li 	r0, #CONST

#if 0
	shouldfail
#endif
	
	MACRO(1)
	MACRO(2)

	
