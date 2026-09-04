FastMode_header_locations:
        dd !fast_mode_save_1_header
        dd !fast_mode_save_2_header
        dd !fast_mode_save_3_header
        dd #preset_route_11_exit_nmg
        dd #preset_route_11_exit_cloud
        dd #preset_route_all_castles
        dd #preset_route_96_exit

FastMode_save_locations:
        dd !fast_mode_save_1
        dd !fast_mode_save_2
        dd !fast_mode_save_3
        dd #preset_route_11_exit_nmg+$10
        dd #preset_route_11_exit_cloud+$10
        dd #preset_route_all_castles+$10
        dd #preset_route_96_exit+$10

preset_route_11_exit_nmg:
        incbin "bin/routes/11_exit_nmg.smwroute"
preset_route_11_exit_cloud:
        incbin "bin/routes/11_exit_cloud.smwroute"
preset_route_all_castles:
        incbin "bin/routes/all_castles.smwroute"
preset_route_96_exit:
        incbin "bin/routes/96_exit.smwroute"
        
try_start_fast_mode:
        LDA !status_fast_mode
        BEQ .done ; fast mode enabled
        LDA !util_byetudlr_hold
        AND #$30
        BNE .done ; pressed start or select
        
        JSL retrieve_current_header
        LDA !fast_mode_save_level_count
        BEQ .done ; header of route exists
        
        LDA #$01
        STA !fast_mode_start_play ; start fast mode!
        STA !fast_mode_save_current_exit_required
        LDA #$FF
        STA !most_recent_exit
        
        STZ !total_frames
        STZ !total_seconds
        STZ !total_minutes
        STZ !total_hours
        
        LDA !restore_status_from_backup
        BNE .done
        
        ; save the current settings
        LDX #!number_of_options
      - LDA.L !status_table,X
        STA.L !backup_status_table,X
        DEX
        BPL -

        ; default settings for fast mode
        LDA #$01
        STA.L !restore_status_from_backup
        STA.L !status_lrreset
        STA.L !status_slowdown
        LDA #$00
        STA.L !status_states
        STA.L !status_pause
        STA.L !status_slots
        STA.L !status_lagometer
        STA.L !status_timedeath
        STA.L !status_region ; force J version for now
        
    .done:
        RTL
        
; copy route (in A) to save 3
; save 1 = 0, first preset = 3, etc
copy_preset_to_route3:
        PHB
        PHK
        PLB
        
        REP #$10
        ASL #2
        TAX
        LDY FastMode_header_locations,X
        STY $00
        LDY FastMode_header_locations+2,X
        STY $02
        LDY #!fast_mode_save_3_header
        STY $03
        LDA.B #bank(!fast_mode_save_3_header)
        STA $05
        
        LDY.W #!fast_mode_header_length-1
      - LDA [$00],Y
        STA [$03],Y
        DEY
        BPL -
        
        LDY FastMode_save_locations,X
        STY $00
        LDY FastMode_save_locations+2,X
        STY $02
        LDY #!fast_mode_save_3
        STY $03
        LDA.B #bank(!fast_mode_save_3)
        STA $05
        
        LDY.W #!fast_mode_data_length-1
      - LDA [$00],Y
        STA [$03],Y
        DEY
        BPL -
        
        SEP #$10
        PLB
        RTL

reset_header:
        PHB
        PHK
        PLB
        LDX #!fast_mode_header_length-1
        LDA !status_fast_mode
        CMP #$01
        BNE +
        
      - LDA #$00
        STA !fast_mode_save_1_header,X
        STA !fast_mode_save_current_header,X
        DEX
        BPL -
        JMP .done
        
      + CMP #$02
        BNE +
        
      - LDA #$00
        STA !fast_mode_save_2_header,X
        STA !fast_mode_save_current_header,X
        DEX
        BPL -
        JMP .done
        
      + CMP #$03
        BNE +
        
      - LDA #$00
        STA !fast_mode_save_3_header,X
        STA !fast_mode_save_current_header,X
        DEX
        BPL -
        JMP .done
        
      + 
      - LDA #$0
        STA !fast_mode_save_1_header,X
        STA !fast_mode_save_2_header,X
        STA !fast_mode_save_3_header,X
        DEX
        BPL -
        
    .done:
        PLB
        RTL


