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

	; Check the current keys every frame and move left or right.
	call UpdateKeys

	; First, check if the left button is pressed.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
    ; Move the paddle one pixel to the left.
    ld a, [_OAMRAM + 1]
    dec a
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 15
    jp z, Main
    ld [_OAMRAM + 1], a
    jp Main

; Then check the right button.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, Main
Right:
    ; Move the paddle one pixel to the right.
    ld a, [_OAMRAM + 1]
    inc a
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 105
    jp z, Main
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
  


SECTION "Counter", WRAM0
	wFrameCounter: db

SECTION "Input Variables", WRAM0
	wCurKeys: db
	wNewKeys: db



INCLUDE "brick.inc"
