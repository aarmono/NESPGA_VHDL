; Saves for the menu of ROM_SD_MENU: battery backed PRG RAM kept in .sav
; files next to the games.
;
; A game's save covers the start of PRG RAM: the PRG NVRAM size of a NES 2.0
; header, or 8 KB for an iNES header with the battery bit. A NES 2.0 header
; without PRG NVRAM has no save the board can reach (EEPROMs and other chip
; RAM are inside the mapper).
;
; Before a game with a save is launched, the menu looks in its directory for
; the file whose full name (the long name, or else the short name) is the
; game's with .sav in place of .nes, ignoring the case of ASCII letters. If
; there is none, one is made: it gets that long name, a short name made from
; its first cluster (Snnnnnnn.SAV, which no other file can have), and
; zeroes. PRG RAM is cleared, the file is read into it, and the file's
; extents are kept in the menu's bank. FLAG_SAVE is set and the game is
; launched with LAUNCH_KEEP_RAM, so that its power up leaves PRG RAM alone.
;
; When the menu comes back after the game (Start and Select held), PRG RAM,
; which the stub and the menu leave alone, is written back to the file
; before anything else, and FLAG_SAVE is cleared. An existing file smaller
; than the save is read and written back as far as it goes.
;
; A new file's clusters are found before anything is written, and its
; cluster chain is written to every FAT before its directory entries, so
; that a failure part way leaves at worst lost clusters. The directory is
; not grown: if it has no room for the entries, ERR_DIR_FULL. On FAT32 the
; search for free clusters starts at the FSInfo sector's next free hint, and
; the sector's free count and hint are kept up to date.

.include "fat.inc"
.include "menu.inc"

BPB_FSINFO = BUF + $30
FSI_FREE   = BUF + $1E8
FSI_NEXT   = BUF + $1EC

; The date given to the files made: 2026-01-01
FILE_DATE = ((2026 - 1980) << 9) | (1 << 5) | 1

; What for_blocks does with each block
OP_ZERO  = 0
OP_LOAD  = 1
OP_STORE = 2

; The extents in TABLE
EXTENTS = 64

; The directory entries being made: a long name entry, and the short entry
ENTRY       = WRAM + $A00
SHORT_ENTRY = WRAM + $A20

.assert <GAMENAME = 0, error, "GAMENAME must be page aligned"

.zeropage

; Blocks of PRG RAM that the save covers, 0 if there is none
save_blocks: .res 1
; Blocks of the save file to read and write back
file_blocks: .res 1
game_clus:   .res 4
game_len:    .res 1
launch_val:  .res 1
flag_val:    .res 1

; for_blocks
op:          .res 1
w_count:     .res 1
w_i:         .res 1
w_off:       .res 2
w_ptr:       .res 2
r_ptr:       .res 2

p1:          .res 2
p2:          .res 2
chr:         .res 1

; make_save
lfn_count:   .res 1
slots:       .res 1
run:         .res 1
slot_state:  .res DIR_STATE_BYTES
ent_tmp:     .res DIR_STATE_BYTES
need:        .res 1
found:       .res 1
scan:        .res 4
scan_left:   .res 4
clus_end:    .res 4
fat_blk:     .res 4
fat_i:       .res 1
val:         .res 4
cur_seq:     .res 1
csum:        .res 1
; The FAT block in the buffer, fat_blk, has entries set but not written
fat_dirty:   .res 1
; The save file was made, so it holds zeroes
made:        .res 1

.code

; Gets the file under the cursor, whose first cluster is clus and whose
; name is in FULLNAME, ready to launch: its save is read into PRG RAM, the
; flags are set, and its extents are in TABLE. Returns the value to write
; to REG_LAUNCH
prepare_launch:
    copy32 game_clus, clus
    jsr read_header
    lda #0
    sta launch_val
    lda #FLAG_RESUME
    sta flag_val
    lda save_blocks
    beq @launch

    jsr save_name
    lda #0
    sta made
    jsr find_save
    bcc @found
    jsr make_save
    inc made
@found:
    jsr build_extents
    bcs @fragmented
    ldx #0
