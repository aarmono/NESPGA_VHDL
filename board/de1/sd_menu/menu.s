; The SD card menu of ROM_SD_MENU, MENU.NES in the root directory of the
; card. The boot stub launches it in menu mode, so it can read the card
; through the registers of sd_menu (see board/de1/sd_menu.vhdl and fat.s).
;
; It lists the .NES files and the directories of a directory, in the order
; they are on the card, with their long names. Hidden entries, names
; starting with '.' and MENU.NES in the root directory are left out. Up and down move the cursor, left and
; right move by a page, A or Start opens a directory or launches a file, and
; B goes back up.
;
; The header declares 8 KB of PRG RAM, which sd_menu maps to a bank of
; cartridge RAM that games do not use (see menu.inc). The stub and the menu
; are launched with PRG RAM kept, so the previous game's PRG RAM is still
; there for save.s to write back. The directory and the cursor are kept in
; the menu's bank too, so the menu comes back where it was after a game.
; A directory is read once when it is opened, to count its entries and to
; note where each page starts. Each page is then read again when it is
; shown. Up to MAX_PAGES pages of a directory are listed.
;
; Errors show a message, with the error's color (see fat.inc) as the
; backdrop. A goes back to the directory after a failed launch, and to the
; root directory after other errors. If writing a save back fails, A tries
; again.

.include "fat.inc"
.include "menu.inc"

PPU_OAM_ADDR = $2003
OAM_DMA      = $4014
APU_DMC      = $4010
JOY1         = $4016
APU_FRAME    = $4017

BUTTON_A      = $80
BUTTON_B      = $40
BUTTON_SELECT = $20
BUTTON_START  = $10
BUTTON_UP     = $08
BUTTON_DOWN   = $04
BUTTON_LEFT   = $02
BUTTON_RIGHT  = $01
BUTTON_DIRS   = $0F

; Frames until a held direction repeats, then between repeats
REPEAT_DELAY = 16
REPEAT_RATE  = 4

CTRL_NMI = $80
MASK_ON  = $1E

; The tile of the cursor sprite. Other tiles are their ASCII codes
TILE_CURSOR = $01

; Screen layout, in tiles
TITLE_ROW  = 2
FIRST_ROW  = 4
ROWS       = 22
FOOTER_ROW = 27
CURSOR_COL = 2
NAME_COL   = 3
PAGE_COL   = 24

MAX_PAGES = 80

KIND_FILE = 0
KIND_DIR  = 1

; RAM. The page table shares its first 512 bytes with TABLE, which is only
; built to launch
OAM         = $0200
PAGES       = $0300
; The entry's name as shown: up to 39 characters of its full name, then
; room for a / and the terminator
NAME        = PAGES + MAX_PAGES * DIR_STATE_BYTES
NAME_BYTES  = 41
LFN_CHARS   = 39
; Long name entries: 13 characters each, 255 in all
LFN_MAX     = 20

.assert TABLE = PAGES, error, "TABLE"
.assert NAME + NAME_BYTES <= $0800, error, "out of RAM"

.zeropage

nmi_count:   .res 1
mask_shadow: .res 1
buttons:     .res 1
pressed:     .res 1
repeat:      .res 1
; The directions to act on this frame
act:         .res 1

; The directory, 0 for the root, how deep it is, and the cursor, in the
; order of RESUME
cur_clus:    .res 4
depth:       .res 1
page:        .res 1
row:         .res 1
; The last entry of the directory
last_page:   .res 1
last_row:    .res 1
; Nonzero if the directory has no entries to list
empty:       .res 1

mounted:     .res 1
launching:   .res 1
err:         .res 1

; next_item
kind:        .res 1
lfn_ok:      .res 1
lfn_seq:     .res 1
lfn_sum:     .res 1
; The sequence number of the first long name entry, the number of entries
lfn_count:   .res 1
item_mode:   .res 1
full_len:    .res 1
fn:          .res 2
case_bits:   .res 1
case_flag:   .res 1
char:        .res 1
index:       .res 1
; The position before the entry being read, and before the first entry of
; the item, its long name or its short entry
ent_state:   .res DIR_STATE_BYTES
item_state:  .res DIR_STATE_BYTES

