INCLUDE "hardware.inc"

; $8000 start of FG tiles
; $9000 start of BG tiles
; $9800 start of tilemap

; constants
DEF TILE_EMPTY EQU $00
DEF TILE_O EQU $01
DEF TILE_X EQU $02


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

    call ClearOam

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

	ld a, 0
    ld [wFrameNo], a

    ld a, 0
    ld [wX], a

    ld a, 0
    ld [wY], a

    ld a, 1
    ld [wKind], a
	

Main:
	call WaitVBlank
    jp Main
	

INCLUDE "misc.inc"


SECTION "Vars", WRAM0
    wFrameNo: db

    wX: db
    wY: db
    wKind: db

    wCurKeys: db
    wNewKeys: db



INCLUDE "tictactoe.inc"