@copy:
    lda TABLE, x
    sta SAVE_EXTENTS, x
    lda TABLE + $100, x
    sta SAVE_EXTENTS + $100, x
    inx
    bne @copy
    lda file_blocks
    sta SAVE_BLOCKS
    copy32 SAVE_SERIAL, vol_serial

    jsr clear_ram
    lda made
    bne @loaded
    lda #OP_LOAD
    ldx file_blocks
    jsr for_blocks
@loaded:
    lda #LAUNCH_KEEP_RAM
    sta launch_val
    lda #FLAG_RESUME | FLAG_SAVE
    sta flag_val

@launch:
    ldx #RESUME_BYTES - 1
@resume:
    lda cur_clus, x
    sta RESUME, x
    dex
    bpl @resume

    copy32 clus, game_clus
    jsr build_extents
    bcs @fragmented
    lda flag_val
    sta REG_FLAGS
    lda launch_val
    rts
@fragmented:
    lda #ERR_FRAGMENTED
    jmp fail

; Writes PRG RAM back to the save file if FLAG_SAVE is set, then clears it.
; Then restores the directory and the cursor if FLAG_RESUME is set
write_back:
    lda REG_STATUS
    and #FLAG_SAVE
    beq @resume
    ldx #3
@serial:
    lda SAVE_SERIAL, x
    cmp vol_serial, x
    bne @wrong_card
    dex
    bpl @serial

    ldx #0
@copy:
    lda SAVE_EXTENTS, x
    sta TABLE, x
    lda SAVE_EXTENTS + $100, x
    sta TABLE + $100, x
    inx
    bne @copy
    lda #OP_STORE
    ldx SAVE_BLOCKS
    jsr for_blocks
    lda #FLAG_RESUME
    sta REG_FLAGS

@resume:
    lda REG_STATUS
    and #FLAG_RESUME
    beq @done
    ldx #RESUME_BYTES - 1
@restore:
    lda RESUME, x
    sta cur_clus, x
    dex
    bpl @restore
@done:
    rts
@wrong_card:
    lda #ERR_WRONG_CARD
    jmp fail

; Reads the iNES header of the file whose first cluster is clus:
; save_blocks, and file_blocks the same
read_header:
    jsr check_clus
    jsr clus_to_block
    jsr read_block
    ldx #3
@magic:
    lda BUF, x
    cmp ines_magic, x
    bne @not_ines
    dex
    bpl @magic

    ; X = 0 from here
    inx
    lda BUF + 6
    and #$02
    beq @done
    ldx #16
    lda BUF + 7
    and #$0C
    cmp #$08
    bne @done
    ; NES 2.0: 64 << n bytes of PRG NVRAM, which is 1 << (n - 3) blocks, at
    ; least 1, and at most the 128 of the PRG RAM window
    ldx #0
    lda BUF + 10
    lsr a
    lsr a
    lsr a
    lsr a
    beq @done
    ldx #1
    cmp #10
    bcc @max
    lda #10
@max:
    sec
    sbc #3
    beq @done
    bcc @done
    tay
@double:
    txa
    asl a
    tax
    dey
    bne @double
@done:
    stx save_blocks
    stx file_blocks
    rts
@not_ines:
    lda #ERR_NOT_INES
    jmp fail

; GAMENAME = FULLNAME with .sav in place of .nes, in the case of each
; letter replaced, or with .sav added if it does not end in .nes
save_name:
    ldx #0
@copy:
    lda FULLNAME, x
    sta GAMENAME, x
    lda FULLNAME + $100, x
    sta GAMENAME + $100, x
    inx
    bne @copy
    lda full_len
    sta game_len

    cmp #4
    bcc @add
    sbc #4
    jsr name_ptr
    ldy #0
    lda #'.'
    jsr name_is
    bne @add
    ldx #0
@ext:
    iny
    iny
    lda nes_ext, x
    jsr name_is
    bne @add
    inx
    cpx #3
    bne @ext
    ldx #2
@replace:
    lda (p1), y
    and #$20
    ora sav_ext, x
    sta (p1), y
    dey
    dey
    dex
    bpl @replace
    rts

