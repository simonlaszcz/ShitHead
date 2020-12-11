org 23990


HEARTS		equ %00010000
DIAMONDS	equ %00100000
SPADES		equ %01000000
CLUBS		equ %10000000	

org 23990

call InitPack
call DealCards

retn


InitPack
proc
	;	Initialize the unshuffled pack

	local _loop

	;	Start of pack
	ld hl, PACK
	;	Used to mask off suit
	ld d, %00001111

	;	12 cards per suit
	;	A=1 K=13
	ld b, 13
_loop
	ld a, b

	;	Save H,D,S,C
	or HEARTS
	ld (hl), a
	inc hl

	and d
	or DIAMONDS
	ld (hl), a
	inc hl

	and d
	or SPADES
	ld (hl), a
	inc hl

	and d
	or CLUBS
	ld (hl), a

	inc hl
	djnz _loop

	ret
endp


DealCards
proc
	;	Deal 9 cards to each player and set counters

	;	34 cards will remain
	ld de, 34
	;	Set hl to point to the first of the last 18 stock cards
	ld hl, PACK
	add hl, de

	;	P1 face down (hl will be incremented by bc)
	ld de, P1FDOWN
	ld bc, 3
	ldir

	;	P2 face down
	;inc hl
	ld de, P2FDOWN
	ld bc, 3
	ldir

	;	P1 face-up
	;inc hl
	ld de, P1FUP
	ld bc, 3
	ldir

	;	P2 face-up
	;inc hl
	ld de, P2FUP
	ld bc, 3
	ldir

	;	P1 hand
	;inc hl
	ld de, P1HAND
	ld bc, 3
	ldir

	;	P2 hand
	;inc hl
	ld de, P2HAND
	ld bc, 3
	ldir

	ret
endp

defb 128
defb 128
defb 128
defb 128

PACK			defs 52		;	Unshuffled pack
defb 128
P1FDOWN			defs 3		;	P1 face-down cards
defb 128
P1FUP			defs 3		;	P1 Face-up cards
defb 128
P1HAND			defs 52		;	P1 Hand cards
defb 128
P2FDOWN			defs 3		;	P2 face-down cards
defb 128
P2FUP			defs 3		;	P2 Face-up cards
defb 128
P2HAND			defs 52		;	P2 Hand cards