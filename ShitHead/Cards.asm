;	Card Constants
;	A card fits into 1 byte SSSS,RRRR; SUIT,RANK
ACE			equ 1
TWO			equ 2
THREE		equ 3
FOUR		equ 4
FIVE		equ 5
SIX			equ 6
SEVEN		equ 7
EIGHT		equ 8
NINE		equ 9
TEN			equ 10
JACK		equ 11
QUEEN		equ 12
KING		equ 13
HEARTS		equ %00010000
DIAMONDS	equ %00100000
SPADES		equ %01000000
CLUBS		equ %10000000	


;	Initialize card stacks
DKInit
proc
	push hl
	push de
	push bc
	push af

	call DKInitStacks
	call DKInitPack
	call DKInitStock
	call DKInitDeal

	pop af
	pop bc
	pop de
	pop hl

	ret
endp


;	Deals B cards and append them to DE
;	If B># cards remaining, only that number are dealt
;	[BYVAL IN] B:number of cards to deal
;	[BYVAL IN] DE:destination stack to append to
DKDeal
proc
	local _deal, _ret

	push hl
	push de
	push bc
	push af

	;	Test whether there are enough cards
	ld hl, STOCKDATA
	call VActivate
	;	Deal if cards remain
	call VGetCount
	;	Return if no cards remain
	jp z, _ret

	;	Test whether there are enough cards. A=count
	cp b
	jp nc, _deal
	;	Deal all remaining cards
	ld b, a

_deal
	;	Get card from STOCKDATA
	call VPop

	;	Append to destination
	ld h, d
	ld l, e
	call VActivate
	call VPush	

	ld hl, STOCKDATA
	call VActivate

	djnz _deal

_ret
	pop af
	pop bc
	pop de
	pop hl	
	ret
endp


;	[BYREF IN] A:card to add to wastepile
;	[OUT] NZ if valid
DKValidateDiscard
proc
	local _valid, _ret

	push hl
	push de
	push bc

	;	Set DE=Discard Rank-1
	and %00001111
	dec a
	ld d, 0
	ld e, a

	;	Valid if wastepile is empty
	ld hl, WASTEPILEDATA
	call VActivate
	call VGetCount
	jp z, _valid

	;	Set BC=wastepile rank-1
	call VPeek
	and %00001111
	dec a
	ld b, 0
	ld c, a

	;	Set HL=DE*13
	ld h, d
	ld l, e
	add hl, hl
	add hl, hl
	add hl, hl	;	*8
	add hl, de
	add hl, de
	add hl, de
	add hl, de
	add hl, de	;	*13

	;	Set HL=HL+VALIDITYGRID+BC
	ld de, VALIDITYGRID
	add hl, de
	add hl, bc

	;	Test
	ld a, (hl)
	jp _ret

_valid
	ld a, 1

_ret
	or a
	pop bc
	pop de
	pop hl
	ret
endp


;	Check the wastepile for a clear (ie 10 or 4 of a kind at the end)
;	[OUT] NZ if clear
DKCheckClear
proc
	local _clear, _noclear, _ret

	push hl
	push bc

	ld hl, WASTEPILEDATA
	call VActivate

	;	Check for ten
	call VPeek
	and %00001111
	cp TEN
	jp z, _clear

	;	Ensure >=4 cards in pile
	call VGetCount
	cp 4
	jp c, _noclear

	;	Get last card rank
	;	B=index, C=rank
	dec a
	ld b, a
	call VGetAt
	and %00001111
	ld c, a

	;n-1
	dec b
	call VGetAt
	and %00001111
	cp c
	jp nz, _noclear

	;n-2
	dec b
	call VGetAt
	and %00001111
	cp c
	jp nz, _noclear

	;n-3
	dec b
	call VGetAt
	and %00001111
	cp c
	jp nz, _noclear

_clear
	call VInitialize
	call DKShowWastepile
	ld a, 1
	or a
	jp _ret

