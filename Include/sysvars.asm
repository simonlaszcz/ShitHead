IF NOT DEFINED __SYSVARS_ASM
__SYSVARS_ASM DEFL 1

;	Default Free Memory Blocks

LOMEM_MIN		equ 23990	;	Gives BASIC 256 bytes
LOMEM_LOC		equ 24768	;	Includes default BASIC workspace
LOMEM_END		equ 32767
HIMEM_LOC		equ 32768	;	Start of extra mempry in 48K model. Access to memory from this point is uncontended by the ULA and thus faster.
HIMEM_END		equ 65535	;	Don't forget the stack! It grows backwards from 65535

;	The entire display file
DISPFILE_LOC	equ 16384
DISPFILE_LEN	equ 6144
DISPFILE_END	equ 22527

;	The display file regions. R1 = Lines 0 to 7, R2 = 8 to 15, R3 = 16 to 24
DISPFILE_R1_LOC	equ DISPFILE_LOC
DISPFILE_R1_LEN	equ ( DISPFILE_LEN / 3 )
DISPFILE_R1_END	equ ( DISPFILE_R1_LOC + DISPFILE_R1_LEN )
DISPFILE_R2_LOC	equ ( DISPFILE_R1_END + 1 )
DISPFILE_R2_LEN	equ DISPFILE_R1_LEN
DISPFILE_R2_END	equ ( DISPFILE_R2_LOC + DISPFILE_R2_LEN )
DISPFILE_R3_LOC	equ ( DISPFILE_R2_END + 1 )
DISPFILE_R3_LEN	equ DISPFILE_R1_LEN
DISPFILE_R3_END	equ DISPFILE_END

;	The entire attribute file
ATTRFILE_LOC	equ 22528
ATTRFILE_LEN	equ 768
ATTRFILE_END	equ 23295

;	The attribute file regions
ATTRFILE_R1_LOC	equ ATTRFILE_LOC
ATTRFILE_R1_LEN	equ ( ATTRFILE_LEN / 3 )
ATTRFILE_R1_END equ ( ATTRFILE_R1_LOC + ATTRFILE_R1_LEN )
ATTRFILE_R2_LOC	equ ( ATTRFILE_R1_END + 1 )
ATTRFILE_R2_LEN	equ ATTRFILE_R1_LEN
ATTRFILE_R2_END equ ( ATTRFILE_R2_LOC + ATTRFILE_R2_LEN )
ATTRFILE_R3_LOC	equ ( ATTRFILE_R2_END + 1 )
ATTRFILE_R3_LEN	equ ATTRFILE_R1_LEN
ATTRFILE_R3_END equ ATTRFILE_END

;	The printer buffer
PRNTBUFF_LOC	equ 23296
PRNTBUFF_LEN	equ 256
PRNTBUFF_END	equ 23551

;	The system variables
SYSVARS_LOC		equ 23552
SYSVARS_LEN		equ 182
SYSVARS_END		equ 23733

;	The microdrive maps
MDMAPS_LOC		equ	23734

;	System Variable Addresses. ** denotes variable used in macros.asm
KSTATE			equ 23552
LAST_K			equ 23560	;	The last key pressed
REPDEL			equ 23561
REPPER			equ 23562
DEFADD			equ	23563
K_DATA			equ 23565
TVDATA			equ 23566
STRMS			equ 23568
CHARS			equ	23606	;	256 less than the address of the character set. (ASCII * 8) + (CHARS) = Character address
CHARS_DFLT		equ 15360
RASP			equ 23608
PIP				equ 23609
ERR_NR			equ 23610
FLAGS			equ 23611
TV_FLAG			equ 23612
ERR_SP			equ 23613
LIST_SP			equ 23615
MODE			equ 23617
NEWPPC			equ 23618
NSPPC			equ 23620
PPC				equ 23621
SUBPPC			equ 23623
BORDCR			equ 23624	;	Border colour. **
E_PPC			equ 23625
VARS			equ 23627
DEST			equ 23629
CHANS			equ 23631
CURCHL			equ 23633
PROG			equ 23635
NXTLIN			equ 23637
DATADD			equ 23639
E_LINE			equ 23641
K_CUR			equ 23643
CH_ADD			equ 23645
X_PTR			equ 23647
WORKSP			equ 23649
STKBOT			equ 23651
STKEND			equ 23653
BREG			equ 23655
MEM				equ 23656
FLAGS2			equ 23658
DF_SZ			equ 23659
S_TOP			equ 23660
OLDPPC			equ 23662
OSPCC			equ 23664
FLAGX			equ 23665
STRLEN			equ 23666
T_ADDR			equ 23668
SEED			equ 23670
FRAMES			equ 23672
UDG				equ 23675	;	Address of first UDG
COORDS			equ 23677	;	X coord of last plot, Y coord or last plot
COORDS_X		equ 23677
COORDS_Y		equ 23678
P_POSN			equ 23679
PR_CC			equ 23680
FILLER1			equ	23681
ECHO_E			equ 23682
DF_CC			equ 23684	;	Address in display file of print position. **
DFCCL			equ 23686
S_POSN			equ 23688	;	Print column (0-32), Print line (0-23). **
S_POSN_LINE		equ 23688	;	**
S_POSN_COL		equ 23689	;	**
SPOSNL			equ 23690	;	Used to store the address in attribute file of current print position.
SCR_CT			equ 23692
ATTR_P			equ 23693	;	Permanent attribute. Only used for cls **
MASK_P			equ 23694	;	Permanent attribute mask. When a bit is set, the bit is taken from the attr file, not ATTR_P
ATTR_T			equ 23695	;	Temporary attribute. Used when printing. **
MASK_T			equ 23696	;	Temporary attribute mask. **
P_FLAG			equ 23697	;	Print flags. Bit 1 controls overprinting. Bit 3 controls inverse video. Bit 5 = mask attribute (MASK_T/ATTR_T)
MEMBOT			equ 23698
RAMTOP			equ 23730
P_RAMT			equ 23732

ENDIF