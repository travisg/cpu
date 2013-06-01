#define UART_ADDR 0x80000000

start:
    li  sp, stack_end

    li  r0, string
    bl  printstr

    li  r0, string2
    bl  printstr

end:
    b   end

printstr:
    li  r1, #UART_ADDR

loop:
    ldr r2, [r0, #0]
    add r0, r0, #4

    lsr r3, r2, #24
    and r3, r3, #0xff
    bz  r3, done
    str r3, [r1, #0]

    lsr r3, r2, #16
    and r3, r3, #0xff
    bz  r3, done
    str r3, [r1, #0]

    lsr r3, r2, #8
    and r3, r3, #0xff
    bz  r3, done
    str r3, [r1, #0]

    and r3, r2, #0xff
    bz  r3, done
    str r3, [r1, #0]

    b   loop

done:
    li  r0, #0
    b   lr

string:
    .asciiz "Hello World!\n"
string2:
    .asciiz "Another line\n"

stack:
    .skip #0x100
stack_end:
