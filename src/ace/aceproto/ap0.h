# AP0.H -- Input catalog data used by this task.

define	AP0_DEF		"aceproto$ap0.h"

define	INDEXID		AP0ID_
define	AP0ID_I		0 # i			/ Image ID
define	AP0ID_N		1 # i			/ Source ID
define	AP0ID_X		2 # r "" %.2f		/ Source X (X, XI, etc.)
define	AP0ID_Y		3 # r "" %.2f		/ Source Y (Y, YI, etc.)
define	AP0ID_M		4 # r mag %.2f		/ Source magnitude
define	AP0ID_A		5 # r "" %.2f		/ Source major axis width
define	AP0ID_B		6 # r "" %.2f		/ Source minor axis width
define	AP0ID_E		7 # r "" %.3f		/ Source ellipticity
define	AP0ID_P		8 # r deg %.1f		/ Source position angle
define	AP0ID_U		9 # r			/ User field (i.e. time)
define	AP0ID_S		10 # r "" %.1f		/ Source significance
define	AP0ID_MJD	12 # d mjd %.6f		/ MJD time stamp
define	AP0ID_EXP	14 # r sec %.1f		/ Exposure time

define	AP0_I		RECI($1,AP0ID_I)
define	AP0_N		RECI($1,AP0ID_N)
define	AP0_X		RECR($1,AP0ID_X)
define	AP0_Y		RECR($1,AP0ID_Y)
define	AP0_M		RECR($1,AP0ID_M)
define	AP0_A		RECR($1,AP0ID_A)
define	AP0_B		RECR($1,AP0ID_B)
define	AP0_E		RECR($1,AP0ID_E)
define	AP0_P		RECR($1,AP0ID_P)
define	AP0_U		RECR($1,AP0ID_U)
define	AP0_S		RECR($1,AP0ID_S)
define	AP0_MJD		RECD($1,AP0ID_MJD)
define	AP0_EXP		RECR($1,AP0ID_EXP)
