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
        andb    $0b11111110,%al
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
        cmpb    %es:(%di),%al
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
        movw    %es:(%di),%cx
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

        movb    %ds:(%esi),%al
        movb     %al,%fs:(%edi)

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


Label_File_Loaded: 

        movw    $0xB800,%ax
        movw    %ax,%gs
        movb    $0xF,%ah                        # 0000: 黑底    1111: 白字
        movb    $'G', %al
        movw     %ax,%gs:(((80 * 0 + 39) * 2))

#=======        get memory address size type

        movw    $0x1301,%ax
        movw    $0x000F,%bx
        movw    $0x0400,%dx              #row 4
        movw    $24,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $StartGetMemStructMessage, %bp
        int     $0x10

        movl    $0,%ebx
        movw    $0x00,%ax
        movw    %ax,%es
        movw    $MemoryStructBufferAddr, %di

Label_Get_Mem_Struct: 

        movl    $0x0E820,%eax
        movl    $20,%ecx
        movl    $0x534D4150,%edx
        int     $0x15
        jc      Label_Get_Mem_Fail
        addw    $20,%di

        cmpl    $0,%ebx
        jne     Label_Get_Mem_Struct
        jmp     Label_Get_Mem_OK

Label_Get_Mem_Fail: 

        movw    $0x1301,%ax
        movw    $0x08C,%bx
        movw    $0x500,%dx              #row 5
        movw    $23,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $GetMemStructErrMessage, %bp
        int     $0x10
Label_Current_Line337:
        jmp     Label_Current_Line337

Label_Get_Mem_OK: 

        movw    $0x1301,%ax
        movw    $0x000F,%bx
        movw    $0x0600,%dx              #row 6
        movw    $29,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $GetMemStructOKMessage, %bp
        int     $0x10

#=======        get SVGA information

        movw    $0x1301,%ax
        movw    $0x000F,%bx
        movw    $0x0800,%dx              #row 8
        movw    $23,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $StartGetSVGAVBEInfoMessage, %bp
        int     $0x10

        movw    $0x00,%ax
        movw    %ax,%es
        movw    $0x8000,%di
        movw    $0x4F00,%ax

        int     $0x10

        cmpw    $0x004F,%ax

        jz      Label_Get_Mem_OK.KO

#=======        Fail

        movw    $0x1301,%ax
        movw    $0x008C,%bx
        movw    $0x0900,%dx              #row 9
        movw    $23,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $GetSVGAVBEInfoErrMessage, %bp
        int     $0x10
Label_Current_Line389:
        jmp     Label_Current_Line389

Label_Get_Mem_OK.KO: 

        movw    $0x1301,%ax
        movw    $0x000F,%bx
        movw    $0x0A00,%dx              #row 10
        movw    $29,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $GetSVGAVBEInfoOKMessage, %bp
        int     $0x10


#=======        Get SVGA Mode Info

        movw    $0x1301,%ax
        movw    $0x000F,%bx
        movw    $0x0C00,%dx              #row 12
        movw    $24,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $StartGetSVGAModeInfoMessage, %bp
        int     $0x10


        movw    $0x0000,%ax
        movw    %ax,%es
        movw    $0x800e,%si

        movl    %es:(%si),%esi
        movl    $0x8200,%edi

Label_SVGA_Mode_Info_Get: 

        movw    %es:(%esi),%cx


#=======        display SVGA mode information

        pushw   %ax

        movw    $0x0,%ax
        movb    %ch,%al
        call    Label_DispAL

        movw    $0x0,%ax
        movb    %cl,%al
        call    Label_DispAL

        popw    %ax

#=======

        cmpw    $0xFFFF,%cx
        jz      Label_SVGA_Mode_Info_Finish

        movw    $0x4F01,%ax
        int     $0x10

        cmpw    $0x004F,%ax

        jnz     Label_SVGA_Mode_Info_FAIL

        addl    $2,%esi
        addl    $0x0100,%edi

        jmp     Label_SVGA_Mode_Info_Get

Label_SVGA_Mode_Info_FAIL: 

        movw    $0x1301,%ax
        movw    $0x008C,%bx
        movw    $0x0D00,%dx              #row 13
        movw    $24,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $GetSVGAModeInfoErrMessage, %bp
        int     $0x10

Label_SET_SVGA_Mode_VESA_VBE_FAIL: 

        jmp     Label_SET_SVGA_Mode_VESA_VBE_FAIL

Label_SVGA_Mode_Info_Finish: 

        movw    $0x1301,%ax
        movw    $0x000F,%bx
        movw    $0x0E00,%dx              #row 14
        movw    $30,%cx
        pushw   %ax
        movw    %ds,%ax
        movw    %ax,%es
        popw    %ax
        movw    $GetSVGAModeInfoOKMessage, %bp
        int     $0x10

#=======        set the SVGA mode(VESA VBE)

        movw    $0x4F02,%ax
        movw    $0x4180,%bx     #========================mode : 0x180 or 0x143
        int     $0x10

        cmpw    $0x04F,%ax
        jnz     Label_SET_SVGA_Mode_VESA_VBE_FAIL


