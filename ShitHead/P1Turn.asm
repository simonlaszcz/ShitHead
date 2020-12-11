P1ExchangeCards
proc
	local _display_menu, _menu, _end_menu, _MENUDATA, _P1MENU

	call P1Init
	call P1SetCursor

_display_menu
	ld hl, _P1MENU
	call PPutStringTable
_menu
	ld hl, _MENUDATA
	call ITestMenu
	jp _menu
_end_menu
	call P1ResetCursor
	ret

_MENUDATA
	defb KEY5
	defw P1Left, _menu
	defb 0
	defb KEY8
	defw P1Right, _menu
	defb 0
	defb KEYE
	defw P1ExchangeCard, _display_menu
	defb 0
	defb KEYF
	defw P1FinishExchange, _end_menu
	defb 0
	defb $80

_P1MENU
	defb 23, 0, %01110001, 0, 32, " <> EXCHANGE FINISH             "
	defb 23, 1, %01110010, 0, 2, "<>"
	defb 23, 4, %01110010, 0, 1, "E"
	defb 23, 13, %01110010, 0, 1, "F"
	defb 128
endp


P1ExchangeCard
proc
	local _FUMENU

	push hl
	push de
	push bc
	push af

	call SClick

	;	D=hand card to exchange
	ld hl, P1HANDDATA
	call VActivate
	ld a, (CURCARDIDX)
	ld b, a
	call VGetAt
	call VRemoveAt
	ld d, a

	;	Get the FU card to replace
	ld hl, _FUMENU
	call PPutStringTable
	ld bc, $0103
	call IInputNumber
	dec a
	ld b, a
	ld hl, P1FUPDATA
	call VActivate
	call VGetAt
	call VRemoveAt
	ld e, a

	call SClick

	;	Add hand card to FU
	ld a, d
	call VPush

	;	Add FU card to hand
	ld hl, P1HANDDATA
	call VActivate
	ld a, e
	call VPush

	call DKShowP1DownCards
	call DKShowP1Hand
	call P1SetCursor

	pop af
	pop bc
	pop de
	pop hl
	ret

_FUMENU
	defb 23, 0, %01110001, 0, 32, "CHOOSE FACE-UP CARD 1-3         ", 128
endp


P1FinishExchange
proc
	call SClick
	ret
endp


P1Turn
proc
	local _menu, _testrv, _MENUDATA, _P1MENU

	call P1Init
	call P1SetCursor

	ld hl, _P1MENU
	call PPutStringTable

_menu
	xor a
	ld (RETVAL), a

	ld hl, _MENUDATA
	call ITestMenu
	jp _menu

_testrv
	ld a, (RETVAL)
	or a
	jp z, _menu
	ret

_MENUDATA
	defb KEY5
	defw P1Left, _menu
	defb 0
	defb KEY8
	defw P1Right, _menu
	defb 0
	defb KEYC
	defw P1Clear, _menu
	defb 0
	defb KEYS
	defw P1Select, _menu
	defb 0
	defb KEYP
	defw P1Pickup, _testrv
	defb 0
	defb KEYD
	defw P1Discard, _testrv
	defb 0
	defb $80

_P1MENU
	defb 23, 0, %01110001, 0, 32, " <> CLEAR SELECT PICKUP DISCARD "
	defb 23, 1, %01110010, 0, 2, "<>"
	defb 23, 4, %01110010, 0, 1, "C"
	defb 23, 10, %01110010, 0, 1, "S"
	defb 23, 17, %01110010, 0, 1, "P"
	defb 23, 24, %01110010, 0, 1, "D"
	defb 128
endp


P1Left
proc
	local _wrap, _save

	call SClick
	call P1ResetCursor
	
	ld a, (CURCARDIDX)
	or a
	jp z, _wrap
	dec a
	jp _save

_wrap
	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	dec a

_save
	ld (CURCARDIDX), a

	call P1SetCursor

	ret
endp


P1Right
proc
	local _wrap, _save

	call SClick
	call P1ResetCursor

	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	ld b, a

	ld a, (CURCARDIDX)
	inc a
	cp b
	jp c, _save

_wrap
	xor a

_save
	ld (CURCARDIDX), a

	call P1SetCursor

	ret
endp


P1Clear
proc
	call SClick
	call P1Init
	call DKShowP1Hand
	call P1SetCursor
	ret
endp


P1ClearNoClick
proc
	call P1Init
	call DKShowP1Hand
	call P1SetCursor
	ret
endp


defb "break"
P1Select
proc
	local _valid, _ret, _invalid_select, _valid_select

	;	Ensure that discard would be valid
	ld hl, P1HANDDATA
	call VActivate
	ld a, (CURCARDIDX)
	ld b, a
	call VGetAt
	call DKValidateDiscard
	jp z, _invalid_select

	;	Set B=rank, C=card
	ld hl, P1HANDDATA
	call VActivate
	ld a, (CURCARDIDX)
	ld b, a
	call VGetAt
	ld c, a
	and %00001111
	ld b, a

	;	Max 4 cards may be selected
	ld hl, SELECTEDCARDS
	call VActivate
	call VGetCount
	cp 4
	jp nc, _invalid_select
	
	;	Test for no cards yet selected
	or a
	jp z, _valid

	;	Ensure only one rank is selected
	call VPeek
	and %00001111
	cp b
	jp nz, _invalid_select

	;	Ensure card not already selected
	ld hl, SELECTEDINDEXES
	call VActivate
	ld a, (CURCARDIDX)
	call VContains
	jp z, _valid_select

_valid
	call P1SetCursorAddress

	ld hl, (AFADDRESS)
	res 6, (hl)
	ld de, 32
	add hl, de
	res 6, (hl)

	ld hl, SELECTEDCARDS
	call VActivate
	ld a, c
	call VPush

	ld hl, SELECTEDINDEXES
	call VActivate
	ld a, (CURCARDIDX)
	call VPush

	ld a, 1
	ld (RETVAL), a

_valid_select
	call SClick
	jr _ret

_invalid_select
	call SBuzzer

_ret
	ret
endp


P1Pickup
proc
	local _valid, _ret

	ld hl, WASTEPILEDATA
	call VActivate
	call VGetCount	
	jp z, _invalid

	call SClick
	call P2OnP1Pickup

	ld hl, P1HANDDATA
	call VActivate
	ld hl, WASTEPILEDATA
	call VAppend

	ld hl, WASTEPILEDATA
	call VActivate
	call VInitialize

	call DKShowWastepile
	call P1ClearNoClick

	ld a, 1
	ld (RETVAL), a

	jr _ret

_invalid
	call SBuzzer

_ret
	ret
endp


P1Discard
proc
	local _ret, _loop, _nodeal, _invalid

	ld hl, SELECTEDCARDS
	call VActivate
	call VGetCount
	jp z, _invalid

	call SClick
	call P2OnP1Discard

	;	Add selected cards to the wastepile
	ld hl, WASTEPILEDATA
	call VActivate
	ld hl, SELECTEDCARDS
	call VAppend
	call DKShowWastepile

	;	Remove selected cards from the hand
	ld hl, VCompareReverse
	call VSetComparer
	ld hl, SELECTEDINDEXES
	call VActivate
	call VSort
	call VGetCount
	ld b, a
_loop
	push bc

	call VPop
	ld b, a
	ld hl, P1HANDDATA
	call VActivate
	call VRemoveAt

	ld hl, SELECTEDINDEXES
	call VActivate

	pop bc
	djnz _loop

	call P1Deal

	ld a, 1
	ld (RETVAL), a

	jr _ret

_invalid
	call SBuzzer

_ret
	ret
endp


