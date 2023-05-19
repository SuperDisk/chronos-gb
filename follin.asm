include "hardware.inc"

MACRO DJNZ
  dec b
  jr nz, \1
ENDM

; Constants
STACK_SIZE EQU $7A
;; Stack starts at $FFFE

; $0000 - $003F: RST handlers.

SECTION "restarts", ROM0[$0000]
ret
REPT 7
    nop
ENDR
; $0008
ret
REPT 7
    nop
ENDR
; $0010
ret
REPT 7
    nop
ENDR
; $0018
ret
REPT 7
    nop
ENDR
; $0020
ret
REPT 7
    nop
ENDR
; $0028
ret
REPT 7
    nop
ENDR
; $0030
ret
REPT 7
    nop
ENDR
; $0038
ret
REPT 7
    nop
ENDR

; Interrupt addresses
SECTION "Vblank interrupt", ROM0[$0040]
    reti

SECTION "LCD controller status interrupt", ROM0[$0048]
    reti

SECTION "Timer overflow interrupt", ROM0[$0050]
    reti

SECTION "Serial transfer completion interrupt", ROM0[$0058]
    reti

SECTION "P10-P13 signal low edge interrupt", ROM0[$0060]
    reti

; Reserved stack space
SECTION "Stack", HRAM[$FFFE - STACK_SIZE]
    ds STACK_SIZE

; Control starts here, but there's more ROM header several bytes later, so the
; only thing we can really do is immediately jump to after the header

SECTION "Header", ROM0[$0100]
    nop
    jp $0150

    NINTENDO_LOGO

; $0134 - $013E: The title, in upper-case letters, followed by zeroes.
DB "HUGE"
DS 7 ; padding
; $013F - $0142: The manufacturer code. Empty for now
DS 4
DS 1
; $0144 - $0145: "New" Licensee Code, a two character name.
DB "NF"

; Initialization
SECTION "main", ROM0[$0150]
    jp _init

MemsetSmall::
  ld [hli], a
  dec c
  jr nz, MemsetSmall
  ret

_init:
    ; Enable sound globally
    ld a, $80
    ldh [rAUDENA], a
    ; Enable all channels in stereo
    ld a, $FF
    ldh [rAUDTERM], a
    ; Set volume
    ld a, $77
    ldh [rAUDVOL], a

    xor a
    ldh [rAUD3ENA], a
    ld a, $FF
    ld c, 16
    ld hl, _AUD3WAVERAM
    call MemsetSmall

    ld a, $FF
    ldh [rAUD3ENA], a
    ld a, %00100000
    ldh [rAUD3LEVEL], a
    ld a, $00
    ldh [rAUD3LOW], a
    ld a, $85
    ldh [rAUD3HIGH], a

zoogus:
    ;; setup workspace
    ; noteLength:			dw $9600	; Note length counter.
    ld a, $00
    ld [noteLength], a
    ld a, $96
    ld [noteLength+1], a

    ; volumeControl:		db $0C		; Volume control.
    ld a, $0C
    ld [volumeControl], a

    ; decayRate:			db $80		; Decay rate.
    ld a, $80
    ld [decayRate], a

    ; decayCount:			db $80		; Current decay count.
    ld a, $80
    ld [decayCount], a

    ; attackRate:			db $00		; Attack rate.
    ld a, $00
    ld [attackRate], a

    ; attackCount:		db $00		; Current attack count.
    ld a, $00
    ld [attackCount], a

    ; attackDecay:		db $00		; Attack (1) or decay (0) phase.
    ld a, $00
    ld [attackDecay], a

    ; decayTargetVolume:	db $01		; Decay target volume.
    ld a, $01
    ld [decayTargetVolume], a

    ; ld hl, musicdata
    ld hl, disassembly+290;122

play:
  DI						; Disable interrupts.

  ; push hl
  ; pop ix            ; IX points to the start of the music.

