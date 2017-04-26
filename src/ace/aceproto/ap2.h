# AP2.H -- Defintions for pair catalog.

define	AP2_DEF		"aceproto$ap2.h"

define	INDEXID		AP2ID_
define	AP2ID_N		0 # i
define	AP2ID_X		1 # r "" %.2f
define	AP2ID_Y		2 # r "" %.2f
define	AP2ID_M		3 # r "" %.2f
define	AP2ID_U		4 # r
define	AP2ID_P		5 # r deg %.1f
define	AP2ID_XH	6 # r "" %.2f
define	AP2ID_YH	7 # r "" %.2f
define	AP2ID_SEP	8 # r "" %.2f
define	AP2ID_RATE	9 # r "" %.2f
define	AP2ID_DM	10 # r mag %.2f
define	AP2ID_DE	11 # r "" %.3f
define	AP2ID_DW	12 # r "" %.2f
define	AP2ID_DP	13 # r deg %.1f
define	AP2ID_DU	14 # r
define	AP2ID_NA	15 # i
define	AP2ID_XA	16 # r "" %.2f
define	AP2ID_YA	17 # r "" %.2f
define	AP2ID_NB	18 # i
define	AP2ID_XB	19 # r "" %.2f
define	AP2ID_YB	20 # r "" %.2f

define	AP2_N		RECI($1,AP2ID_N)
define	AP2_X		RECR($1,AP2ID_X)
define	AP2_Y		RECR($1,AP2ID_Y)
define	AP2_M		RECR($1,AP2ID_M)
define	AP2_U		RECR($1,AP2ID_U)
define	AP2_P		RECR($1,AP2ID_P)
define	AP2_XH		RECR($1,AP2ID_XH)
define	AP2_YH		RECR($1,AP2ID_YH)
define	AP2_SEP		RECR($1,AP2ID_SEP)
define	AP2_RATE	RECR($1,AP2ID_RATE)
define	AP2_DM		RECR($1,AP2ID_DM)
define	AP2_DE		RECR($1,AP2ID_DE)
define	AP2_DW		RECR($1,AP2ID_DW)
define	AP2_DP		RECR($1,AP2ID_DP)
define	AP2_DU		RECR($1,AP2ID_DU)
define	AP2_NA		RECI($1,AP2ID_NA)
define	AP2_XA		RECR($1,AP2ID_XA)
define	AP2_YA		RECR($1,AP2ID_YA)
define	AP2_NB		RECI($1,AP2ID_NB)
define	AP2_XB		RECR($1,AP2ID_XB)
define	AP2_YB		RECR($1,AP2ID_YB)

define	AP2_LEN		17
define	AP2_REC		($1+AP2_LEN*($2-1))
define	AP2_RECA	Memi[$1]
define	AP2_RECB	Memi[$1+1]
define	AP2_ID		Memr[P2R($1+2)]
define	AP2_XC		Memr[P2R($1+3)]
define	AP2_YC		Memr[P2R($1+4)]
define	AP2_MAV		Memr[P2R($1+5)]
define	AP2_UAV		Memr[P2R($1+6)]
define	AP2_PA		Memr[P2R($1+7)]
define	AP2_XH1		Memr[P2R($1+8)]
define	AP2_YH1		Memr[P2R($1+9)]
define	AP2_SEP1	Memr[P2R($1+10)]
define	AP2_RATE1	Memr[P2R($1+11)]
define	AP2_DM1		Memr[P2R($1+12)]
define	AP2_DE1		Memr[P2R($1+13)]
define	AP2_DW1		Memr[P2R($1+14)]
define	AP2_DP1		Memr[P2R($1+15)]
define	AP2_DU1		Memr[P2R($1+16)]
