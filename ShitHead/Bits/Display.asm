;	Print a set of blind (back) cards at current DFADDRESS
;	[BYVAL IN] HL:Card stack
DPrintBlindCards
proc
	;	HL = Card Data

	local _blankloop
	local _displaycards
	local _displaycards1
	local _loop
	local _end
	local _STREMPTY

	push hl

	;	Blank previous cards, set initial print pos

	ld a, (hl)
	ld (S_POSN_LINE), a
	inc hl
	ld a, (hl)
	ld (S_POSN_COL), a

	ld b, 9
_blankloop
	push bc
	call SetDisplayAddress
	ld hl, T_BLANK
	call PrintTile
	pop bc

	;	Inc column
	ld a, (S_POSN_COL)
	inc a
	ld (S_POSN_COL), a

	djnz _blankloop
	pop hl

	;	Show current cards. Set initial print pos
	ld a, (hl)
	ld (S_POSN_LINE), a
	inc hl
	ld a, (hl)
	ld (S_POSN_COL), a
	inc hl

	ld a, (hl)
	or a
	jp nz, _displaycards

	;	No cards left. Display 'empty' message
	ld hl, _STREMPTY
	call PrintStringTable

	jp _end

_displaycards
	;	If STOCKCNT < 10 then show that many cards, otherwise just show 9 max
	cp 10
	jp nc, _displaycards1
	ld b, a
	jp _loop
_displaycards1
	ld b, 9
_loop
	push bc
	call SetDisplayAddress
	ld hl, T_CARDREVERSE
	call PrintTile
	pop bc

	;	Inc the column
	ld a, (S_POSN_COL)
	inc a
	ld (S_POSN_COL), a

	djnz _loop

_end
	ret

_STREMPTY
	;	String table data: Line, Column, Attribute, pflags, Length, String
	defb 4, 1, %00001111, 0, 8, "NO CARDS"
	defb 128
endp