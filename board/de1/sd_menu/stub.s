; The boot stub of ROM_SD_MENU. sd_menu streams it into sdram_rom when the
; SD card holds a filesystem, as the top of the 16 KB PRG ROM of an NROM
; image. It finds MENU.NES in the root directory of the card's FAT16 or FAT32
; filesystem and launches it through the registers of sd_menu, keeping menu
; mode so that the menu can read the card.
;
; The card is either a superfloppy, with the FAT boot sector at block 0, or
; has an MBR whose first partition is FAT16 (type $04, $06 or $0E) or FAT32
; (type $0B or $0C). FAT32 is told from FAT16 by a zero 16 bit FAT size in
; the BPB, so small FAT32 volumes work too.
;
; Errors are shown as the backdrop color:
;   $11  The card failed
;   $12  Block 0, or the partition's first block, does not end in $55 $AA
;   $13  The card has a GPT (protective MBR, partition type $EE)
;   $14  The first partition is not FAT16 or FAT32 (exFAT, NTFS, ...)
;   $15  No FAT boot sector at block 0 or at the start of the partition
;   $16  The filesystem is FAT12
;   $17  There is no MENU.NES in the root directory
;   $18  MENU.NES is empty, or its cluster chain is broken
;
; If MENU.NES has more than 64 extents, only the first 64 are launched, and
; sd_menu fails the launch if they do not hold the whole file.

BUF        = $5000
REG_BLOCK  = $5200
REG_STATUS = $5200
REG_READ   = $5204
REG_LAUNCH = $5205

; Bit 0 of the value written to REG_LAUNCH: stay in menu mode
LAUNCH_MENU = $01

STATUS_BUSY   = $80
STATUS_FAILED = $40

PPU_CTRL   = $2000
PPU_MASK   = $2001
PPU_STATUS = $2002
PPU_ADDR   = $2006
PPU_DATA   = $2007

; The extent table is built here, since reading the FAT uses the buffer
TABLE = $0300

ERR_CARD      = $11
ERR_SIGNATURE = $12
ERR_GPT       = $13
ERR_PARTITION = $14
ERR_BOOT      = $15
ERR_FAT12     = $16
ERR_NOT_FOUND = $17
ERR_CHAIN     = $18

; Boot sector fields
BPB_SEC_PER_CLUS = BUF + $0D
BPB_RESERVED     = BUF + $0E
BPB_NUM_FATS     = BUF + $10
BPB_ROOT_ENTRIES = BUF + $11
BPB_TOTAL_16     = BUF + $13
BPB_FAT_SIZE_16  = BUF + $16
BPB_TOTAL_32     = BUF + $20
BPB_FAT_SIZE_32  = BUF + $24
BPB_ROOT_CLUS    = BUF + $2C

MBR_TYPE  = BUF + $1C2
MBR_START = BUF + $1C6

; Directory entry fields
DIR_ATTR     = 11
DIR_CLUS_HI  = 20
DIR_CLUS_LO  = 26
; Directory and volume label, which also covers long name entries
ATTR_SKIP    = $18

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

.zeropage

; The block to read
block:     .res 4
; The block in the buffer, if cache_ok is set
cached:    .res 4
cache_ok:  .res 1
fat_lba:   .res 4
; The first block of cluster 2
data_lba:  .res 4
; FAT16: the first block of the root directory
root_lba:  .res 4
clus:      .res 4
tmp:       .res 4
; Blocks left in the run of directory blocks being searched
count:     .res 2
sec_per_clus: .res 1
clus_shift:   .res 1
; Bit 7 set for FAT32
fat32:     .res 1
ptr:       .res 2
; The extent being built in TABLE
ext_ptr:   .res 2
; The block after the last extent
ext_end:   .res 4

.code

