# This file defines the object parameters.

define  ID_RA             0 # r "hr" "%11.2h"
define  ID_DEC            1 # r "deg" "%11.1h"
define  ID_MAG            2 # r "" "%4.1f"

# These are optional application macros.

define	OBJ_RA		RECR($1,ID_RA)
define	OBJ_DEC		RECR($1,ID_DEC)
define	OBJ_MAG		RECR($1,ID_MAG)
