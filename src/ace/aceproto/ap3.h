# AP3.H -- Defintions for single pair of pair or pair catalog.

define	AP3_DEF		"aceproto$ap3.h"

define	INDEXID		AP3ID_
define	AP3ID_N		0 # i
define	AP3ID_X		1 # r "" %.2f
define	AP3ID_Y		2 # r "" %.2f
define	AP3ID_M		3 # r "" %.2f
define	AP3ID_U		4 # r
define	AP3ID_P		5 # r deg %.1f
define	AP3ID_XH	6 # r "" %.2f
define	AP3ID_YH	7 # r "" %.2f
define	AP3ID_SEP	8 # r "" %.2f
define	AP3ID_RATE	9 # r "" %.2f
define	AP3ID_DM	10 # r mag %.2f
define	AP3ID_DE	11 # r "" %.3f
define	AP3ID_DW	12 # r "" %.2f
define	AP3ID_DP	13 # r deg %.1f
define	AP3ID_DU	14 # r
define	AP3ID_NA	15 # i
define	AP3ID_XA	16 # r "" %.2f
define	AP3ID_YA	17 # r "" %.2f
define	AP3ID_NB	18 # i
define	AP3ID_XB	19 # r "" %.2f
define	AP3ID_YB	20 # r "" %.2f

define	AP3_N		RECI($1,AP3ID_N)
define	AP3_X		RECR($1,AP3ID_X)
define	AP3_Y		RECR($1,AP3ID_Y)
define	AP3_M		RECR($1,AP3ID_M)
define	AP3_U		RECR($1,AP3ID_U)
define	AP3_P		RECR($1,AP3ID_P)
define	AP3_XH		RECR($1,AP3ID_XH)
define	AP3_YH		RECR($1,AP3ID_YH)
define	AP3_SEP		RECR($1,AP3ID_SEP)
define	AP3_RATE	RECR($1,AP3ID_RATE)
define	AP3_DM		RECR($1,AP3ID_DM)
define	AP3_DE		RECR($1,AP3ID_DE)
define	AP3_DW		RECR($1,AP3ID_DW)
define	AP3_DP		RECR($1,AP3ID_DP)
define	AP3_DU		RECR($1,AP3ID_DU)
define	AP3_NA		RECI($1,AP3ID_NA)
define	AP3_XA		RECR($1,AP3ID_XA)
define	AP3_YA		RECR($1,AP3ID_YA)
define	AP3_NB		RECI($1,AP3ID_NB)
define	AP3_XB		RECR($1,AP3ID_XB)
define	AP3_YB		RECR($1,AP3ID_YB)

