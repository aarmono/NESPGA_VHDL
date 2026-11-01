; What menu.s and save.s share. Include fat.inc first

; The menu's 8 KB of PRG RAM at $6000 is a bank of cartridge RAM that sd_menu
; selects (see board/de1/sd_menu.vhdl). Banks 0-7 are the game's PRG RAM,
; and MENU_BANK, which games do not use, holds the menu's own data, so that
; it is still there when the menu comes back after a game
MENU_BANK = 24
WRAM      = $6000

MAX_DEPTH = 7
; Per level: the parent's cluster (4 bytes), page and row
DIR_BYTES = 6
; The width of the list, and of the titles
NAME_COLS = 27
TITLE_BYTES = NAME_COLS + 1

; Kept while a game runs, and valid if FLAG_RESUME is set:
; The directory and the cursor: cur_clus, depth, page and row
RESUME       = WRAM
RESUME_BYTES = 7
; Per level of the directory stack
DIRS         = WRAM + $10
; Per level: the title, zero terminated
TITLES       = DIRS + MAX_DEPTH * DIR_BYTES
; The serial number of the card that holds the save, the blocks to write
; back, and the save file's extents, in the format of TABLE
SAVE_SERIAL  = WRAM + $1F8
SAVE_BLOCKS  = WRAM + $1FC
SAVE_EXTENTS = WRAM + $200

; The full name of the entry that next_item read last, full_len UCS-2
; characters, lowest byte first
FULLNAME     = WRAM + $400
; The name of the save file being looked for or made, game_len characters
GAMENAME     = WRAM + $600
; The clusters of a new save file, 4 bytes each
CLIST        = WRAM + $800
MAX_NAME     = 255

.assert TITLES + MAX_DEPTH * TITLE_BYTES <= SAVE_SERIAL, error, "WRAM"

; next_item: 0 lists .NES files and directories, 1 returns every file,
; hidden ones too
.globalzp item_mode
.globalzp full_len
; The directory and the cursor
.globalzp cur_clus, depth, page, row

.global next_item, lfn_offsets
; save.s
.global prepare_launch, write_back