pg_ptr:      .res 2
str:         .res 2
counter:     .res 1

.segment "HEADER"
    ; NES 2.0, mapper 0, 1 16 KB PRG ROM bank, 1 8 KB CHR ROM bank, 8 KB of
    ; PRG RAM, no CHR RAM, NTSC
    .byte "NES", $1A, 1, 1, $00, $08, 0, 0, $07, 0, 0, 0, 0, 0

.segment "CHARS"
    .incbin "font.chr"

.macro print_at r, c, s
    lda #<s
    sta str
    lda #>s
    sta str + 1
    lda #r
    ldx #c
    jsr ppu_at
    jsr print
.endmacro

; Copies character n of a long name entry, at offset off in the entry at
; ptr, to (fn)
.macro lfn_char off, n
    ldy #off
    lda (ptr), y
    ldy #2 * n
    sta (fn), y
    ldy #off + 1
    lda (ptr), y
    ldy #2 * n + 1
    sta (fn), y
.endmacro

.code

reset:
    sei
    cld
    ldx #$FF
    txs
    inx
    stx PPU_CTRL
    stx PPU_MASK
    stx APU_DMC
    lda #$40
    sta APU_FRAME
    ; The PPU ignores writes until the second vblank after power up
    bit PPU_STATUS
@vblank1:
    bit PPU_STATUS
    bpl @vblank1
@vblank2:
    bit PPU_STATUS
    bpl @vblank2

    ; Zero page, then the sprites hidden
    lda #0
@zp:
    sta $00, x
    inx
    bne @zp
    lda #$FF
@oam:
    sta OAM, x
    inx
    bne @oam
    jsr load_palette
    lda #MENU_BANK
    sta REG_BANK
    ; Buttons held now, such as the Start and Select that returned to the
    ; menu, count as pressed only once they are released and pressed again
    jsr read_joy

    jsr mount
    jsr write_back
    inc mounted

; Reads the directory cur_clus and shows the page with the cursor
open_dir:
    ldx #$FF
    txs
    lda #0
    sta launching
    jsr scan
    ; Keep the cursor in the directory
    lda last_page
    cmp page
    bcs @page_ok
    sta page
    lda last_row
    sta row
@page_ok:
    lda page
    cmp last_page
    bne @row_ok
    lda last_row
    cmp row
    bcs @row_ok
    sta row
@row_ok:
    jsr draw_page

main_loop:
    jsr wait_frame
    jsr read_joy
    lda pressed
    and #BUTTON_A | BUTTON_START
    beq @not_open
    jmp open_item
@not_open:
    lda pressed
    and #BUTTON_B
    beq @not_back
    jmp back
@not_back:
    lda pressed
    and #BUTTON_DIRS
    beq @held
    sta act
    lda #REPEAT_DELAY
    sta repeat
    bne @move
@held:
    lda buttons
    and #BUTTON_DIRS
    beq main_loop
    dec repeat
    bne main_loop
    lda #REPEAT_RATE
    sta repeat
    lda buttons
    and #BUTTON_DIRS
    sta act
@move:
    lda empty
    bne main_loop
    lda page
    pha
    lda act
    and #BUTTON_UP
    beq :+
    jsr cursor_up
:   lda act
    and #BUTTON_DOWN
    beq :+
    jsr cursor_down
:   lda act
    and #BUTTON_LEFT
    beq :+
    jsr page_left
:   lda act
    and #BUTTON_RIGHT
    beq :+
    jsr page_right
:   pla
    cmp page
    beq @same_page
    jsr draw_page
    jmp main_loop
@same_page:
    jsr place_cursor
    jmp main_loop

cursor_up:
    lda row
    bne @row
    lda page
    bne @page
    ; Wrap to the last entry
    lda last_page
    sta page
    lda last_row
    sta row
    rts
@page:
    dec page
    lda #ROWS
    sta row
@row:
    dec row
    rts

cursor_down:
    lda page
    cmp last_page
    bne @not_last
    lda row
    cmp last_row
    bne @next
    ; Wrap to the first entry
    lda #0
    sta page
    sta row
    rts