@add:
    ; Over the end of a name too long for .sav to be added
    lda game_len
    cmp #MAX_NAME - 3
    bcc @room
    lda #MAX_NAME - 4
@room:
    sta chr
    jsr name_ptr
    ldx #0
    ldy #0
@char:
    lda dot_sav, x
    sta (p1), y
    iny
    lda #0
    sta (p1), y
    iny
    inx
    cpx #4
    bne @char
    clc
    lda chr
    adc #4
    sta game_len
    rts

; p1 = GAMENAME + 2 * A, character A of GAMENAME
name_ptr:
    asl a
    sta p1
    lda #>GAMENAME
    adc #0
    sta p1 + 1
    rts

; Z set if the character at (p1), y is A, an upper case letter or another
; ASCII character, in either case. Keeps X and Y
name_is:
    sta chr
    iny
    lda (p1), y
    dey
    ora #0
    bne @done
    lda (p1), y
    jsr upper
    cmp chr
@done:
    rts

; A in upper case, if it is an ASCII letter
upper:
    cmp #'a'
    bcc @done
    cmp #'z' + 1
    bcs @done
    and #$DF
@done:
    rts

; Looks in directory cur_clus for the file named GAMENAME. Carry clear if
; it is there: clus is its first cluster, and file_blocks is no more than
; the blocks it holds
find_save:
    copy32 clus, cur_clus
    jsr dir_open
    inc item_mode
@next:
    jsr next_item
    bcs @none
    lda full_len
    cmp game_len
    bne @next
    lda #<FULLNAME
    sta p1
    lda #>FULLNAME
    sta p1 + 1
    lda #<GAMENAME
    sta p2
    lda #>GAMENAME
    sta p2 + 1
    ldx game_len
@char:
    ldy #1
    lda (p1), y
    cmp (p2), y
    bne @next
    dey
    ora #0
    bne @exact
    ; ASCII, so the case of letters does not matter
    lda (p1), y
    jsr upper
    sta chr
    lda (p2), y
    jsr upper
    cmp chr
    bne @next
    beq @same
@exact:
    lda (p1), y
    cmp (p2), y
    bne @next
@same:
    clc
    lda p1
    adc #2
    sta p1
    bcc :+
    inc p1 + 1
:   clc
    lda p2
    adc #2
    sta p2
    bcc :+
    inc p2 + 1
:   dex
    bne @char

    ; The blocks the file holds, rounded up. 64 KB or more holds the
    ; largest save
    dec item_mode
    ldy #DIR_SIZE + 3
    lda (ptr), y
    dey
    ora (ptr), y
    bne @whole
    dey
    lda (ptr), y
    lsr a
    sta chr
    bcs @up
    dey
    lda (ptr), y
    beq @blocks
@up:
    inc chr
@blocks:
    lda chr
    cmp save_blocks
    bcs @whole
    sta file_blocks
@whole:
    clc
    rts
@none:
    dec item_mode
    sec
    rts

; Makes the file GAMENAME in directory cur_clus, save_blocks long and
; zeroed. clus is its first cluster
make_save:
    ; Long name entries of 13 characters, and the short entry
    lda game_len
    ldx #0
@div:
    inx
    sec
    sbc #13
    beq @counted
    bcs @div
@counted:
    stx lfn_count
    inx
    stx slots
    jsr find_slots
    jsr alloc

    copy32 clus, CLIST
    jsr build_extents
    ldx #0
    txa
    sta cache_ok
@zero:
    sta BUF, x
    sta BUF + $100, x
    inx
    bne @zero
    lda #OP_ZERO
    ldx save_blocks
    jsr for_blocks

    jsr write_entries
    jsr update_fsinfo
    copy32 clus, CLIST
    rts

; Finds slots free entries in a row in directory cur_clus: slot_state is
; the directory position before the first
find_slots:
    copy32 clus, cur_clus
    jsr dir_open
    lda #$80
    sta dir_all
    lda #0
    sta run
@entry:
    ldx #DIR_STATE_BYTES - 1
