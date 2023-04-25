INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
	jp EntryPoint
	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Do not turn the LCD off outside of VBlank
	call WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data (bg)
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call Memcopy

	; Copy the tile data (objects: paddle)
	ld de, Paddle
	ld hl, $8000
	ld bc, PaddleEnd - Paddle
	call Memcopy
	
	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

    ; set BGP palette
    ;ld a, %00011011 ; black to white
    ld a, %11100100 ; white to black
	ld [rBGP], a

	; Turn the LCD on
	;ld a, LCDCF_ON | LCDCF_BGON
	;ld [rLCDC], a

    ; clean OAM
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM

ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; draw object
    ld hl, _OAMRAM
    ld a, 128 + 16 ; x=128
    ld [hli], a
    ld a, 16 + 8 ; y=16
    ld [hli], a
    ld a, 0 ; tile id=0
    ld [hli], a
    ld [hl], a ; attributes=0

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; During the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

	; define wFrameCounter = 0
	ld a, 0
    ld [wFrameCounter], a

Main:
	call WaitVBlank

	ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    cp a, 15 ; Every 15 frames (a quarter of a second), run the following code
    jp nz, Main

    ; Reset the frame counter back to 0
    ld a, 0
    ld [wFrameCounter], a

    ; Move the paddle one pixel to the right.
    ld a, [_OAMRAM + 1]
    inc a
    ld [_OAMRAM + 1], a
    jp Main



; wait for vblank to continue
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank
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



SECTION "Counter", WRAM0
	wFrameCounter: db

INCLUDE "brick.inc"
