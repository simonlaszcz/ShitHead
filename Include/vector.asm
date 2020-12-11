IF NOT DEFINED __VECTOR_ASM
__VECTOR_ASM DEFL 1

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Vector operations
;	~~~~~~~~~~~~~~~~~
;	The data structure can be treated as an array or vector
;
;	Data Definition:
;
;	VECTORDATA
;	MAXSIZE			byte
;	CURRENT_SIZE	byte
;	DATA			byte[ MAXSIZE ]
;	BUFFER			byte (Required for RemoveAt) = 0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;	Sets the active vector
;	[BYVAL IN] HL:vector data pointer
VActivate
proc
	push hl
	push af

	;	Store a ptr to the entire data block	
	ld (VDATAPTR), hl

	;	Cache the maximum size
	ld a, (hl)
	ld (MAXSIZE), a
	
	;	Store a ptr to the current size byte
	inc hl
	ld (CURSIZEPTR), hl

	;	Store a ptr to the vector
	inc hl
	ld (VECTORPTR), hl	

	pop af
	pop hl

	ret
endp


;	[OUT] A:count of cards in stack
VGetCount
proc
	push hl
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	or a
	pop hl
	ret
endp


;	The comparer routine is called when sorting. It should have the following signature:
;		[BYVAL IN] B:l-value
;		[BYVAL IN] C:r-value
;		[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
;	[BYVAL IN] HL:comparer routine address
VSetComparer
proc
	ld (COMPARERPTR), hl
	ret
endp


;	Default comparer
;	[BYVAL IN] B:l-value
;	[BYVAL IN] C:r-value
;	[BYREF OUT] A:z when B==C; <0 if B<C; >0 if B>C
VCompareReverse
proc
	push bc

	ld a, c
	sub b

	pop bc
	ret
endp


;	Initializes all elements to 0
;	All registers preserved
VInitialize
proc
	push af
	push bc
	push hl
	push de

	ld hl, (VDATAPTR)

	;	Get MAXSIZE
	ld a, (hl)

	;	We will initialize MAXSIZE bytes
	ld b, 0
	ld c, a

	;	Initialize the current size
	inc hl
	xor a
	ld (hl), a

	;	Propagate 0 to the rest of the vector
	ld d, h
	ld e, l
	inc de
	ldir

	pop de
	pop hl
	pop bc
	pop af

	ret
endp


;	Appends the specified vector to the active vector
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYVAL IN] HL:vector data pointer to append
VAppend
proc
	push hl
	push de
	push bc
	push af

	;	Set DE to next unused element in the active vector
	push hl
	call VSeekEnd
	ld d, h
	ld e, l
	pop hl

	;	Get the number of bytes to copy
	inc hl
	ld a, (hl)
	ld b, 0
	ld c, a

	;	Update the current size
	push hl
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	add a, c
	ld (hl), a
	pop hl

	;	Move to the start of the data
	inc hl

	;	Copy
	ldir

	pop af
	pop bc
	pop de
	pop hl

	ret
endp


;	Assigns the specified vector to the active vector
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYVAL IN] HL:vector data pointer to assign
VAssign
proc
	push hl
	push de
	push bc
	push af

	;	Set DE to the first element in the active vector
	push hl
	ld hl, (VECTORPTR)
	ld d, h
	ld e, l
	pop hl

	;	Get the number of bytes to copy
	inc hl
	ld a, (hl)
	ld b, 0
	ld c, a

	;	Set the current size
	push hl
	ld hl, (CURSIZEPTR)
	ld (hl), a
	pop hl

	;	Move to the start of the data
	inc hl

	;	Copy
	ldir

	pop af
	pop bc
	pop de
	pop hl

	ret
endp


;	Adds a byte to the active vector
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYVAL IN] A:new byte

VPush
proc
	push af
	push hl

	;	Store
	call VSeekEnd
	ld (hl), a

	;	Increment the size
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	inc a
	ld (hl), a

	pop hl
	pop af	

	ret
endp


;	Pops a byte from the active vector
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[OUT] A:popped byte
VPop
proc
	push hl

	;	Get last byte
	call VSeekLast
	ld a, (hl)

	push af

	;	Reset last byte
	xor a
	ld (hl), a

	;	Decrease size
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	dec a
	ld (hl), a

	pop af
	pop hl

	ret
endp


;	Peeks a byte from the active vector
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[OUT] A:peeked byte
VPeek
proc
	push hl

	;	Get last byte
	call VSeekLast
	ld a, (hl)

	pop hl

	ret
endp


