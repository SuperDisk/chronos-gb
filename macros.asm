; predef commands
predefCommand1 EQU $FF
predefCommand2 EQU $03

; to mute use parameters: 1, 0, 1, 1
MACRO chord_envelope;, ?attack, ?sustain, ?decay, ?release
  db predefCommand1
  db $01, \1, \2, \3, \4
ENDM

MACRO fx_02
  db predefCommand1
  db $02
ENDM

MACRO fx_03
  db predefCommand1
  db $03
ENDM

MACRO drumA ; play drum pattern A
  db predefCommand1
  db $04
ENDM

MACRO drumB ; play drum pattern B
  db predefCommand1
  db $05
ENDM

MACRO drum_speed;, ?speed ; speeding up drums may slow down entire song
  db predefCommand1
  db $08, \1
ENDM

MACRO two_note_chord ; beware: this will also ENABLE echo
  db predefCommand1
  db $09
ENDM

MACRO three_note_chord ; beware: this will also DISABLE echo
  db predefCommand1
  db $0A
ENDM

MACRO enable_glide
  db predefCommand2
  db $01
ENDM

MACRO disable_glide
  db predefCommand2
  db $02
ENDM

MACRO glide_speed;, ?speed
  db predefCommand2
  db $03, \1
ENDM

; to mute use parameters: 1, 0, 1
MACRO melody_envelope;, ?is_attack, ?attack, ?decay ; set envelope?
  db predefCommand2
  db $04, \1, \2, \3
ENDM

MACRO echo_volume;, ?volume
  db predefCommand2
  db $05, 1
ENDM

MACRO enable_echo ; only works in 2-note chord mode. This also detunes the melody.
  db predefCommand2
  db $06
ENDM

MACRO disable_echo
  db predefCommand2
  db $07
ENDM

MACRO return
  db $01
ENDM

MACRO repeat;, ?times ; minimum of 2x
  db $02, \1-1
ENDM

MACRO end_song
  db $00
ENDM

MACRO note;, ?note, ?length
  db \1
  db \2 * _SPEED
ENDM

MACRO chord2;, ?note1, ?note2, ?length ; two notes pressed
  db \1, \2
  db \3 * _SPEED
ENDM

MACRO chord3;, ?note1, ?note2, ?note3, ?length ; two notes pressed
  db \1, \2, \3
  db \4 * _SPEED
ENDM

MACRO song_speed;, ?speed ; compile-time parameter
; higher speed parameter = slower song
; this is usually the length of a 16th note
  DEF _SPEED = \1
ENDM
