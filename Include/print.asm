IF NOT DEFINED __PRINT_ASM
__PRINT_ASM DEFL 1

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Text printing routines
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


BLUE			equ 1
RED				equ 2
MAGENTA			equ 3
GREEN			equ 4
CYAN			equ 5
YELLOW			equ 6
WHITE			equ 7
BLACK			equ 0


;	Sets the next printing position
;	[BYVAL IN] BC:Line,Column (0 based)
PPrintAt
proc
	push af
	push bc

	ld a, b
	ld (PLINE), a
	ld a, c
	ld (PCOL), a

	call PSetDFAddress
	call PSetAFAddress

	pop bc
	pop af

	ret
endp


;	Advances the print position
PAdvance
proc
	;	Increment column, possibly line, wrapping if necessary
	;	Destroys AF

	local _newcolok, _newlineok, _end

	push af

	;	Increment the column
	ld a, (PCOL)
	inc a

	;	If col > 31 (If we have to carry (a<=31) there's no need to inc the line)
	cp 32
	jp c, _newcolok
	
	;	Set col = 0
	xor a
	ld (PCOL), a

	;	Increment the line
	ld a, (PLINE)
	inc a

	;	If line > 23
	cp 24
	jp c, _newlineok
	;	Set line = 0
	xor a

_newlineok
	ld (PLINE), a
	jp _end

_newcolok
	ld (PCOL), a

_end
	call PSetDFAddress
	call PSetAFAddress

	pop af

	ret
endp


;	Immediately changes the border colour
;	[BYVAL IN] A:border colour 0-7
PSetBorder
proc
	push af
	
	;	Mask of MIC and EAR bits
	and %00000111
	ld (BORDCR), a

	;	Output to port
	out (0xFE), a

	pop af

	ret
endp


;	Sets the next paper colour
;	[BYVAL IN] A:colour
PSetPaper
proc
	push bc
	push af

	;	Mask off extraneous bits and shift left
	and %00000111
	rlca
	rlca
	rlca
	ld b, a

	;	Add to ATTR and store
	ld a, (ATTR)
	and %11000111
	or b
	ld (ATTR), a

	pop af
	pop bc

	ret
endp


;	Sets the next ink colour
;	[BYVAL IN] A:colour
PSetInk
proc
	push bc
	push af

	;	Mask off extraneous bits and shift left
	and %00000111
	ld b, a

	;	Add to ATTR and store
	ld a, (ATTR)
	and %11111000
	or b
	ld (ATTR), a

	pop af
	pop bc

	ret
endp


;	Sets the print flags
;	[BYVAL IN] A:flags (0:over;2:inverse;4:masking)
PSetPrintFlags
proc
	ld (PRINTFLAGS), a
	ret
endp


;	Sets the current attribute mask
;	[BYVAL IN] A:mask
PSetMask
proc
	ld (MASK), a
	ret
endp


;	Sets the current attribute
;	[BYVAL IN] A:attr
PSetAttribute
proc
	ld (ATTR), a
	ret
endp


;	Clears the screen using ATTR
PClearScreen
proc
	push hl
	push de
	push bc
	push af

	;	Clear the DF

	ld hl, DISPFILE_LOC
	ld (hl), 0
	ld d, h
	ld e, l
	inc de
	ld bc, DISPFILE_LEN - 1
	ldir

	;	Clear the AF
	ld a, (ATTR)
	ld hl, ATTRFILE_LOC
	ld (hl), a
	ld d, h
	ld e, l
	inc de
	ld bc, ATTRFILE_LEN - 1
	ldir

	pop af
	pop bc
	pop de
	pop hl

	ret
endp


;	Clears a rectangular region with TLC at DFADDRESS
;	[BYVAL IN] BC:lines,columns
PClearRegion
proc
	call PClearDisplayRegion
	call PClearAttributeRegion
	ret
endp


;	Clears a rectangular display region with TLC at DFADDRESS
;	[BYVAL IN] BC:lines,columns
PClearDisplayRegion
proc
	local _foreachline, _foreachrow, _foreachcol, _nextcol, _endforeachcol, _nextrow
	local _endforeachrow, _nextline, _nextline1, _endforeachline
	
	push hl
	push de
	push bc
	push af

	;	Load DF address
	ld de, (DFADDRESS)

_foreachline
	;	Set the row to 0
	ld a, d
	and %11111000
	ld d, a

	push bc
	ld b, 8
_foreachrow
	;	Set E=line low byte
	ld a, e
	and %11100000
	ld e, a

	;	Set A=starting column
	push de
	ld de, (DFADDRESS)
	ld a, e
	and %00011111
	pop de

	;	Set E=line lb & starting column
	or e
	ld e, a

	push bc
	ld b, c
_foreachcol
	xor a
	ld (de), a
_nextcol
	dec b
	jp z, _endforeachcol
	;	Else If b>0 increment the DF column
	inc e
	jp _foreachcol
_endforeachcol
	pop bc

_nextrow
	dec b
	jp z, _endforeachrow
	;	Else if b>0 increment the DF row
	inc d
	jp _foreachrow
_endforeachrow
	pop bc
	;	If the loop ended, the previous inc d was invalid

_nextline
	dec b
	jp z, _endforeachline
	;	Else if b>0 Increment the line
	ld a, e
	add a, %00100000
	ld e, a
	jp nc, _nextline1
	ld a, d
	add a, %00001000
_nextline1
	jp _foreachline
_endforeachline

	pop af
	pop bc
	pop de
	pop hl
	ret
endp


;	Clears a rectangular attribute region with TLC at AFADDRESS
;	[BYVAL IN] BC:lines,columns
PClearAttributeRegion
proc
	local _afcls

	push hl
	push de
	push bc
	push af

	;	Clear the attribute region
	ld hl, (AFADDRESS)

	;	Get the current attribute
	ld a, (ATTR)

	;	Clear B attribute lines
_afcls
	push bc

	;	Initialize the current line
	push hl
	;	Set the first attribute and propogate it to the other columns
	ld (hl), a
	ld d, h
	ld e, l
	inc de
	;	Initialize C-1 columns
	dec bc
	ld b, 0
	;	Copy
	ldir
	pop hl

	;	Move to the next line
	ld de, 32
	add hl, de

	pop bc
	djnz _afcls

	pop af
	pop bc
	pop de
	pop hl
	ret
endp


;	Print a character at the current position
;	[BYVAL IN] A:char code
PPutChar
proc
	local _nomasking, _setattr, _printloop, _testoverp, _draw

	push hl
	push de
	push bc
	push af

	;	Set the attribute
	push af	

	;	Get the AF address
	ld hl, (AFADDRESS)

	;	Get the print flags
	ld a, (PRINTFLAGS)
	;	Test for attribute masking
	and %00010000
	jp z, _nomasking

	;	Set D=ATTR & ~MASK
	ld a, (MASK)
	cpl
	ld d, a
	ld a, (ATTR)
	and d
	ld d, a

	;	Mask the current attribute with D
	ld a, (hl)
	or d
	jp _setattr

_nomasking
	ld a, (ATTR)

_setattr
	ld (hl), a
	pop af

	;	Multiply the code by 8 and add it to CHARS to give the character data address
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	ld de, (CHARS)
	add hl, de

	;	Get the DF address
	ld de, (DFADDRESS)

	;	Copy the character (from) HL to the DF (DE)
	ld b, 8
_printloop
	ld c, (hl)

	;	Test for inverse video
	ld a, (PRINTFLAGS)
	and %00000100
	jp z, _testoverp

	;	Reverse paper and ink data
	ld a, c
	cpl
	ld c, a

_testoverp
	;	Test for overprinting
	ld a, (PRINTFLAGS)
	and %00000001
	jp z, _draw

	;	Overprint new on existing (de) char
	ld a, (de)
	and c
	ld c, a

_draw
	ld a, c
	ld (de), a

	;	Increment the DF row (8 rows per line)
	inc d
	;	Move to the next byte of character data
	inc hl
	;	Draw the next row
	djnz _printloop

	pop af
	pop bc
	pop de
	pop hl

	ret
endp


;	Print a string at the current position
;	[BYREF IN] HL:string data (1st byte conatins the length)
PPutString
proc
	local _ploop

	push bc
	push af

	;	Get the length
	ld b, (hl)
_ploop
	;	Get the first/next character
	inc hl
	ld a, (hl)

	call PPutChar
	call PAdvance

	djnz _ploop

	pop af
	pop bc

	ret
endp


;	[BYVAL IN] HL:string table
;	DEF:
;		STRING-TABLE
;			STRING-DATA-ENTRY
;				LINE		byte
;				COLUMN		byte
;				ATTR		byte
;				PRINTFLAGS	byte
;				STRLENGTH	byte
;				STRINGDATA	byte[]
;			...
;		$80
PPutStringTable
proc
	local _ploop

	push hl
	push bc
	push af

_ploop
	;	Set line (B) and column (C) for this string
	ld a, (hl)
	ld b, a
	inc hl
	ld a, (hl)
	ld c, a
	call PPrintAt

	;	Set ATTR
	inc hl
	ld a, (hl)
	ld (ATTR), a

	;	Set PRINTFLAGS
	inc hl
	ld a, (hl)
	ld (PRINTFLAGS), a

	;	Print the string
	inc hl
	call PPutString

	;	Test for the end of the data block ($80)
	inc hl
	ld a, (hl)
	cp $80
	jp c, _ploop

	pop af
	pop bc
	pop hl

	ret
endp


;	HL=tile address
;	Print a tile with TLC at (DF_CC). (SPOSNL) should also be valid
;	[BYVAL IN] HL:tile data
;
;	TILEDATA-DEF
;		LINES			byte
;		COLUMNS			byte
;		DFDATA			byte[]
;		AFDATA			byte[]

PPutTile
proc
	local _foreachline, _endforeachline, _foreachrow, _endforeachrow, _foreachcol, _endforeachcol, _noinverse
	local _draw, _nextcol, _nextrow, _nextline, _nextline1

	push hl
	push de
	push bc
	push af

	;	Load the size of the tile (lines,cols)
	ld b, (hl)
	inc hl
	ld c, (hl)

	;	Save bc for the attributes
	push bc

	;	Load DF address
	ld de, (DFADDRESS)

	;	Foreach line
_foreachline

	;	Set the row to 0
	ld a, d
	and %11111000
	ld d, a

	;	Foreach row in the line	
	push bc
	ld b, 8
_foreachrow

	;	Set the column to original value while preserving the line
	ld a, e
	and %11100000
	ld e, a
	push de
	ld de, (DFADDRESS)
	ld a, e
	and %00011111
	pop de
	or e
	ld e, a

	;	Foreach col in the tile
	push bc
	ld b, c
_foreachcol
	;	Print the row
	push bc

	;	Move to the next tile byte
	inc hl

	;	Copy the new row
	ld c, (hl)

	;	Test for inverse
	ld a, (PRINTFLAGS)
	and 4
	jp z, _noinverse

	;	Do inverse on C
	ld a, c
	cpl
	ld c, a

_noinverse
	;	Test for overprinting
	ld a, (PRINTFLAGS)
	and 1
	jp z, _draw

	;	Overprint new on existing (de) char
	ld a, (de)
	and c
	ld c, a

_draw
	ld a, c
	ld (de), a
	pop bc

_nextcol
	dec b
	jp z, _endforeachcol
	;	Else If b>0 increment the DF column
	inc e
	jp _foreachcol
_endforeachcol
	pop bc

_nextrow
	dec b
	jp z, _endforeachrow
	;	Else if b>0 increment the DF row
	inc d
	jp _foreachrow
_endforeachrow
	pop bc
	;	If the loop ended, the previous inc d was invalid

_nextline
	dec b
	jp z, _endforeachline
	;	Else if b>0 Increment the line
	ld a, e
	add a, %00100000
	ld e, a
	jp nc, _nextline1
	ld a, d
	add a, %00001000
_nextline1
	jp _foreachline
_endforeachline
	pop bc

	;	Print the attributes

	local _foreachattrline

	inc hl

	;	AF address
	ld de, (AFADDRESS)
	;	B already correct
_foreachattrline
	push bc

	;	Set bc = #cols
	xor a
	ld b, a

	push de
	push bc
	ldir
	pop bc
	pop de

	;	Add 32 to DE to move to next line
	ld a, e
	add a, %00100000
	ld e, a
	ld a, d
	adc a, 0
	ld d, a

	pop bc
	djnz _foreachattrline

	pop af
	pop bc
	pop de
	pop hl
	ret
endp


;	Data


PLINE		defb 0	;	Line
PCOL		defb 0	;	Column
DFADDRESS	defw 0	;	Display file address
AFADDRESS	defw 0	;	Attribute file address
PRINTFLAGS	defb 0	;	Bit 0: use overprinting, Bit 2: use reverse video, Bit 5: use attribute masking
ATTR		defb 0	;	Current attribute
MASK		defb 0	;	Current mask


;	Private routines


PSetDFAddress
proc
	;	Sets next DF printing address
	;	A display file address is composed as such:
	;	high, low
	;	010LLRRR,LLLCCCCC

	push hl
	push af

	;	Construct the high byte
	ld a, (PLINE)
	and %00011000
	add a, %01000000
	ld h, a

	;	Construct the low byte
	ld a, (PLINE)
	rrca
	rrca
	rrca
	and %11100000
	ld l, a
	ld a, (PCOL)
	add a, l
	ld l, a

	;	Save to DF_CC
	ld (DFADDRESS), hl

	pop af
	pop hl

	ret
endp


PSetAFAddress
proc
	;	Sets next AF printing address
	;	Address = ATTRFILE_LOC + ( ( LINE * 32 ) + COL )

	push hl
	push de
	push af

	ld a, (PLINE)
	ld h, 0
	ld l, a

	;	Multiply by 32
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	;	Add the column
	ld d, 0
	ld a, (PCOL)
	ld e, a
	add hl, de

	;	Add the attr file base address
	ld de, ATTRFILE_LOC
	add hl, de

	;	Store
	ld (AFADDRESS), hl

	pop af
	pop de
	pop hl

	ret
endp

ENDIF