_noclear
	xor a
	or a

_ret	
	pop bc
	pop hl
	ret
endp


DKShowStockCards
proc	
	local _initploop, _ploop, _nostock, _ret, _EMPTYSTR, _clearrect

	push hl
	push de
	push bc
	push af

	;	Display 'empty' if no cards exist
	ld hl, STOCKDATA
	call VActivate
	call VGetCount
	jp z, _nostock

	;	Show no more than 5 cards
	cp 6
	jp c, _initploop
	ld a, 5

_initploop
	ld b, a

	;	Test whether a redraw is necessary
	ld a, (LASTSTOCKCOUNT)
	cp b
	jp z, _ret
	ld a, b
	ld (LASTSTOCKCOUNT), a

	call _clearrect

	ld hl, T_CARDREVERSE

_ploop
	call PPutTile
	call PAdvance
	djnz _ploop
	jp _ret

_nostock
	call _clearrect
	ld hl, _EMPTYSTR
	call PPutStringTable

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret

_EMPTYSTR
	defb 1, 1, %01110001, 0, 11, "STOCK EMPTY", $80

_clearrect
	push bc
	;	Clear existing stock card display
	ld a, %00100100
	call PSetAttribute
	ld bc, $0101
	call PPrintAt
	ld bc, $0407
	call PClearRegion
	pop bc
	ret
endp


DKShowWastepile
proc
	local _initloop, _loop, _ret, _IDX

	push hl
	push de
	push bc
	push af

	;	Clear existing wastepile display
	ld a, %00100100
	call PSetAttribute
	xor a
	call PSetPrintFlags
	ld bc, $030a
	call PPrintAt
	ld bc, $0407
	call PClearRegion

	ld a, 1
	call PSetPrintFlags

	ld hl, WASTEPILEDATA
	call VActivate
	call VGetCount
	;	Exit if no cards
	jp z, _ret

	;	Show no more than 5 cards
	cp 6
	jp c, _initloop
	ld a, 5

_initloop
	ld b, a

	;	B=#cards to show
	call VGetCount
	;	A=stock count
	;	Set _IDX=first index to show
	sub b
	ld (_IDX), a

	;	DE=Print position
	ld de, $030E

_loop
	push bc

	;	Set the print position
	push bc
	ld b, d
	ld c, e
	call PPrintAt
	pop bc

	push bc
	;	Set B=(_IDX)++
	ld a, (_IDX)
	ld b, a
	inc a
	ld (_IDX), a
	;	Set A=card[B]
	call VGetAt
	call DKPrintCard
	pop bc

	;	Decrement the print column
	ld a, e
	dec a
	ld e, a

	pop bc
	djnz _loop

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret

_IDX defb 0
endp


DKShowP1DownCards
proc
	local _fdloop, _fuloop, _ret, _IDX

	push hl
	push de
	push bc
	push af

	;	Clear existing cards
	xor a
	call PSetPrintFlags
	ld a, %10100100
	call PSetAttribute
	ld bc, $0A01
	call PPrintAt
	ld bc, $060B
	call PClearRegion

	;	Show face down cards
	ld hl, P1FDOWNDATA
	call VActivate
	call VGetCount
	;	If there are no cards, then there can't be any face up cards either
	jp z, _ret

	;	DE=Print position
	ld de, $0C01
	ld hl, T_CARDREVERSE
	ld b, a
_fdloop
	push bc

	;	Set the print position
	ld b, d
	ld c, e
	call PPrintAt
	;	Print the tile
	call PPutTile
	;	Advance the print column
	ld a, e
	add a, 4
	ld e, a

	pop bc
	djnz _fdloop

	;~~~~~~~~~~~~~~~~~~~~~
	;	Show face up cards
	;~~~~~~~~~~~~~~~~~~~~~

	ld a, 1
	call PSetPrintFlags
	ld hl, P1FUPDATA
	call VActivate
	call VGetCount
	;	Exit if no cards
	jp z, _ret

	;	DE=Print position
	ld de, $0A01
	ld b, a
	xor a
	ld (_IDX), a