@not_last:
    lda row
    cmp #ROWS - 1
    bne @next
    inc page
    lda #0
    sta row
    rts
@next:
    inc row
    rts

page_left:
    lda page
    beq @first
    dec page
    rts
@first:
    lda #0
    sta row
    rts

page_right:
    lda page
    cmp last_page
    beq @last
    inc page
    lda page
    cmp last_page
    bne @done
    lda last_row
    cmp row
    bcs @done
@last:
    lda last_row
    sta row
@done:
    rts

; Opens the directory or launches the file under the cursor
open_item:
    lda empty
    beq @select
    jmp main_loop
@select:
    jsr select_item
    lda kind
    cmp #KIND_DIR
    beq @dir

    inc launching
    jsr prepare_launch
    pha
    jsr screen_off
    pla
    jmp launch

@dir:
    lda depth
    cmp #MAX_DEPTH
    bne @push
    jmp main_loop
@push:
    ; DIRS + DIR_BYTES * depth
    asl a
    adc depth
    asl a
    tax
    .repeat 4, i
        lda cur_clus + i
        sta DIRS + i, x
    .endrepeat
    lda page
    sta DIRS + 4, x
    lda row
    sta DIRS + 5, x
    copy32 cur_clus, clus
    inc depth
    ; The title of the new level
    jsr format_name
    jsr title_ptr
    ldy #0
@title:
    lda NAME, y
    sta (str), y
    beq @titled
    iny
    cpy #NAME_COLS
    bne @title
    lda #0
    sta (str), y
@titled:
    lda #0
    sta page
    sta row
    jmp open_dir

; Goes back to the parent directory
back:
    lda depth
    bne @pop
    jmp main_loop
@pop:
    dec depth
    lda depth
    asl a
    adc depth
    asl a
    tax
    .repeat 4, i
        lda DIRS + i, x
        sta cur_clus + i
    .endrepeat
    lda DIRS + 4, x
    sta page
    lda DIRS + 5, x
    sta row
    jmp open_dir

; str = the title of level depth, which is not the root
title_ptr:
    lda #<(TITLES - TITLE_BYTES)
    sta str
    lda #>(TITLES - TITLE_BYTES)
    sta str + 1
    ldx depth
@add:
    clc
    lda str
    adc #TITLE_BYTES
    sta str
    bcc :+
    inc str + 1
:   dex
    bne @add
    rts

; Counts the entries of directory cur_clus, noting where each page starts
scan:
    copy32 clus, cur_clus
    jsr dir_open
    lda #0
    sta last_page
    sta last_row
    sta counter     ; Rows of the page so far
    lda #1
    sta empty
    lda #0
    jsr page_entry
@item:
    jsr next_item
    bcs @done
    lda counter
    bne @counted
    ; The first entry of a page
    lda empty
    beq @next_page
    dec empty
    beq @note
@next_page:
    lda last_page
    cmp #MAX_PAGES - 1
    beq @done
    inc last_page
    clc
    lda pg_ptr
    adc #DIR_STATE_BYTES
    sta pg_ptr
    bcc @note
    inc pg_ptr + 1
@note:
    ldy #DIR_STATE_BYTES - 1
@copy:
    lda item_state, y
    sta (pg_ptr), y
    dey
    bpl @copy
@counted:
    lda counter
    sta last_row
    inc counter
    lda counter
    cmp #ROWS
    bne @item
    lda #0
    sta counter
    beq @item
@done:
    rts

; pg_ptr = the page table entry of page A
page_entry:
    tax
    lda #<PAGES
    sta pg_ptr
    lda #>PAGES
    sta pg_ptr + 1
    cpx #0
    beq @done
@add:
    clc
    lda pg_ptr
    adc #DIR_STATE_BYTES
    sta pg_ptr
    bcc :+
    inc pg_ptr + 1
:   dex
    bne @add
@done:
    rts

; Reads from the start of page page
restore_page:
    lda page
    jsr page_entry
    ldy #DIR_STATE_BYTES - 1
@copy:
    lda (pg_ptr), y
    sta dir_state, y
    dey
    bpl @copy
    rts