#=======        init IDT GDT goto protect mode 

        cli                     #======close interrupt


        lgdtl    GdtPtr

#       lidtl    IDT_POINTER

        movl    %cr0, %eax
        orl     $1,%eax
        movl    %eax, %cr0

        jmpl    $SelectorCode32,$GO_TO_TMP_Protect

.section .s32
.code32

GO_TO_TMP_Protect: 

#=======        go to tmp long mode

        movw    $0x10,%ax
        movw    %ax,%ds
        movw    %ax,%es
        movw    %ax,%fs
        movw    %ax,%ss
        movl    $0x7E00,%esp

        call    support_long_mode
        testl   %eax,%eax

        jz      no_support


#=======        init temporary page table 0x90000

        movl    $0x91007,0x90000
        movl    $0x91007,0x90800

        movl    $0x92007,0x91000

        movl    $0x000083,0x92000

        movl    $0x200083,0x92008

        movl    $0x400083,0x92010

        movl    $0x600083,0x92018

        movl    $0x800083,0x92020

        movl    $0xa00083,0x92028

#=======        load GDTR64


        lgdtl    GdtPtr64
        movw    $0x10,%ax
        movw    %ax,%ds
        movw    %ax,%es
        movw    %ax,%fs
        movw    %ax,%gs
        movw    %ax,%ss

        movl    $0x7E00,%esp

#=======        open PAE

        movl    %cr4, %eax
        btsl    $5,%eax
        movl    %eax, %cr4

#=======        load    cr3

        movl    $0x90000,%eax
        movl    %eax, %cr3

#=======        enable long-mode

        movl    $0xC0000080,%ecx                #IA32_EFER
        rdmsr

        btsl    $8,%eax
        wrmsr

#=======        open PE and paging

        movl    %cr0, %eax
        btsl    $0,%eax
        btsl    $31,%eax
        movl    %eax, %cr0

        jmp     $SelectorCode64,$OffsetOfKernelFile

#=======        test support long mode or not

support_long_mode: 

        movl    $0x80000000,%eax
        cpuid
        cmpl    $0x80000001,%eax
        setnbb  %al
        jb      support_long_mode_done
        movl    $0x80000001,%eax
        cpuid
        btl     $29,%edx
        setcb   %al
support_long_mode_done: 

        movzbl  %al,%eax
        ret

#=======        no support

no_support: 
        jmp     no_support

#=======        read one sector from floppy

.section .s16lib
.code16

Func_ReadOneSector: 

        pushw   %bp
        movw    %sp,%bp
        subl    $2,%esp
        movb     %cl, -2(%bp)
        pushw   %bx
        movb    BPB_SecPerTrk,%bl
        divb    %bl
        incb    %ah
        movb    %ah,%cl
        movb    %al,%dh
        shrb    %al
        movb    %al,%ch
        andb    $1,%dh
        popw    %bx
        movb    BS_DrvNum,%dl
Label_Go_On_Reading: 
        movb    $2,%ah
        movb    -2(%bp),%al
        int     $0x13
        jc      Label_Go_On_Reading
        addl    $2,%esp
        popw    %bp
        ret

#=======        get FAT Entry

Func_GetFATEntry: 

        pushw   %es
        pushw   %bx
        pushw   %ax
        movw    $00,%ax
        movw    %ax,%es
        popw    %ax
        movb    $0,Odd
        movw    $3,%bx
        mulw    %bx
        movw    $2,%bx
        divw    %bx
        cmpw    $0,%dx
        jz      Label_Even
        movb    $1,Odd

Label_Even: 

        xorw    %dx,%dx
        movw    BPB_BytesPerSec,%bx
        divw    %bx
        pushw   %dx
        movw    $0x8000,%bx
        addw    $SectorNumOfFAT1Start, %ax
        movb    $2,%cl
        call    Func_ReadOneSector

        popw    %dx
        addw    %dx,%bx
        movw    %es:(%bx),%ax
        cmpb    $1,Odd
        jnz     Label_Even_2
        shrw    $4,%ax

Label_Even_2: 
        andw    $0xFFF,%ax
        popw    %bx
        popw    %es
        ret

#=======        display num in al

Label_DispAL: 

        pushl   %ecx
        pushl   %edx
        pushl   %edi

        movl    DisplayPosition,%edi
        movb    $0xF,%ah
        movb    %al,%dl
        shrb    $4,%al
        movl    $2,%ecx
Label_DispAL.begin: 

        andb    $0xF,%al
        cmpb    $9,%al
        ja      Label_DispAL.1
        addb    $'0', %al
        jmp     Label_DispAL.2
Label_DispAL.1: 

        subb    $0xA,%al
        addb    $'A', %al
Label_DispAL.2: 

        movw    %ax,%gs:(%edi)
        addl    $2,%edi

        movb    %dl,%al
        loop    Label_DispAL.begin

        movl    %edi,DisplayPosition

        popl    %edi
        popl    %edx
        popl    %ecx

        ret


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





