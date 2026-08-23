; 0 - Translevel 
; 1 - itembox start
; 2 - itembox end
; 3 - pppp PPPP -> PPPP=Starting powerup  pppp=Ending powerup
; 4 - yyyy YYYY -> YYYY=Starting Yoshi yyyy=ending yoshi
; 5 - eems gybr -> ee - Exit type : m = Midway enable : s = special enable  :  gybr = switches

;$00 = #$00 for normal, #$01 for secret

FastMode_header_locations:
    dd !FastMode_save_1_header, !FastMode_save_2_header, !FastMode_save_3_header, #ALL_CASTLES_SAVE

FastMode_save_locations:
    dd !FastMode_save_1, !FastMode_save_2, !FastMode_save_3, #ALL_CASTLES_SAVE+$10

ALL_CASTLES_SAVE:
    incbin "bin/routes/AllCastles.smwroute"

; Retrieves current header from either save 1,2,3 based on status_fastmode
; stores to FastMode_save_current_header
; on exit: A=0, if invalid, a=1 if valid
;          x = 0 if save 1 -- 4 if save 2 -- 8 if save 3
default_header_1:
db $00, $00
db $1c, $0a, $1f, $0e, $26, $01, $26, $26
db $00, $00, $00, $00, $00, $00
default_header_2:
db $00, $00
db $1c, $0a, $1f, $0e, $26, $02, $26, $26
db $00, $00, $00, $00, $00, $00
default_header_3:
db $00, $00
db $1c, $0a, $1f, $0e, $26, $03, $26, $26
db $00, $00, $00, $00, $00, $00

reset_header:
    PHB
    PHk
    PLB
    LDX #$0F
    LDA !status_FastMode
    CMP #$01
    BNE +
    -
    LDA default_header_1,X
    STA !FastMode_save_1_header,X
    STA !FastMode_save_current_header,X
    dex
    BPL -
    JMP .done
    +
    CMP #$02
    BNE +
    -
    LDA default_header_2,X
    STA !FastMode_save_2_header,X
    STA !FastMode_save_current_header,X
    dex
    BPL -
    JMP .done
    +
    CMP #$03
    BNE +
    -
    LDA default_header_3,X
    STA !FastMode_save_3_header,X
    STA !FastMode_save_current_header,X
    dex
    BPL -
    JMP .done
    +
    -
    LDA default_header_1,X
    STA !FastMode_save_1_header,X
    LDA default_header_2,X
    STA !FastMode_save_2_header,X
    LDA default_header_3,X
    STA !FastMode_save_3_header,X
    dex
    bpl -
    .done:
    PLB
    RTL

retrieve_current_header:
    PHB
    PHK
    PLB
    lda !status_FastMode
    BNE +
        JMP .done_fail
    +

    DEC 
    ASL #2
    tax
    LDA FastMode_header_locations+0,X
    sta $00
    LDA FastMode_header_locations+1,X
    sta $01
    lda FastMode_header_locations+2,x
    sta $02

    ldy #$0F
    -
    LDA [$00],y
    STA !FastMode_save_current_header,y
    dey
    bpl -
    
    .done_success:
    PLB
    LDA #$01
    RTL
    .done_fail:
    PLB
    LDA #$00
    RTL



