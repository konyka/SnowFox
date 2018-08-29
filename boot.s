##########################################################################################

.text
.globl _start
.code16                              #16 bit mode

#.equ BaseOfStack, 0x7c00


_start:
    jmp code

StartBootMessage:
    .ascii "Start Booting......\0"

code:

    mov   %cs, %ax
    mov   %ax, %ds
    mov   %ax, %es
    mov   %ax, %ss
   #mov   $BaseOfStack,  %sp                # core dump


#   clear screen
##########################################################################################

    mov   $0x0600, %ax
    mov   $0x0700, %bx
    mov   $0x0, %cx
    mov   $0x184f,  %dx
    int   $0x10

#   set focus
##########################################################################################

    mov   $0x0200,  %ax
    mov   $0x0000,  %bx
    mov   $0x0000,  %dx
    int   $0x10

#   display on screen : Start Booting......
##########################################################################################

    mov   $0x1301,  %ax
    mov   $0x000f,  %bx
    mov   $0x0000,  %dx
    mov   $19,  %cx
    push  %ax
    mov   %ds,  %ax
    mov   %ax,  %es
    pop   %ax
    mov   $StartBootMessage, %bp
    int   $0x10

#   reset floopy
##########################################################################################

    xor   %ah,  %ah
    xor   %dl,  %dl
    int   $0x13

##########################################################################################

   .org   510, 0x55

   .word  0xaa55

##########################################################################################
