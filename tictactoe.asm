INCLUDE "hardware.inc"

; $8000 start of FG tiles
; $9000 start of BG tiles
; $9800 start of tilemap

; constants
DEF TILE_EMPTY EQU $00
DEF TILE_O EQU $01
DEF TILE_X EQU $02

; DEF BRICK_LEFT EQU $05
; DEF BRICK_RIGHT EQU $06
; DEF BLANK_TILE EQU $08


SECTION "Header", ROM0[$100]
	jp EntryPoint
	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	ld a, 0
	ld [rNR52], a ; Shut down audio circuitry

	call WaitVBlank ; Do not turn the LCD off outside of VBlank!

	ld a, 0
	ld [rLCDC], a ; Turn the LCD off

    ; copy tiles
	ld de, TileEmpty ; $00
	ld hl, $9000
	ld bc, TileEmptyEnd - TileEmpty
	call Memcopy

    ld de, TileO ; $01
	ld hl, $9010
	ld bc, TileOEnd - TileO
	call Memcopy

    ld de, TileX ; $02
	ld hl, $9020
	ld bc, TileXEnd - TileX
	call Memcopy

    ld de, TileHor ; $03
	ld hl, $9030
	ld bc, TileHorEnd - TileHor
	call Memcopy

    ld de, TileVer ; $04
	ld hl, $9040
	ld bc, TileVerEnd - TileVer
	call Memcopy

    ld de, TileCross ; $05
	ld hl, $9050
	ld bc, TileCrossEnd - TileCross
	call Memcopy

    ld de, TileSelect
	ld hl, $8000
	ld bc, TileSelectEnd - TileSelect
	call Memcopy
	
	; copy tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

    ld a, TILE_O
    ld [$98c7], a

    ld a, TILE_X
    ld [$98c7 + 2], a

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
	ld a, 6*8 + 16 ; y
	ld [hli], a
	ld a, 7*8 + 8 ; x
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

    ; set variables

	; define wFrameCounter = 0
	ld a, 0
    ld [wFrameCounter], a

    ld a, 0
    ld [wX], a

    ld a, 0
    ld [wY], a

    ld a, 1
    ld [wKind], a
	

Main:
	call WaitVBlank
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


UpdateKeys:
	; Poll half the controller
	ld a, P1F_GET_BTN
	call .onenibble
	ld b, a ; B7-4 = 1; B3-0 = unpressed buttons
  
	; Poll the other half
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a ; A3-0 = unpressed directions; A7-4 = 1
	xor a, b ; A = pressed buttons + directions
	ld b, a ; B = pressed buttons + directions
  
	; And release the controller
	ld a, P1F_GET_NONE
	ldh [rP1], a
  
	; Combine with previous wCurKeys to make wNewKeys
	ld a, [wCurKeys]
	xor a, b ; A = keys that changed state
	and a, b ; A = keys that changed to pressed
	ld [wNewKeys], a
	ld a, b
	ld [wCurKeys], a
	ret
  
  .onenibble
	ldh [rP1], a ; switch the key matrix
	call .knownret ; burn 10 cycles calling a known ret
	ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
	ldh a, [rP1]
	ldh a, [rP1] ; this read counts
	or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
  .knownret
	ret
  

; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First, we need to divide by 8 to convert a pixel position to a tile position.
    ; After this we want to multiply the Y position by 32.
    ; These operations effectively cancel out so we only need to mask the Y value.
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; Now we have the position * 8 in hl
    add hl, hl ; position * 16
    add hl, hl ; position * 32
    ; Convert the X position to an offset.
    ld a, b
    srl a ; a / 2
    srl a ; a / 4
    srl a ; a / 8
    ; Add the two offsets together.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Add the offset to the tilemap's base address, and we are done!
    ld bc, $9800
    add hl, bc
    ret



SECTION "Vars", WRAM0
	wFrameCounter: db
    wX: db
    wY: db
    wKind: db

SECTION "Input Variables", WRAM0
	wCurKeys: db
	wNewKeys: db
	

INCLUDE "tictactoe.inc"
