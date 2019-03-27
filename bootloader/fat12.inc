
.equ    RootDirSectors, 14
.equ    SectorNumOfRootDirStart, 19
.equ    SectorNumOfFAT1Start, 1
.equ    SectorBalance, 17

#   FAT12
#============================================================================
BS_OEMName:
    .ascii      "Snowboot"
BPB_BytesPerSec:
    .hword       512
BPB_SecPerClus:
    .byte         1
BPB_RsvdSecCnt:
    .hword       1
BPB_NumFATs:
    .byte         2
BPB_RootEntCnt:
    .hword       224
BPB_TotSec16:
    .hword       2880
BPB_Media:
    .byte         0xf0
BPB_FATSz16:
    .hword       9
BPB_SecPerTrk:
    .hword       18
BPB_NumHeads:
    .hword       2
BPB_HiddSec:
    .long        0
BPB_TotSec32:
    .long        0
BS_DrvNum:
    .byte        0
BS_Reserved1:
    .byte        0
BS_BootSig:
    .byte        0x29
BS_VolID:
    .long        0
BS_VolLab:
    .ascii      "boot loader"
BS_FileSysType:
    .ascii      "FAT12   "
#============================================================================





