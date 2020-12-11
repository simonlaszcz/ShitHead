PORT equ 254
ON	equ %00010000
OFF	equ %11101111


macro m_beep, off_count, on_count, loop_count
proc
	;	nb. A must contain the border color

	local _repeat, _next_off, _next_on

	ld b, loop_count
_repeat
	push bc

	;	Send 0s
	and OFF
	ld b, off_count
_next_off
	out (PORT), a
	djnz _next_off

	;	Send 1s
	or ON
	ld b, on_count
_next_on
	out (PORT), a
	djnz _next_on

	pop bc
	djnz _repeat
endp
endm


SClick
proc
	local _loop1, _loop2

	ld a, (BORDCR)

	m_beep 32, 32, 32

	ret
endp


SBuzzer
proc
	local _loop1, _loop2

	ld a, (BORDCR)

	m_beep 255, 255, 32

	ret
endp