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

.section .s16
.code16

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
        an.byte    $0b11111110,%al
        movl    %eax, %cr0

        sti

#=======        reset floppy

        xorb    %ah,%ah
        xorb    %dl,%dl
        int     $0x13

#=======        search kernel.bin

movw    $SectorNumOfRootDirStart, SectorNo     

Lable_Search_In_Root_Dir_Begin: 

        cmpw    $0,RootDirSizeForLoop
        jz      Label_No_LoaderBin
        decw    RootDirSizeForLoop
        movw    $0x0,%ax
        movw    %ax,%es
        movw    $0x8000,%bx
        movw    SectorNo,%ax
        movb    $1,%cl
        call    Func_ReadOneSector
        movw    $KernelFileName, %si
        movw    $0x8000,%di
        cld
        movw    $0x10,%dx

Label_Search_For_LoaderBin: 

        cmpw    $0,%dx
        jz      Label_Goto_Next_Sector_In_Root_Dir
        decw    %dx
        movw    $11,%cx

Label_Cmp_FileName: 

        cmpw    $0,%cx
        jz      Label_FileName_Found
        decw    %cx
        lodsb
        cmpb    es:di,%al
        jz      Label_Go_On
        jmp     Label_Different

Label_Go_On: 

        incw    %di
        jmp     Label_Cmp_FileName

Label_Different: 

        andw    $0xFFE0,%di
        addw    $0x20,%di
        movw    $KernelFileName, %si
        jmp     Label_Search_For_LoaderBin

Label_Goto_Next_Sector_In_Root_Dir: 

        addw    $1,SectorNo
        jmp     Lable_Search_In_Root_Dir_Begin

#=======        display message on screen : ERROR:No KERNEL Found

Label_No_LoaderBin: 

        movw    $0x1301,%ax
        movw    $0x008C,%bx
        movw    $0x0300,%dx              #row 3
        movw    $21,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $NoLoaderMessage, %bp
        int     $0x10
Label_Current_Line201:
        jmp     Label_Current_Line201

#=======        found kernel.bin  in root director struct

Label_FileName_Found: 
        movw    $RootDirSectors, %ax
        andw    $0xFFE0,%di
        addw    $0x1A,%di
        movw    es:di,%cx
        pushw   %cx
        addw    %ax,%cx
        addw    $SectorBalance, %cx
        movl    $BaseTmpOfKernelAddr, %eax      #BaseOfKernelFile
        movl    %eax,%es
        movw    $OffsetTmpOfKernelFile, %bx     #OffsetOfKernelFile
        movw    %cx,%ax

Label_Go_On_Loading_File: 
        pushw   %ax
        pushw   %bx
        movb    $0xE,%ah
        movb    $'.', %al
        movb    $0xF,%bl
        int     $0x10
        popw    %bx
        popw    %ax

        movb    $1,%cl
        call    Func_ReadOneSector
        popw    %ax

####################### 

        pushw   %cx
        pushl   %eax
        pushl   %fs
        pushl   %edi
        pushl   %ds
        pushl   %esi

        movw    $0x200,%cx
        movw    $BaseOfKernelFile, %ax
        movw    %ax,%fs
        movl    OffsetOfKernelFileCount,%edi

        movw    $BaseTmpOfKernelAddr, %ax
        movw    %ax,%ds
        movl    $OffsetTmpOfKernelFile, %esi

Label_Mov_Kernel:

        movb    %ds:%esi,%al
        movb     %al,%fs:%edi

        incl    %esi
        incl    %edi

        loop    Label_Mov_Kernel

        movl    $0x1000,%eax
        movl    %eax,%ds

        movl     %edi,   OffsetOfKernelFileCount  

        popl    %esi
        popl    %ds
        popl    %edi
        popl    %fs
        popl    %eax
        popw    %cx

####################### 

        call    Func_GetFATEntry
        cmpw    $0xFFF,%ax
        jz      Label_File_Loaded
        pushw   %ax
        movw    $RootDirSectors, %dx
        addw    %dx,%ax
        addw    $SectorBalance, %ax

        jmp     Label_Go_On_Loading_File

######
#=======        tmp IDT

IDT: 
    .fill   0x50, 8, 0
IDT_END: 

IDT_POINTER: 
    .word      IDT_END - IDT - 1
    .long      IDT

#=======        tmp variable

RootDirSizeForLoop:
        .word      RootDirSectors
SectorNo:
        .word      0
Odd:
        .byte      0
OffsetOfKernelFileCount:
        .long      OffsetOfKernelFile

DisplayPosition: 
        .long      0


#        display messages
#============================================================================

StartLoaderMessage:
        .ascii      "Start Loader......"
NoLoaderMessage:
        .byte       "ERROR:No KERNEL Found"
KernelFileName:
        .byte      "KERNEL  BIN"
StartGetMemStructMessage:
        .byte      "Start Get Memory Struct."
GetMemStructErrMessage:
        .byte      "Get Memory Struct ERROR"
GetMemStructOKMessage:
        .byte      "Get Memory Struct SUCCESSFUL!"

StartGetSVGAVBEInfoMessage:
        .byte      "Start Get SVGA VBE Info"
GetSVGAVBEInfoErrMessage:
        .byte      "Get SVGA VBE Info ERROR"
GetSVGAVBEInfoOKMessage:
        .byte      "Get SVGA VBE Info SUCCESSFUL!"

StartGetSVGAModeInfoMessage:
        .byte      "Start Get SVGA Mode Info"
GetSVGAModeInfoErrMessage:
        .byte      "Get SVGA Mode Info ERROR"
GetSVGAModeInfoOKMessage:
        .byte      "Get SVGA Mode Info SUCCESSFUL!"