; Reads the entry under the cursor: kind, NAME and clus
select_item:
    jsr restore_page
    ldx row
    inx
    stx counter
@item:
    jsr next_item
    bcs @gone
    dec counter
    bne @item
    rts
@gone:
    ; The card changed under the menu
    lda #ERR_CHAIN
    jmp fail

; Reads the next entry of the directory to list, a .NES file or a
; directory, or with item_mode 1 any file: kind, its full name in FULLNAME
; and full_len, the name to show in NAME, and its first cluster in clus. Its
; long name is used if it has one that is whole and whose checksum matches
; the short entry. Carry set at the end of the directory
next_item:
    lda #0
    sta lfn_ok
@entry:
    ldx #DIR_STATE_BYTES - 1
@save:
    lda dir_state, x
    sta ent_state, x
    dex
    bpl @save
    jsr dir_next
    bcc @read
    rts
@read:
    ldy #0
    lda (ptr), y
    cmp #$E5
    bne @used
    jmp @orphan
@used:
    ldy #DIR_ATTR
    lda (ptr), y
    and #ATTR_LFN_MASK
    cmp #ATTR_LFN
    beq @lfn
    jmp @short

@lfn:
    ldy #0
    lda (ptr), y
    and #$40
    beq @continued
    ; The first entry of a long name holds its last characters
    lda (ptr), y
    and #$1F
    cmp #LFN_MAX + 1
    bcs @orphan
    sta lfn_seq
    sta lfn_count
    ldy #13
    lda (ptr), y
    sta lfn_sum
    ldx #DIR_STATE_BYTES - 1
@start:
    lda ent_state, x
    sta item_state, x
    dex
    bpl @start
    lda #1
    sta lfn_ok
    bne @chars

@continued:
    lda lfn_ok
    beq @entry
    ldy #13
    lda (ptr), y
    cmp lfn_sum
    bne @orphan
    ldy #0
    lda (ptr), y
    tax
    inx
    cpx lfn_seq
    bne @orphan
    sta lfn_seq

@chars:
    ; The entry's 13 characters go to FULLNAME from (lfn_seq - 1) * 13
    ldx lfn_seq
    beq @orphan
    jsr lfn_copy
    jmp @entry

@orphan:
    lda #0
    sta lfn_ok
    jmp @entry

@short:
    ldy #DIR_ATTR
    lda (ptr), y
    ldx item_mode
    and skip_attrs, x
    bne @orphan
    lda lfn_ok
    beq @short_name
    lda lfn_seq
    cmp #1
    bne @short_name
    ; The checksum of the short name
    ldy #0
    lda #0
@sum:
    lsr a
    bcc :+
    ora #$80
:   clc
    adc (ptr), y
    iny
    cpy #11
    bne @sum
    cmp lfn_sum
    bne @short_name
    jsr lfn_name
    jmp @named

@short_name:
    ldx #DIR_STATE_BYTES - 1
@here:
    lda ent_state, x
    sta item_state, x
    dex
    bpl @here
    ldy #DIR_CASE
    lda (ptr), y
    sta case_bits
    lda #$08
    sta case_flag
    ldx #0
    ldy #0
@base:
    jsr short_char
    iny
    cpy #8
    bne @base
    jsr trim
    ldy #8
    lda (ptr), y
    cmp #' '
    beq @no_ext
    lda #'.'
    sta NAME, x
    inx
    lda #$10
    sta case_flag
@ext:
    jsr short_char
    iny
    cpy #11
    bne @ext
    jsr trim
@no_ext:
    lda #0
    sta NAME, x
    ; The full name is the same
    stx full_len
    txa
    asl a
    tay
@full:
    dey
    bmi @named
    lda #0
    sta FULLNAME, y
    dey
    dex
    lda NAME, x
    sta FULLNAME, y
    tya
    bne @full

@named:
    lda #0
    sta lfn_ok
    lda NAME
    cmp #'.'
    bne @shown
    jmp @entry
