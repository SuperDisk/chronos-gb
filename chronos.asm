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

Memcpy::
  ; Increment B if C is non-zero
  dec bc
  inc b
  inc c
.loop
  ld a, [de]
  ld [hli], a
  inc de
  dec c
  jr nz, .loop
  dec b
  jr nz, .loop
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

    ld hl, Music_Init
    ld de, RAMCode
    ld bc, ramcode_end - Music_Init
    call Memcpy

    jp Music_Init

include "driver.asm"