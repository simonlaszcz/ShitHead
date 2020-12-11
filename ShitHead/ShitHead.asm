;	TARGET: Sinclair (Z80)
;	ASSEMBLER: PASMO

include "..\include\sysvars.asm"
include "..\include\macros.asm"

FACEUP_CHARS	equ ( FACEUP_A - 8 )
HAND_CHARS		equ ( HAND_SPACE )
SUIT_CHARS		equ ( SUITS_SPACE )

	org HIMEM_LOC

proc
	call InitCharSets
	call MenuScreen
endp


InitCharSets
proc
	;	Initialize hand chars
	m_memcpy HAND_A, 15880, 8
	m_memcpy HAND_2_9, 15760, 64
	m_memcpy HAND_J, 15952, 8
	m_memcpy HAND_Q, 16008, 8
	m_memcpy HAND_K, 15960, 8

	ret
endp


MenuScreen
proc
	local _init, _showmenu, _showdifficulty, _runmenu
	local _MENUSTRINGS, _MENUDATA

_init
	ld a, BLACK
	call PSetBorder
	ld a, %00000100
	call PSetAttribute
	call PClearScreen

	;	Draw the logo
	m_memcpy DISPFILE_LOC, SH_LOGO, SH_LOGO_LEN
	m_memcpy ATTRFILE_LOC, SH_LOGO_ATTRS, SH_LOGO_ATTRS_LEN
	
_showmenu
	ld hl, _MENUSTRINGS
	call PPutStringTable

_runmenu
	ld hl, _MENUDATA
	call ITestMenu
	jp	_runmenu

_MENUSTRINGS
		defb 12, 8, GREEN, 0, 16,"1.  Instructions"
		defb 13, 8, GREEN, 0, 8, "2.  Play"
		defb 19, 6, YELLOW, 0, 18, "2007  Simon Laszcz"
		defb 128
_MENUDATA
		defb KEY1
		defw ShowInstructions, _init
		defb 0
		defb KEY2
		defw PlayGame, _init
		defb 0
		defb 128
endp


ShowInstructions
proc
	ld a, BLACK
	call PSetBorder
	ld a, %00000100
	call PSetAttribute

	;	Page 1
	call PClearScreen
	ld hl, INSTR_S1
	call PPutStringTable
	call IWaitKey

	;	Page 2
	call PClearScreen
	ld hl, INSTR_S2
	call PPutStringTable
	call IWaitKey

	;	Page 3
	call PClearScreen
	ld hl, INSTR_S3
	call PPutStringTable
	call IWaitKey

	ret
endp


PlayGame
proc
	local _human_first, _cpu_first, _p1_go, _p2_go, _p1_proc, _p2_proc, _ret

	ld a, GREEN
	call PSetBorder
	ld a, %00100111
	call PSetAttribute
	call PClearScreen

	call RNDSeed
	call DKInit
	call P2InitGame

	call DKShowStockCards
	call DKShowWastepile
	call DKShowP1DownCards
	call DKShowP1Hand
	call DKShowP2DownCards
	call DKShowP2Hand

	call P2ExchangeCards
	call DKShowP2DownCards
	call DKShowP2Hand

	call P1ExchangeCards

	; NZ CPU, Z HUMAN
	call DecideFirstPlayer
	jp nz, _cpu_first
_human_first
	ld hl, HumanTurn
	ld (_p1_proc), hl
	ld hl, CPUTurn
	ld (_p2_proc), hl
	jp _p1_go
_cpu_first
	ld hl, CPUTurn
	ld (_p1_proc), hl
	ld hl, HumanTurn
	ld (_p2_proc), hl

_p1_go
	;	call xxxx
defb $CD
_p1_proc
defw 0
	jp nz, _ret

_p2_go
	;	call xxxx
defb $CD
_p2_proc
defw 0
	jp nz, _ret
	jp _p1_go
	
_ret
	ret
endp


;	On exit, NZ if P1 has won
HumanTurn
proc
	local _p1go, _p1win, _p2go, _P1AGAIN

_p1go
	call P1Turn
	call TestP1Win
	jp z, _p1win
	call DKCheckClear
	jp z, _p2go
	call P2OnClear
	ld hl, _P1AGAIN
	call ShowMsg
	jp _p1go

_p1win
	xor a
	call ShowWinningMessage
	or 1
	jp _ret

_p2go
	xor a

_ret
	ret

_P1AGAIN
	defb 23, 0, %01110001, 0, 32, "YOU GET ANOTHER GO              ", 128
endp


;	On exit, NZ if P2 has won
CPUTurn
proc
	local _p2loop, _p2win, _p1go, _ret, _P2MSG, _P2AGAIN

	ld hl, _P2MSG
	call ShowMsg

_p2loop
	call P2Turn
	call TestP2Win
	jp z, _p2win
	call DKCheckClear
	jp z, _p1go
	call P2OnClear
	ld hl, _P2AGAIN
	call ShowMsg
	jp _p2loop