@shown:
    ldy #DIR_ATTR
    lda (ptr), y
    and #ATTR_DIR
    bne @dir
    lda item_mode
    bne @file
    ldy #8
    lda (ptr), y
    cmp #'N'
    bne @skip
    iny
    lda (ptr), y
    cmp #'E'
    bne @skip
    iny
    lda (ptr), y
    cmp #'S'
    bne @skip
    ; The menu itself
    lda depth
    bne @file
    ldy #10
@menu:
    lda (ptr), y
    cmp menu_name, y
    bne @file
    dey
    bpl @menu
    bmi @skip
@file:
    lda #KIND_FILE
    beq @found
@skip:
    jmp @entry
@dir:
    lda item_mode
    bne @skip
    lda #KIND_DIR
@found:
    sta kind
    jsr entry_clus
    clc
    rts

; Copies the 13 characters of the long name entry at ptr, whose sequence
; number is X, to FULLNAME
lfn_copy:
    jsr lfn_ptr
    ; Unrolled, as this is most of the time taken to list a directory
    lfn_char 1, 0
    lfn_char 3, 1
    lfn_char 5, 2
    lfn_char 7, 3
    lfn_char 9, 4
    lfn_char 14, 5
    lfn_char 16, 6
    lfn_char 18, 7
    lfn_char 20, 8
    lfn_char 22, 9
    lfn_char 24, 10
    lfn_char 28, 11
    lfn_char 30, 12
    rts

; fn = FULLNAME + (X - 1) * 26, where the characters of long name entry X
; go
lfn_ptr:
    lda #<FULLNAME
    sta fn
    lda #>FULLNAME
    sta fn + 1
@add:
    dex
    beq @done
    clc
    lda fn
    adc #26
    sta fn
    bcc @add
    inc fn + 1
    bne @add
@done:
    rts

; The long name is whole: full_len is its length, up to its terminator, and
; NAME is its first LFN_CHARS characters, with ? for those that are not
; ASCII
lfn_name:
    ; The terminator can only be in the last entry
    ldx lfn_count
    jsr lfn_ptr
    lda #0
    ldx lfn_count
@base:
    dex
    beq @find
    clc
    adc #13
    bne @base
@find:
    sta full_len
    ldy #0
@terminator:
    lda (fn), y
    iny
    ora (fn), y
    beq @length
    iny
    inc full_len
    beq @too_long
    cpy #26
    bne @terminator
    beq @length
@too_long:
    dec full_len
@length:

    lda #<FULLNAME
    sta fn
    lda #>FULLNAME
    sta fn + 1
    ldx #0
@char:
    cpx full_len
    beq @end
    cpx #LFN_CHARS
    beq @end
    txa
    asl a
    tay
    iny
    lda (fn), y
    bne @bad
    dey
    lda (fn), y
    cmp #$20
    bcc @bad
    cmp #$7F
    bcc @store
@bad:
    lda #'?'
@store:
    sta NAME, x
    inx
    bne @char
@end:
    lda #0
    sta NAME, x
    rts

; NAME, x = the character of the short entry at y, in lower case if
; case_flag is set in case_bits. Advances x
short_char:
    lda (ptr), y
    cmp #'A'
    bcc @store
    cmp #'Z' + 1
    bcs @printable
    pha
    lda case_bits
    and case_flag
    beq :+
    pla
    ora #$20
    bne @store
:   pla
    bne @store
@printable:
    cmp #$7F
    bcc @store
    lda #'?'
@store:
    cmp #' '
    bcs :+
    lda #'?'
:   sta NAME, x
    inx
    rts

; Moves x back over the spaces at the end of NAME
trim:
    cpx #0
    beq @done
    lda NAME - 1, x
    cmp #' '
    bne @done
    dex
    bne trim
@done:
    rts

; Makes NAME the text shown for the entry: without .nes for files, and
; with a / after directories
format_name:
    ldx #0
@length:
    lda NAME, x
    beq @end
    inx
    cpx #LFN_CHARS
    bne @length
@end:
    lda kind
    bne @dir
    cpx #5
    bcc @done
    lda NAME - 4, x
    cmp #'.'
    bne @done
    lda NAME - 3, x
    ora #$20
    cmp #'n'
    bne @done
    lda NAME - 2, x
    ora #$20
    cmp #'e'
    bne @done
    lda NAME - 1, x
    ora #$20
    cmp #'s'
    bne @done
    dex
    dex
    dex
    dex
    bne @done
