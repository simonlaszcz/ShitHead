IF NOT DEFINED __RANDOM_ASM
__RANDOM_ASM DEFL 1


RNDSeed
proc
	push hl
	push de
	push af

	;	Set (RANDOM) to the 2 least significant bytes of FRAMES
	ld hl, FRAMES
	inc hl

	ld a, (hl)
	ld d, a
	inc hl
	ld a, (hl)
	ld e, a

	ld (RANDOM), de

	pop af
	pop de
	pop hl
	ret
endp


;	[OUT] HL=16 bit random number. Also saved in (RANDOM)
RND16Next
proc
	local _calculate, _ret

	push de
	push af

	;	ld de, dddd
	defb $11
RANDOM
	defw 0

_calculate
	ld	a, d
	ld	h, e
	ld	l, 253
	or	a
	sbc	hl, de
	sbc	a, 0
	sbc	hl, de
	ld	d, 0
	sbc	a, d
	ld	e, a
	sbc	hl, de
	jr	nc, _ret
	inc	hl

_ret
	ld (RANDOM), hl

	pop af
	pop de
	ret	
endp

ENDIF