; Retrieves current header from either save 1,2,3 based on status_fastmode
; stores to FastMode_save_current_header
; on exit: A=0, if invalid, a=1 if valid
;          x = 0 if save 1 -- 4 if save 2 -- 8 if save 3
retrieve_current_header:
        PHB
        PHK
        PLB
        LDA !status_fast_mode
        BNE +
        JMP .done_fail

      + DEC 
        ASL #2
        TAX
        LDA FastMode_header_locations+0,X
        STA $00
        LDA FastMode_header_locations+1,X
        STA $01
        LDA FastMode_header_locations+2,X
        STA $02

        LDY #!fast_mode_header_length-1
      - LDA [$00],Y
        STA !fast_mode_save_current_header,Y
        DEY
        BPL -
        
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
        
      + LDA FastMode_save_locations,X
        STA $00
        LDA FastMode_save_locations+1,X
        STA $01
        LDA FastMode_save_locations+2,X
        STA $02

        LDA !fast_mode_current_level
        CMP !fast_mode_save_level_count
        BCC +
        JMP .done_fail
        
      + XBA
        LDA $04
        PHA
        XBA
        REP #$30
        AND #$00FF
        STA $03
        ASL #2
        CLC
        ADC $03
        ASL A ; x10
        TAY
        SEP #$20
        PLA
        STA $04

        LDA [$00],Y ; translevel
        STA !fast_mode_save_current_level
        
        INY
        LDA [$00],Y ; item box start
        STA !fast_mode_save_current_item_box_start

        INY
        LDA [$00],Y ; item box end
        STA !fast_mode_save_current_item_box_end

        INY
        LDA [$00],Y ; powerup start
        STA !fast_mode_save_current_powerup_start

        INY
        LDA [$00],Y ; powerup end
        STA !fast_mode_save_current_powerup_end

        INY
        LDA [$00],Y ; yoshi start
        STA !fast_mode_save_current_yoshi_start

        INY
        LDA [$00],Y ; yoshi end
        STA !fast_mode_save_current_yoshi_end

        INY 
        LDA [$00],Y ; --msgybr
        TAX
        AND #$01
        STA !fast_mode_save_current_red_switch
        TXA : LSR : TAX : AND #$01
        STA !fast_mode_save_current_blue_switch
        TXA : LSR : TAX : AND #$01
        STA !fast_mode_save_current_yellow_switch
        TXA : LSR : TAX : AND #$01
        STA !fast_mode_save_current_green_switch
        TXA : LSR : TAX : AND #$01
        STA !fast_mode_save_current_special_clear
        TXA : LSR : TAX : AND #$01
        STA !fast_mode_save_current_midway_enable
        
        INY
        LDA [$00],Y ; eeexpyyi
        TAX
        AND #$01
        STA !fast_mode_save_current_item_box_required
        TXA : LSR : TAX : AND #$03
        STA !fast_mode_save_current_yoshi_required
        TXA : LSR #2 : TAX : AND #$01
        STA !fast_mode_save_current_powerup_required
        TXA : LSR : TAX : AND #$01
        STA !fast_mode_save_current_exit_required
        TXA : LSR
        STA !fast_mode_save_current_exit_type

;        INY
;        LDA [$00],Y ; reserved
        
    .done_success:
        SEP #$30
        PLB
        LDA #$01
        RTL
        
    .done_fail:
        SEP #$30
        PLB
        LDA #$00
        RTL