@dir:
    lda #'/'
    sta NAME, x
    inx
@done:
    lda #0
    sta NAME, x
    rts

; Shows the page of the cursor
draw_page:
    jsr screen_off
    jsr clear_screen

    lda #TITLE_ROW
    ldx #NAME_COL
    jsr ppu_at
    lda depth
    bne @title
    lda #'/'
    sta PPU_DATA
    jmp @titled
@title:
    jsr title_ptr
    jsr print
@titled:

    lda empty
    beq @entries
    print_at FIRST_ROW, NAME_COL, no_entries_text
    jmp @footer

@entries:
    jsr restore_page
    lda #0
    sta counter
@entry:
    jsr next_item
    bcs @footer
    jsr format_name
    lda counter
    clc
    adc #FIRST_ROW
    ldx #NAME_COL
    jsr ppu_at
    ldx #0
@char:
    lda NAME, x
    beq @next
    sta PPU_DATA
    inx
    cpx #NAME_COLS
    bne @char
@next:
    lda page
    cmp last_page
    bne @full
    lda counter
    cmp last_row
    beq @footer
@full:
    inc counter
    lda counter
    cmp #ROWS
    bne @entry

@footer:
    print_at FOOTER_ROW, NAME_COL, footer_text
    lda empty
    bne @no_pages
    lda #FOOTER_ROW
    ldx #PAGE_COL
    jsr ppu_at
    ldx page
    inx
    txa
    jsr print_dec
    lda #'/'
    sta PPU_DATA
    ldx last_page
    inx
    txa
    jsr print_dec
@no_pages:
    jsr place_cursor
    jmp screen_on

; Puts the cursor sprite on the cursor's row
place_cursor:
    lda empty
    beq @shown
    lda #$FF
    sta OAM
    rts
@shown:
    lda row
    clc
    adc #FIRST_ROW
    asl a
    asl a
    asl a
    sbc #0          ; Carry is clear: sprites are drawn a line low
    sta OAM
    lda #TILE_CURSOR
    sta OAM + 1
    lda #0
    sta OAM + 2
    lda #CURSOR_COL * 8
    sta OAM + 3
    rts

; Shows error A until A, B or Start is pressed, then goes back to the
; directory after a failed launch, and to the root directory after other
; errors
fail:
    ldx #$FF
    txs
    sta err
    lda #MENU_BANK
    sta REG_BANK
    lda #0
    sta item_mode
    sta dir_all
    jsr screen_off
    jsr clear_screen
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda err
    sta PPU_DATA

    print_at TITLE_ROW, NAME_COL, error_text
    lda err
    sec
    sbc #ERR_CARD
    asl a
    tax
    lda error_messages, x
    sta str
    lda error_messages + 1, x
    sta str + 1
    lda #FIRST_ROW
    ldx #NAME_COL
    jsr ppu_at
    jsr print
    print_at FOOTER_ROW, NAME_COL, continue_text
    lda #$FF
    sta OAM
    jsr screen_on

@wait:
    jsr wait_frame
    jsr read_joy
    lda pressed
    and #BUTTON_A | BUTTON_B | BUTTON_START
    beq @wait

    jsr screen_off
    jsr load_palette
    lda mounted
    bne @mounted
    jmp reset
@mounted:
    lda launching
    bne @directory
    lda #0
    sta depth
    sta cur_clus
    sta cur_clus + 1
    sta cur_clus + 2
    sta cur_clus + 3
    sta page
    sta row
@directory:
    jmp open_dir

; buttons = the buttons held, pressed = those pressed since the last call
read_joy:
    lda buttons
    pha
    lda #1
    sta JOY1
    lda #0
    sta JOY1
    ldx #8
@bit:
    lda JOY1
    and #$03
    cmp #1
    rol buttons
    dex
    bne @bit
    pla
    eor #$FF
    and buttons
    sta pressed
    rts

wait_frame:
    lda nmi_count
