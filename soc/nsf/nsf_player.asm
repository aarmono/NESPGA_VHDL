
    processor 6502

MUSIC_INIT = $4102
MUSIC_PLAY = $4104
MUSIC_SONG = $4100
MUSIC_TYPE = $4101
INIT_ROUTINE = $4200
PLAY_ROUTINE = $4280

MASK_NMI = $4106

APU_CONTROL = $4015
APU_FRAME = $4017

    seg INIT
    org INIT_ROUTINE
INIT subroutine
    ldx #$FF
    txs
    
    lda #$0F
    sta APU_CONTROL
    lda #$40
    sta APU_FRAME
    
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
    
    lda #$01
    sta MASK_NMI
    
    lda #((.ret >> 8) & $FF)
    pha
    lda #(.ret & $FF)
    pha

    jmp (MUSIC_PLAY)

.ret nop
    
    lda #$00
    sta MASK_NMI
    
    rti

