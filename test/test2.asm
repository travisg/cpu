#define UART_ADDR 0x80000000
#define DEBUG_ADDR 0x80010000

start:
    li  sp, stack_end

    li  r0, string
    bl  printstr

    li  r0, #0
    li  r9, #DEBUG_ADDR
bigloop:
    add r0, r0, #1

    li r1, #1
loop:
    sub r1, r1, #1
    bnz r1, loop

    str r0, [r9, #4]

    b bigloop

/* output a string in r0 */
printstr:
    sub sp, sp, #4
    str lr, [sp, #0]

    mov r4, r0

printstr_loop:
    ldr r5, [r4, #0]
    add r4, r4, #4

    lsr r0, r5, #24
    and r0, r0, #0xff
    bz  r0, printstr_done
    bl  writeuart

    lsr r0, r5, #16
    and r0, r0, #0xff
    bz  r0, printstr_done
    bl  writeuart

    lsr r0, r5, #8
    and r0, r0, #0xff
    bz  r0, printstr_done
    bl  writeuart

    and r0, r5, #0xff
    bz  r0, printstr_done
    bl  writeuart

    b   printstr_loop

printstr_done:
    li  r0, #0

    ldr lr, [sp, #0]
    add sp, sp, #4
    b   lr

writeuart:
    li  r1, #UART_ADDR
    ldr r2, [r1, #0]
    bz  r2, writeuart

    str r0, [r1, #0]
    b   lr

string:
    .asciiz "Hello World!\r\n"

    .align #4
stack:
    .skip #0x100
stack_end:

    .word #99