reset:
    sei
    cld
    ldx #$FF
    txs
    inx
    stx PPU_CTRL
    stx PPU_MASK
    stx cache_ok

    stx block
    stx block + 1
    stx block + 2
    stx block + 3
    jsr read_block
    jsr check_signature
    jsr check_boot
    bcs filesystem

    lda MBR_TYPE
    cmp #$EE
    bne @not_gpt
    lda #ERR_GPT
    jmp fail
@not_gpt:
    ldx #PARTITION_TYPES - 1
@type:
    cmp partition_types, x
    beq @partition
    dex
    bpl @type
    lda #ERR_PARTITION
    jmp fail

@partition:
    copy32 block, MBR_START
    jsr read_block
    jsr check_signature
    jsr check_boot
    bcs filesystem
    lda #ERR_BOOT
    jmp fail

; block is the boot sector, which is in the buffer
filesystem:
    clc
    lda block
    adc BPB_RESERVED
    sta fat_lba
    lda block + 1
    adc BPB_RESERVED + 1
    sta fat_lba + 1
    lda block + 2
    adc #0
    sta fat_lba + 2
    lda block + 3
    adc #0
    sta fat_lba + 3

    ; The size of a FAT. The 16 bit size is 0 on FAT32
    ldx #0
    stx tmp + 2
    stx tmp + 3
    lda BPB_FAT_SIZE_16
    sta tmp
    lda BPB_FAT_SIZE_16 + 1
    sta tmp + 1
    ora tmp
    bne @fat16
    copy32 tmp, BPB_FAT_SIZE_32
    dex
@fat16:
    stx fat32

    copy32 data_lba, fat_lba
    ldx BPB_NUM_FATS
@fats:
    add32 data_lba, tmp
    dex
    bne @fats

    bit fat32
    bpl @root16
    copy32 clus, BPB_ROOT_CLUS
    jmp search

@root16:
    ; The root directory comes before cluster 2, in (entries + 15) / 16
    ; blocks
    copy32 root_lba, data_lba
    clc
    lda BPB_ROOT_ENTRIES
    adc #15
    sta count
    lda BPB_ROOT_ENTRIES + 1
    adc #0
    ldx #4
@div16:
    lsr a
    ror count
    dex
    bne @div16
    sta count + 1

    clc
    lda data_lba
    adc count
    sta data_lba
    lda data_lba + 1
    adc count + 1
    sta data_lba + 1
    bcc @fat12
    inc data_lba + 2
    bne @fat12
    inc data_lba + 3

    ; FAT12 has fewer than 4085 clusters: the blocks from data_lba to the
    ; end of the volume, block + total, shifted down by clus_shift
@fat12:
    lda BPB_TOTAL_16
    sta tmp
    lda BPB_TOTAL_16 + 1
    sta tmp + 1
    ldx #0
    stx tmp + 2
    stx tmp + 3
    ora tmp
    bne @total
    copy32 tmp, BPB_TOTAL_32
@total:
    add32 tmp, block
    sec
    .repeat 4, i
        lda tmp + i
        sbc data_lba + i
        sta tmp + i
    .endrepeat
    ldx clus_shift
    beq @clusters
@shift:
    lsr tmp + 3
    ror tmp + 2
    ror tmp + 1
    ror tmp
    dex
    bne @shift
@clusters:
    lda tmp + 3
    ora tmp + 2
    bne @not_fat12
    lda tmp
    cmp #<4085
    lda tmp + 1
    sbc #>4085
    bcs @not_fat12
    lda #ERR_FAT12
    jmp fail
@not_fat12:
    copy32 block, root_lba
    jmp search_block

; Search the root directory for MENU.NES. A FAT32 root directory is a
; cluster chain starting at clus
search:
    jsr clus_to_block
search_block:
    jsr read_block
    lda #<BUF
    sta ptr
    lda #>BUF
    sta ptr + 1
@entry:
    ldy #0
    lda (ptr), y
    beq not_found
    cmp #$E5
    beq @next
    ldy #DIR_ATTR
    lda (ptr), y
    and #ATTR_SKIP
    bne @next
    ldy #10