next:
  ; LD    A,(IX+0)			; Look at the next byte of music.
  ld a, [hl]

  INC   A
  JP    NZ, break_			; If A is OFFh read a new envelope.

  ; INC   IX
  inc hl

  ; LD    H,(IX+1)			; Load the note length.
  ; LD    L,(IX+0)
  ; LD    (noteLength),HL
  ; INC   IX
  ; INC   IX

  ld a, [hl+]
  ld [noteLength+0], a
  ld a, [hl+]
  ld [noteLength+1], a

  ; LD    A,(IX+0)			; Load the attack rate.
  ld a, [hl+]
  LD    [attackRate],A

  ; LD    A,(IX+1)			; Load the decay rate.
  ld a, [hl+]
  LD    [decayRate],A

  ; LD    A,(IX+2)			; Decay target volume.
  ld a, [hl+]
  LD    [decayTargetVolume],A

  ; INC   IX				; Move IX to next music data.
  ; INC   IX
  ; INC   IX
  JP    next
break_:
  LD    A,[decayRate]		; Copy decay rate to decay count.
  LD    [decayCount],A
  LD    A,[attackRate]	; Copy attack rate to attack count.
  LD    [attackCount],A

  ; LD    BC,(noteLength)	; BC contains the note length.
  ld a, [noteLength]
  ld c, a
  ld a, [noteLength+1]
  ld b, a

  ; LD    H,(IX+0)			; H, L and D contain the note pitches.
  ; LD    L,(IX+1)
  ; LD    D,(IX+2)
  ld a, [hl+]
  ld [origH], a
  ld a, [hl+]
  ld [origL], a
  ld a, [hl+]
  ld [origD], a

  ; subr doesn't use IX but it does use HL, so save it
  push hl

  ld d, a
  ld a, [origH]
  ld h, a
  ld a, [origL]
  ld l, a

  LD    E,10				; Only control volume every ten cycles.
  LD    A,1
  LD    [volumeControl],A	; Set volume to 1.
  LD    [attackDecay],A	; Set attack phase.
  CALL  subr				; Call subroutine that drives the beeper.
  XOR   A					; Zero accumulator.

  ; IN    A,(254)			; Read keyboard.
  ; CPL						; Complement result.
  ; AND   31				; Mask keyboard bits.
  ; JP    NZ, keyp			; Jump if a key is pressed.

  ; INC   IX				; Move IX 3 bytes along.
  ; INC   IX
  ; INC   IX
  pop hl

  ; LD    A,(IX+0)			; Check for a zero.
  ld a, [hl]
  AND   A
  JP    NZ, next			; Finished?

subr:
  PUSH  BC				; Start of subroutine. Save the note length.
  LD    A,[volumeControl]	; Get the volume.
  LD    C,A
  DEC   H					; Decrement counter for first channel.
  JR    NZ,labl1			; Do we play the first note yet?
  XOR   A					; Zero A.
  ; OUT   (254),A			; Set beeper low.
  ldh [rNR32], a
  LD    B,C				; B holds a delay.
wait1:
  DJNZ  wait1				; Wait for the first half of the duty cycle.
  ; LD    A,16				; Set beeper bit.
  ; OUT   (254),A			; Set beeper high.
  ld a, %00100000
  ldh [rNR32], a

  ld a, 16
  SUB   C					; Subtract delay from 16.
  LD    B,A
wait2:
  DJNZ  wait2				; Wait for the second half of the duty cycle.
  ; LD    H,(IX+0)			; Re-load H with pitch for channel 1.
  ld a, [origH]
  ld h, a
labl1:
  DEC   L
  JR    NZ,labl2			; Do we play the second note yet?
  XOR   A					; Zero A.
  ; OUT   (254),A			; Set beeper low.
  ldh [rNR32], a
  LD    B,C
wait3:
  DJNZ  wait3				; Wait for the first half of the duty cycle.
  ; LD    A,16				; Set beeper bit.
  ; OUT   (254),A			; Set beeper high.
  ld a, %00100000
  ldh [rNR32], a

  ld a, 16
  SUB   C					; Subtract delay from 16.
  LD    B,A