@save:
    lda dir_state, x
    sta ent_tmp, x
    dex
    bpl @save
    jsr dir_next
    bcs @full
    ldy #0
    lda (ptr), y
    beq @free
    cmp #$E5
    beq @free
    lda #0
    sta run
    beq @entry
@free:
    lda run
    bne @counted
    ldx #DIR_STATE_BYTES - 1
@first:
    lda ent_tmp, x
    sta slot_state, x
    dex
    bpl @first
@counted:
    inc run
    lda run
    cmp slots
    bne @entry
    lda #0
    sta dir_all
    rts
@full:
    lda #ERR_DIR_FULL
    jmp fail

; Finds the free clusters for save_blocks blocks, puts them in CLIST, and
; chains them in every FAT
alloc:
    ; need = (save_blocks + sec_per_clus - 1) >> clus_shift
    clc
    lda save_blocks
    adc sec_per_clus
    sec
    sbc #1
    ldx clus_shift
    beq @need
@shift:
    lsr a
    dex
    bne @shift
@need:
    sta need

    clc
    lda clus_count
    adc #2
    sta clus_end
    .repeat 3, i
        lda clus_count + i + 1
        adc #0
        sta clus_end + i + 1
    .endrepeat
    copy32 scan_left, clus_count

    ; From the FSInfo hint if it is a cluster, otherwise from cluster 2
    lda #2
    sta scan
    lda #0
    sta scan + 1
    sta scan + 2
    sta scan + 3
    jsr fsinfo
    bcc @search
    copy32 val, FSI_NEXT
    lda val + 3
    ora val + 2
    ora val + 1
    bne @not_low
    lda val
    cmp #2
    bcc @search
@not_low:
    sec
    .repeat 4, i
        lda val + i
        sbc clus_end + i
    .endrepeat
    bcs @search
    copy32 scan, val

@search:
    lda #<CLIST
    sta p2
    lda #>CLIST
    sta p2 + 1
    lda #0
    sta found
@next:
    lda scan_left
    ora scan_left + 1
    ora scan_left + 2
    ora scan_left + 3
    bne @look
    lda #ERR_DISK_FULL
    jmp fail
@look:
    copy32 clus, scan
    jsr is_free
    bne @used
    ldy #3
@note:
    lda scan, y
    sta (p2), y
    dey
    bpl @note
    clc
    lda p2
    adc #4
    sta p2
    bcc :+
    inc p2 + 1
:   inc found
    lda found
    cmp need
    beq @got
@used:
    inc32 scan
    ldx #3
@end:
    lda scan, x
    cmp clus_end, x
    bne @in
    dex
    bpl @end
    lda #2
    sta scan
    lda #0
    sta scan + 1
    sta scan + 2
    sta scan + 3
@in:
    ; scan_left - 1, borrowing through the bytes that are 0
    lda scan_left
    bne @dec0
    lda scan_left + 1
    bne @dec1
    lda scan_left + 2
    bne @dec2
    dec scan_left + 3
@dec2:
    dec scan_left + 2
@dec1:
    dec scan_left + 1
@dec0:
    dec scan_left
    jmp @next

@got:
    ; The new file must fit in the launch table
    lda #<CLIST
    sta p1
    lda #>CLIST
    sta p1 + 1
    lda #1
    sta fat_i
    ldx need
    dex
    beq @fits
@extent:
    ldy #0
    sec
@plus1:
    lda (p1), y
    adc #0
    sta val, y
    iny
    cpy #4
    bne @plus1
@cmp:
    lda (p1), y
    cmp val - 4, y
    bne @break
    iny
    cpy #8
    bne @cmp
    beq @run
@break:
    inc fat_i
@run:
    clc
    lda p1
    adc #4
    sta p1
    bcc :+
    inc p1 + 1
:   dex
    bne @extent
    lda fat_i
    cmp #EXTENTS + 1
    bcc @fits
    lda #ERR_FRAGMENTED
    jmp fail

@fits:
    ; Each cluster points at the next, and the last ends the chain
    lda #0
    sta fat_dirty
    lda #<CLIST
    sta p1
    lda #>CLIST
    sta p1 + 1
    lda need
    sta found
@link:
    ; clus = this cluster, val = the next, which the entry after the last
    ; is not
    ldy #3
