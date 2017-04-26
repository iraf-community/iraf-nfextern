# CATMATCH.H -- Catalog information required by the task.
# The mapping from actual catalogs to these quantities is handled by ACECAT.

define	ID_RA		0 # d hr %11.7f
define	ID_DEC		2 # d deg %11.6f
define	ID_MREF		4 # r mag %.2f
define	ID_X		6 # d pixels %.2f
define	ID_Y		8 # d pixels %.2f
define	ID_MAG		10 # r magnitudes %15.7g
define  ID_A            11 # r pixels %.2f
define  ID_B            12 # r pixels %.2f
define	ID_FLAGS	13 # 8 "" ""
define	ID_PTR		17 # ii		/ Pointer/integer for internal use

define	ACM_RA		RECD($1,ID_RA)
define	ACM_DEC		RECD($1,ID_DEC)
define	ACM_MREF	RECR($1,ID_MREF)
define	ACM_X		RECD($1,ID_X)
define	ACM_Y		RECD($1,ID_Y)
define	ACM_MAG		RECR($1,ID_MAG)
define  ACM_A           RECR($1,ID_A)
define  ACM_B           RECR($1,ID_B)
define  ACM_FLAGS       RECT($1,ID_FLAGS)
define	ACM_PTR		RECI($1,ID_PTR)

define	ACM_BP		RECC($1,ID_FLAGS,4)