store_current_header:
        PHB
        PHK
        PLB
        LDA !status_fast_mode
        BNE +
        JMP .done_fail
            
      + DEC 
        ASL #2
        TAX
        LDA FastMode_header_locations+0,X
        STA $00
        LDA FastMode_header_locations+1,X
        STA $01
        LDA FastMode_header_locations+2,X
        STA $02

        LDY #!fast_mode_header_length-1
      - LDA !fast_mode_save_current_header,Y
        STA [$00],Y
        DEY
        BPL -

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
        
      + LDA FastMode_save_locations,X
        STA $00
        LDA FastMode_save_locations+1,X
        STA $01
        LDA FastMode_save_locations+2,X
        STA $02

        LDA $04
        PHA
        LDA !fast_mode_current_level
        REP #$30
        AND #$00FF
        STA $03
        ASL #2
        CLC
        ADC $03
        ASL A ; x10
        TAY
        SEP #$20
        PLA
        STA $04

        LDA !fast_mode_save_current_level
        STA [$00],Y

        INY
        LDA !fast_mode_save_current_item_box_start
        STA [$00],Y

        INY
        LDA !fast_mode_save_current_item_box_end
        STA [$00],Y

        INY
        LDA !fast_mode_save_current_powerup_start
        STA [$00],Y

        INY
        LDA !fast_mode_save_current_powerup_end
        STA [$00],Y

        INY
        LDA !fast_mode_save_current_yoshi_start
        STA [$00],Y

        INY
        LDA !fast_mode_save_current_yoshi_end
        STA [$00],Y

        LDA !fast_mode_save_current_midway_enable
        AND #$01 : ASL : STA $03
        LDA !fast_mode_save_current_special_clear
        AND #$01 : ORA $03 : ASL : STA $03
        LDA !fast_mode_save_current_green_switch
        AND #$01 : ORA $03 : ASL : STA $03
        LDA !fast_mode_save_current_yellow_switch
        AND #$01 : ORA $03 : ASL : STA $03
        LDA !fast_mode_save_current_blue_switch
        AND #$01 : ORA $03 : ASL : STA $03
        LDA !fast_mode_save_current_red_switch
        AND #$01 : ORA $03 : STA $03
        INY
        STA [$00],Y

        LDA !fast_mode_save_current_exit_type
        ASL : STA $03
        LDA !fast_mode_save_current_exit_required
        AND #$01 : ORA $03 : ASL : STA $03
        LDA !fast_mode_save_current_powerup_required
        AND #$01 : ORA $03 : ASL #2 : STA $03
        LDA !fast_mode_save_current_yoshi_required
        AND #$03 : ORA $03 : ASL : STA $03
        LDA !fast_mode_save_current_item_box_required
        AND #$01 : ORA $03 : STA $03
        INY
        STA [$00],Y

    .done_success:
        SEP #$30
        PLB
        LDA #$01
        RTL
        
    .done_fail:
        SEP #$30
        PLB
        LDA #$00
        RTL

menu_nmi_draw_tiles:
        LDA #$80
        STA $2115  
        REP #$10
        LDX #!menu_tile_upload_location ;Source Offset into source bank
        STX $4302       ;Set Source address lower 16-bits
        LDA #00         ;Source bank
        STA $4304       ;Set Source address upper 8-bits
        LDX !menu_tile_upload_bytes   ;# of bytes to copy (16k)
        BEQ .done
        STX $4305       ;Set DMA transfer size
        LDA #$16        ;$2118 is the destination, so
        STA $4301       ;  set lower 8-bits of destination to $18
        LDA #$04        ;Set DMA transfer mode: auto address increment
        STA $4300       ;  using write mode 1 (meaning write a word to $2118/$2119)
        LDA #$01        ;The registers we've been setting are for channel 0
        STA $420B       ;  so Start DMA transfer on channel 0 (LSB of $420B)
    .done:
        SEP #$30
        STZ !menu_tile_upload_bytes
        STZ !menu_tile_upload_bytes+1
        RTL

FastMode_add_level:
        LDA !potential_translevel
        BNE +
        BRL .done
        
      + PHX
        JSL retrieve_current_header
        PLX
        
        LDA !fast_mode_save_level_count
        CMP.B #!fast_mode_max_route_length ; full
        BCC +
        LDA #$2A ; wrong sound
        STA $1DFC ; apu i/o
        BRL .done
        
      + STA !fast_mode_current_level
        INC !fast_mode_save_level_count
        
        LDA !potential_translevel
        STA !fast_mode_save_current_level

        LDA !status_itembox
        STA !fast_mode_save_current_item_box_start

        LDA #$00 ; end itembox
        STA !fast_mode_save_current_item_box_end
        
        LDA !status_powerup
        STA !fast_mode_save_current_powerup_start
        
        LDA #$00 ; end powerup
        STA !fast_mode_save_current_powerup_end

        LDA !status_yoshi
        STA !fast_mode_save_current_yoshi_start

        LDA #$00 ; end yoshi
        STA !fast_mode_save_current_yoshi_end

        LDA !status_red
        STA !fast_mode_save_current_red_switch

        LDA !status_blue
        STA !fast_mode_save_current_blue_switch

        LDA !status_yellow
        STA !fast_mode_save_current_yellow_switch
        
        LDA !status_green
        STA !fast_mode_save_current_green_switch

        LDA !status_special
        STA !fast_mode_save_current_special_clear

        LDA #$00
        STA !fast_mode_save_current_midway_enable
        STA !fast_mode_save_current_item_box_required
        STA !fast_mode_save_current_yoshi_required
        STA !fast_mode_save_current_powerup_required
        
        LDA #$01
        STA !fast_mode_save_current_exit_required

        ; exit type
        STX !fast_mode_save_current_exit_type
        
        JSL store_current_level

        LDA #$02 ; bop sound
        STA $1DF9 ; apu i/o
        
    .done:
        SEP #$30
        RTL