@cur:
    lda (p1), y
    sta clus, y
    dey
    bpl @cur
    ldy #4
@next_clus:
    lda (p1), y
    sta val - 4, y
    iny
    cpy #8
    bne @next_clus
    dec found
    bne @chain
    lda #$FF
    sta val
    sta val + 1
    sta val + 2
    lda #$0F
    sta val + 3
@chain:
    jsr set_fat
    clc
    lda p1
    adc #4
    sta p1
    bcc :+
    inc p1 + 1
:   lda found
    bne @link
    ; The last cluster, for the FSInfo hint
    copy32 scan, clus
    jmp fat_flush

; Z set if the FAT entry of cluster clus is 0, a free cluster
is_free:
    jsr fat_locate
    ldy #0
    lda (ptr), y
    iny
    ora (ptr), y
    sta tmp
    bit fat32
    bpl @done
    iny
    lda (ptr), y
    ora tmp
    sta tmp
    iny
    lda (ptr), y
    and #$0F
    ora tmp
    sta tmp
@done:
    lda tmp
    rts

; Sets the FAT entry of cluster clus to val, in the buffer. The block is
; written to every FAT by fat_flush, which is called first if the entry is
; in another block
set_fat:
    jsr fat_where
    lda fat_dirty
    beq @read
    ldx #3
@same:
    lda block, x
    cmp fat_blk, x
    bne @other
    dex
    bpl @same
    bmi @read
@other:
    jsr fat_flush
    jsr fat_where
@read:
    jsr read_block
    copy32 fat_blk, block
    lda #1
    sta fat_dirty
    ldy #0
    lda val
    sta (ptr), y
    iny
    lda val + 1
    sta (ptr), y
    bit fat32
    bpl @write
    iny
    lda val + 2
    sta (ptr), y
    ; The top 4 bits are reserved, and kept
    iny
    lda (ptr), y
    and #$F0
    sta tmp
    lda val + 3
    and #$0F
    ora tmp
    sta (ptr), y
@write:
    rts

; Writes the FAT block in the buffer, fat_blk, to every FAT, if it has
; entries that are not written yet. The last FAT first, so that the buffer
; is left holding the block of the first, which it was read from
fat_flush:
    lda fat_dirty
    beq @done
    lda #0
    sta fat_dirty
    ldx num_fats
@fat:
    dex
    stx fat_i
    copy32 block, fat_blk
@add:
    cpx #0
    beq @put
    add32 block, fat_size
    dex
    jmp @add
@put:
    jsr write_block
    ldx fat_i
    bne @fat
@done:
    rts

; Carry set if the filesystem is FAT32 with an FSInfo sector, which is then
; in the buffer, with block its block
fsinfo:
    bit fat32
    bpl @none
    copy32 block, vol_lba
    jsr read_block
    ; 0 and $FFFF mean there is none
    lda BPB_FSINFO
    ora BPB_FSINFO + 1
    beq @none
    lda BPB_FSINFO
    and BPB_FSINFO + 1
    cmp #$FF
    beq @none
    clc
    lda block
    adc BPB_FSINFO
    sta block
    lda block + 1
    adc BPB_FSINFO + 1
    sta block + 1
    lda block + 2
    adc #0
    sta block + 2
    lda block + 3
    adc #0
    sta block + 3
    jsr read_block
    ldx #3
@signature:
    lda BUF, x
    cmp fsi_lead, x
    bne @none
    lda BUF + $1E4, x
    cmp fsi_struct, x
    bne @none
    dex
    bpl @signature
    sec
    rts
@none:
    clc
    rts

; Takes need clusters off the FSInfo free count, unless it is unknown, and
; makes the last cluster allocated, in scan, the next free hint
update_fsinfo:
    jsr fsinfo
    bcc @done
    lda FSI_FREE
    and FSI_FREE + 1
    and FSI_FREE + 2
    and FSI_FREE + 3
    cmp #$FF
    beq @hint
    sec
    lda FSI_FREE
    sbc need
    sta FSI_FREE
    .repeat 3, i
        lda FSI_FREE + i + 1
        sbc #0
        sta FSI_FREE + i + 1
    .endrepeat