_fuloop
	push bc

	;	Set the print position
	push bc
	ld b, d
	ld c, e
	call PPrintAt
	pop bc

	push bc
	;	Set B=_IDX++
	ld a, (_IDX)
	ld b, a
	inc a
	ld (_IDX), a
	call VGetAt
	call DKPrintCard
	pop bc

	;	Advance the print column
	ld a, e
	add a, 4
	ld e, a

	pop bc
	djnz _fuloop

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret

_IDX
	defb 0
endp


DKShowP2DownCards
proc
	local _fdloop, _fuloop, _ret

	push hl
	push de
	push bc
	push af

	;	Clear existing cards
	xor a
	call PSetPrintFlags
	ld a, %10100100
	call PSetAttribute
	ld bc, $0114
	call PPrintAt
	ld bc, $060B
	call PClearRegion

	;	Show face down cards
	ld hl, P2FDOWNDATA
	call VActivate
	call VGetCount
	;	If there are no cards, then there can't be any face up cards either
	jp z, _ret

	;	DE=Print position
	ld de, $0314
	ld hl, T_CARDREVERSE
	ld b, a
_fdloop
	push bc

	;	Set the print position
	ld b, d
	ld c, e
	call PPrintAt
	;	Print the tile
	call PPutTile
	;	Advance the print column
	ld a, e
	add a, 4
	ld e, a

	pop bc
	djnz _fdloop

	;~~~~~~~~~~~~~~~~~~~~~
	;	Show face up cards
	;~~~~~~~~~~~~~~~~~~~~~

	ld a, 1
	call PSetPrintFlags
	ld hl, P2FUPDATA
	call VActivate
	call VGetCount
	;	Exit if no cards
	jp z, _ret

	;	DE=Print position
	ld de, $0114
	ld b, a
_fuloop
	push bc

	;	Set the print position
	push bc
	ld b, d
	ld c, e
	call PPrintAt
	pop bc

	push bc
	dec b
	call VGetAt
	call DKPrintCard
	pop bc

	;	Advance the print column
	ld a, e
	add a, 4
	ld e, a

	pop bc
	djnz _fuloop

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp


DKShowP1Hand
proc
	local _eachline
	local _eachcard
	local _redsuit
	local _blacksuit
	local _setattr
	local _ret
	local _nosuit
	local _OLDCHARS

	push hl
	push de
	push bc
	push af

	call DKSortP1Hand

	ld hl, (CHARS)
	ld (_OLDCHARS), hl

	xor a
	call PSetPrintFlags
	or %00100111
	call PSetAttribute

	ld bc, $1201
	call PPrintAt
	ld bc, $041A
	call PClearRegion	

	;	Print position
	ld de, $1201
	ld hl, P1HANDSTACK
	ld b, 2
_eachline
	push bc

	;	Print at column 1
	ld e, 1
	push bc
	ld b, d
	ld c, e
	call PPrintAt
	pop bc

	ld b, 26
_eachcard
	push bc

	;	Set suits charset
	push hl
	ld hl, SUIT_CHARS
	ld (CHARS), hl
	pop hl

	;	Set the attribute based on the suit
	ld a, (hl)
	and %11110000

	push af

	jp z, _nosuit
	cp CLUBS
	jp nc, _blacksuit
	cp SPADES
	jp nc, _blacksuit

_redsuit
	ld a, %01111010
	jp _setattr

_blacksuit
	ld a, %01111000
	jp _setattr

_nosuit
	ld a, %00100111

