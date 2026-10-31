; The boot stub of ROM_SD_MENU. sd_menu streams it into sdram_rom when the
; SD card holds a filesystem, as the top of the 16 KB PRG ROM of an NROM
; image. It finds MENU.NES in the root directory of the card's FAT16 or FAT32
; filesystem (see fat.s) and launches it through the registers of sd_menu,
; keeping menu mode so that the menu can read the card.
;
; Errors are shown as the backdrop color. The codes are listed in fat.inc;
; $17 means there is no MENU.NES. Entries with the directory or volume bit
; are skipped, which covers long name entries.

.include "fat.inc"

ATTR_SKIP = ATTR_DIR | ATTR_VOLUME

.code

reset:
    sei
    cld
    ldx #$FF
    txs
    inx
    stx PPU_CTRL
    stx PPU_MASK

    jsr mount
    lda #0
    sta clus
    sta clus + 1
    sta clus + 2
    sta clus + 3
    jsr dir_open
@entry:
    jsr dir_next
    bcs @not_found
    ldy #0
    lda (ptr), y
    cmp #$E5
    beq @entry
    ldy #DIR_ATTR
    lda (ptr), y
    and #ATTR_SKIP
    bne @entry
    ldy #10
@name:
    lda (ptr), y
    cmp menu_name, y
    bne @entry
    dey
    bpl @name

    jsr entry_clus
    jsr build_extents
    bcs @fragmented
    lda #LAUNCH_MENU
    jmp launch
@not_found:
    lda #ERR_NOT_FOUND
    .byte $2C       ; bit abs: skips the next lda
@fragmented:
    lda #ERR_FRAGMENTED

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

menu_name:
    .byte "MENU    NES"

.segment "VECTORS"
    .word nmi, reset, irq
