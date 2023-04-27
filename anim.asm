INCLUDE "hardware.inc"

; constants
DEF FRAMES EQU 30
DEF X_MIN EQU  6; +  8 ; offset x is 8
DEF X_MAX EQU 154 +  8
DEF Y     EQU  62 + 16  ; offset y is 16

DEF VRAM_FG_START EQU $8000
DEF VRAM_BG_START EQU $9000

SECTION "Start", ROM0[$100]
	jp EntryPoint
	ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ld a, 0
	ld [rNR52], a ; Shut down audio circuitry

    call WaitVBlank

    ld a, 0
	ld [rLCDC], a ; Turn the LCD off

    ld de, TileDot
	ld hl, VRAM_FG_START ; each takes $10
	ld bc, TileDotEnd - TileDot
	call Memcopy

    ld de, TileEmpty
	ld hl, VRAM_BG_START + 0 * $10
	ld bc, TileEmptyEnd - TileEmpty
	call Memcopy

    ld de, Tile0
	ld hl, VRAM_BG_START + 1 * $10 ; starts at #1
	ld bc, Tile9End - Tile0
	call Memcopy

    ld de, TileA
	ld hl, VRAM_BG_START + 11 * $10 ; starts at #11
	ld bc, TileZEnd - TileA
	call Memcopy

    ld a, 18 + 11 ; S
    ld [_SCRN0 + 0], a
    ld a, 2 + 11 ; C
    ld [_SCRN0 + 1], a
    ld a, 14 + 11 ; O
    ld [_SCRN0 + 2], a
    ld a, 17 + 11 ; R
    ld [_SCRN0 + 3], a
    ld a, 4 + 11 ; E
    ld [_SCRN0 + 4], a

    ld a, 1 + 1 ; 1
    ld [_SCRN0 + 0 + 32], a
    ld a, 2 + 1 ; 2
    ld [_SCRN0 + 1 + 32], a
    ld a, 3 + 1 ; 3
    ld [_SCRN0 + 2 + 32], a

    call ClearOam

    ; define objects
    ld hl, _OAMRAM

    ; define object (select)
    ld a, Y;0 + 16 ; y
    ld [hli], a
    ld a, X_MIN;0 + 8 ; x
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

    ld a, 50
    ld [y], a

    ld a, 1
    ld [dx], a

Main:
	call WaitVBlank

; RandomizeX:
;     call RNG ; updates RandomVal
;     cp a, 152
;     jp nc, RandomizeX

;     ; screen dims are 160x144 pixels (20x18 sprites)
;     ; to 160-8 = [0, 152]
;     add 8
;     ld hl, _OAMRAM+1
;     ld [hl], a

;     jp Main


    ld a, [frameNo]
    dec a
    jp z, .doFrame
    ld [frameNo], a
    jp Main
.doFrame:
    ld a, FRAMES
    ld [frameNo], a

; up or down via keys

    call UpdateKeys

    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, .afterUp

; up:
    ld a, [y]
    dec a
    ld [y], a
    jp .afterDown

.afterUp:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, .afterDown

; down:
    ld a, [y]
    inc a
    ld [y], a

.afterDown:

; left/right via dx and x

    ld a, [dx] ; dx == 1 ?
    cp a, 1
    jp z, .goingRight


.goingLeft:
    ld a, [x]
    dec a
    cp a, X_MIN
    jp nz, .moveObject
    ld b, a
    ld a, 1 ; to right
    ld [dx], a
    ld a, b
    jp .moveObject

.goingRight:
    ld a, [x]
    inc a
    cp a, X_MAX
    jp nz, .moveObject
    ld b, a
    ld a, -1 ; to left
    ld [dx], a
    ld a, b

.moveObject:
    ld [x], a

    ld hl, _OAMRAM

    ld a, [y]
    ld [hli], a ; set y and move to x

    ld a, [x]
    ld [hl], a

    jp Main


;;;;;;;;;;;;;;;;;;


INCLUDE "misc.inc"
INCLUDE "digits.inc"
INCLUDE "alphabet.inc"


;;;;;;;;;;;;;;;;;;


SECTION "Vars", WRAM0
    frameNo: db

    x: db
    y: db
    dx: db

    wCurKeys: db
    wNewKeys: db

    RandomVal: db

;;;;;;;;;;;;;;;;;;


SECTION "Tile data", ROM0

; FG

TileDot: ; 0
    dw `00000000
    dw `00333300
    dw `03222230
    dw `03211230
    dw `03211230
    dw `03222230
    dw `00333300
    dw `00000000
TileDotEnd:

TileEmpty: ; 0
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
TileEmptyEnd:
