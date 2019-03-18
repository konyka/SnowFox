
#/**
#*===========================================================================
#*  SnowFox OS Source File.
#*  Copyright (C), DarkBlue Studios.
#* -------------------------------------------------------------------------
#*    File name: boot.s
#*      Version: v0.0.0
#*   Created on: Sept 5, 2018 by konyka
#*       Editor: Sublime Text3 
#*        EMail: 13855132@qq.com
#*  Description: 
#* -------------------------------------------------------------------------
#*      History:
#*
#*===========================================================================
#*/



#============================================================================

.text
.globl _start
.code16                              #16 bit mode

#.equ BaseOfStack, 0x7c00


_start:
    jmp code

StartBootMessage:
    .ascii "Start Booting......\0"

code:

    movw   %cs, %ax
    movw   %ax, %ds
    movw   %ax, %es
    movw   %ax, %ss
   #movw   $BaseOfStack,  %sp                # core dump 有问题


#   clear screen
#============================================================================

    movw   $0x0600, %ax
    movw   $0x0700, %bx
    movw   $0x0000, %cx
    movw   $0x184f, %dx
    int    $0x10

#   set focus
#============================================================================

    movw   $0x0200,  %ax
    movw   $0x0000,  %bx
    movw   $0x0000,  %dx
    int    $0x10

#   display on screen : Start Booting......
#============================================================================

    movw   $0x1301,  %ax
    movw   $0x000f,  %bx
    movw   $0x0000,  %dx
    movw   $19,  %cx
    pushw  %ax
    movw   %ds,  %ax
    movw   %ax,  %es
    popw   %ax
    movw   $StartBootMessage, %bp
    int    $0x10

#   reset floopy
#============================================================================

    xorb   %ah,  %ah
    xorb   %dl,  %dl
    int    $0x13

#============================================================================

   .org   510, 0x55

   .word  0xaa55

#============================================================================
