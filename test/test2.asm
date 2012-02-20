; location of the debug 
	li	r0, #0
	li	r9, #256
bigloop:
	add	r0, r0, #1

	li r1, #1
loop:
	sub r1, r1, #1
	bnz r1, loop

	str	r0, [r9, #0]

	b bigloop