@hint:
    copy32 FSI_NEXT, scan
    jmp write_block
@done:
    rts

; Writes the long name entries of GAMENAME and its short entry, for the
; file at CLIST, to the free entries from slot_state
write_entries:
    jsr make_short
    ldx #DIR_STATE_BYTES - 1
@restore:
    lda slot_state, x
    sta dir_state, x
    dex
    bpl @restore
    lda #$80
    sta dir_all

    ; The long name entries, from the last
    lda lfn_count
    sta cur_seq
@lfn:
    jsr make_lfn
    lda #<ENTRY
    sta p1
    lda #>ENTRY
    sta p1 + 1
    jsr put_entry
    dec cur_seq
    bne @lfn

    lda #<SHORT_ENTRY
    sta p1
    lda #>SHORT_ENTRY
    sta p1 + 1
    jsr put_entry
    lda #0
    sta dir_all
    rts

; Writes the entry at p1 to the next entry of the directory
put_entry:
    jsr dir_next
    ldy #31
@copy:
    lda (p1), y
    sta (ptr), y
    dey
    bpl @copy
    jmp write_block

; The short entry of the new file at SHORT_ENTRY, and csum, its checksum
make_short:
    ldx #31
@template:
    lda short_template, x
    sta SHORT_ENTRY, x
    dex
    bpl @template
    ; Snnnnnnn: the first cluster in hex
    ldx #3
    ldy #1
@byte:
    lda CLIST, x
    lsr a
    lsr a
    lsr a
    lsr a
    cpx #3
    beq @low
    jsr hex
    sta SHORT_ENTRY, y
    iny
@low:
    lda CLIST, x
    and #$0F
    jsr hex
    sta SHORT_ENTRY, y
    iny
    dex
    bpl @byte

    lda CLIST
    sta SHORT_ENTRY + DIR_CLUS_LO
    lda CLIST + 1
    sta SHORT_ENTRY + DIR_CLUS_LO + 1
    lda CLIST + 2
    sta SHORT_ENTRY + DIR_CLUS_HI
    lda CLIST + 3
    sta SHORT_ENTRY + DIR_CLUS_HI + 1
    ; save_blocks * 512 bytes
    lda save_blocks
    asl a
    sta SHORT_ENTRY + DIR_SIZE + 1
    lda #0
    rol a
    sta SHORT_ENTRY + DIR_SIZE + 2

    ldx #0
    txa
@sum:
    lsr a
    bcc :+
    ora #$80
:   clc
    adc SHORT_ENTRY, x
    inx
    cpx #11
    bne @sum
    sta csum
    rts

; The hex digit of A, 0-15
hex:
    cmp #10
    bcc :+
    adc #'A' - '0' - 10 - 1
:   adc #'0'
    rts

; Long name entry cur_seq of GAMENAME at ENTRY
make_lfn:
    lda cur_seq
    cmp lfn_count
    bne :+
    ora #$40
:   sta ENTRY
    lda #ATTR_LFN
    sta ENTRY + DIR_ATTR
    lda #0
    sta ENTRY + 12
    sta ENTRY + 26
    sta ENTRY + 27
    lda csum
    sta ENTRY + 13

    ; Its first character is (cur_seq - 1) * 13
    lda #0
    ldx cur_seq
@base:
    dex
    beq @chars
    clc
    adc #13
    bne @base
@chars:
    sta chr
    ldx #0
@char:
    ldy lfn_offsets, x
    txa
    clc
    adc chr
    bcs @pad
    cmp game_len
    beq @end
    bcs @pad
    asl a
    sta p2
    lda #>GAMENAME
    adc #0
    sta p2 + 1
    tya
    pha
    ldy #0
    lda (p2), y
    sta val
    iny
    lda (p2), y
    sta val + 1
    pla
    tay
    lda val
    sta ENTRY, y
    lda val + 1
    sta ENTRY + 1, y
    jmp @next
@end:
    ; The terminator
    lda #0
    beq @store
@pad:
    lda #$FF