_setattr
	call PSetAttribute

	pop af

	;	Get the UDG code
	rlca
	rlca
	rlca
	rlca
	call PPutChar

	;	Inc the line to print the rank
	inc d
	push bc
	ld b, d
	ld c, e
	call PPrintAt
	pop bc

	;	Set rank charset
	push hl
	ld hl, HAND_CHARS
	ld (CHARS), hl
	pop hl

	;	Get the rank
	ld a, (hl)
	and %00001111
	call PPutChar

	;	Inc the column and dec line
	inc e
	dec d
	push bc
	ld b, d
	ld c, e
	call PPrintAt
	pop bc

	;	Next card
	inc hl
	pop bc
	djnz _eachcard

	;	Next row
	ld d, 20
	
	ld a, 20
	ld (S_POSN_LINE), a
	pop bc
	djnz _eachline

_ret
	ld hl, (_OLDCHARS)
	ld (CHARS), hl

	pop af
	pop bc
	pop de
	pop hl
	ret

_OLDCHARS	defw 0
endp


;DKShowP2Hand
;proc
;	local _eachline
;	local _eachcard
;	local _redsuit
;	local _blacksuit
;	local _setattr
;	local _ret
;	local _nosuit
;	local _OLDCHARS
;
;	push hl
;	push de
;	push bc
;	push af
;
;	ld hl, (CHARS)
;	ld (_OLDCHARS), hl
;
;	xor a
;	call PSetPrintFlags
;	or %00100111
;	call PSetAttribute
;	ld bc, $0814
;	call PPrintAt
;	ld bc, $0407
;	call PClearRegion	
;
;	;	Print position
;	ld de, $0814
;	ld hl, P2HANDSTACK
;	ld b, 2
;_eachline
;	push bc
;
;	;	Print at column 1
;	ld e, 1
;	push bc
;	ld b, d
;	ld c, e
;	call PPrintAt
;	pop bc
;
;	ld b, 26
;_eachcard
;	push bc
;
;	;	Set suits charset
;	push hl
;	ld hl, SUIT_CHARS
;	ld (CHARS), hl
;	pop hl
;
;	;	Set the attribute based on the suit
;	ld a, (hl)
;	and %11110000
;
;	push af
;
;	jp z, _nosuit
;	cp CLUBS
;	jp nc, _blacksuit
;	cp SPADES
;	jp nc, _blacksuit
;
;_redsuit
;	ld a, %01111010
;	jp _setattr
;
;_blacksuit
;	ld a, %01111000
;	jp _setattr
;
;_nosuit
;	ld a, %00100111
;
;_setattr
;	call PSetAttribute
;
;	pop af
;
;	;	Get the UDG code
;	rlca
;	rlca
;	rlca
;	rlca
;	call PPutChar
;
;	;	Inc the line to print the rank
;	inc d
;	push bc
;	ld b, d
;	ld c, e
;	call PPrintAt
;	pop bc
;
;	;	Set rank charset
;	push hl
;	ld hl, HAND_CHARS
;	ld (CHARS), hl
;	pop hl
;
;	;	Get the rank
;	ld a, (hl)
;	and %00001111
;	call PPutChar
;
;	;	Inc the column and dec line
;	inc e
;	dec d
;	push bc
;	ld b, d
;	ld c, e
;	call PPrintAt
;	pop bc
;
;	;	Next card
;	inc hl
;	pop bc
;	djnz _eachcard
;
;	;	Next row
;	ld d, 20
;	
;	ld a, 20
;	ld (S_POSN_LINE), a
;	pop bc
;	djnz _eachline
;
;_ret
;	ld hl, (_OLDCHARS)
;	ld (CHARS), hl
;
;	pop af
;	pop bc
;	pop de
;	pop hl
;	ret
;
;_OLDCHARS	defw 0
;endp

DKShowP2Hand
proc
	local _initploop, _ploop, _ret

	push hl
	push de
	push bc
	push af

	xor a
	call PSetPrintFlags
	ld a, %00100100
	call PSetAttribute
	ld bc, $0814
	call PPrintAt
	ld bc, $0407
	call PClearRegion

	ld hl, P2HANDDATA
	call VActivate
	call VGetCount
	jp z, _ret

	;	Show no more than 5 cards
	cp 6
	jp c, _initploop
	ld a, 5

