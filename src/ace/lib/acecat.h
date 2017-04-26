# ACECAT.H -- Public catalog data structures and definitions.

# Catalog data structure.
#
# The record structure length is automatically set.

define  CAT_IHDR	Memi[$1]    # Input catalog header (IMIO)
define  CAT_OHDR	Memi[$1+1]  # Output catalog header (IMIO)
define	CAT_WCS		Memi[$1+2]  # WCS (MWCS)
define  CAT_RECS	Memi[$1+3]  # Array of records (ptr)
define  CAT_NRECS	Memi[$1+4]  # Number of records
define  CAT_RECLEN	Memi[$1+5]  # Object record length
define  CAT_NF		Memi[$1+6]  # Number of fields in record
define	CAT_NIM		Memi[$1+7]  # Number of images
define  CAT_DEFS	Memi[$1+8]  # Pointer to array of defs

# WCS structure.
# The transformations are only defined when they are first needed.

define	CAT_WCSLEN	7
define	CAT_MW		Memi[$1]    # MWCS pointer
define	CAT_CTLW	Memi[$1+1]  # Logical to world (MWCS CT)
define	CAT_CTWL	Memi[$1+2]  # World to logical (MWCS CT)
define	CAT_CTLP	Memi[$1+3]  # Logical to physical (MWCS CT)
define	CAT_CTPL	Memi[$1+4]  # Physical to logical (MWCS CT)
define	CAT_CTPW	Memi[$1+5]  # Physical to world (MWCS CT)
define	CAT_CTWP	Memi[$1+6]  # World to Physical (MWCS CT)


# Object record definitions.
#
# Reference to elements of the application defined
# record structure may be made with the generic REC[IRDC]
# macros or with the application defined macros; i.e. "define
# REC_X RECR($1,ID_X)" where ID_X is a structure offset into
# the record.

define	CAT_REC		Memi[CAT_RECS($1)+$2-1] # Record

define  RECI		Memi[$1+$2]        # Ref integer parameter
define  RECR		Memr[P2R($1+$2)]   # Ref real parameter
define  RECD		Memd[P2D($1+$2)]   # Ref double parameter
define  RECC		Memc[P2C($1+$2)+$3]# Ref char parameter
define  RECT		Memc[P2C($1+$2)]   # Ref text string parameter

# The following may be used to reference the field definitions.

define  CAT_DEF		Memi[CAT_DEFS($1)+$2]      # Pointer defs
define  CAT_TYPE	Memi[CAT_DEF($1,$2)]       # Data type
define  CAT_READ	Memi[CAT_DEF($1,$2)+1]       # Read from catalog
define  CAT_WRITE	Memi[CAT_DEF($1,$2)+2]       # Write to catalog
define  CAT_NAME	Memc[P2C(CAT_DEF($1,$2)+3)]  # Name (task)
define  CAT_CNAME	Memc[P2C(CAT_DEF($1,$2)+13)]  # Name (catalog)
define  CAT_UNITS	Memc[P2C(CAT_DEF($1,$2)+23)] # Units
define  CAT_FORMAT	Memc[P2C(CAT_DEF($1,$2)+33)] # Format
