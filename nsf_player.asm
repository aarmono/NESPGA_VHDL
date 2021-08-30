
    processor 6502

MUSIC_INIT = $3702
MUSIC_PLAY = $3704
MUSIC_SONG = $3700
MUSIC_TYPE = $3701
INIT_ROUTINE = $3800
PLAY_ROUTINE = $3880

    seg INIT
    org INIT_ROUTINE
INIT subroutine
    ldx #$FF
    txs
    
    lda #((.ret >> 8) & $FF)
    pha
    lda #(.ret & $FF)
    pha
    
    lda MUSIC_SONG
    ldx MUSIC_TYPE

    jmp (MUSIC_INIT)

.ret nop
.loop lda #1
    bne .loop

    seg PLAY
    org PLAY_ROUTINE
PLAY subroutine
    
    lda #((.ret >> 8) & $FF)
    pha
    lda #(.ret & $FF)
    pha

    jmp (MUSIC_PLAY)

.ret nop
    
    rti

