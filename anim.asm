INCLUDE "hardware.inc"

; constants
DEF FRAMES EQU 30;120
DEF X_MIN EQU 16
DEF X_MAX EQU 90

SECTION "Start", ROM0[$100]
	jp EntryPoint
	ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ld a, 0
	ld [rNR52], a ; Shut down audio circuitry

    call WaitVBlank

    ld a, 0
	ld [rLCDC], a ; Turn the LCD off

    ld de, TileO
	ld hl, $8000
	ld bc, TileOEnd - TileO
	call Memcopy

    ; clean OAM
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
    ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; define objects
    ld hl, _OAMRAM

    ; define object (select)
    ld a, 0 + 16 ; y
    ld [hli], a
    ld a, 0 + 8 ; x
    ld [hli], a
    ld a, 0 ; tile id
    ld [hli], a 
    ld a, 0 ; attributes
    ld [hli], a 

    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON ; Turn the LCD on
    ld [rLCDC], a

    ; initialize display registers (palettes)
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    ld a, 0 ; scroll to (0, 0)
    ld [rSCX], a
    ld [rSCY], a

    ld a, FRAMES
    ld [frameNo], a
    
    ld a, X_MIN
    ld [x], a

    ld a, 1
    ld [dx], a

Main:
	call WaitVBlank

    ld a, [frameNo]
    cp a, 0
    jp z, GoOn
    dec a
    ld [frameNo], a
    jp Main

GoOn:
    ld a, FRAMES
    ld [frameNo], a

    ld a, [x]

    inc a

    cp a, X_MAX
    jp nz, SkipXReset
    ld a, X_MIN
SkipXReset:

    ld [x], a

    ld hl, _OAMRAM + 1
    ld [hli], a

    jp Main


;;;;;;;;;;;;;;;;;;


; wait for vblank to continue
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank ; while rLY < 144
	ret


; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret


;;;;;;;;;;;;;;;;;;


SECTION "Vars", WRAM0
    frameNo: db
    x: db
    dx: db


;;;;;;;;;;;;;;;;;;


SECTION "Tile data", ROM0

; FG

TileO: ; 0
    dw `00000000
    dw `00333300
    dw `03222230
    dw `03211230
    dw `03211230
    dw `03222230
    dw `00333300
    dw `00000000
TileOEnd:
