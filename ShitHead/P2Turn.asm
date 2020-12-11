MEMORY_FACTOR equ 25


P2InitGame
proc
	push hl
	push bc
	push af

	;	Set P1 data sizes
	ld a, MEMORY_FACTOR
	ld (P2P1HAND), a
	ld (P2WASTEPILE), a
	ld (P2MAXMEMSIZE), a

	;	Init P1 data stacks

	ld hl, P2P1HAND
	call VActivate
	call VInitialize

	ld hl, P2WASTEPILE
	call VActivate
	call VInitialize

	pop af
	pop bc
	pop hl
	ret
endp


P2ExchangeCards
proc
	local _MSG, _TEMPSTACK, _loop1, _loop2

	push hl
	push bc
	push af

	ld hl, _MSG
	call ShowMsg

	;	Create new stack. Add FU and hand cards. Sort. 
	ld hl, _TEMPSTACK
	call VActivate
	call VInitialize
	ld hl, P2FUPDATA
	call VAssign
	ld hl, P2HANDDATA
	call VAppend

	;	Sort
	ld hl, COLEXCHANGE
	ld (CURCOLSET), hl
	ld hl, P2Compare
	call VSetComparer
	call VSort

	;	Init stacks
	ld hl, P2FUPDATA
	call VActivate
	call VInitialize
	ld hl, P2HANDDATA
	call VActivate
	call VInitialize

	;	Place highest 3 cards in FU
	ld b, 3
_loop1
	push bc
	
	ld b, 0
	ld hl, _TEMPSTACK
	call VActivate
	call VGetAt
	call VRemoveAt
	ld hl, P2FUPDATA
	call VActivate
	call VPush

	pop bc
	djnz _loop1

	;	Place lowest 3 cards in hand
	ld b, 3
_loop2
	push bc
	
	ld b, 0
	ld hl, _TEMPSTACK
	call VActivate
	call VGetAt
	call VRemoveAt
	ld hl, P2HANDDATA
	call VActivate
	call VPush

	pop bc
	djnz _loop2

	pop af
	pop bc
	pop hl
	ret

_TEMPSTACK
	defb 6, 0
	defs 7
_MSG
	defb 23, 0, %01110001, 0, 32, "CPU IS EXCHANGING CARDS         ", 128
endp


P2Turn
proc
	local _pickup, _discard, _ret

	push hl
	push de
	push bc
	push af

	call P2InitHand
	call P2Select

	ld a, (P2SICURIDXSZ)
	or a
	jp nz, _discard

_pickup
	call P2Pickup
	jp _ret

_discard
	call P2Discard

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp


P2SELECTEDCARDS
	defb 4, 0
	defs 4
	defb 0
P2SELECTEDINDEXES
	P2SIMAXIDXSZ		defb 4
	P2SICURIDXSZ		defb 0
	P2SIIDXSTACK		defs 4
	defb 0
P2FREQUENCIES	;	Indexed by rank. v[n]=f
	defb 14
P2FREQSZ
	defb 14		;	Always 14 for ranks 1..13 thus v[0] is never used
	defs 14
	defb 0
P2FREQORDER		;	Descending freq order v[n]=rank
	defb 52, 0
	defs 52
	defb 0


;	Card collation sets
CURCOLSET	defw COLSTANDARD
;			A,	2,	3,	4,	5,	6,	7,	8,	9,	T,	J,	Q,	K
COLSTANDARD
	;	Biased to discarding low cards
	defb	12,	11,	1,	2,	3,	4,	5,	6,	7,	13,	8,	9,	10
COLBLOCK
	;	Biased to forcing a pickup with highest possible card
	defb	1,	12,	11,	10,	9,	8,	2,	7,	6,	13,	5,	4,	3
COLMINBLOCK
	;	Biased to forcing a pickup with lowest possible card
	defb	7,	12,	11,	10,	9,	8,	4,	6,	5,	13,	1,	2,	3
COLEXCHANGE
	;	Used when exchanging cards
	defb	1,	2,	13,	12,	11,	10,	7,	9,	8,	3,	4,	5,	6