;Also retrieves header while called
retrieve_current_level:
    PHB
    PHK
    PLB
    JSL retrieve_current_header
    BNE +
        JMP .done_fail
    +
    lda FastMode_save_locations,X
    sta $00
    lda FastMode_save_locations+1,X
    sta $01
    lda FastMode_save_locations+2,X
    sta $02

    lda !FastMode_current_level
    CMP !FastMode_save_current_header+0
    BCC +
        JMP .done_fail
    +
    REP #$30
    AND #$00FF
    ASL #3
    TAY
    SEP #$20

    LDA [$00],Y
    sta !FastMode_save_current_level+0
    
    INY
    LDA [$00],Y
    STA !FastMode_save_current_level+1

    INY
    LDA [$00],Y
    STA !FastMode_save_current_level+2
    
    INY
    LDA [$00],Y
    TAX
    AND #$01
    STA !FastMode_save_current_level+11
    TXA : LSR : TAX
    AND #$01
    STA !FastMode_save_current_level+12
    TXA : LSR : TAX
    AND #$07
    STA !FastMode_save_current_level+3
    TXA
    LSR #3
    STA !FastMode_save_current_level+4

    INY
    LDA [$00],Y
    TAX
    AND #$03
    sta !FastMode_save_current_level+14
    TXA : LSR #2 : TAX
    AND #$07
    sta !FastMode_save_current_level+5
    TXA
    LSR #3
    STA !FastMode_save_current_level+6

    INY 
    LDA [$00],Y
    TAX
    AND #$01
    STA !FastMode_save_current_level+7

    TXA : LSR : TAX : AND #$01
    STA !FastMode_save_current_level+8

    TXA : LSR : TAX : AND #$01
    STA !FastMode_save_current_level+9

    TXA : LSR : TAX : AND #$01
    STA !FastMode_save_current_level+10

    TXA : LSR : TAX : AND #$07
    STA !FastMode_save_current_level+13
    .done_success:
    SEP #$30
    plb
    LDA #$01
    RTL
    .done_fail:
    SEP #$30
    plb
    LDA #$00
    RTL

store_current_header:
    PHB
    PHK
    PLB
    lda !status_FastMode
    BNE +
        JMP .done_fail
    +
    DEC 
    ASL #2
    tax
    LDA FastMode_header_locations+0,X
    sta $00
    LDA FastMode_header_locations+1,X
    sta $01
    lda FastMode_header_locations+2,x
    sta $02

    ldy #$0F
    -
    LDA !FastMode_save_current_header,y
    STA [$00],y
    dey
    bpl -

    .done_success:
    PLB
    LDA #$01
    RTL
    .done_fail
    PLB
    LDA #$00
    RTL

; Also stores header while called
store_current_level:
    PHB
    PHK
    PLB
    JSL store_current_header
    BNE +
        JMP .done_fail
    +
    lda FastMode_save_locations,X
    sta $00
    lda FastMode_save_locations+1,X
    sta $01
    lda FastMode_save_locations+2,X
    sta $02

    lda !FastMode_current_level
    REP #$30
    AND #$00FF
    ASL #3
    TAY
    SEP #$20

    LDA !FastMode_save_current_level+0    
    STA [$00],Y

    INY
    LDA !FastMode_save_current_level+1    
    STA [$00],Y

    INY
    LDA !FastMode_save_current_level+2
    STA [$00],Y

    INY
    LDA !FastMode_save_current_level+4
    ASL #3
    STA $03
    LDA !FastMode_save_current_level+3
    AND #$07
    ORA $03
    ASL #1
    STA $03
    LDA !FastMode_save_current_level+12
    AND #$01
    ORA $03
    ASL #1
    STA $03
    LDA !FastMode_save_current_level+11
    AND #$01
    ORA $03
    STA [$00],Y
    
    INY
    LDA !FastMode_save_current_level+6
    ASL #3
    STA $03
    LDA !FastMode_save_current_level+5
    AND #$07
    ORA $03
    ASL #2
    STA $03
    LDA !FastMode_save_current_level+14
    AND #$03
    ORA $03
    STA [$00],Y

    
    LDA !FastMode_save_current_level+13
    AND #$07 : ASL : STA $03

    LDA !FastMode_save_current_level+10
    AND #$01 : ORA $03 : ASL : STA $03

    LDA !FastMode_save_current_level+09
    AND #$01 : ORA $03 : ASL : STA $03

    LDA !FastMode_save_current_level+08
    AND #$01 : ORA $03 : ASL : STA $03

    LDA !FastMode_save_current_level+07
    AND #$01 : ORA $03 : STA $03

    INY
    STA [$00],Y

    .done_success:
    SEP #$30
    PLB
    lda #$01
    RTL
    .done_fail:
    SEP #$30
    PLB
    LDA #$00
    RTL

