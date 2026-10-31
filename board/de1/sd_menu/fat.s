; The FAT code that the boot stub and the menu share. It reads the card
; through the registers of sd_menu (see board/de1/sd_menu.vhdl).
;
; The card is either a superfloppy, with the FAT boot sector at block 0, or
; has an MBR whose first partition is FAT16 (type $04, $06 or $0E) or FAT32
; (type $0B or $0C). FAT32 is told from FAT16 by a zero 16 bit FAT size in
; the BPB, so small FAT32 volumes work too. Errors go to fail, with the codes
; in fat.inc.

.include "fat.inc"

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
BPB_SERIAL_16    = BUF + $27
BPB_SERIAL_32    = BUF + $43

MBR_TYPE  = BUF + $1C2
MBR_START = BUF + $1C6

.zeropage

block:     .res 4
; The block in the buffer, if cache_ok is set
cached:    .res 4
cache_ok:  .res 1
; The block of the boot sector, and the volume's serial number
vol_lba:   .res 4
vol_serial: .res 4
fat_lba:   .res 4
fat_size:  .res 4
num_fats:  .res 1
; The number of clusters, from cluster 2
clus_count: .res 4
; The first block of cluster 2
data_lba:  .res 4
; FAT16: the first block of the root directory. FAT32: its first cluster
root:      .res 4
; FAT16: the blocks of the root directory
root_count: .res 2
clus:      .res 4
tmp:       .res 4
sec_per_clus: .res 1
clus_shift:   .res 1
fat32:     .res 1
ptr:       .res 2
; Bit 7 set: dir_next does not stop at the end marker
dir_all:   .res 1
; The extent being built in TABLE
ext_ptr:   .res 2
; The block after the last extent
ext_end:   .res 4

dir_state:
; The cluster of the directory block in dir_block, 0 in a FAT16 root
dir_clus:  .res 4
dir_block: .res 4
; The blocks left in the cluster, or the FAT16 root, from dir_block
dir_count: .res 2
; The entry in dir_block that dir_next returns next. 16 moves to the next
; block
dir_entry: .res 1

.assert * - dir_state = DIR_STATE_BYTES, error, "DIR_STATE_BYTES"

.code

; Finds the filesystem on the card
mount:
    lda #0
    sta cache_ok
    sta block
    sta block + 1
    sta block + 2
    sta block + 3
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
    copy32 vol_lba, block
    lda BPB_NUM_FATS
    sta num_fats
    add32_16 fat_lba, block, BPB_RESERVED

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
    copy32 vol_serial, BPB_SERIAL_32
    dex
    bne @size
@fat16:
    copy32 vol_serial, BPB_SERIAL_16
@size:
    stx fat32
    copy32 fat_size, tmp

    copy32 data_lba, fat_lba
    ldx BPB_NUM_FATS
@fats:
    add32 data_lba, tmp
    dex
    bne @fats

    bit fat32
    bpl @root16
    copy32 root, BPB_ROOT_CLUS
    jmp @count

@root16:
    ; The root directory comes before cluster 2, in (entries + 15) / 16
    ; blocks
    copy32 root, data_lba
    clc
    lda BPB_ROOT_ENTRIES
    adc #15
    sta root_count
    lda BPB_ROOT_ENTRIES + 1
    adc #0
    ldx #4
@div16:
    lsr a
    ror root_count
    dex
    bne @div16
    sta root_count + 1

    clc
    lda data_lba
    adc root_count
    sta data_lba
    lda data_lba + 1
    adc root_count + 1
    sta data_lba + 1
    bcc @count
    inc data_lba + 2
    bne @count
    inc data_lba + 3

    ; The clusters: the blocks from data_lba to the end of the volume,
    ; block + total, shifted down by clus_shift. FAT12 has fewer than
    ; 4085
@count:
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
    copy32 clus_count, tmp
    bit fat32
    bmi @not_fat12
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
    rts

; Writes the buffer to block
write_block:
    ldy #REG_WRITE - REG_BLOCK
    bne block_cmd

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
    ldy #REG_READ - REG_BLOCK
    ; Falls through

