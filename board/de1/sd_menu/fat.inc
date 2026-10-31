; The registers of sd_menu (see board/de1/sd_menu.vhdl) and the FAT code
; that the boot stub and the menu share, in fat.s

BUF        = $5000
REG_BLOCK  = $5200
REG_STATUS = $5200
REG_FLAGS  = $5201
REG_READ   = $5204
REG_LAUNCH = $5205
REG_WRITE  = $5206
REG_BANK   = $5207

; The value written to REG_LAUNCH. Bit 0: stay in menu mode. Bit 1: keep
; PRG RAM, which holds a save
LAUNCH_MENU     = $01
LAUNCH_KEEP_RAM = $02

STATUS_BUSY   = $80
STATUS_FAILED = $40
; The flags, which only the board's reset (power on) clears. The menu sets
; FLAG_SAVE while a game runs whose save is in PRG RAM and not yet written
; back, and FLAG_RESUME once what it keeps in cartridge RAM is valid
FLAG_SAVE     = $01
FLAG_RESUME   = $02

PPU_CTRL   = $2000
PPU_MASK   = $2001
PPU_STATUS = $2002
PPU_SCROLL = $2005
PPU_ADDR   = $2006
PPU_DATA   = $2007

; The extent table of a launch is built here, since reading the FAT uses the
; buffer. 64 entries of 8 bytes, in the format of sd_menu's launch table
TABLE = $0300

; Error codes, which the stub shows as the backdrop color:
;   $11  The card failed
;   $12  Block 0, or the partition's first block, does not end in $55 $AA
;   $13  The card has a GPT (protective MBR, partition type $EE)
;   $14  The first partition is not FAT16 or FAT32 (exFAT, NTFS, ...)
;   $15  No FAT boot sector at block 0 or at the start of the partition
;   $16  The filesystem is FAT12
;   $17  There is no MENU.NES in the root directory
;   $18  The file is empty, or its cluster chain is broken
;   $19  The file has more than 64 extents
; and, in the menu:
;   $1A  The file is not an iNES file
;   $1B  There is no room in the directory for a save file
;   $1C  There is no room on the card for a save file
;   $1D  A save is waiting to be written back, but the card was changed
ERR_CARD       = $11
ERR_SIGNATURE  = $12
ERR_GPT        = $13
ERR_PARTITION  = $14
ERR_BOOT       = $15
ERR_FAT12      = $16
ERR_NOT_FOUND  = $17
ERR_CHAIN      = $18
ERR_FRAGMENTED = $19
ERR_NOT_INES   = $1A
ERR_DIR_FULL   = $1B
ERR_DISK_FULL  = $1C
ERR_WRONG_CARD = $1D

; Directory entry fields
DIR_ATTR     = 11
DIR_CASE     = 12
DIR_CLUS_HI  = 20
DIR_CLUS_LO  = 26
DIR_SIZE     = 28

ATTR_HIDDEN  = $02
ATTR_VOLUME  = $08
ATTR_DIR     = $10
; The attribute bits of a long name entry
ATTR_LFN     = $0F
ATTR_LFN_MASK = $3F

; The block to read
.globalzp block
; The cluster that next_clus, clus_to_block, dir_open and build_extents use
.globalzp clus
; The directory entry that dir_next returns
.globalzp ptr
; Scratch, which the routines of fat.s clobber
.globalzp tmp
; Bit 7 set for FAT32
.globalzp fat32
; What mount found: the volume's first block and serial number, the first
; block, size in blocks and number of the FATs, the number of clusters
; (from cluster 2) and the blocks per cluster, and its log2
.globalzp vol_lba, vol_serial, fat_lba, fat_size, num_fats, clus_count
.globalzp sec_per_clus, clus_shift
; The block in the buffer, if cache_ok is nonzero
.globalzp cached, cache_ok
; Bit 7 set: dir_next does not stop at the end marker of the directory, so
; that it returns every entry in the directory's blocks
.globalzp dir_all
; The position of dir_next in its directory, DIR_STATE_BYTES bytes, which
; can be saved and restored to read entries again
.globalzp dir_state
DIR_STATE_BYTES = 11

; Shows error A. Each program has its own. It must not return
.global fail

.global mount, read_block, write_block, dir_open, dir_next, entry_clus
.global build_extents, launch, check_clus, clus_to_block, fat_locate
.global fat_where

.macro copy32 dst, src
    .repeat 4, i
        lda src + i
        sta dst + i
    .endrepeat
.endmacro

.macro add32 dst, src
    clc
    .repeat 4, i
        lda dst + i
        adc src + i
        sta dst + i
    .endrepeat
.endmacro

.macro inc32 dst
    inc dst
    bne :+
    inc dst + 1
    bne :+
    inc dst + 2
    bne :+
    inc dst + 3
:
.endmacro