_p2win
	or 1
	call ShowWinningMessage
	jp _ret

_p1go
	xor a

_ret
	ret

_P2MSG
	defb 23, 0, %01110001, 0, 32, "CPU'S TURN                      ", 128
_P2AGAIN
	defb 23, 0, %01110001, 0, 32, "CPU GETS ANOTHER GO             ", 128
endp


; NZ CPU, Z HUMAN
DecideFirstPlayer
proc
	local _cpu, _ret

	push hl
	push bc

	ld hl, DKCompareReverse
	call VSetComparer

	;	Get the first card for each player
	ld b, 0

	ld hl, P1HANDDATA
	call VActivate
	call VSort
	call VGetAt
	and %00001111
	ld c, a

	ld hl, P2HANDDATA
	call VActivate
	call VSort
	call VGetAt
	and %00001111

	;	If C<A Then human else cpu
	cp c
	jp c, _cpu
	xor a
	jp _ret

_cpu
	ld hl, _CPU
	call ShowMsg
	or 1

_ret
	call DKSortP1Hand
	pop bc
	pop hl
	ret

_CPU
	defb 23, 0, %01110001, 0, 32, "THE CPU WILL GO FIRST           ", 128
endp


;	Z if win
TestP1Win
proc
	ld hl, P1FDOWNDATA
	call VActivate
	call VGetCount
	ld b, a

	ld hl, P1HANDDATA
	call VActivate
	call VGetCount
	add a, b
	ret
endp


TestP2Win
proc
	ld hl, P2FDOWNDATA
	call VActivate
	call VGetCount
	ld b, a

	ld hl, P2HANDDATA
	call VActivate
	call VGetCount
	add a, b
	ret
endp


ShowMsg
proc
	call PPutStringTable
	call Pause
	ret
endp


Pause
proc
	local _loop

	push bc

	ld b, 49
_loop
	halt
	djnz _loop

	pop bc

	ret
endp


;	NZ CPU, Z HUMAN
ShowWinningMessage
proc
	local _CPU_WIN, _YOU_WIN, _WINNING_MESSAGE, _ATTRS, _ATTRS_END, _ATTRS_LEN, _ATTRS_START
	local _cpu_won, _draw

_ATTRS_START equ (255 + ATTRFILE_LOC)

	push hl
	push de
	push bc
	push af

	jp nz, _cpu_won
	m_memcpy _WHO_WON, _YOU_WIN, 23
	jp _draw

_cpu_won
	m_memcpy _WHO_WON, _CPU_WIN, 23

_draw
	call Pause
	ld a, GREEN
	call PSetBorder
	ld a, %00100111
	call PSetAttribute
	call PClearScreen

	ld hl, _WINNING_MESSAGE
	call PPutStringTable
	m_memcpy _ATTRS_START, _ATTRS, _ATTRS_LEN

	call IWaitKey

	pop af
	pop bc
	pop de
	pop hl
	ret

_CPU_WIN
	defb 10, 6, %01110001, 0, 18, "    SHIT HEAD!    "
_YOU_WIN
	defb 10, 6, %01110001, 0, 18, "     YOU WON!     "
_WINNING_MESSAGE
	defb 08, 6, %01110001, 0, 18, "                  "
	defb 09, 6, %01110001, 0, 18, "                  "
_WHO_WON
	defb 10, 6, %01110001, 0, 18, "                  "
	defb 11, 6, %01110001, 0, 18, "                  "
	defb 12, 6, %01110001, 0, 18, "                  "
	defb 128
_ATTRS
	;	blue on yellow default
	; r/w 10111010 = 186
	; w/r 10010111 = 151
	defb 36, 36, 36, 36, 36, 36, 36, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 36, 36, 36, 36, 36, 36, 36
	defb 36, 36, 36, 36, 36, 36, 36, 151, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 186, 36, 36, 36, 36, 36, 36, 36
	defb 36, 36, 36, 36, 36, 36, 36, 186, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 151, 36, 36, 36, 36, 36, 36, 36
	defb 36, 36, 36, 36, 36, 36, 36, 151, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 186, 36, 36, 36, 36, 36, 36, 36
	defb 36, 36, 36, 36, 36, 36, 36, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 186, 151, 36, 36, 36, 36, 36, 36, 36
_ATTRS_END
_ATTRS_LEN equ (_ATTRS_END - _ATTRS)
endp


include "..\include\input.asm"
include "..\include\print.asm"
include "..\include\vector.asm"
include "..\include\random.asm"
include "cards.asm"
include "p1turn.asm"
include "p2turn.asm"
include "p2ai.asm"
include "sounds.asm"
include "resources\loadscreen.asm"
include "resources\instructions.asm"
include "resources\tiles.asm"
include "resources\udg.asm"