; Sends block, then command Y, the offset of its register from REG_BLOCK.
; The buffer then holds block
block_cmd:
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
    sta REG_BLOCK, y
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

; block = the first block of cluster clus
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
    rts

; clus = the cluster after clus in its chain. Carry set at the end of the
; chain
next_clus:
    jsr fat_locate
    jmp fat_value

; Reads the block of the first FAT that holds the entry of cluster clus:
; block is that block, and ptr the entry in the buffer
fat_locate:
    jsr fat_where
    jmp read_block

; block = the block of the first FAT that holds the entry of cluster clus,
; and ptr = the entry in the buffer once the block is read
fat_where:
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
    rts

fat_value:
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

; Starts reading the directory at cluster clus, or the root directory if
; clus is 0
dir_open:
    lda #0
    sta dir_entry
    lda clus
    ora clus + 1
    ora clus + 2
    ora clus + 3
    bne @chain
    bit fat32
    bmi @root32
    copy32 dir_clus, clus
    copy32 dir_block, root
    lda root_count
    sta dir_count
    lda root_count + 1
    sta dir_count + 1
    rts
@root32:
    copy32 clus, root
@chain:
; Reads the directory from the start of cluster clus, part of its chain
dir_chain:
    copy32 dir_clus, clus
    jsr clus_to_block
    copy32 dir_block, block
    lda sec_per_clus
    sta dir_count
    lda #0
    sta dir_count + 1
    rts

; ptr = the next entry of the directory, carry clear. Carry set at the end
; of the directory: its end marker, or the end of its blocks
dir_next:
    lda dir_entry
    cmp #16
    bne @read
    lda #0
    sta dir_entry
    lda dir_count
    bne @dec
    dec dir_count + 1
@dec:
    dec dir_count
    lda dir_count
    ora dir_count + 1
    beq @run_end
    inc32 dir_block
    jmp @read
@run_end:
    lda dir_clus
    ora dir_clus + 1
    ora dir_clus + 2
    ora dir_clus + 3
    beq @end
    copy32 clus, dir_clus
    jsr next_clus
    bcs @end
    jsr dir_chain

@read:
    copy32 block, dir_block
    jsr read_block
    ; ptr = BUF + 32 * dir_entry
    lda dir_entry
    lsr a
    lsr a
    lsr a
    ora #>BUF
    sta ptr + 1
    lda dir_entry
    asl a
    asl a
    asl a
    asl a
    asl a
    sta ptr
    inc dir_entry
    bit dir_all
    bmi @entry
    ldy #0
    lda (ptr), y
    beq @end
@entry:
    clc
    rts
@end:
    sec
    rts

; Z set if the directory entry at ptr is MENU.NES. Changes A and Y
is_menu:
    ldy #10
:   lda (ptr), y
    cmp menu_name, y
    bne :+
    dey
    bpl :-
    lda #0
:   rts

menu_name:
    .byte "MENU    NES"

; clus = the first cluster of the file whose directory entry is at ptr
entry_clus:
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
    bpl @done
    ldy #DIR_CLUS_HI
    lda (ptr), y
    sta clus + 2
    iny
    lda (ptr), y
    sta clus + 3
@done:
    rts

; Builds the extent table in TABLE for the file whose first cluster is
; clus. Carry set if it has more than 64 extents
build_extents:
    jsr check_clus

    ldx #0
    txa
    fill512 TABLE
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
    add16i ext_ptr, 8
@entry:
    lda ext_ptr + 1
    cmp #>(TABLE + $200)
    bne @start
    ; Carry is set
    rts
@start:
    ldy #3
@block:
    lda block, y
    sta (ext_ptr), y
    dey
    bpl @block
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
    clc
    rts

; Launches the file whose extents are in TABLE, with A the value written to
; REG_LAUNCH. It does not return: the NES is held in reset until the file
; is loaded
launch:
    pha
    copy512 BUF, TABLE
    pla
    sta REG_LAUNCH
@wait:
    jmp @wait

partition_types:
    .byte $04, $06, $0E, $0B, $0C
PARTITION_TYPES = * - partition_types