wait4:
  DJNZ  wait4				; Wait for the second half of the duty cycle.
  ; LD    L,(IX+1)			; Re-load L with pitch for channel 2.
  ld a, [origL]
  ld l, a
labl2:
  DEC   D
  JR    NZ,labl3			; Do we play the third note yet?
  XOR   A					; Zero A.
  ; OUT   (254),A			; Set beeper low.
  ldh [rNR32], a
  LD    B,C
wait5:
  DJNZ  wait5				; Wait for the first half of the duty cycle.
  ; LD    A,16				; Set beeper bit.
  ; OUT   (254),A			; Set beeper high.
  ld a, %00100000
  ldh [rNR32], a

  ld a, 16
  SUB   C					; Subtract delay from 16.
  LD    B,A
wait6:
  DJNZ  wait6				; Wait for the second half of the duty cycle.
  ; LD    D,(IX+2)			; Re-load D with pitch for channel 3.
  ld a, [origD]
  ld d, a
labl3:
  DEC   E					; Volume control loop.
  JP    NZ,labl5			; Only use every ten cycles.
  LD    E,10
  LD    A,[attackDecay]	; Attack (1) or Decay (0)?
  AND   A
  JP    Z,labl4
  LD    A,[attackCount]	; Load the current attack count.
  DEC   A					; Subtract 1.
  LD    [attackCount],A	; Save it.
  JP    NZ,labl5			; We're done if count is not zero.
  LD    A,[attackRate]	; Loat the attack rate.
  LD    [attackCount],A	; Save it in the attack count.
  LD    A,[volumeControl]	; Load the volume.
  INC   A					; Increase it.
  LD    [volumeControl],A	; Save it.
  CP    15				; Is it maxed out?
  JP    NZ,labl5			; If not, skip this next bit.
  DEC   A
  LD    [volumeControl],A	; Decrease volume.
  XOR   A
  LD    [attackDecay],A	; Switch to decay.
  JP    labl5				; Skip to the end of the loop.
labl4:
  LD    A,[decayCount]	; Load the decay count.
  DEC   A
  LD    [decayCount],A
  JP    NZ,labl5			; Is it zero yet?
  LD    A,[decayRate]		; Load decay rate.
  LD    [decayCount],A	; Store it in count.
  LD    A,[volumeControl]	; Load volume.
  DEC   A					; Decrease it.
  LD    B,A				; Store it in B.
  LD    A,[decayTargetVolume]	; Load decay target.
  CP    B					; Is volume on target?
  JP    Z,labl5
  LD    A,B				; Store new volume.
  LD    [volumeControl],A
labl5:
  POP   BC				; Restore BC
  DEC   BC				; Decrement BC
  LD    A,B				; Is the note finished?
  OR    C
  JP    NZ,subr			; If BC is not zero loop again.
  RET						; return from subroutine

SECTION "workspace", WRAM0
noteLength:			dw ;$9600	; Note length counter.
volumeControl:		db ;$0C		; Volume control.
decayRate:			db ;$80		; Decay rate.
decayCount:			db ;$80		; Current decay count.
attackRate:			db ;$00		; Attack rate.
attackCount:		db ;$00		; Current attack count.
attackDecay:		db ;$00		; Attack (1) or decay (0) phase.
decayTargetVolume:	db ;$01		; Decay target volume.

;; npf
origH: db
origL: db
origD: db

SECTION "music data", ROM0

