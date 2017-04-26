define	NUMSTART		11	# First object number

# Mask Flags.
define	MASK_DNUM	017777777B	# Mask number
define	MASK_NUM	000777777B	# Mask number
define	MASK_GRW	001000000B	# Grow pixel
define	MASK_SPLIT	002000000B	# Split flag
define	MASK_BNDRY	004000000B	# Boundary flag
define	MASK_BPFLAG	010000000B	# Bad pixel flag
define	MASK_BP		020000000B	# Bad pixel
define	MASK_DARK	040000000B	# Dark flag

define	MSETFLAG	ori($1,$2)
define	MUNSETFLAG	andi($1,noti($2))

define	MDNUM		(andi($1,MASK_DNUM))
define	MNUM		(andi($1,MASK_NUM))
define	MNOTGRW		(andi($1,MASK_GRW)==0)
define	MGRW		(andi($1,MASK_GRW)!=0)
define	MNOTBP		(andi($1,MASK_BP)==0)
define	MBP		(andi($1,MASK_BP)!=0)
define	MNOTBPFLAG	(andi($1,MASK_BPFLAG)==0)
define	MBPFLAG		(andi($1,MASK_BPFLAG)!=0)
define	MNOTBNDRY	(andi($1,MASK_BNDRY)==0)
define	MBNDRY		(andi($1,MASK_BNDRY)!=0)
define	MNOTSPLIT	(andi($1,MASK_SPLIT)==0)
define	MSPLIT		(andi($1,MASK_SPLIT)!=0)
define	MNOTDARK	(andi($1,MASK_DARK)==0)
define	MDARK		(andi($1,MASK_DARK)!=0)

# Output object masks types.
define	OM_TYPES		"|boolean|numbers|all|bboolean|bnumbers|"
define	OM_BOOL		1	# Boolean (0=sky, 1=object+bad+grow)
define	OM_ONUM		2	# Object number only
define	OM_ALL		3	# All values
define	OM_BBOOL	4	# Boolean (0=sky, 1=object+bad+grow)
define	OM_BONUM	5	# Object number only