;	P1 card fuzzy stats
P2MAXMEMSIZE	defb 0	; max size of P2P1HAND and P2WASTEPILE
P2P1HAND
	defb 52, 0
	defs 52
	defb 0
P2WASTEPILE
	defb 52, 0
	defs 52
	defb 0


P2InitHand
proc
	;	Standard sort the hand

	ld hl, COLSTANDARD
	ld (CURCOLSET), hl
	ld hl, P2Compare
	call VSetComparer
	ld hl, P2HANDDATA
	call VActivate
	call VSort

	;	Analyze the hand

	ld hl, P2FREQUENCIES
	call VActivate
	call VInitialize
	ld a, 14
	ld (P2FREQSZ), a

	ld hl, P2FREQORDER
	call VActivate
	call VInitialize
	ld hl, P2HANDDATA
	call VAssign

	call P2AnalyzeFreq
	call P2AnalyzeP1

	;	Init other stacks

	ld hl, P2SELECTEDCARDS
	call VActivate
	call VInitialize

	ld hl, P2SELECTEDINDEXES
	call VActivate
	call VInitialize

	ret
endp


;	[BYVAL IN] B:l-value
;	[BYVAL IN] C:r-value
;	[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
P2Compare
proc
	;	Sort cards ascending, A high, suit irrelevant
	;	VCompare will sort descending
	push hl
	push de
	push bc

	ld hl, (CURCOLSET)

	ld a, b
	call P2CardSub
	ld b, a

	ld a, c
	call P2CardSub
	sub b

	pop bc
	pop de
	pop hl
	ret
endp


;	[BYVAL IN] B:l-value
;	[BYVAL IN] C:r-value
;	[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
P2CompareReverse
proc
	;	Sort cards descending

	push hl
	push de
	push bc

	ld hl, (CURCOLSET)

	ld a, c
	call P2CardSub
	ld c, a

	ld a, b
	call P2CardSub
	sub c

	pop bc
	pop de
	pop hl
	ret
endp


;	Substitutes A with the appropriate value from specified table
;	[BYVAL IN] HL:pointer to 13 element switch table
;	[BYREF IN] A :value
P2CardSub
proc
	push hl

	;	a=rank-1
	and %00001111
	dec a

	ld d, 0
	ld e, a
	add hl, de

	ld a, (hl)

	pop hl
	ret
endp


P2AnalyzeFreq
proc
	local _IDX, _loop, _ret

	;	Set _IDX=0
	xor a
	ld (_IDX), a

	;	Set b=count
	ld hl, P2HANDDATA
	call VActivate
	call VGetCount
	jp z, _ret

	ld b, a
_loop
	push bc

	;	Set b=_IDX++
	ld a, (_IDX)
	ld b, a
	inc a
	ld (_IDX), a

	;	A=hand[b]
	ld hl, P2HANDDATA
	call VActivate
	call VGetAt

	;	b=rank
	and %00001111
	ld b, a

	;	++freq[b]
	ld hl, P2FREQUENCIES
	call VActivate
	call VGetAt
	inc a
	call VSetAt

	pop bc
	djnz _loop

	;	Sort the frequencies
	ld hl, P2CompareFreq
	call VSetComparer
	ld hl, P2FREQORDER
	call VActivate
	call VSort

_ret
	ret

_IDX defb 0
endp


;	[BYVAL IN] B:l-value
;	[BYVAL IN] C:r-value
;	[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
P2CompareFreq
proc
	local _b, _ret

	;	Sort descending freq order
	push hl
	push bc

	;	_b=count of rankof b
	ld a, b
	and %00001111
	ld b, a
	ld hl, P2FREQUENCIES
	call VActivate
	call VGetAt
	ld (_b), a

	;	c=count of rankof c
	ld a, c
	and %00001111
	ld b, a
	call VGetAt
	ld c, a

	;	Subtract c from b
	ld a, (_b)
	cp c

_ret
	ld hl, P2FREQORDER
	call VActivate
	pop bc
	pop hl
	ret

_b defb 0
endp


P2AnalyzeP1
proc
	push hl

	ld hl, COLSTANDARD
	ld (CURCOLSET), hl
	ld hl, P2CompareReverse
	call VSetComparer

	ld hl, P2P1HAND
	call VActivate
	call VSort

	ld hl, P2WASTEPILE
	call VActivate
	call VSort

	pop hl
	ret
endp


P2Select
proc
	local _ret, _high_block_condition, _min_block_condition

	push hl
	push de
	push bc
	push af

	call P2CanWinWithThisHand
	jp nz, _default

	call P2IsHighBlockCondition
	jp nz, _high_block_condition

	call P2IsMinBlockCondition
	jp nz, _min_block_condition

_default
	call P2ClearFourOfAKind
	jp nz, _ret
	call P2StandardDiscard
	jp _ret

_high_block_condition
	call P2BlockHigh
	jp nz, _ret
	call P2BlockWithSeven
	jp nz, _ret
	call P2BlockLow
	jp nz, _ret
	call P2StandardDiscard
	jp _ret

_min_block_condition
	call P2BlockWithSeven
	jp nz, _ret
	call P2BlockLow
	jp nz, _ret
	call P2StandardDiscard

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp


P2CanWinWithThisHand
proc
	local _loop, _zero_count, _no, _ret

	push hl
	push de
	push bc

	;	CPU can't win this hand if face up/down cards exist

	ld hl, P2FUPDATA
	call VActivate
	call VGetCount
	ld b, a

	ld hl, P2FDOWNDATA
	call VActivate
	call VGetCount
	add a, b
	jp nz, _no

	;	Sum (C) the number of ranks in CPU's hand

	ld c, 0
	ld b, KING
	ld hl, P2FREQUENCIES
	call VActivate
_loop
	call VGetAt
	jr z, _zero_count
	inc c
_zero_count
	djnz _loop
	
	ld a, 1
	cp c
	jp c, _no

	;	All cards held are of the same rank. Test whether it's valid

	ld hl, P2HANDDATA
	call VActivate
	call VPeek
	call DKValidateDiscard
	jp z, _no

	or 1
	jr _ret

_no
	xor a

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2IsMinBlockCondition
proc
	local _ret, _no_block

	push hl
	push de
	push bc

	;	Try to force P1 to pickup if there are >7 cards in the WP

	ld hl, WASTEPILEDATA
	call VActivate
	call VGetCount
	cp 8
	jp c, _no_block

	or 1
	jr _ret

_no_block
	xor a

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2IsHighBlockCondition
proc
	local _ret, _block, _no_block

	push hl
	push de
	push bc

	;	High block if P1 has 0 face down cards and <3 hand cards

	ld hl, P1FDOWNDATA
	call VActivate
	call VGetCount
	jp nz, _no_block

	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	cp 2
	jp nc, _no_block

	or 1
	jr _ret

_no_block
	xor a

_ret
	pop bc
	pop de
	pop hl
	ret
endp


P2GetLowestValidRank
proc
	local _loop, _found, _IDX

	;	Loop through P2 hand until a valid discard is found

	xor a
	ld (_IDX), a

	ld hl, P2HANDDATA
	call VActivate
	call VGetCount
	ret z

	ld b, a
_loop
	push bc

	;	b = (_IDX)++
	ld a, (_IDX)
	ld b, a
	inc a
	ld (_IDX), a
	
	ld hl, P2HANDDATA
	call VActivate
	call VGetAt
	ld d, a
	call DKValidateDiscard	
	jp nz, _found

	pop bc
	djnz _loop

	;	No valid card found. A=0
	xor a
	ret

_found
	;	Card found. A=card
	pop bc
	ld a, d
	ret

_IDX defb 0
endp


P2Pickup
proc
	local _MSGBAR

	ld hl, _MSGBAR
	call ShowMsg

	ld hl, WASTEPILEDATA
	call VActivate
	call VGetCount	
	ret z

	call P2OnP2Pickup

	ld hl, P2HANDDATA
	call VActivate
	ld hl, WASTEPILEDATA
	call VAppend

	ld hl, WASTEPILEDATA
	call VActivate
	call VInitialize

	call DKShowWastepile
	call DKShowP2Hand

	ret

_MSGBAR
	defb 23, 0, %01110001, 0, 32, "CPU CANNOT DISCARD              ", 128
endp


P2Discard
proc
	local _ret, _loop, _MSGBAR, _COUNT

	ld hl, P2SELECTEDCARDS
	call VActivate
	call VGetCount
	jp z, _ret
	add a, 48
	ld (_COUNT), a

	call P2OnP1Discard

	ld hl, _MSGBAR
	call ShowMsg

	;	Add selected cards to the wastepile
	ld hl, WASTEPILEDATA
	call VActivate
	ld hl, P2SELECTEDCARDS
	call VAppend
	call DKShowWastepile

	;	Remove selected cards from the hand
	ld hl, VCompareReverse
	call VSetComparer
	ld hl, P2SELECTEDINDEXES
	call VActivate
	call VSort
	call VGetCount
	ld b, a
_loop
	push bc

	call VPop
	ld b, a
	ld hl, P2HANDDATA
	call VActivate
	call VRemoveAt

	ld hl, P2SELECTEDINDEXES
	call VActivate

	pop bc
	djnz _loop

	call P2Deal

_ret
	ret

_MSGBAR
	defb 23, 0, %01110001, 0, 32
	defb "CPU DISCARDS "
_COUNT
	defb 32
	defb "                  ", 128		 
endp


P2Deal
proc
	local _choosefu, _getfdcard, _choosefd, _deal, _ret
	local _MSG1, _MSG2, _MSG3, _CNT1

	ld hl, 0
	ld (_MSG), hl

	;	Get more cards if necessary
	ld hl, P2HANDDATA
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
	ld hl, P2HANDDATA
	call VActivate
	call VGetCount
	jp nz, _ret

	;	Show the empty hand
	call DKShowP2Hand

	ld hl, P2FUPDATA
	call VActivate
	call VGetCount
	jp z, _getfdcard

	ld hl, _MSG3
	ld (_MSG), hl

	ld b, 0
	ld hl, P2FUPDATA
	call VActivate
	call VGetAt
	call VRemoveAt
	call DKShowP2DownCards

	ld hl, P2HANDDATA
	call VActivate
	call VPush
	jp _ret

_getfdcard
	ld hl, P2FDOWNDATA
	call VActivate
	call VGetCount
	jp z, _ret

	ld hl, _MSG2
	ld (_MSG), hl

	ld b, 0
	ld hl, P2FDOWNDATA
	call VActivate
	call VGetAt
	call VRemoveAt
	call DKShowP2DownCards

	ld hl, P2HANDDATA
	call VActivate
	call VPush
	jp _ret

_deal
	ld hl, P2HANDDATA
	call VActivate
	call VGetCount
	ld b, a
	ld a, 3
	sub b
	ld b, a
	ld de, P2HANDDATA
	call DKDeal
	call DKShowStockCards

	add a, 48
	ld (_CNT1), a
	ld hl, _MSG1
	ld (_MSG), hl

_ret
	ld hl, DKCompare
	call VSetComparer
	ld hl, P2HANDDATA
	call VActivate
	call VSort
	call DKShowP2Hand

	ld hl, (_MSG)
	ld a, h
	or l
	ret z
	call ShowMsg
	ret

_MSG
	defw 0
_MSG1
	defb 23, 0, %01110001, 0, 32
	defb "CPU WAS DEALT "
_CNT1
	defb 32, "                 ", 128
_MSG2
	defb 23, 0, %01110001, 0, 32, "CPU TOOK A FACE-DOWN CARD       ", 128
_MSG3
	defb 23, 0, %01110001, 0, 32, "CPU TOOK A FACE-UP CARD         ", 128
endp


;	[BYVAL IN] A: face up/down card count
;	[OUT] B:randomly selected index 0..2
;P2Rnd
;proc
;	local _zret, _rndret
;
;	;	Set B=index to remove (0..A-1)
;	push hl
;	push af
;
;	;	If A=0..1 then B=0
;	or a
;	jp z, _zret
;	cp 1
;	jp z, _zret
;
;	;	A>1
;	;	Resulting index should be 0 based
;	;	B=0..1 or 0..2
;	dec a
;	or 1
;	ld b, a
;
;	;	Set HL=next random number
;	call RND16Next
;	;	A=L (0.255)
;	ld a, l
;	;	Ignore unrequired bits
;	and b
;	;	Return b
;	ld b, a
;	jp _rndret
;
;_zret
;	ld b, 0
;
;_rndret
;	pop af
;	pop hl
;	ret
;endp


;	Add discards to memorized view of the WASTEPILE
;	[BYVAL IN] HL:discards
P2OnP1Discard
proc
	local _ret, _loop, _next, _notfound

	push hl
	push de
	push bc
	push af

	;	Add to P2WASTEPILE
	ex de, hl
	ld hl, P2WASTEPILE
	;	DE=discards
	;	HL=P2WASTEPILE
	call P2Memorize

	;	Foreach card in P2P1HAND
	;		Test whether in discards
	;			If in discards, remove

	ld hl, P2P1HAND
	;	DE=discards
	;	HL=P2P1HAND
	call VActivate
	call VGetCount
	jp z, _ret

	ld b, a
_loop
	push bc

	;	B=loopcount-1=index	
	dec b
	;	DE=discards
	;	HL=P2P1HAND
	;	A=P2P1HAND[B]
	call VGetAt

	ex de, hl
	;	HL=discards
	;	DE=P2P1HAND
	call VActivate
	;	Contains A?
	call VContains
	jp nz, _notfound

	;	Remove P2P1Hand[b]
	ex de, hl
	;	DE=discards
	;	HL=P2P1HAND
	call VActivate
	call VRemoveAt
	jp _next

_notfound
	ex de, hl
	;	DE=discards
	;	HL=P2P1HAND
	call VActivate

_next
	pop bc
	djnz _loop

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp


;	Add discards to memorized view of the WASTEPILE
;	[BYVAL IN] HL:discards
P2OnP2Discard
proc
	local _ret

	;	Add to P2WASTEPILE
	push hl
	push de

	ex de, hl
	ld hl, P2WASTEPILE
	call P2Memorize

_ret
	pop de
	pop hl
	ret
endp


;	No parameters
P2OnClear
proc
	push hl
	ld hl, P2WASTEPILE
	call VActivate
	call VInitialize
	pop hl
	ret
endp


;	No parameters
P2OnP1Pickup
proc
	push hl
	push de
	ld de, P2WASTEPILE
	ld hl, P2P1HAND
	call P2Memorize
	call P2OnClear
	pop de
	pop hl
	ret
endp


;	No parameters
P2OnP2Pickup
proc
	call P2OnClear
	ret
endp


;	Add pickup to memorized view of the P1HAND
;	[BYVAL IN] A:card
P2OnP1FupSel
proc
	local _ret, _P2P1FUPDAT, _SEL

	;	Add to P2P1HAND
	push hl
	push de
	push af

	ld (_SEL), a
	ld de, _P2P1FUPDAT
	ld hl, P2P1HAND
	call P2Memorize

_ret
	pop af
	pop de
	pop hl
	ret

_P2P1FUPDAT
	defb 1, 1
_SEL
	defb 0
	defb 0
endp


;	[BYVAL IN] DE:Source stack
;	[BYVAL IN] HL:Target stack
P2Memorize
proc
	local _ret, _remove, _append

	push hl
	push de
	push bc
	push af

	;	C=source stack size
	ex de, hl			;	HL=Source
	call VActivate
	call VGetCount
	ld c, a
	ex de, hl			;	HL=Target

	;	A=space left in target stack
	call VActivate
	call VGetCount
	ld b, a
	ld a, (P2MAXMEMSIZE)
	sub b

	;	A=source stack size - space left = spaces needed to be removed
	ld b, a
	ld a, c
	sub b
	jp m, _append
	jp z, _append

	;	make space by removing v[0] A times
	call VActivate
	ld b, a
_remove
	push bc
	ld b, 0
	call VRemoveAt
	pop bc
	djnz _remove

_append
	;	Memorize
	ex de, hl		;	HL=Source
	call VAppend

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp