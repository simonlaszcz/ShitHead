;	All routines follow the pattern:
;	All registers destroyed
;	On exit, A=NZ if cards selected


P2BlockWithSeven
proc
	local _ret, _picture_found

	push hl
	push de
	push bc

	;	Abort if we don't hold a seven
	ld hl, P2FREQUENCIES
	call VActivate
	ld b, SEVEN
	call VGetAt
	or a
	jp z, _ret

	ld hl, WASTEPILEDATA
	call VActivate

	;	Abort if the wastepile is empty
	call VGetCount
	or a
	jp z, _ret

	;	Abort unless a picture card is atop the wastepile
	call VPeek
	cp JACK
	jp z, _picture_found
	cp QUEEN
	jp z, _picture_found
	cp KING
	jp z, _picture_found

	;	None found
	xor a
	jp _ret

_picture_found
	ld a, SEVEN
	call P2SelectOneOfRank
	or 1

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2BlockLow
proc
	local _ret

	push hl
	push de
	push bc

	ld hl, P2Compare
	call VSetComparer

	ld hl, P2HANDDATA
	call VActivate

	ld hl, COLMINBLOCK
	ld (CURCOLSET), hl
	call VSort

	;	Get the highest possible discard to block
	call P2GetLowestValidRank
	or a
	jp z, _ret

	call P2SelectOneOfRank
	or 1

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2BlockHigh
proc
	local _ret

	push hl
	push de
	push bc

	ld hl, P2Compare
	call VSetComparer

	ld hl, P2HANDDATA
	call VActivate

	ld hl, COLBLOCK
	ld (CURCOLSET), hl
	call VSort

	;	Get the highest possible discard to block
	call P2GetLowestValidRank
	or a
	jp z, _ret

	call P2SelectOneOfRank
	or 1

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2StandardDiscard
proc
	local _ret, _retok, _retfail
	local _select_all_of_rank, _select_one_of_rank

	push hl
	push de
	push bc

	ld hl, P2Compare
	call VSetComparer

	ld hl, P2HANDDATA
	call VActivate

	ld hl, COLSTANDARD
	ld (CURCOLSET), hl
	call VSort

	call P2GetLowestValidRank
	or a
	jp z, _retfail

	;	SET B=A
	and %00001111
	ld b, a

	cp SEVEN
	jp z, _select_one_of_rank
	cp TEN
	jp z, _select_one_of_rank
	cp ACE
	jp z, _select_one_of_rank
	cp TWO
	jp z, _select_one_of_rank

	;	Otherwise, 
	;		if P1 holds a card of this rank play one
	;		else play all

	ld hl, P2P1HAND
	call VActivate

	or HEARTS
	call VContains
	jp z, _select_one_of_rank

	ld a, b
	or DIAMONDS
	call VContains
	jp z, _select_one_of_rank

	ld a, b
	or CLUBS
	call VContains
	jp z, _select_one_of_rank

	ld a, b
	or SPADES
	call VContains
	jp z, _select_one_of_rank

_select_all_of_rank
	ld a, b
	call P2SelectAllOfRank
	jp _retok

_select_one_of_rank
	ld a, b
	call P2SelectOneOfRank

_retok
	or 1
	jr _ret

_retfail
	xor a

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2ClearFourOfAKind
proc
	local _finished_counting, _clear_with_higher_card, _test_next
	local _retfail, _retok, _ret

	push hl
	push de
	push bc

	ld d, 0

	;	Count the number of cards atop the wp with the same rank.
	;	Assumption: maximum of 3

	;	Test whether the wp is empty
	ld hl, WASTEPILEDATA
	call VActivate
	call VGetCount
	jp z, _clear_with_higher_card


	;	B=wp count - 1
	dec a
	ld b, a
	;	E=count of cards with same rank atop wp.
	ld e, 0


	;	D=rankof(WP[max])
	call VGetAt
	and %00001111
	ld d, a
	;	E=count of cards with same rank atop wp. 
	inc e
	;	If B is 0 then stop the count
	ld a, b
	or a
	jp z, _finished_counting


	;	A=rankof(WP[max-1])
	dec b
	call VGetAt
	and %00001111
	;	If rankof(A)=rankof(D), inc counter else stop the count
	cp d
	jp nz, _finished_counting
	inc e
	;	If B is 0 then stop the count
	ld a, b
	or a
	jp z, _finished_counting


	;	A=rankof(WP[max-2])
	dec b
	call VGetAt
	and %00001111
	;	If rankof(A)=rankof(D), inc counter else stop the count
	cp d
	jp nz, _finished_counting
	inc e


_finished_counting
	;	E=count of cards with same rank atop wp. 
	;	D=rank
	;	See if we can make 4 of the top card
	ld hl, P2FREQUENCIES
	call VActivate

	ld b, d
	call VGetAt
	add a, e
	cp 4
	;	We cant make 4 therefore try to clear with a higher card
	jp nz, _clear_with_higher_card

	;	Select all cards
	ld a, d
	call P2SelectAllOfRank
	jp _retok


_clear_with_higher_card
	ld hl, P2FREQUENCIES
	call VActivate

_test_next
	;	D=rank + 1
	inc d
	;	Test whether D>King
	cp KING
	jp m, _retfail

	;	Get the count of the number of cards held of this rank
	ld b, d
	call VGetAt
	cp 4
	jp c, _test_next


	;	We have 4 of this card. Validate it
	ld a, d
	call DKValidateDiscard
	jp z, _test_next

	
	;	Validated OK
	call P2SelectAllOfRank
	jp _retok


_retfail
	xor a
	jp _ret
_retok
	or 1
_ret
	pop bc
	pop de
	pop hl
	ret
endp


;	A=card
P2SelectAllOfRank
proc
	local _loop, _next, _IDX

	push af

	;	d = rank
	and %00001111
	ld d, a

	xor a
	ld (_IDX), a

	ld hl, P2HANDDATA
	call VActivate
	call VGetCount

	ld b, a
_loop
	push bc

	;	b = _IDX
	ld a, (_IDX)
	ld b, a

	ld hl, P2HANDDATA
	call VActivate
	call VGetAt
	ld e, a
	and %00001111
	cp d
	jp nz, _next

	;	d=rank, e=card, b=index
	ld hl, P2SELECTEDCARDS
	call VActivate
	ld a, e
	call VPush

	ld hl, P2SELECTEDINDEXES
	call VActivate
	ld a, b
	call VPush

_next
	;	++_IDX
	ld a, (_IDX)
	inc a
	ld (_IDX), a

	pop bc
	djnz _loop

	pop af
	ret

_IDX	defb 0
endp


;	A=card
P2SelectOneOfRank
proc
	local _loop, _next, _IDX, _found, _ret

	push af

	;	d = rank
	and %00001111
	ld d, a

	xor a
	ld (_IDX), a

	ld hl, P2HANDDATA
	call VActivate
	call VGetCount

	ld b, a
_loop
	push bc

	;	b = _IDX
	ld a, (_IDX)
	ld b, a

	ld hl, P2HANDDATA
	call VActivate
	call VGetAt
	ld e, a
	and %00001111
	cp d
	jp nz, _next

_found
	;	d=rank, e=card, b=index
	ld hl, P2SELECTEDCARDS
	call VActivate
	ld a, e
	call VPush

	ld hl, P2SELECTEDINDEXES
	call VActivate
	ld a, b
	call VPush

	pop bc
	jp _ret

_next
	;	++_IDX
	ld a, (_IDX)
	inc a
	ld (_IDX), a

	pop bc
	djnz _loop

_ret
	pop af
	ret

_IDX	defb 0
endp