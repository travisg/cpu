start:
	add		r0, r0, r0
; what
what:
	add		r0, r1, r2
	add		r1, r2, #3
	add		r0, r1, what
	mov		r0, #1
	mov		r0, #0
	mov		r0, #-1
	mov		r0, #0x54
	mov		r0, r1
	mov		r5, what
	not		r0, r1
	mvn		r0, r1

	b		#4

	b		start
	and		r0, r0, r0

shit:
	mov		r0, #3

loop0:
	sub		r0, r0, #1
	bnz		r0, loop0

	mov		r1, #0x88
	ldr		r0, [r1]
	ldr		r0, [r1,#4]
	ldr		r0, [r1,#-4]
	ldr		r0, [sp,#4]
	ldr		r0, [lr,#4]
	ldr		r0, [r2, r3]
	str		r0, [r1]
	str		r0, [r1,#4]
	str		r0, [r1,#-4]
	str		r0, [sp,#4]
	str		r0, [lr,#4]
	str		r0, [r2, r3]
	b		loop0

	add		r0, r0, r0
	b		r5

	; imm branches
	b		#28
	bl		#28

	; identifier branches
	b		start
	bl		start

	; one register branches
	b		r9
	bl		r9

	; two register branches
	bz		r9, r1
	bnz		r9, r1
	blz		r9, r1
	blnz	r9, r1

	; reg, imm branches
	bz		r9, #28
	bnz		r9, #28
	blz		r9, #28
	blnz	r9, #28

	; reg, identifier branches
	bz		r9, start
	bnz		r9, start
	blz		r9, start
	blnz	r9, start

	; immediate loads
	li		r0, #0
	li		r0, #1
	li		r0, #-1
	li		r0, #0x8000
	li		r0, #0xffff
	li		r0, #0x10000
	li		r0, #0xffffffff

	; labels
	li		r0, label

label:
	.word	label
	.word	#99