;	Gets the byte at [index]
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYVAL IN] B:index
;	[OUT] A:value
VGetAt
proc
	push hl

	ld a, b
	call VSeek
	ld a, (hl)

	pop hl

	ret
endp


;	Removes the byte at [index]
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYVAL IN] B:index
VRemoveAt
proc
	local _reset, _ret

	push hl
	push de
	push bc
	push af

	;	Set C = the number of copies from n+1 to n we'll need
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	sub b
	dec a
	ld c, a

	;	Set hl[n]
	ld a, b
	call VSeek
	ld d, h
	ld e, l

	;	If c=0 then we're positioned at the end of the stack and simply need to set the byte to 0
	;	nb. Executing ldir when bc=0 would result in 65535 moves
	ld a, c
	or a
	jp z, _reset
	;	Abort if c is negative
	jp m, _ret

	;	Copy from n+1 to n
	inc hl
	ld b, 0
	ldir

	;	Reset last byte
_reset
	xor a
	ld (de), a

	;	Decrease the count
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	dec a
	ld (hl), a

_ret
	pop af
	pop bc
	pop de
	pop hl

	ret
endp


;	Sets the byte at [index]
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYVAL IN] B:index
;	[BYVAL IN] A:value
VSetAt
proc
	push hl

	push af
	ld a, b
	call VSeek
	pop af

	ld (hl), a

	pop hl

	ret
endp


;	Sets the byte at [index]
;	n.b. The value of MAXSIZE is *NOT* checked.
;	[BYREF IN] A:search value
;	[OUT] Z if found, NZ otherwise
VContains
proc
	local _empty_array, _ret

	push hl
	push de
	push bc

	ld d, a

	;	Get the maximum number of bytes to search
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	or a
	jr z, _empty_array

	ld b, 0
	ld c, a

	;	Start the search from here
	ld hl, (VECTORPTR)

	;	Search
	ld a, d
	cpir
	jr _ret

_empty_array
	or 1

_ret
	pop bc
	pop de
	pop hl

	ret
endp


;	Calls the comparer for each pair of bytes, swapping as necessary
VSort
proc
	local _whilesort, _foreach, _cmpnext, _ret

	push hl
	push de
	push bc
	push af

	;	Get the size of the array
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	or a
	;	The array is empty
	jp z, _ret

	dec a
	;	Abort if 0, ie the array is 1 element long
	jp z, _ret

	ld b, a

	;	While d=1
_whilesort
	push bc

	;	Set d=0
	ld d, 0

	;	Iterate from n[0]..n[m-1]
	ld ix, (VECTORPTR)
_foreach
	push bc

	ld b, (ix + 0)
	ld c, (ix + 1)

	;	CALL XXXX
	push ix
			defb $CD
COMPARERPTR	defw 0
	pop ix

	;	Test A: swap if b < c
	jp p, _cmpnext
	
	;	swap
	ld (ix + 0), c
	ld (ix + 1), b
	;	Set d=1
	ld d, 1
_cmpnext
	inc ix
	pop bc
	djnz _foreach

	pop bc
	;	If any elements were swapped, iterate through the vector again
	ld a, d
	or a
	jp nz, _whilesort

_ret
	pop af
	pop bc
	pop de
	pop hl
	ret
endp


;~~~~~~~~~~~~~~~~~~~
;	Data
;~~~~~~~~~~~~~~~~~~~


VDATAPTR		defw 0	;	Address of the active vector data
	MAXSIZE		defb 0
	CURSIZEPTR	defw 0
	VECTORPTR	defw 0

;~~~~~~~~~~~~~~~~~~~
;	Private routines
;~~~~~~~~~~~~~~~~~~~


;	[BYVAL IN] A:index
;	[OUT] HL:&VECTOR[index]
VSeek
proc
	push de

	ld d, 0
	ld e, a
	ld hl, (VECTORPTR)
	add hl, de

	pop de

	ret
endp


;	[OUT] HL:&VECTOR[CURRENT_SIZE]
VSeekLast
proc
	push af
	push de

	;	Get the current size
	ld hl, (CURSIZEPTR)
	ld a, (hl)
	dec a

	ld d, 0
	ld e, a

	ld hl, (VECTORPTR)
	add hl, de

	pop de
	pop af

	ret
endp


;	[OUT] HL:&VECTOR[CURRENT_SIZE+1]
VSeekEnd
proc
	push af
	push de

	;	Get the current size
	ld hl, (CURSIZEPTR)
	ld a, (hl)

	ld d, 0
	ld e, a

	ld hl, (VECTORPTR)
	add hl, de

	pop de
	pop af

	ret
endp

ENDIF