_initploop
	ld b, a
	ld hl, T_CARDREVERSE

_ploop
	call PPutTile
	call PAdvance
	djnz _ploop

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp


;~~~~~~~~~~~~~~~~~~~
;	Private Routines
;~~~~~~~~~~~~~~~~~~~


;	[BYVAL IN] B:l-value
;	[BYVAL IN] C:r-value
;	[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
DKCompare
proc
	;	Compare ranks while ignorring suits

	push bc

	ld a, b
	and %00001111
	ld b, a

	ld a, c
	and %00001111
	ld c, a

	ld a, b
	cp c	
		
	pop bc

	ret
endp


;	[BYVAL IN] B:l-value
;	[BYVAL IN] C:r-value
;	[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
DKCompareReverse
proc
	;	Compare ranks while ignorring suits

	push bc

	ld a, b
	and %00001111
	ld b, a

	ld a, c
	and %00001111
	ld c, a

	ld a, c
	cp b	
		
	pop bc

	ret
endp


;	Prints a card at the current DFADDRESS
;	[BYVAL IN] A:card
DKPrintCard
proc
	local _OLDCHARS, _puttile

	push hl
	push af

	;	Change the charset
	ld hl, (CHARS)
	ld (_OLDCHARS), hl
	ld hl, FACEUP_CHARS
	ld (CHARS), hl

	push af
	ld a, %00010000
	call PSetPrintFlags
	ld a, %11111111
	call PSetMask
	pop af

	;	Test the suit and show the appropriate tile
	ld hl, T_CLUBS
	cp CLUBS
	jp nc, _puttile
	ld hl, T_SPADES
	cp SPADES
	jp nc, _puttile
	ld hl, T_DIAMONDS
	cp DIAMONDS
	jp nc, _puttile
	ld hl, T_HEARTS
_puttile
	call PPutTile

	;	Mask off the suit to give the rank char code
	and %00001111
	call PPutChar

	;	Reset the charset
	ld hl, (_OLDCHARS)
	ld (CHARS), hl

	pop af
	pop hl
	ret

_OLDCHARS	defw 0
endp


DKInitStacks
proc
	local _loop

	xor a
	ld (LASTSTOCKCOUNT), a

	ld hl, STACKENUM
	ld b, STACKENUMCOUNT
_loop
	push bc

	ld c, (hl)
	inc hl
	ld b, (hl)

	push hl
	ld h, b
	ld l, c
	call VActivate
	call VInitialize
	pop hl

	inc hl
	pop bc
	djnz _loop

	ret
endp


DKInitPack
proc
	;	Initialize PACKDATA

	local _loop

	;	Start of pack
	ld hl, PDSTACK
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

	ld a, 52
	ld (PDCURSIZE), a

	ret
endp


;DKInitStock
;proc
;	;	Shuffle the pack into stock
;	
;	ld hl, STOCKDATA
;	call VActivate
;
;	ld hl, PACKDATA
;	call VAssign
;
;	ret
;endp


DKInitStock
proc
	local _next_rnd, _ret

	;	Shuffle PACKDATA into STOCKDATA

	;	Current PACKDATA max
	ld c, 51

_next_rnd
	;	Set HL. Ignore H
	call RND16Next
	;	L=0.255. Divide it by 4 so that L=0.63 ish
	ld a, l
	srl a
	srl a
	ld l, a

	;	Check the range. We require 0..C
	ld a, c
	cp l
	jr c, _next_rnd
	ld a, l
		
	ld b, a
	ld hl, PACKDATA
	call VActivate
	call VGetAt
	call VRemoveAt
	dec c

	ld hl, STOCKDATA
	call VActivate
	call VPush

	;	Repeat while C>=0
	ld a, c
	or a
	jp m, _ret
	jr _next_rnd

_ret
	ret
endp


DKInitDeal
proc
	local _loop

	ld hl, HANDENUM
	ld b, HANDENUMCOUNT
_loop
	push bc

	;	Set destination stack
	ld e, (hl)
	inc hl
	ld d, (hl)

	;	Deal 3 cards to each of the hand stacks
	ld b, 3	
	call DKDeal

	inc hl
	pop bc
	djnz _loop

	ret
endp


DKSortP1Hand
proc
	push hl
	ld hl, DKCompare
	call VSetComparer
	ld hl, P1HANDDATA
	call VActivate
	call VSort
	pop hl
	ret
endp


;	Data

PACKDATA				;	Default unshuffled pack
	PDMAXSIZE	defb 52
	PDCURSIZE	defb 0
	PDSTACK		defs 52
	defb 0
STOCKDATA				;	Shuffled pack
	SDMAXSIZE	defb 52
	SDCURSIZE	defb 0
	SDSTACK		defs 52
	defb 0
WASTEPILEDATA			;	Discards
	WDMAXSIZE	defb 52
	WDCURSIZE	defb 0
	WDSTACK		defs 52
	defb 0

;	Player 1 data
P1HANDDATA
	P1HANDSZ		defb 52
	P1HANDCS		defb 0
	P1HANDSTACK		defs 52
	defb 0
P1FDOWNDATA
	P1FDOWNSZ		defb 3
	P1FDOWNCS		defb 0
	P1FDOWNSTACK	defs 3
	defb 0
P1FUPDATA
	P1FUPSZ			defb 3
	P1FUPCS			defb 0
	P1FUPSTACK		defs 3
	defb 0

;	Player 2 data
P2HANDDATA
	P2HANDSZ		defb 52
	P2HANDCS		defb 0
	P2HANDSTACK		defs 52
	defb 0
P2FUPDATA
	P2FUPSZ			defb 3
	P2FUPCS			defb 0
	P2FUPSTACK		defs 3
	defb 0
P2FDOWNDATA
	P2FDOWNSZ		defb 3
	P2FDOWNCS		defb 0
	P2FDOWNSTACK	defs 3
	defb 0


STACKENUM		defw PACKDATA, STOCKDATA, WASTEPILEDATA, P1HANDDATA, P1FUPDATA, P1FDOWNDATA, P2HANDDATA, P2FUPDATA, P2FDOWNDATA
STACKENUMCOUNT	equ $9
HANDENUM		defw P1HANDDATA, P1FUPDATA, P1FDOWNDATA, P2HANDDATA, P2FUPDATA, P2FDOWNDATA
HANDENUMCOUNT	equ $6
LASTSTOCKCOUNT	defb 0

;	13x13 matrix; is card y rank valid on card x?

VALIDITYGRID
	; Is Y valid on X
	; X= wastepile card
	; Y= discard
	; X= A,2,3,4,5,6,7,8,9,T,J,Q,K
	defb 1,1,1,1,1,1,1,1,1,1,1,1,1	; A 
	defb 1,1,1,1,1,1,1,1,1,1,1,1,1	; 2 
	defb 0,1,1,0,0,0,0,0,0,0,0,0,0	; 3 
	defb 0,1,1,1,0,0,0,0,0,0,0,0,0	; 4 
	defb 0,1,1,1,1,0,0,0,0,0,0,0,0	; 5
	defb 0,1,1,1,1,1,0,0,0,0,0,0,0	; 6
	defb 0,1,1,1,1,1,1,0,0,0,1,1,1	; 7
	defb 0,1,1,1,1,1,1,1,0,0,0,0,0	; 8
	defb 0,1,1,1,1,1,1,1,1,0,0,0,0	; 9
	defb 1,1,1,1,1,1,1,1,1,1,1,1,1	; T
	defb 0,1,1,1,1,1,0,1,1,1,1,0,0	; J
	defb 0,1,1,1,1,1,0,1,1,1,1,1,0	; Q
	defb 0,1,1,1,1,1,0,1,1,1,1,1,1	; K