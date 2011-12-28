	add		r0, r0, r0
; what
what:
	add		r0, r1, r2
	add		r1, r2, #3
	add		r0, r1, what
	li		r0, #1
	li		r0, #0
	li		r0, #-1
	li		r0, #0x54
	mov		r0, r1
	li		r5, what

	b		#2

	b		shit
	and		r0, r0, r0

shit:
	li		r0, #3

loop0:
	sub		r0, r0, #1
	bnz		r0, loop0

	li		r1, #0x88
	ldr		r0, [r1]
	ldr		r0, [r1,#4]
	ldr		r0, [r1,#-4]
	ldr		r0, [r1],#4+
	ldr		r0, [r1],#4+
	ldr		r0, [sp],#4+
	ldr		r0, [pc]
	ldr		r0, [pc, #4]
	ldr		r0, [pc, #-4]
	str		r0, [sp,#4]+
	b		loop0

	add		r0, r0, r0
	b		r5

	b		sp
	b		lr
	bl		lr
	b		#-2
	b		#-2
	b		#2
	bl		#0x1024
	bz		r1, #-44
	bnz		r5, #46
	bz		r0, #0
	bnz		r0, #2
	bz		r3, what
	bnz		r3, what
	b		what
	bl		what

	push	r0
	pop		r1