P1Deal
proc
	local _choosefu, _getfdcard, _choosefd, _deal, _ret, _FUMENU, _FUMAX, _FDMENU, _FDMAX

	;	Get more cards if necessary
	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	cp 3
	jp nc, _ret

	;	If cards remain in the stockpile, deal
	ld hl, STOCKDATA
	call VActivate
	call VGetCount
	jp nz, _deal

	;	If the stock is empty and so is the hand, get a face-up/down card
	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	jp nz, _ret

	;	Show the empty hand
	call DKShowP1Hand

	ld hl, P1FUPDATA
	call VActivate
	call VGetCount
	jp z, _getfdcard

	;	If 1 face-up card remains take it
	cp 1
	jp nz, _choosefu
	call VPop
	call DKShowP1DownCards
	ld hl, P1HANDDATA
	call VActivate
	call VPush
	jp _ret

	;	Else ask the user to choose
_choosefu	
	push af
	add a, 48
	ld (_FUMAX), a
	pop af
	ld hl, _FUMENU
	call PPutStringTable

	push af
	ld a, 1
	ld b, a
	pop af
	ld c, a
	call IInputNumber
	dec a
	ld b, a

	ld hl, P1FUPDATA
	call VActivate
	call VGetAt
	call VRemoveAt
	call DKShowP1DownCards

	ld hl, P1HANDDATA
	call VActivate
	call VPush
	call P2OnP1FupSel
	call SClick
	jp _ret

_getfdcard
	ld hl, P1FDOWNDATA
	call VActivate
	call VGetCount
	jp z, _ret

	;	If 1 face-down card remains take it
	cp 1
	jp nz, _choosefd
	call VPop
	call DKShowP1DownCards
	ld hl, P1HANDDATA
	call VActivate
	call VPush
	jp _ret

_choosefd
	push af
	add a, 48
	ld (_FDMAX), a
	pop af
	ld hl, _FDMENU
	call PPutStringTable

	push af
	ld a, 1
	ld b, a
	pop af
	ld c, a
	call IInputNumber
	dec a
	ld b, a

	ld hl, P1FDOWNDATA
	call VActivate
	call VGetAt
	call VRemoveAt
	call DKShowP1DownCards

	ld hl, P1HANDDATA
	call VActivate
	call VPush
	call SClick
	jp _ret

_deal
	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	ld b, a
	ld a, 3
	sub b
	ld b, a
	ld de, P1HANDDATA
	call DKDeal
	call DKShowStockCards

_ret
	call P1ClearNoClick
	ret

_FUMENU
	defb 23, 0, %01110001, 0, 32, "CHOOSE FACE-UP CARD 1-"
_FUMAX
	defb 50
	defb "         ", 128
_FDMENU
	defb 23, 0, %01110001, 0, 32, "CHOOSE FACE-DOWN CARD 1-"
_FDMAX
	defb 50
	defb "       ", 128
endp


CURCARDIDX			defb 0
RETVAL				defb 0
SELECTEDCARDS
	MAXSZ			defb 4
	CURSZ			defb 0
	STACK			defs 4
	defb 0
SELECTEDINDEXES
	MAXIDXSZ		defb 4
	CURIDXSZ		defb 0
	IDXSTACK		defs 4
	defb 0


P1Init
proc
	ld hl, SELECTEDCARDS
	call VActivate
	call VInitialize
	
	ld hl, SELECTEDINDEXES
	call VActivate
	call VInitialize

	xor a
	ld (CURCARDIDX), a

	ret
endp


P1ResetCursor
proc
	push de
	push bc
	push af

	call P1SetCursorAddress

	ld hl, (AFADDRESS)
	res 7, (hl)
	ld de, 32
	add hl, de
	res 7, (hl)

	pop af
	pop bc
	pop de

	ret
endp


P1SetCursor
proc
	push de
	push bc
	push af

	call P1SetCursorAddress

	ld hl, (AFADDRESS)
	set 7, (hl)
	ld de, 32
	add hl, de
	set 7, (hl)

	pop af
	pop bc
	pop de

	ret
endp


;	Sets CURCOL, CURLINE
P1SetCursorAddress
proc
	local _line2, _ret

	push bc
	push af

	ld a, (CURCARDIDX)
	cp 26
	jp nc, _line2

	inc a
	ld c, a
	ld b, 18

	jp _ret

_line2
	sub 25
	ld c, a
	ld b, 20

_ret
	call PPrintAt
	pop af
	pop bc
	ret
endp