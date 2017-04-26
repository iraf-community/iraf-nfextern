# AP1.H -- Definitions for single source catalog.

define	AP1_DEF		"aceproto$ap1.h"

define	INDEXID		AP1ID_
define	AP1ID_I		0 # i
define	AP1ID_N		1 # i
define	AP1ID_X		2 # r pix %.2f
define	AP1ID_Y		3 # r pix %.2f
define	AP1ID_M		4 # r mag %.2f
define	AP1ID_W		5 # r "" %.2f
define	AP1ID_E		6 # r "" %.3f
define	AP1ID_P		7 # r deg %.1f
define	AP1ID_U		8 # r

define	AP1_I		RECI($1,AP1ID_I)
define	AP1_N		RECI($1,AP1ID_N)
define	AP1_X		RECR($1,AP1ID_X)
define	AP1_Y		RECR($1,AP1ID_Y)
define	AP1_M		RECR($1,AP1ID_M)
define	AP1_W		RECR($1,AP1ID_W)
define	AP1_E		RECR($1,AP1ID_E)
define	AP1_P		RECR($1,AP1ID_P)
define	AP1_U		RECR($1,AP1ID_U)