menu_nmi_draw_tiles:
    lda #$80
    sta $2115  
    REP #$10
    LDX #!menu_tile_upload_location ;Source Offset into source bank
    STX $4302       ;Set Source address lower 16-bits
    LDA #00   ;Source bank
    STA $4304       ;Set Source address upper 8-bits
    LDX !menu_tile_upload_bytes   ;# of bytes to copy (16k)
    beq .done
    STX $4305       ;Set DMA transfer size
    LDA #$16        ;$2118 is the destination, so
    STA $4301       ;  set lower 8-bits of destination to $18
    LDA #$04        ;Set DMA transfer mode: auto address increment
    STA $4300       ;  using write mode 1 (meaning write a word to $2118/$2119)
    LDA #$01        ;The registers we've been setting are for channel 0
    STA $420B       ;  so Start DMA transfer on channel 0 (LSB of $420B)
    .done:
    sep #$30
    stz !menu_tile_upload_bytes
    stz !menu_tile_upload_bytes+1
    RTL

FastMode_add_level:
        lda !potential_translevel
        BEQ .done
        PHX
        JSL retrieve_current_header
        PLX
        lda !FastMode_save_current_header+0
        sta !FastMode_current_level
        inc !FastMode_save_current_header+0       ; |
        
        LDA !potential_translevel
        STA !FastMode_save_current_level+0

        LDA !status_itembox
        STA !FastMode_save_current_level+1

        LDA #$00
        STA !FastMode_save_current_level+2
        
        LDA !status_powerup
        STA !FastMode_save_current_level+3
        
        LDA #$00
        STA !FastMode_save_current_level+4

        LDA !status_yoshi
        STA !FastMode_save_current_level+5

        LDA #$00
        STA !FastMode_save_current_level+6

        LDA $1f2a
        STA !FastMode_save_current_level+7

        LDA $1f2a
        sta !FastMode_save_current_level+8

        lda $1f28
        sta !FastMode_save_current_level+9
        
        lda $1f27
        sta !FastMode_save_current_level+10

        lda !status_special
        sta !FastMode_save_current_level+11

        lda #$00
        sta !FastMode_save_current_level+12

        
        stx !FastMode_save_current_level+13

        lda #$00
        sta !FastMode_save_current_level+14
        
        JSL store_current_level

        LDA #$02                            ; \
        STA $1df9                           ; |
        .done:
        SEP #$30
        RTL



submap_table:
    db $ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$ff,$00,$00,$00,$00,$ff,$00,$ff,$00,$00,$00,$00,$ff,$00
    db $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$04
    db $04,$04,$04,$04,$04,$04,$ff,$04,$04,$04,$04,$04,$02,$02,$02,$02
    db $02,$03,$03,$03,$03,$03,$03,$03,$05,$05,$05,$05,$05,$05,$05,$05
    db $05,$05,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06