@name:
    lda (ptr), y
    cmp menu_name, y
    bne @next
    dey
    bpl @name
    jmp found
@next:
    clc
    lda ptr
    adc #32
    sta ptr
    bcc @entry
    inc ptr + 1
    lda ptr + 1
    cmp #>(BUF + $200)
    bne @entry

    inc block
    bne @count
    inc block + 1
    bne @count
    inc block + 2
    bne @count
    inc block + 3
@count:
    lda count
    bne @dec
    dec count + 1
@dec:
    dec count
    lda count
    ora count + 1
    bne search_block

    bit fat32
    bpl not_found
    jsr next_clus
    bcc search
not_found:
    lda #ERR_NOT_FOUND
    jmp fail

; ptr is MENU.NES's directory entry
found:
    ldy #DIR_CLUS_LO
    lda (ptr), y
    sta clus
    iny
    lda (ptr), y
    sta clus + 1
    lda #0
    sta clus + 2
    sta clus + 3
    bit fat32
    bpl @lo
    ldy #DIR_CLUS_HI
    lda (ptr), y
    sta clus + 2
    iny
    lda (ptr), y
    sta clus + 3
@lo:
    jsr check_clus

    ldx #0
    txa
@clear:
    sta TABLE, x
    sta TABLE + $100, x
    inx
    bne @clear
    stx ext_end
    stx ext_end + 1
    stx ext_end + 2
    stx ext_end + 3
    ; Before the first entry, since the first cluster starts a new extent:
    ; no cluster starts at block 0
    lda #<(TABLE - 8)
    sta ext_ptr
    lda #>(TABLE - 8)
    sta ext_ptr + 1

@cluster:
    jsr clus_to_block
    ldx #3
@contiguous:
    lda block, x
    cmp ext_end, x
    bne @new
    dex
    bpl @contiguous

    ldy #4
    clc
    lda (ext_ptr), y
    adc sec_per_clus
    sta (ext_ptr), y
    iny
    lda (ext_ptr), y
    adc #0
    sta (ext_ptr), y
    jmp @end

@new:
    clc
    lda ext_ptr
    adc #8
    sta ext_ptr
    bcc @entry
    inc ext_ptr + 1
@entry:
    lda ext_ptr + 1
    cmp #>(TABLE + $200)
    beq launch
    ldy #3
@start:
    lda block, y
    sta (ext_ptr), y
    dey
    bpl @start
    ldy #4
    lda sec_per_clus
    sta (ext_ptr), y

@end:
    clc
    lda block
    adc sec_per_clus
    sta ext_end
    .repeat 3, i
        lda block + i + 1
        adc #0
        sta ext_end + i + 1
    .endrepeat

    jsr next_clus
    bcc @cluster

launch:
    ldx #0
@copy:
    lda TABLE, x
    sta BUF, x
    lda TABLE + $100, x
    sta BUF + $100, x
    inx
    bne @copy
    lda #LAUNCH_MENU
    sta REG_LAUNCH
    ; The NES is held in reset from here until MENU.NES is loaded
@wait:
    jmp @wait

; Reads block into the buffer, unless it is already there
read_block:
    lda cache_ok
    beq @read
    ldx #3
@cached:
    lda block, x
    cmp cached, x
    bne @read
    dex
    bpl @cached
    rts
@read:
    ; Commands are ignored during a read, which a reset can leave running
@idle:
    bit REG_STATUS
    bmi @idle
    ldx #0
@shift:
    lda block, x
    sta REG_BLOCK
    sta cached, x
    inx
    cpx #4
    bne @shift
    sta REG_READ
@busy:
    lda REG_STATUS
    bmi @busy
    and #STATUS_FAILED
    bne @failed
    lda #1
    sta cache_ok
    rts
@failed:
    lda #ERR_CARD
    jmp fail

check_signature:
    lda BUF + $1FE
    cmp #$55
    bne @bad
    lda BUF + $1FF
    cmp #$AA
    bne @bad
    rts
