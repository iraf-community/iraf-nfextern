# AP4.H -- Definitions for pair alignment catalog.

define	AP4_DEF		"aceproto$ap4.h"

define	INDEXID		AP4ID_
define	AP4ID_N		0 # i
define	AP4ID_X		1 # r pix %.2f
define	AP4ID_Y		2 # r pix %.2f
define	AP4ID_P		3 # r deg %.1f
define	AP4ID_XH	4 # r "" %.2f
define	AP4ID_YH	5 # r "" %.2f
define	AP4ID_DP1	6 # r deg %.1f
define	AP4ID_DP2	7 # r deg %.1f
define	AP4ID_NA	8 # i
define	AP4ID_XA	9 # r pix %.2f
define	AP4ID_YA	10 # r pix %.2f
define	AP4ID_NB	11 # i
define	AP4ID_XB	12 # r pix %.2f
define	AP4ID_YB	13 # r pix %.2f
define	AP4ID_NAA	14 # i
define	AP4ID_NBA	15 # i
define	AP4ID_NAB	16 # i
define	AP4ID_NBB	17 # i

define	AP4_N		RECI($1,AP4ID_N)
define	AP4_X		RECR($1,AP4ID_X)
define	AP4_Y		RECR($1,AP4ID_Y)
define	AP4_P		RECR($1,AP4ID_P)
define	AP4_XH		RECR($1,AP4ID_XH)
define	AP4_YH		RECR($1,AP4ID_YH)
define	AP4_DP1		RECR($1,AP4ID_DP1)
define	AP4_DP2		RECR($1,AP4ID_DP2)
define	AP4_NA		RECI($1,AP4ID_NA)
define	AP4_XA		RECR($1,AP4ID_XA)
define	AP4_YA		RECR($1,AP4ID_YA)
define	AP4_NB		RECI($1,AP4ID_NB)
define	AP4_XB		RECR($1,AP4ID_XB)
define	AP4_YB		RECR($1,AP4ID_YB)
define	AP4_NAA		RECI($1,AP4ID_NAA)
define	AP4_NBA		RECI($1,AP4ID_NBA)
define	AP4_NAB		RECI($1,AP4ID_NAB)
define	AP4_NBB		RECI($1,AP4ID_NBB)


define	AP4_LEN		10
define	AP4_REC		($1+AP4_LEN*($2-1))
define	AP4_RECA	Memi[$1]
define	AP4_RECB	Memi[$1+1]
define	AP4_ID		Memr[P2R($1+2)]
define	AP4_XC		Memr[P2R($1+3)]
define	AP4_YC		Memr[P2R($1+4)]
define	AP4_PA		Memr[P2R($1+5)]
define	AP4_XH1		Memr[P2R($1+6)]
define	AP4_YH1		Memr[P2R($1+7)]
define	AP4_DPA1	Memr[P2R($1+8)]
define	AP4_DPA2	Memr[P2R($1+9)]