ResetLevel:
    jsl retrieve_current_level

    LDA !FastMode_save_current_level+14
    STA !status_FastMode_difficulty

    lda !FastMode_save_current_level+1
    sta $0dc2                       ;Item

    LDA !FastMode_save_current_level+2
    STA !status_FastMode_end_item

    lda !FastMode_save_current_level+3
    STA $19                         ;Powerup

    lda !FastMode_save_current_level+4
    sta !status_FastMode_end_powerup



    lda !FastMode_save_current_level+5
    sta !status_yoshi
    sta $0dc1                       ; Yoshi
    stz !level_is_no_yoshi
    LDX #$12
    -
    LDA.L no_yoshi_translevels,X
    CMP !FastMode_save_current_level+0
    BEQ .remove_yoshi
    DEX
    BPL -
    BRA +
    .remove_yoshi:
    STZ $0DBA
    stz $0dc1
    inc !level_is_no_yoshi
    +
    JSL save_yoshi_color

    lda !FastMode_save_current_level+6
    sta !status_FastMode_end_yoshi

    lda !FastMode_save_current_level+7
    STA $1f2a

    lda !FastMode_save_current_level+8
    STA $1f29

    lda !FastMode_save_current_level+9
    STA $1f28

    lda !FastMode_save_current_level+10
    STA $1f27

    lda !FastMode_save_current_level+11
    STA !status_special

    lda !FastMode_save_current_level+12
    STA !midway_enable_flag

    lda !FastMode_save_current_level+13
    STA !status_FastMode_exit_type

    lda #$07    ;\
    sta $1f21   ; | Set Mario's overworld position to a known value.
    lda #$06    ; |  
    sta $1f1f   ;/


     
    
     lda.L !FastMode_save_current_level+0   ;translevel
     sta $13bf
     sta $7ed076    ; Overworld tile used in level loading routine. Main map/submap
     sta $7ed476    ; Address calculated from Mario's overworld position
     
     tax
     LDA.L submap_table,X   ; Submap
     STA $13c3
     STA $1f11


     stz $0dda
     stz $13c6
     stz $0109
     stz $141a
     stz $141d
     stz $0DD5
     lda #$ff
     sta $0101
     sta $0102
     sta $0103

    
    RTL

attempt_level_advance:
        lda !FastMode_start_play
        BEQ .no_advance_hop
            LDA !status_FastMode_difficulty
            CMP #$00
            BEQ .check_advance_mode_0
            CMP #$01
            BEQ .check_advance_mode_1
            CMP #$02
            BEQ .check_advance_mode_2
            BRA .next_level_hop

        .check_advance_mode_0:
            LDA !level_finished
            BNE .next_level_hop
            lda !status_FastMode_exit_type
            CMP #$02
            BEQ .start_select
            CMP #$03
            BEQ .death
            bra .no_advance_hop
            .start_select:
                lda $0dd5
                CMP #$81
                BEQ .next_level_hop
                BRA .no_advance_hop
            .death:
                lda $0dd5
                CMP #$82
                BEQ .next_level_hop
                BRA .no_advance_hop
        .check_advance_mode_1:
            LDA !status_FastMode_exit_type
            CMP #$00
            BNE +
                LDA !level_finished
                BEQ .no_advance_hop
                LDA !most_recent_exit
                CMP #$00
                BNE .no_advance_hop
                BRA .next_level_hop
            +
            CMP #$01
            BNE +
                LDA !level_finished
                BEQ .no_advance_hop
                LDA !most_recent_exit
                CMP #$01
                BNE .no_advance_hop
                BRA .next_level_hop
            +
            CMP #$02
                LDA $0dd5
                CMP #$81
                BNE .no_advance_hop
                .next_level_hop
                BRA .next_level
            CMP #$03
                LDA $0dd5
                CMP #$82
                BEQ .next_level
                .no_advance_hop:
                BRA .no_advance

        .check_advance_mode_2:
            lda !status_FastMode_end_item
            BEQ +
                CMP $0dc2
                BNE .no_advance
            + 
            lda !status_FastMode_end_powerup
            BEQ +
                CMP $19
                BNE .no_advance
            + 
            lda !status_FastMode_end_yoshi
            BEQ +
                lda !level_is_no_yoshi
                BNE +
                lda $187a
                BEQ .no_advance
            +
            LDA !status_FastMode_exit_type 
            CMP #$00
            BNE +
                LDA !level_finished
                BEQ .no_advance
                LDA !most_recent_exit
                CMP #$00
                BNE .no_advance
                BRA .next_level
            +
            CMP #$01
            BNE +
                LDA !level_finished
                BEQ .no_advance
                LDA !most_recent_exit
                CMP #$01
                BNE .no_advance
                BRA .next_level
            +
            CMP #$02
            BNE +
                LDA $0dd5
                CMP #$81
                BNE .no_advance
                BRA .next_level
            +
            CMP #$03
            BNE .next_level
                LDA $0dd5
                CMP #$82
                BNE .no_advance
                BRA .next_level

        .next_level:
        INC !FastMode_current_level   ; Next level
        LDA !FastMode_current_level   
        CMP !FastMode_save_current_header+0
        BCC +
            lda #00
            RTL
        +
        .no_advance:
        LDA #$01
        RTL


