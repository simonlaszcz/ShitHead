IF NOT DEFINED __MACROS_ASM
__MACROS_ASM DEFL 1

;~~~~~~~~~~~~~~~~
;	Memory macros
;~~~~~~~~~~~~~~~~

macro m_memcpy, target, source, count
	;	Copies [count] bytes from [source] to [target]
	;	Destroys HL

	ld de, target
	ld hl, source
	ld bc, count

	;	ldir automatically copies (hl) to (de) before incrementing hl and de and decrementing bc.
	;	This is repeated until bc is zero.
	ldir
endm


macro m_memset, target, byteval, count
	;	Write [count] occurrences of [byteval] starting at [target]
	;	Detroys HL,DE,BC

	;	Set (target) to [byteval]
	ld hl, target
	ld (hl), byteval

	;	Set de to [byteval+1]
	ld de, target
	inc de

	;	We need to set [count-1] as the first byte has already been set
	ld bc, count
	dec bc

	;	ldir automatically copies (hl) to (de) before incrementing hl and de and decrementing bc.
	;	This is repeated until bc is zero. Essentially (address+1) is set to (address) in a loop.
	ldir
endm

ENDIF