@bad:
    lda #ERR_SIGNATURE
    jmp fail

; Carry set if the buffer holds a FAT boot sector: a jump, 512 byte
; blocks, a power of two blocks per cluster and at least one FAT. Sets
; sec_per_clus and clus_shift
check_boot:
    lda BUF
    cmp #$E9
    beq @bpb
    cmp #$EB
    bne @no
    lda BUF + 2
    cmp #$90
    bne @no
@bpb:
    lda BUF + $0B
    bne @no
    lda BUF + $0C
    cmp #2
    bne @no
    lda BPB_NUM_FATS
    beq @no
    lda BPB_SEC_PER_CLUS
    beq @no
    sta sec_per_clus
    ldx #0
@log2:
    lsr a
    bcs @one
    inx
    bne @log2
@one:
    bne @no
    stx clus_shift
    sec
    rts
@no:
    clc
    rts

; block = the first block of cluster clus, count = blocks per cluster
clus_to_block:
    sec
    lda clus
    sbc #2
    sta block
    .repeat 3, i
        lda clus + i + 1
        sbc #0
        sta block + i + 1
    .endrepeat
    ldx clus_shift
    beq @add
@shift:
    asl block
    rol block + 1
    rol block + 2
    rol block + 3
    dex
    bne @shift
@add:
    add32 block, data_lba
    lda sec_per_clus
    sta count
    lda #0
    sta count + 1
    rts

; clus = the cluster after clus in its chain. Carry set at the end of the
; chain
next_clus:
    ; The entry's byte offset in the FAT
    copy32 tmp, clus
    asl tmp
    rol tmp + 1
    rol tmp + 2
    rol tmp + 3
    bit fat32
    bpl @offset
    asl tmp
    rol tmp + 1
    rol tmp + 2
    rol tmp + 3
@offset:
    lda tmp
    sta ptr
    lda tmp + 1
    and #1
    ora #>BUF
    sta ptr + 1

    lda #0
    sta block + 3
    lda tmp + 3
    lsr a
    sta block + 2
    lda tmp + 2
    ror a
    sta block + 1
    lda tmp + 1
    ror a
    sta block
    add32 block, fat_lba
    jsr read_block

    ldy #0
    lda (ptr), y
    sta clus
    iny
    lda (ptr), y
    sta clus + 1
    bit fat32
    bmi @fat32
    lda #0
    sta clus + 2
    sta clus + 3
    lda clus + 1
    cmp #$FF
    bne check_clus
    beq @last
@fat32:
    iny
    lda (ptr), y
    sta clus + 2
    iny
    lda (ptr), y
    and #$0F
    sta clus + 3
    cmp #$0F
    bne check_clus
    lda clus + 2
    and clus + 1
    cmp #$FF
    bne check_clus
    ; $FFF7 and $0FFFFFF7 mark bad clusters, which are never in a chain, and
    ; the values above that end it
@last:
    lda clus
    cmp #$F7
    bcc check_clus
    rts

; Fails unless clus is a cluster number. Carry clear
check_clus:
    lda clus + 3
    ora clus + 2
    ora clus + 1
    bne @ok
    lda clus
    cmp #2
    bcs @ok
    lda #ERR_CHAIN
    jmp fail
@ok:
    clc
    rts

; Shows color A in the backdrop, forever
fail:
    tax
    ; The PPU ignores writes until the second vblank after power up
    bit PPU_STATUS
@vblank1:
    bit PPU_STATUS
    bpl @vblank1
@vblank2:
    bit PPU_STATUS
    bpl @vblank2
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    stx PPU_DATA
    ; Off the palette, so that rendering off shows the backdrop
    sta PPU_ADDR
    sta PPU_ADDR
@forever:
    jmp @forever

nmi:
irq:
    rti

partition_types:
    .byte $04, $06, $0E, $0B, $0C
PARTITION_TYPES = * - partition_types

menu_name:
    .byte "MENU    NES"

.segment "VECTORS"
    .word nmi, reset, irq
