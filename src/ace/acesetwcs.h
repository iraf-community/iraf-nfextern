# ACESETWCS -- Catalog information used by the task.

define	ID_RA		 0 # d hr %.2f		/ X world coordinate
define	ID_DEC		 2 # d deg %.2f		/ Y world coordinate
define	ID_X		 4 # r pixels %.2f	/ X aperture coordinate
define	ID_Y		 5 # r pixels %.2f	/ Y aperture coordinate

define	OBJ_RA		RECD($1,ID_RA)		# X world coordinate
define	OBJ_DEC		RECD($1,ID_DEC)		# Y world coordinate
define	OBJ_X		RECR($1,ID_X)		# X aperture coordinate
define	OBJ_Y		RECR($1,ID_Y)		# Y aperture coordinate