@wait:
    cmp nmi_count
    beq @wait
    rts

; Turns rendering and NMIs off, at the next vblank if they are on
screen_off:
    lda mask_shadow
    beq @off
    jsr wait_frame
@off:
    lda #0
    sta mask_shadow
    sta PPU_MASK
    sta PPU_CTRL
    rts

; Turns NMIs on, and rendering on at the next one
screen_on:
    lda #MASK_ON
    sta mask_shadow
    bit PPU_STATUS
    lda #CTRL_NMI
    sta PPU_CTRL
    rts

nmi:
    pha
    lda #0
    sta PPU_OAM_ADDR
    lda #>OAM
    sta OAM_DMA
    lda mask_shadow
    sta PPU_MASK
    lda #0
    sta PPU_SCROLL
    sta PPU_SCROLL
    lda #CTRL_NMI
    sta PPU_CTRL
    inc nmi_count
    pla
irq:
    rti

load_palette:
    lda #$3F
    sta PPU_ADDR
    ldx #0
    stx PPU_ADDR
@copy:
    lda palette, x
    sta PPU_DATA
    inx
    cpx #32
    bne @copy
    rts

; Fills nametable 0 and its attributes with 0, a blank tile
clear_screen:
    lda #$20
    sta PPU_ADDR
    lda #0
    sta PPU_ADDR
    ldy #4
    tax
@fill:
    sta PPU_DATA
    inx
    bne @fill
    dey
    bne @fill
    rts

; Sets the PPU address to row A, column X of nametable 0
ppu_at:
    pha
    lsr a
    lsr a
    lsr a
    ora #$20
    sta PPU_ADDR
    pla
    asl a
    asl a
    asl a
    asl a
    asl a
    sta char
    txa
    ora char
    sta PPU_ADDR
    rts

; Writes the zero terminated string at str
print:
    ldy #0
@char:
    lda (str), y
    beq @done
    sta PPU_DATA
    iny
    bne @char
@done:
    rts

; Writes A, less than 100, in decimal
print_dec:
    ldx #'0' - 1
    sec
@tens:
    inx
    sbc #10
    bcs @tens
    adc #'0' + 10
    cpx #'0'
    beq @ones
    stx PPU_DATA
@ones:
    sta PPU_DATA
    rts

.rodata

; The attributes of short entries that next_item skips, by item_mode
skip_attrs:
    .byte ATTR_VOLUME | ATTR_HIDDEN, ATTR_VOLUME
; The offsets of the 13 characters in a long name entry
lfn_offsets:
    .byte 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30

palette:
    .byte $0F, $00, $10, $30, $0F, $00, $10, $30
    .byte $0F, $00, $10, $30, $0F, $00, $10, $30
    .byte $0F, $2A, $2A, $2A, $0F, $2A, $2A, $2A
    .byte $0F, $2A, $2A, $2A, $0F, $2A, $2A, $2A

menu_name:       .byte "MENU    NES"
no_entries_text: .asciiz "No games here"
footer_text:     .asciiz "A:Open  B:Back"
error_text:      .asciiz "Error"
continue_text:   .asciiz "Press A"

error_messages:
    .word err_card, err_signature, err_gpt, err_partition, err_boot
    .word err_fat12, err_not_found, err_chain, err_fragmented
    .word err_not_ines, err_dir_full, err_disk_full, err_wrong_card

err_card:       .asciiz "SD card failed"
err_signature:  .asciiz "No MBR or boot sector"
err_gpt:        .asciiz "GPT cards are not supported"
err_partition:  .asciiz "Not a FAT16/FAT32 partition"
err_boot:       .asciiz "No FAT boot sector"
err_fat12:      .asciiz "FAT12 is not supported"
err_not_found:  .asciiz "File not found"
err_chain:      .asciiz "Broken or empty file"
err_fragmented: .asciiz "File has over 64 fragments"
err_not_ines:   .asciiz "Not an iNES file"
err_dir_full:   .asciiz "No room in the folder"
err_disk_full:  .asciiz "The card is full"
err_wrong_card: .asciiz "Card changed: save not written"

.segment "VECTORS"
    .word nmi, reset, irq