submap_table:
        db $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        db $00,$00,$FF,$00,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$00,$FF,$00
        db $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$04
        db $04,$04,$04,$04,$04,$04,$FF,$04,$04,$04,$04,$04,$02,$02,$02,$02
        db $02,$03,$03,$03,$03,$03,$03,$03,$05,$05,$05,$05,$05,$05,$05,$05
        db $05,$05,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06

ResetLevel:
        JSL retrieve_current_level

        LDA !fast_mode_save_current_item_box_start
        STA $0DC2 ;Item

        LDA !fast_mode_save_current_item_box_end
        STA !status_fast_mode_end_item

        LDA !fast_mode_save_current_powerup_start
        STA $19 ;Powerup

        LDA !fast_mode_save_current_powerup_end
        STA !status_fast_mode_end_powerup

        LDA !fast_mode_save_current_yoshi_start
        STA !status_yoshi
        STA $0DC1 ; Yoshi
        STZ !level_is_no_yoshi
        LDX #$12
        
      - LDA.L no_yoshi_translevels,X
        CMP !fast_mode_save_current_level
        BEQ .remove_yoshi
        DEX
        BPL -
        BRA +
        
    .remove_yoshi:
        STZ $0DBA
        STZ $0DC1
        INC !level_is_no_yoshi
        
      + JSL save_yoshi_color

        LDA !fast_mode_save_current_yoshi_end
        STA !status_fast_mode_end_yoshi

        LDA !fast_mode_save_current_red_switch
        STA !status_red
        STA $1F2A

        LDA !fast_mode_save_current_blue_switch
        STA !status_blue
        STA $1F29

        LDA !fast_mode_save_current_yellow_switch
        STA !status_yellow
        STA $1F28

        LDA !fast_mode_save_current_green_switch
        STA !status_green
        STA $1F27

        LDA !fast_mode_save_current_special_clear
        STA !status_special

        LDA !fast_mode_save_current_midway_enable
        STA !midway_enable_flag

        LDA !fast_mode_save_current_exit_type
        STA !status_fast_mode_exit_type

        LDA #$07    ;\
        STA $1F21   ; | Set Mario's overworld position to a known value.
        LDA #$06    ; |  
        STA $1F1F   ;/

        LDA.L !fast_mode_save_current_level
        STA $13BF
        STA $7ED076    ; Overworld tile used in level loading routine. Main map/submap
        STA $7ED476    ; Address calculated from Mario's overworld position

        TAX
        LDA.L submap_table,X   ; Submap
        STA $13C3
        STA $1F11

        STZ $0DDA
        STZ $13C6
        STZ $0109
        STZ $141A
        STZ $141D
        STZ $0DD5
        LDA #$FF
        STA $0101
        STA $0102
        STA $0103

        RTL

attempt_level_advance:
        LDA !fast_mode_start_play
        BEQ .no_advance
        
        JSL can_advance_to_next_level
        BEQ .no_advance

        INC !fast_mode_current_level   ; Next level
        LDA !fast_mode_current_level   
        CMP !fast_mode_save_level_count
        BCC .finished
        LDA #00
        RTL
        
    .finished:
    .no_advance:
        LDA #$01
        RTL
        