fade_to_overworld:
    LDA !status_FastMode
    BEQ .done
        LDA !FastMode_start_play
        BEQ .done
            LDA !util_byetudlr_hold
            AND #$10
            BEQ .start_play
                bra .stop_play
            .start_play:
                JSL attempt_level_advance
                beq .stop_play
            LDA #$E9
            STA $0109
            RTL
    .stop_play:
        LDA #$00
        STA !FastMode_start_play
        sta !midway_enable_flag
        STA $0109
        JSL set_position_to_yoshis_house        
    .done:
        LDA !restore_status_from_backup
        BEQ +
        LDA #$00
        STA !restore_status_from_backup
        LDX #!number_of_options
      - LDA.L !backup_status_table,X
        STA.L !status_table,X
        DEX
        BPL -
        JSL restore_basic_settings

        +
    RTL


pre_level_loading:
    lda $0109
    CMP #$E9
    BNE .done
    ; lda #$01
    ; sta !status_FastMode


    JSL ResetLevel
    .done
    RTL

init_original_statusbar_properties:
        
        PHB
        PHK
        PLB
        PHP
        ldx #$A0
        -
        lda original_properties-1,X
        sta $0904,X
        dex
        bne -
        
        REP #$10
        SEP #$20
        LDX #$4130
        STX $2116 ; vram address
        LDA.B #bank(overworld_layer_3_tiles)
        LDX #overworld_layer_3_tiles+$5C0
        LDY #$0010

        JSL load_vram

        PLP
        PLB
        RTL

original_properties:
        db $28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28
        db $28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$38,$38,$38,$78,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28
        db $28,$28,$28,$28,$28,$28,$28,$38,$3C,$3C,$3C,$3C,$38,$38,$38,$38,$38,$78,$38,$3C,$3C,$3C,$38,$38,$38,$3C,$38,$38,$38,$38,$28,$28
        db $28,$28,$28,$38,$38,$38,$38,$38,$38,$28,$38,$38,$38,$38,$38,$38,$38,$78,$38,$3C,$3C,$3C,$38,$38,$38,$38,$38,$38,$38,$38,$28,$28
        db $28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$B8,$B8,$B8,$F8,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28,$28



draw_original_statusbar:
        PHB
        PHP
        PHK
        PLB

        LDA $0d9b
        cmp #$c1
        BEQ .done

        LDX #$A0
        -
        LDA real_game_meters-1,X
        STA !status_bar-1,X
        DEX
        BNE -


        LDA $0f31                   ;
        sta !status_bar+$73         ;
        LDA $0f32                   ;
        sta !status_bar+$74         ;
        LDA $0f33                   ;
        sta !status_bar+$75         ;
                                    ;
        ldy #$00                    ;     Handle In-Level-Timer
        -                           ;
        lda !status_bar+$73,Y       ;
        bne +                       ;
        lda #$FC                    ;
        sta !status_bar+$73,Y       ;
        iny                         ;
        cpy #$02                    ;
        bne -                       ;
        +                           ;

        lda $0DBE
        INC A                       ; Lives
        sta !status_bar+$65

        lda $0DBF
        JSL !_F+$00974C
        TXY
        BNE +
        LDX #$FC
        +
        stx !status_bar+$5C
        sta !status_bar+$5D         ;Coins

        PHB
        LDA #$80
        PHA
        PLB
        JSL !_F+$008Ec6             ;Score
        
        LDX #$00
        JSL !_F+$008f8f             ; Bonus Stars
        PLB


        .done
        PLP
        PLB
        RTL

