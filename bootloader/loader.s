
/**
 *===========================================================================
 *  SnowFox OS Source File.
 *  Copyright (C), DarkBlue Studios.
 * -------------------------------------------------------------------------
 *    File name: loader.s
 *      Version: v0.0.0
 *   Created on: Sept 5, 2018 by konyka
 *       Editor: Sublime Text3 
 *        EMail: 13855132@qq.com
 *  Description: 
 * -------------------------------------------------------------------------
 *      History:
 *
 *===========================================================================
 */


.text
.globl _start
.code16                              #16 bit mode
.align 16
#============================================================================
_start:
    jmp code
    nop
    
.include "fat12.inc"

# placeholder
.word 0x0000

.equ    BaseOfKernelFile, 0x00
.equ    OffsetOfKernelFile, 0x100000

.equ    BaseTmpOfKernelAddr, 0x00
.equ    OffsetTmpOfKernelFile, 0x7E00

.equ    MemoryStructBufferAddr, 0x7E00

#.section gdt

LABEL_GDT:              .long 0,0
LABEL_DESC_CODE32:      .long 0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:      .long 0x0000FFFF,0x00CF9200
LABEL_GDT_END: 

.equ    GdtLen,      LABEL_GDT_END - LABEL_GDT

GdtPtr:
    .word      GdtLen - 1
    .long     0x00010040#LABEL_GDT
    #relocation placeholder
    .word 0x0000  

.equ    SelectorCode32,  LABEL_DESC_CODE32 - LABEL_GDT
.equ    SelectorData32,  LABEL_DESC_DATA32 - LABEL_GDT

#.section gdt64

LABEL_GDT64:            .quad 0x0000000000000000
LABEL_DESC_CODE64:      .quad 0x0020980000000000
LABEL_DESC_DATA64:      .quad 0x0000920000000000
LABEL_GDT64_END:

.equ    GdtLen64,    LABEL_GDT64_END - LABEL_GDT64

GdtPtr64:
    .word      GdtLen64 - 1
    .long      0x00010060#LABEL_GDT64

.equ    SelectorCode64,  LABEL_DESC_CODE64 - LABEL_GDT64
.equ    SelectorData64,  LABEL_DESC_DATA64 - LABEL_GDT64


code:

# -Ttext 0x0000

        movw    %cs, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    $0x0000, %ax
        movw    %ax, %ss
        movw    $0x7c00, %sp

#        display on screen : Start Loader......
#============================================================================

        movw    $0x1301, %ax
        movw    $0x000f, %bx
        movw    $0x0200, %dx
        movw    $18, %cx
        pushw   %ax
        movw    %ds, %ax
        movw    %ax, %es
        popw    %ax
        movw    $StartLoaderMessage, %bp
        int      $0x10

#=======        open address A20
        pushw   %ax
        inb     $0x92,%al
        orb     $0b00000010,%al
        outb    %al, $0x92
        popw    %ax

        cli

        #.byte 0x66
        lgdtl    GdtPtr

        movl    %cr0, %eax
        orl     $1,%eax
        movl    %eax, %cr0

        movw    $SelectorData32, %ax
        movw    %ax,%fs
        movl    %cr0, %eax
        andb    $0b11111110,%al
        movl    %eax, %cr0

        sti

#=======        reset floppy

        xorb    %ah,%ah
        xorb    %dl,%dl
        int     $0x13

        Label_Loop_Current_Line:
        jmp     Label_Loop_Current_Line

#        display messages
#============================================================================

StartLoaderMessage:
    .ascii     "Start Loader......"