; A = 1 if all requirements are met and player can move onto the next level, 0 if not
can_advance_to_next_level:
    .check_exit_type:
        LDA !fast_mode_save_current_exit_required
        BEQ .exit_not_required
    
    .exit_required:
        LDA !most_recent_exit ; (0, 1, 2, 3 = exit number)
        STA $00
        LDA $0DD5 ; level exit type
        BPL +
        SEC
        SBC #$7D ; convert ($81, $82, $83 to 4, 5, 6)
        STA $00
        
        ; swap normal and secret exit for dgh and fgh
      + LDA !fast_mode_save_current_level
        CMP #$04 ; dgh
        BEQ .swap_exit
        CMP #$41 ; fgh
        BNE +
    .swap_exit:
        LDA $00
        TAX
        LDA.L .swapped_exits,X
        BRA ++
        
      + LDA $00
     ++ CMP !fast_mode_save_current_exit_type
        BEQ .check_item_box
        BRA .do_not_advance
    
    ; "exit not required" actually means "level finished only"
    .exit_not_required:
        LDA $0DD5 ; level exit type
        BEQ .check_item_box
        BRA .do_not_advance
        
    .check_item_box:
        LDA !fast_mode_save_current_item_box_required
        BEQ .check_yoshi
        
        LDA $0DC2 ; item box
        CMP !fast_mode_save_current_item_box_end
        BEQ .check_yoshi
        BRA .do_not_advance
        
    .check_yoshi:
        LDA !level_is_no_yoshi
        BNE .check_powerup ; right now any no-yoshi level ignores all yoshi checks
        LDA !fast_mode_save_current_yoshi_required
        BEQ .check_powerup
        CMP #$01
        BEQ +
        
        LDA $187A ; riding yoshi flag
        BNE .check_powerup
        BRA .do_not_advance
        
      + LDA $187A ; riding yoshi flag
        BEQ +
        LDA $13C7 ; ow yoshi color
        CMP #$0B
        BCS +
        TAX
        LDA.L yoshi_color_mapping_input,X
      + CMP !fast_mode_save_current_yoshi_end
        BEQ .check_powerup
        BRA .do_not_advance
        
    .check_powerup:
        LDA !fast_mode_save_current_powerup_required
        BEQ .advance_next_level
        
        LDA $19 ; powerup
        CMP !fast_mode_save_current_powerup_end
        BEQ .advance_next_level
        BRA .do_not_advance
        
    .advance_next_level:
        LDA #$01
        RTL
    .do_not_advance:
        LDA #$00
        RTL
        
    .swapped_exits:
        db $01,$00,$02,$03
        

fade_to_overworld:
        LDA !status_fast_mode
        BEQ .done
        
        LDA !fast_mode_start_play
        BEQ .done
        
        LDA !util_byetudlr_hold
        AND #$10 ; hold start to exit the run early
        BEQ .start_play
        
        LDA #$FF
        STA !total_frames ; don't show the final time if you quit
        
        BRA .stop_play
    .start_play:
        JSL attempt_level_advance
        BEQ .stop_play
        
        LDA #$E9
        STA $0109
        RTL
        
    .stop_play:
        LDA #$00
        STA !fast_mode_start_play
        STA !midway_enable_flag
        STA $0109
        JSL set_overworld_position   
        
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

      + RTL


pre_level_loading:
        LDA $0109
        CMP #$E9
        BNE +
        JSL ResetLevel
      + RTL

; display the run time on the status bar
; this draws only on level exit
display_fastmode_run_time:
        LDA !fast_mode_save_show_timer
        BNE .do_draw_it ; if the timer is set to show at level end, draw it
        LDA !fast_mode_current_level
        INC A
        CMP !fast_mode_save_level_count
        BNE .dont_draw_it ; otherwise, if this is not the last level in the run, skip it
        JSL can_advance_to_next_level
        BNE .do_draw_it ; if it is, draw the timer anyway if the run is completed
    .dont_draw_it:
        RTL
        
    .do_draw_it:
        LDA !total_hours
        STA !status_bar+$93
        
        LDA !total_minutes
        JSL !_F+$00974C ; hex2dec
        STX !status_bar+$95
        STA !status_bar+$96
        
        LDA !total_seconds
        JSL !_F+$00974C ; hex2dec
        STX !status_bar+$98
        STA !status_bar+$99
        
        LDA !total_frames
        JSL convert_frames_to_centiseconds
        JSL !_F+$00974C ; hex2dec
        STX !status_bar+$9B
        STA !status_bar+$9C
        
        LDA #$78
        STA !status_bar+$94
        STA !status_bar+$97
        LDA #$24
        STA !status_bar+$9A
        
        RTL

; on overworld load, if just finished a run,
; display the time on the top left
display_fast_mode_finish_time:
        PHP
        LDA !total_frames
        BMI .nope ; no run
        LDA $0DD5
        BMI .nope ; run aborted
        
        REP #$30
        LDA.L $7F837B ; size
        TAX
        LDA #$E350
        STA.L $7F837D,X ; stripe
        INX #2
        LDA.W #$1300
        STA.L $7F837D,X ; stripe
        INX #2
        
        SEP #$20
        LDY #$0000
      - LDA !status_bar+$93,Y
        STA.L $7F837D,X ; stripe
        INX
        LDA #$3C
        STA.L $7F837D,X ; stripe
        INX
        INY
        CPY.W #10
        BNE -
        
        LDA #$FF
        STA !total_frames ; don't draw it again
        STA.L $7F837D,X ; stripe
        STA.L $7F837D+1,X ; stripe
        TXA
        STA.L $7F837B ; size
        
    .nope:
        PLP
        RTL