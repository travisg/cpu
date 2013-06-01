add r0, r0, #0
add r0, r0, #1
add r0, r0, #0x7fff
add r0, r0, #32767
add r0, r0, #-32768
add r0, r0, #-1
add r0, r0, #32768 ; should be out of range
add r0, r0, #-32769 ; should be out of range

b #0
b #-4
b #4
b #0x00800000
b #0xff800004
b #0x00800004 ; should be out of range
b #0xff800000 ; should be out of range

b #1        ; unaligned
b #-1       ; unaligned
b #2        ; unaligned
b #-2       ; unaligned
b #3        ; unaligned
b #-3       ; unaligned