real_game_meters:
        db $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,  $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC                      
        db $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$3A,$3B,  $3B,$3A,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        db $FC,$FC,$30,$31,$32,$33,$34,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$4A,$FC,  $FC,$4A,$FC,$3D,$3E,$3F,$FC,$FC,$FC,$2E,$26,$FC,$FC,$00,$FC,$FC
        db $FC,$FC,$FC,$26,$FC,$00,$FC,$FC,$FC,$64,$26,$FC,$FC,$FC,$4A,$FC,  $FC,$4A,$FC,$FE,$FE,$00,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$00,$FC,$FC
        db $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$3A,$3B,  $3B,$3A,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC




draw_FastMode_level_tiles:
        PHP
        PHB
        PHK
        PLB
        
        ;JSR locate_levels
        
        LDA !status_FastMode
        BNE +
            JMP .done
        +
        LDA !FastMode_save_1_header+0
        BNE +
            JMP .done
        +
        LDA !FastMode_tile_timer 
        CMP !FastMode_save_1_header+0
        BCC .counter_overflow
        lda #$00
        sta !FastMode_tile_timer
        BRA +
        .counter_overflow:
        LDA !FastMode_tile_timer
        inc !FastMode_tile_timer

        +
        REP #$30                          ; A, X/Y 16 bit
        AND #$00FF
        ;BEQ .done
        ASL #3
        TAX                               ; X <- FastMode Level Index
        SEP #$20                          ; A: 8 bit X/Y 16 bit
        LDA !FastMode_save_1+0,X            ; Load Translevel to A
        LDY #$0000                        ; Clear upper byte of Y
        ASL
        TAY                               
        LDA translevel_locations_2+1,Y        ;$00 -> X Pos
        STA $00
        LDA translevel_locations_2+0,Y        ;$01 -> Y Pos
        STA $01
        

        LDA slot_tiles
        STA $03C2 ; tile
        REP #$20
        LDA $00
        AND #$001F
        ASL #4
        CLC
        ADC slot_offsets
        SEC
        SBC $1E
        BMI .continue
        CMP #$0100
        BCS .continue
        SEP #$20
        STA $03C0 ; x
        LDA $01
        AND #$20
        BEQ +
        LDA $1F11 ; submap
        BEQ .continue
        BRA ++
      + LDA $1F11 ; submap
        BNE .continue
     ++ REP #$20
        LDA $01
        AND #$001F
        ASL #4
        CLC
        ADC slot_offsets+2
        SEC
        SBC $20
        BMI .continue
        CMP #$00E0
        BCS .continue
        SEP #$20
        STA $03C1 ; y
        TXA
        INC A
        ASL A
        ORA #$30
        STA $03C3 ; properties
        LDA #$00
        STA $0490 ; size
    .continue:
    .done:
        SEP #$30
        
        PLB
        PLP
        RTL

translevel_locations_2:
        dw $0000,$0C03,$0E03,$0508,$050A,$090A,$0B0C,$0D0C
        dw $010D,$030D,$050E,$1003,$1403,$1603,$1A03,$1405
        dw $1705,$1408,$100F,$0710,$0211,$0511,$0712,$0517
        dw $0E17,$0319,$0C1B,$0F1B,$0C1D,$0F1D,$1410,$1610
        dw $1812,$1516,$1816,$131B,$151B,$0922,$0B24,$0926
        dw $0627,$0328,$0928,$082C,$002E,$032E,$0C2E,$1021
        dw $1423,$1723,$1923,$1425,$1725,$1925,$1227,$1427
        dw $1727,$1927,$1B27,$1729,$0830,$0C30,$0532,$0A32
        dw $0C32,$0637,$0837,$043A,$0A3A,$0C3A,$043C,$083C
        dw $1131,$1331,$1631,$1931,$1C31,$1133,$1333,$1633
        dw $1933,$1C33,$1736,$1238,$1538,$1738,$1938,$1C38
        dw $143A,$1A3A,$173B,$123D,$1C3D



