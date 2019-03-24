
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
#============================================================================
_start:
    jmp code


code:

# -Ttext 10000

        movw    %cs, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    $0x0000, %ax
        movw    %ax, %ss
#        movw    $0x7c00, %sp

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
Label_Loop_Current_Line:
        jmp     Label_Loop_Current_Line

#        display messages
#============================================================================

StartLoaderMessage:
    .ascii     "Start Loader......"



