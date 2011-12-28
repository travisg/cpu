add	r0, r0, #0
add	r0, r0, #1
add	r0, r0, #0x7
add	r0, r0, #0x8 ; should be out of range
add	r0, r0, #-1 ; should be out of range

lsl r0, r0, #1
lsl r0, r0, #7
lsl r0, r0, #8 ; special case, encoded as 0
lsl r0, r0, #9 ; out of range

li r0, #0
li r0, #1
li r0, #-1
li r0, #255
li r0, #-256
li r0, #0xffffffff
li r0, #256 	; out of range
li r0, #-257 	; out of range

bz r0, #0
bz r0, #-2
bz r0, #2
bz r0, #512
bz r0, #-510
bz r0, #514		; out of range
bz r0, #-512	; out of range

bz r0, #1		; unaligned
bz r0, #-1		; unaligned

b  #0
b  #2
b  #-2
b  #4096
b  #-4094
b  #4098		; out of range
b  #-4096		; out of range

bl	#0
bl	#2
bl	#-2
bl	#16777216
bl	#-16777214
bl	#16777218	; out of range
bl	#-16777216	; out of range

ldr	r0, [pc, #0]
ldr	r0, [pc, #4]
ldr	r0, [pc, #-4]
ldr	r0, [pc, #8188]
ldr	r0, [pc, #-8192]
ldr	r0, [pc, #8192]		; out of range
ldr	r0, [pc, #-8196]	; out of range

ldr	r0, [r1, #0]
ldr	r0, [r1, #4]
ldr	r0, [r1, #-4]
ldr	r0, [r1, #60]
ldr	r0, [r1, #-64]
ldr	r0, [r1, #64]	; out of range
ldr	r0, [r1, #-68]	; out of range

str	r0, [r1, #0]+
str	r0, [r1, #4]+
str	r0, [r1, #-4]+
str	r0, [r1, #60]+
str	r0, [r1, #-64]+
str	r0, [r1, #64]+	; out of range
str	r0, [r1, #-68]+	; out of range

ldr	r0, [r1], #0+
ldr	r0, [r1], #4+
ldr	r0, [r1], #-4+
ldr	r0, [r1], #60+
ldr	r0, [r1], #-64+
ldr	r0, [r1], #64+	; out of range
ldr	r0, [r1], #-68+	; out of range

