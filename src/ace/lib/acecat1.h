# ACECAT1.H -- Internal catalog structures.

# Catalog internal data structure.

define	CAT_SZSTR	99		# Length of catalog string
define	CAT_SLEN	19		# Length of strings
define	CAT_DEFLEN	43		# Length of entry structure
define	CAT_LEN		220		# Length of catalog structure

define	CAT_NUMMAX	CAT_NRECS($1)	# Maximum record number
define	CAT_FLAGS	Memi[$1+11]	# Catalog flags
define	CAT_STP		Memi[$1+12]	# Record structure symbol table
define	CAT_INTBL	Memi[$1+13]	# Input table structure
define	CAT_OUTTBL	Memi[$1+14]	# Output table structure
define	CAT_UFUNC	Memi[$1+15]	# User transformation function
define	CAT_APFLUX	Memi[$1+16]	# Array of aperture fluxes (ptr)
define	CAT_MAGZERO	Memr[P2R($1+17)]# Magnitude zero
define	CAT_CUR		Memi[$1+18]	# Current index (for cathead/catnext)
define	CAT_CATALOG	Memc[P2C($1+20)]	# Catalog name
define	CAT_RECID	Memc[P2C($1+70)]	# Default ID
define	CAT_STRPTR	P2C($1+120)		# String pointer
define	CAT_STR		Memc[CAT_STRPTR($1)]	# String value
define	CAT_BUF		($1+170)		# Working buffer (50)

# Table structure.
define	TBL_SZBUF	99		# BUF size in chars
define	TBL_LEN		52		# Structure length
define	TBL_TP		Memi[$1]	# Table pointer
define	TBL_STP		Memi[$1+1]	# Symbol table of entries
define	TBL_BUF		($1+2)		# Working buffer

# Catalog entry structure.
define	ENTRY_ULEN	19			# Length of units string
define	ENTRY_FLEN	19			# Length of format string
define	ENTRY_DLEN	99			# Length of description string
define	ENTRY_LEN	180			# Length of entry structure
define	ENTRY_ID	Memi[$1]		# Entry id
define	ENTRY_EVAL	Memi[$1+1]		# Evaluate?
define	ENTRY_READ	Memi[$1+2]		# Read from catalog?
define	ENTRY_WRITE	Memi[$1+3]		# Write to catalog?
define	ENTRY_TYPE	Memi[$1+4]		# Datatype in record
define	ENTRY_CTYPE	Memi[$1+5]		# Datatype in catalog
define	ENTRY_CDEF	Memi[$1+6]		# Column descriptor
define	ENTRY_NAME	Memc[P2C($1+10)]	# Entry name (99)
define	ENTRY_UNITS	Memc[P2C($1+60)]	# Entry units (19)
define	ENTRY_FORMAT	Memc[P2C($1+70)]	# Entry format (19)
define	ENTRY_DESC	Memc[P2C($1+80)]	# Entry description (99)
define	ENTRY_ARGS	Memc[P2C($1+130)]	# Entry arguments (99)

# Catalog extensions.
define	CATEXTNS	"|fits|tab|"

# Catalog Parameters.
define	CATPARAMS	"|incatalog|outcatalog|image|objmask|objid|catalog|nobjects|magzero|irows|orows|"
