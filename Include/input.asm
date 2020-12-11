IF NOT DEFINED __INPUT_ASM
__INPUT_ASM DEFL 1

;~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Keyboard input routines
;~~~~~~~~~~~~~~~~~~~~~~~~~~


;	HHHK,KKKK where
;	HHH = half row 0-8 (CAPS-V=0;1-5=3;6-0=4;B-BREAK=7)
;	KKKKK = Key position. Bit 0 is the outside key; bit 4 the inner. e.g. CAPS=0,BREAK=0,V=4
KEY1			equ %01100001
KEY2			equ %01100010
KEY3			equ %01100100
KEY4			equ %01101000
KEY5			equ %01110000
KEY6			equ %10010000
KEY7			equ %10001000
KEY8			equ %10000100
KEY9			equ %10000010
KEY0			equ %10000001
KEYC			equ %00001000
KEYD			equ %00100100
KEYE			equ %01000100
KEYF			equ %00101000
KEYP			equ %10100001
KEYQ			equ %01000001
KEYS			equ %00100010
KEYT			equ %01010000
KEYENTER		equ %11000001


;	Wait for a key press
IWaitKey
proc
	;	wait until a key is pressed	

	local _inkey

	push af

	call IFlush

_inkey
	;	Reset the accumulator so that we read all address lines (all keyboard half rows)
	xor a
	;	Read the keyboard
	in a, (0xFE)
	;	Test for key press
	cpl
	and %00011111

	;	No key has been pressed
	jp z, _inkey

	pop af

	ret
endp


;	Flush the input buffer
IFlush
proc
	;	Wait 10/50ths second
	halt
	halt
	halt
	halt
	halt
	halt
	halt
	halt
	halt
	halt
	ret
endp


;	[BYVAL IN] D:Code of required key
;	[OUT] A: NZ if key pressed, Z otherwise
;	HHHK,KKKK where
;	HHH = half row 0-8 (CAPS-V=0;1-5=3;6-0=4;B-BREAK=7)
;	KKKKK = Key position. Bit 0 is the outside key; bit 4 the inner. e.g. CAPS=0,BREAK=0,V=4
ITestKey
proc
	local _shift

	push bc

	;	Compute the address line number
	ld a, d
	rlc a
	rlc a
	rlc a
	and %00000111

	;	Create the address bus high byte
	ld b, a
	ld a, 1
_shift
	rlc a
	djnz _shift
	cpl

	;	Read the data lines for the half row into A
	;	If a key is pressed its data bit will be 0 so cpl it
	in a, (0xFE)
	cpl
	and %00011111

	;	Save the data lines
	ld b, a
	;	Get the key position and mask off the half row
	ld a, d
	and %00011111
	;	Test the key press: Code & in
	and b

	pop bc

	ret
endp


;	Performs one pass through a menu data block 
;	If a key is pressed
;		the associated routine is executed
;		and either
;			a jump is made to the return address
;		or a code is returned in A with CF=0
;	Else the routine exits with CF=1
;
;	[BYVAL IN] HL:menu data
;	[OPTIONAL OUT] A: return code
;	MENU-DATA-DEF
;		KEYCODE					byte
;		ROUTINEADDRESS			word
;		RETURNADDRESS			word (maybe 0)
;		RETURNCODE				byte (assigned to A when RETURNADDRESS is 0)
;	$80
ITestMenu
proc
	local _test, _call, _a1, _a2, _skipdata, _returncode, _nextkey, _nopress

	push hl
	push de
	push bc
	push af

_test
	;	Test the keycode
	ld d, (hl)
	call ITestKey
	jp z, _skipdata

_call
	;	Load the call address
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	ld (_a1), bc

	;	Test for 0 address
	ld a, b
	or c
	jp z, _jp

	;	call XXXX
	push hl
	defb $CD
_a1	defw 0
	pop hl

_jp
	;	Load the return address
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	ld (_a2), bc

	;	Test for 0. If 0, return a code
	ld a, b
	or c
	jp z, _returncode

	;	Flush the input buffer
	call IFlush
	;	Restore the stack
	pop af
	pop bc
	pop de
	pop hl

	;	Return
	pop hl
	ld hl, (_a2)
	push hl
	ret
_a2 defw 0

_returncode
	;	Flush the input buffer
	call IFlush

	;	Get the return code
	pop af
	inc hl
	ld a, (hl)
	or a
	;	Restore the stack
	pop bc
	pop de
	pop hl

	ret
	
_skipdata
	;	Skip the call/return/code data
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl

_nextkey
	;	Test for end of data block
	inc hl
	ld a, (hl)
	cp $80
	;	Test next key if more data exists
	jp nz, _test

_nopress
	pop af
	pop bc
	pop de
	pop hl
	scf
	ret
endp


;	[BYVAL IN] B:min
;	[BYVAL IN] C:max
;	[OUT] A:number
IInputNumber
proc
	local _loop, _MENU

	push bc

	inc c

	ld hl, _MENU

_loop
	call ITestMenu
	jp c, _loop

	;	Test A>=B
	cp b
	jp c, _loop

	;	Test A<C
	cp c
	jp nc, _loop

	pop bc

	ret

_MENU
	defb KEY0, 0, 0, 0, 0, 0
	defb KEY1, 0, 0, 0, 0, 1
	defb KEY2, 0, 0, 0, 0, 2
	defb KEY3, 0, 0, 0, 0, 3
	defb KEY4, 0, 0, 0, 0, 4
	defb KEY5, 0, 0, 0, 0, 5
	defb KEY6, 0, 0, 0, 0, 6
	defb KEY7, 0, 0, 0, 0, 7
	defb KEY8, 0, 0, 0, 0, 8
	defb KEY9, 0, 0, 0, 0, 9
	defb $80
endp

ENDIF