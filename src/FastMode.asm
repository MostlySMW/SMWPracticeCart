; 0 - Translevel 
; 1 - itembox start
; 2 - itembox end
; 3 - pppp PPPP -> PPPP=Starting powerup  pppp=Ending powerup
; 4 - yyyy YYYY -> YYYY=Starting Yoshi yyyy=ending yoshi
; 5 - eems gybr -> ee - Exit type : m = Midway enable : s = special enable  :  gybr = switches

;$00 = #$00 for normal, #$01 for secret
FastMode_add_level:
        LDA #$02                            ; \
        STA $1df9                           ; |                       
        LDA !FastMode_save_1_header+0       ; |
        INC                                 ; | Increment level pointer
        STA !FastMode_save_1_header+0       ; | X = 16 bit index into level save data
        DEC                                 ; |
        REP #$30 
        AND #$00FF
        ASL #3                              ; |
        TAX                                 ; |
        SEP #$20                            ; /
        
        LDA !potential_translevel
        STA !FastMode_save_1+0,X

        LDA !status_itembox
        STA !FastMode_save_1+1,X

        LDA #$00
        STA !FastMode_save_1+2,X
        
        LDA !status_powerup
        AND #$0F
        STA !FastMode_save_1+3,X
        
        LDA !status_yoshi
        AND #$0F
        STA !FastMode_save_1+4,X


        LDA $00
        ASL 
        ORA #$00
        ASL
        ORA !status_special
        ASL
        ORA $1f27
        ASL
        ORA $1f28
        ASL
        ORA $1f29
        ASL
        ORA $1f2a
        sta !FastMode_save_1+5,X

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
    PHX
    REP #$30                        ;
    LDA !FastMode_current_level     ;
    AND #$00FF                      ;
    ASL #3                          ;Index to save table stored in X
    TAX                             ;
    SEP #$20                        ;

    LDA !FastMode_save_1_header+1
    STA !status_FastMode_difficulty

    lda !FastMode_save_1+1, X
    sta $0dc2                       ;Item

    LDA !FastMode_save_1+2,X
    STA !status_FastMode_end_item

    lda !FastMode_save_1+3, X
    AND #$0F
    STA $19                         ;Powerup

    lda !FastMode_save_1+3,X
    LSR #4
    sta !status_FastMode_end_powerup


    lda #$00
    lda !FastMode_save_1+4,X
    AND #$0F
    sta !status_yoshi
    sta $0dc1                       ; Yoshi
    PHX
    sep #$30
    JSL save_yoshi_color
    REP #$10
    PLX

    LDA !FastMode_save_1+5,X
    TAY : AND #$01
    STA $1f2a

    TYA : LSR : TAY : AND #$01
    STA $1f29

    TYA : LSR : TAY : AND #$01
    STA $1f28

    TYA : LSR : TAY : AND #$01
    STA $1f27

    TYA : LSR : TAY : AND #$01
    STA !status_special

    TYA : LSR : TAY : AND #$01
    STA !midway_enable_flag

    TYA : LSR : TAY : AND #$03
    STA !status_FastMode_exit_type

    lda #$07    ;\
    sta $1f21   ; | Set Mario's overworld position to a known value.
    lda #$06    ; |  
    sta $1f1f   ;/


     
    
     lda.L !FastMode_save_1+0,X   ;translevel
     SEP #$30
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
     lda #$ff
     sta $0101
     sta $0102
     sta $0103

    
    PLX
    RTL



fade_to_overworld:
    LDA !status_FastMode
    BEQ .done
        LDA !FastMode_start_play
        BEQ .done
            LDA !util_byetudlr_hold
            AND #$10
            BEQ .start_play
                LDA #$00
                STA !FastMode_start_play
                STA $0109
                JSL set_position_to_yoshis_house
                BRA .done
            .start_play:
            LDA #$E9
            STA $0109
            RTL
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
    lda #$01
    sta !status_FastMode


    JSL ResetLevel
    .done
    RTL

init_original_statusbar_properties:
        
        PHB
        PHK
        PLB
        ldx #$A0
        -
        lda original_properties-1,X
        sta $0904,X
        dex
        bne -
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



