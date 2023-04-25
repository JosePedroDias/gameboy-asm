INCLUDE "hardware.inc"

; constants
DEF BRICK_LEFT EQU $05
DEF BRICK_RIGHT EQU $06
DEF BLANK_TILE EQU $08

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

	; Copy the ball tile
	ld de, Ball
	ld hl, $8010
	ld bc, BallEnd - Ball
	call Memcopy
	
	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

    call ClearOam

    ; define object (paddle)
    ld hl, _OAMRAM
    ld a, 128 + 16 ; y=128
    ld [hli], a
    ld a, 16 + 8 ;   x=16
    ld [hli], a
    ld a, 0 ;        tile id=0, attributes=0
    ld [hli], a
    ld [hli], a 

	; define object (ball)
	ld a, 100 + 16 ; y=100
	ld [hli], a
	ld a, 32 + 8 ;   x=32
	ld [hli], a
	ld a, 1 ;        tile id=1
	ld [hli], a 
	ld a, 0 ;        attributes=0
	ld [hli], a 

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; During the first (blank) frame, initialize display registers (palettes)
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

	; define wFrameCounter = 0
	ld a, 0
    ld [wFrameCounter], a

	; The ball starts out going up and to the right
	ld a, 1 ; right
	ld [wBallMomentumX], a
	ld a, -1 ; up
	ld [wBallMomentumY], a

	; resetting keys (not required, used if I dont call the fn UpdateKeys)
	; ld a, 0
	; ld [wNewKeys], a
	; ld [wCurKeys], a
	

Main:
	call WaitVBlank

	jp AfterFC ; changing this breaks the game, crap

	ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    cp a, 3 ; every 3 frames, aka 60/3 = 20 fps
    jp nz, Main
    ld a, 0 ; Reset the frame counter back to 0
    ld [wFrameCounter], a

AfterFC:
	; Add the ball's momentum to its position in OAM.
    ld a, [wBallMomentumX]
    ld b, a
    ld a, [_OAMRAM + 5] ; ball's x
    add a, b
    ld [_OAMRAM + 5], a

    ld a, [wBallMomentumY]
    ld b, a
    ld a, [_OAMRAM + 4] ;ball's y
    add a, b
    ld [_OAMRAM + 4], a

	;jp BounceDone

BounceOnTop:
    ; Remember to offset the OAM position!
    ; (8, 16) in OAM coordinates is (0, 0) on the screen.
    ld a, [_OAMRAM + 4]
    sub a, 16 + 1 ; CHECK (x, y-1)
    ld c, a ; c = y
    ld a, [_OAMRAM + 5]
    sub a, 8
    ld b, a ; b = x
    call GetTileByPixel ; Returns tile address in hl
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnRight
	call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumY], a

BounceOnRight:
    ld a, [_OAMRAM + 4]
    sub a, 16
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8 - 1 ; CHECK (x+1, y)
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnLeft
	call CheckAndHandleBrick
    ld a, -1
    ld [wBallMomentumX], a

BounceOnLeft:
    ld a, [_OAMRAM + 4]
    sub a, 16
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8 + 1 ; CHECK (x-1, y)
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnBottom
	call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumX], a

BounceOnBottom:
    ld a, [_OAMRAM + 4]
    sub a, 16 - 1 ; CHECK (x, y+1)
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceDone
	call CheckAndHandleBrick
    ld a, -1
    ld [wBallMomentumY], a

BounceDone:
	jp PaddleBounceDone

	; TODO THIS PART IS NOT WORKING WELL

    ; First, check if the ball is low enough to bounce off the paddle.
    ld a, [_OAMRAM] ; paddle_y
    ld b, a
    ld a, [_OAMRAM + 4] ; ball_y
	sub a, 6 ; tweaking the bounce height
    cp a, b
    jp nz, PaddleBounceDone ; If the ball isn't at the same Y position as the paddle, it can't bounce.
    ; Now let's compare the X positions of the objects to see if they're touching.
    ld a, [_OAMRAM + 5] ; ball_x
    ld b, a
    ld a, [_OAMRAM + 1] ; paddle_x
    sub a, 8
    cp a, b
    jp c, PaddleBounceDone ; to the left < 8 (12 to the left of paddle center)
    add a, 8 + 16 ; 8 to undo, 16 as the width.
    cp a, b
    jp nc, PaddleBounceDone ; to the right > 8 + 16 (12 to the right of paddle center)

    ld a, -1
    ld [wBallMomentumY], a

PaddleBounceDone:
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


;;;;;;;;;;;;;;;;;;;;;


; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret


; Checks if a brick was collided with and breaks it if possible.
; @param hl: address of tile.
CheckAndHandleBrick:
    ld a, [hl]
    cp a, BRICK_LEFT
    jr nz, CheckAndHandleBrickRight
    ; Break a brick from the left side.
    ld [hl], BLANK_TILE
    inc hl
    ld [hl], BLANK_TILE
CheckAndHandleBrickRight:
    cp a, BRICK_RIGHT
    ret nz
    ; Break a brick from the right side.
    ld [hl], BLANK_TILE
    dec hl
    ld [hl], BLANK_TILE
    ret


INCLUDE "misc.inc"


SECTION "Counter", WRAM0
	wFrameCounter: db

SECTION "Input Variables", WRAM0
	wCurKeys: db
	wNewKeys: db

SECTION "Ball Data", WRAM0
	wBallMomentumX: db
	wBallMomentumY: db
	

INCLUDE "brick.inc"