disassembly:
db $F3, $21, $E8, $03, $22, $5A, $9D, $DD
db $21, $62, $9D, $DD, $7E, $00, $3C, $C2
db $7C, $9C, $DD, $23, $DD, $66, $01, $DD
db $6E, $00, $22, $57, $9D, $DD, $23, $DD
db $23, $DD, $7E, $00, $32, $5C, $9D, $DD
db $7E, $01, $32, $5A, $9D, $DD, $7E, $02
db $32, $5F, $9D, $DD, $23, $DD, $23, $DD
db $23, $C3, $4B, $9C, $3A, $5A, $9D, $32
db $5B, $9D, $3A, $5C, $9D, $32, $5D, $9D
db $ED, $4B, $57, $9D, $DD, $66, $00, $DD
db $6E, $01, $DD, $56, $02, $1E, $0A, $3E
db $01, $32, $59, $9D, $32, $5E, $9D, $CD
db $BA, $9C, $AF, $DB, $FE, $2F, $E6, $1F
db $C2, $B8, $9C, $DD, $23, $DD, $23, $DD
db $23, $DD, $7E, $00, $A7, $C2, $4B, $9C
db $FB, $C9, $C5, $3A, $59, $9D, $4F, $25
db $20, $11, $AF, $D3, $FE, $41, $10, $FE
db $3E, $10, $D3, $FE, $91, $47, $10, $FE
db $DD, $66, $00, $2D, $20, $11, $AF, $D3
db $FE, $41, $10, $FE, $3E, $10, $D3, $FE
db $91, $47, $10, $FE, $DD, $6E, $01, $15
db $20, $11, $AF, $D3, $FE, $41, $10, $FE
db $3E, $10, $D3, $FE, $91, $47, $10, $FE
db $DD, $56, $02, $1D, $C2, $4F, $9D, $1E
db $0A, $3A, $5E, $9D, $A7, $CA, $2F, $9D
db $3A, $5D, $9D, $3D, $32, $5D, $9D, $C2
db $4F, $9D, $3A, $5C, $9D, $32, $5D, $9D
db $3A, $59, $9D, $3C, $32, $59, $9D, $FE
db $0F, $C2, $4F, $9D, $3D, $32, $59, $9D
db $AF, $32, $5E, $9D, $C3, $4F, $9D, $3A
db $5B, $9D, $3D, $32, $5B, $9D, $C2, $4F
db $9D, $3A, $5A, $9D, $32, $5B, $9D, $3A
db $59, $9D, $3D, $47, $3A, $5F, $9D, $B8
db $CA, $4F, $9D, $78, $32, $59, $9D, $C1
db $0B, $78, $B1, $C2, $BA, $9C, $C9, $00
db $96, $0C, $80, $80, $00, $00, $00, $01
db $00, $00, $FF, $60, $09, $02, $01, $0A
db $41, $52, $6D, $3D, $52, $6D, $41, $52
db $6D, $49, $52, $6D, $FF, $00, $96, $01
db $96, $01, $57, $62, $83, $FF, $00, $96
db $FA, $00, $0F, $57, $62, $83, $FF, $60
db $09, $04, $01, $0A, $53, $5D, $7C, $46
db $5D, $7C, $3E, $5D, $7C, $46, $5D, $7C
db $5D, $5D, $7C, $63, $5D, $7C, $5D, $53
db $7C, $63, $53, $7C, $6E, $53, $7C, $7C
db $53, $7C, $8C, $53, $7C, $7C, $53, $7C
db $6F, $53, $7C, $53, $53, $7C, $FF, $60
db $09, $04, $01, $0A, $64, $85, $C8, $59
db $85, $C8, $54, $85, $C8, $42, $84, $C7
db $54, $85, $C8, $59, $85, $C8, $64, $85
db $C8, $70, $86, $C8, $4B, $96, $E1, $54
db $96, $E1, $5F, $96, $E1, $64, $96, $E1
db $71, $96, $E1, $7F, $97, $E1, $71, $96
db $E1, $64, $96, $E1, $4E, $9D, $EB, $58
db $9D, $EB, $4E, $9D, $EB, $42, $9C, $EA
db $46, $9C, $EB, $58, $9C, $EB, $4E, $9D
db $EB, $58, $9D, $EB, $4E, $9D, $EB, $63
db $9D, $EB, $69, $9D, $EB, $84, $9D, $EB
db $76, $9D, $EB, $76, $9D, $EB, $76, $9D
db $EB, $76, $9D, $EB, $58, $63, $C7, $58
db $53, $C6, $57, $41, $C5, $57, $37, $C3
db $58, $63, $C7, $58, $53, $C6, $57, $41
db $C5, $57, $37, $C3, $53, $63, $C7, $53
db $53, $C6, $53, $41, $C5, $53, $37, $C3
db $53, $63, $C7, $53, $53, $C6, $53, $41
db $C5, $53, $37, $C3, $63, $63, $DF, $63
db $5E, $DF, $63, $4A, $DF, $63, $3E, $DF
db $63, $63, $DF, $63, $5E, $DF, $63, $4A
db $DF, $63, $3E, $DF, $5D, $63, $DF, $5D
db $5E, $DF, $5D, $4A, $DF, $5D, $3E, $DF
db $5D, $63, $DF, $5D, $5E, $DF, $5D, $4A
db $DF, $5D, $3E, $DF, $6F, $63, $C7, $6F
db $53, $C6, $6F, $41, $C5, $6F, $37, $C3
db $84, $63, $C7, $84, $53, $C6, $84, $41
db $C5, $84, $37, $C3, $7D, $63, $DF, $7D
db $5E, $DF, $7D, $4A, $DF, $7D, $3E, $DF
db $94, $63, $DF, $94, $5E, $DF, $94, $4A
db $DF, $94, $3E, $DF, $84, $63, $C7, $84
db $53, $C6, $84, $41, $C5, $84, $37, $C3
db $6F, $63, $C7, $6F, $53, $C6, $6F, $41
db $C5, $6F, $37, $C3, $63, $63, $C7, $63
db $53, $C6, $63, $41, $C5, $63, $37, $C3
db $63, $63, $C7, $63, $53, $C6, $63, $41
db $C5, $63, $37, $C3, $63, $63, $C7, $5E
db $53, $C6, $63, $41, $C5, $5E, $37, $C3
db $63, $63, $C7, $5E, $53, $C6, $63, $41
db $C5, $5E, $37, $C3, $5D, $5D, $D2, $75
db $58, $D2, $5C, $45, $CF, $58, $3A, $D0
db $5D, $5D, $D2, $75, $58, $D2, $5C, $45
db $CF, $58, $3A, $D0, $5D, $5D, $D2, $75
db $58, $D2, $5C, $45, $CF, $58, $3A, $D0
db $5C, $5C, $8B, $75, $58, $8B, $5C, $45
db $8B, $58, $3A, $8B, $63, $63, $DE, $63
db $5E, $DE, $63, $4A, $DD, $62, $3E, $DC
db $63, $63, $DE, $63, $5E, $DE, $63, $4A
db $6F, $62, $3E, $DC, $63, $63, $94, $63
db $5E, $F8, $63, $4A, $94, $62, $3E, $F8
db $63, $63, $F8, $63, $5E, $F8, $63, $4A
db $F8, $62, $3E, $F8, $FF, $60, $09, $01
db $01, $0D, $63, $63, $F8, $63, $5E, $F8
db $63, $4A, $F8, $62, $3E, $F8, $63, $63
db $F8, $63, $5E, $F8, $63, $4A, $F8, $62
db $3E, $F8, $6F, $63, $F8, $6F, $5E, $F8
db $6F, $4A, $F8, $6F, $3E, $F8, $6F, $63
db $F8, $6F, $5E, $F8, $6F, $4A, $F8, $6F
db $3E, $F8, $FF, $C0, $12, $01, $01, $0D
db $4A, $59, $DE, $53, $63, $DC, $59, $6F
db $DE, $53, $63, $DC, $63, $7C, $F9, $58
db $6F, $F9, $4A, $58, $F9, $58, $6F, $F9
db $FF, $60, $09, $01, $01, $0D, $57, $68
db $83, $68, $68, $83, $83, $68, $83, $62
db $68, $83, $68, $68, $83, $83, $68, $83
db $62, $6F, $94, $6F, $6F, $94, $94, $6F
db $94, $58, $6F, $94, $6F, $6F, $94, $94
db $6F, $94, $57, $68, $83, $68, $68, $83
db $83, $68, $83, $62, $68, $83, $68, $68
db $83, $83, $68, $83, $62, $6F, $94, $6F
db $6F, $94, $94, $6F, $94, $76, $6F, $94
db $6F, $6F, $94, $94, $6F, $94, $FF, $60
db $09, $01, $1E, $01, $6F, $94, $DE, $6F
db $94, $DE, $6F, $94, $DE, $6F, $94, $DE
db $7D, $A6, $DE, $6F, $94, $DE, $7D, $A6
db $DE, $6F, $94, $DE, $5D, $8C, $DE, $6F
db $8C, $DE, $6F, $8C, $DE, $6F, $8C, $DE
db $7D, $8C, $DE, $6F, $8C, $DE, $5D, $8C
db $DE, $6F, $8C, $DE, $53, $7C, $DE, $63
db $7C, $DE, $7C, $7C, $DE, $95, $7C, $DE
db $7C, $7C, $DE, $63, $7C, $DE, $53, $7C
db $DE, $5D, $7C, $DE, $63, $7C, $DE, $7C
db $7C, $DE, $6F, $6F, $DE, $6F, $6F, $DE
db $6F, $6F, $DE, $6F, $6F, $DE, $6F, $6F
db $DE, $6F, $6F, $DE, $6F, $6F, $DE, $6F
db $6F, $DE, $6F, $6F, $DE, $FF, $C0, $12
db $01, $00, $00, $E0, $E1, $E2, $E0, $E1
db $E2, $FF, $60, $09, $01, $00, $28, $5D
db $7C, $93, $E0, $E1, $E2, $E0, $E1, $E2
db $5D, $7C, $93, $E0, $E1, $E2, $E0, $E1
db $E2, $5D, $7C, $93, $E0, $E1, $E2, $FF
db $80, $25, $01, $00, $1E, $62, $7C, $A5
db $FF, $60, $09, $01, $00, $02, $3D, $7A
db $B8, $45, $6E, $B8, $49, $7A, $B8, $36
db $6D, $A3, $3D, $61, $A3, $41, $6D, $A3
db $3D, $7A, $B8, $45, $6E, $B8, $49, $7A
db $B8, $36, $6D, $A3, $3D, $61, $A3, $41
db $6D, $A3, $FF, $C0, $12, $01, $00, $28
db $E0, $E1, $E2, $E0, $E1, $E2, $FF, $60
db $09, $01, $00, $28, $5D, $7C, $93, $E0
db $E1, $E2, $E0, $E1, $E2, $5D, $7C, $93
db $E0, $E1, $E2, $E0, $E1, $E2, $5D, $7C
db $93, $E0, $E1, $E2, $FF, $80, $25, $01
db $00, $1E, $52, $6D, $82, $FF, $60, $09
db $01, $00, $02, $3D, $7A, $B8, $45, $6E
db $B8, $49, $7A, $B8, $36, $6D, $A3, $3D
db $61, $A3, $41, $6D, $A3, $45, $8A, $CF
db $4E, $7C, $CF, $53, $8B, $D0, $3D, $7A
db $B8, $45, $6E, $B8, $49, $7A, $B8, $4E
db $9C, $EA, $58, $8C, $EA, $5E, $9D, $EB
db $45, $8A, $CF, $4E, $7C, $CF, $53, $8B
db $D0, $3D, $7A, $B8, $45, $6E, $B8, $49
db $7A, $B8, $36, $6D, $A3, $3D, $61, $A3
db $41, $6D, $A3, $30, $60, $90, $36, $56
db $90, $39, $60, $90, $36, $56, $90, $30
db $60, $90, $36, $56, $90, $39, $60, $90
db $36, $56, $90, $30, $60, $90, $36, $56
db $90, $39, $60, $90, $36, $56, $90, $30
db $60, $90, $36, $56, $90, $39, $60, $90
db $36, $56, $90, $FF, $00, $96, $00, $80
db $01, $39, $60, $90, $00, $00, $00, $00