@store:
    sta ENTRY, y
    sta ENTRY + 1, y
@next:
    inx
    cpx #13
    bne @char
    rts

; Zeroes the PRG RAM that the save covers and that the file will not be
; read into: all of it for a file just made, which holds zeroes
clear_ram:
    lda #0
    ldx made
    bne @from
    lda file_blocks
@from:
    sta w_i
@block:
    lda w_i
    cmp save_blocks
    beq menu_bank
    jsr ram_select
    lda #0
    tay
@zero:
    sta (r_ptr), y
    iny
    bne @zero
    inc r_ptr + 1
@zero2:
    sta (r_ptr), y
    iny
    bne @zero2
    inc w_i
    bne @block

; Selects the menu's bank again
menu_bank:
    lda #MENU_BANK
    sta REG_BANK
    rts

; r_ptr = the PRG RAM of block w_i of the save, its bank selected
ram_select:
    lda w_i
    lsr a
    lsr a
    lsr a
    lsr a
    sta REG_BANK
    lda w_i
    and #$0F
    asl a
    ora #>WRAM
    sta r_ptr + 1
    lda #0
    sta r_ptr
    rts

; Does op to blocks 0 to X - 1 of the file whose extents are in TABLE:
; OP_ZERO writes the buffer to them, OP_LOAD reads each into PRG RAM, and
; OP_STORE writes PRG RAM to each
for_blocks:
    sta op
    stx w_count
    lda #<TABLE
    sta w_ptr
    lda #>TABLE
    sta w_ptr + 1
    lda #0
    sta w_i
    sta w_off
    sta w_off + 1
@loop:
    lda w_i
    cmp w_count
    bne @block
    rts
@block:
    ; The extents end before the blocks do if the cluster chain is shorter
    ; than the file's size. Block 0 + w_off must not be written then
    ldy #4
    lda (w_ptr), y
    iny
    ora (w_ptr), y
    bne @extent
    lda #ERR_CHAIN
    jmp fail
@extent:
    ldy #0
    clc
    lda (w_ptr), y
    adc w_off
    sta block
    iny
    lda (w_ptr), y
    adc w_off + 1
    sta block + 1
    iny
    lda (w_ptr), y
    adc #0
    sta block + 2
    iny
    lda (w_ptr), y
    adc #0
    sta block + 3

    lda op
    beq @write
    cmp #OP_LOAD
    beq @load
    jsr ram_select
    ldy #0
@from:
    lda (r_ptr), y
    sta BUF, y
    iny
    bne @from
    inc r_ptr + 1
@from2:
    lda (r_ptr), y
    sta BUF + $100, y
    iny
    bne @from2
    jsr menu_bank
@write:
    jsr write_block
    jmp @next
@load:
    jsr read_block
    jsr ram_select
    ldy #0
@to:
    lda BUF, y
    sta (r_ptr), y
    iny
    bne @to
    inc r_ptr + 1
@to2:
    lda BUF + $100, y
    sta (r_ptr), y
    iny
    bne @to2
    jsr menu_bank

@next:
    inc w_i
    inc w_off
    bne :+
    inc w_off + 1
:   ldy #4
    lda (w_ptr), y
    cmp w_off
    bne @same
    iny
    lda (w_ptr), y
    cmp w_off + 1
    bne @same
    ; The next extent
    clc
    lda w_ptr
    adc #8
    sta w_ptr
    bcc :+
    inc w_ptr + 1
:   lda #0
    sta w_off
    sta w_off + 1
@same:
    jmp @loop

.rodata

ines_magic: .byte "NES", $1A
nes_ext:    .byte "NES"
sav_ext:    .byte "SAV"
dot_sav:    .byte ".sav"
fsi_lead:   .byte "RRaA"
fsi_struct: .byte "rrAa"

short_template:
    .byte "S0000000SAV"
    .byte $20                       ; Archive
    .byte 0, 0, 0, 0                ; Case, creation time
    .word FILE_DATE, FILE_DATE      ; Creation and access dates
    .word 0, 0                      ; Cluster high, write time
    .word FILE_DATE
    .word 0                         ; Cluster low
    .dword 0                        ; Size
