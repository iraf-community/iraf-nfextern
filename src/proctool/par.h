# PROCTOOL parameters.
define	PAR_LEN		818			# Length of parameter object
define	PAR_SZSTR	199			# Length of strings

define	PAR_OST		Memi[$1]		# Expression symbol table
define	PAR_OPERAND	Memi[$1+1]		# Operand symbol table
define	PAR_OUTTYPE	Memi[$1+2]		# Output file type
define	PAR_LISTIM	Memi[$1+3]		# List image properties?
define	PAR_OLLIST	Memi[$1+4]		# List of output logfiles
define	PAR_OVERRIDE	Memi[$1+5]		# Override previous processing?
define	PAR_COPY	Memi[$1+6]		# Copy if no processing?
define	PAR_ERRACT	Memi[$1+7]		# Error action code
define	PAR_SRTORDER	P2C($1+8)		# Sort order (8)
define	PAR_MASKKEY	Memc[P2C($1+13)]	# Keyword for mask output (8)
define	PAR_TSEC	Memc[P2C($1+18)]	# Trim section expression
define	PAR_DORDER	Memc[P2C($1+118)]	# Dark processing order
define	PAR_FORDER	Memc[P2C($1+218)]	# Flat processing order
define	PAR_ORDER	Memc[P2C($1+318)]	# Processing order
define	PAR_GDEV	Memc[P2C($1+418)]	# Graphics device
define	PAR_GCUR	Memc[P2C($1+518)]	# Graphics cursor
define	PAR_GPFILE	Memc[P2C($1+618)]	# Plot file
define	PAR_STR		Memc[P2C($1+718)]	# Work string

define	PAR_OUTTYPES	"|image|mask|list|vlist|"
define	PAR_OUTIMG	1
define	PAR_OUTMSK	2
define	PAR_OUTLST	3
define	PAR_OUTVLST	4

define	PAR_EA		"|warn|error|quit|"
define	PAR_EAWARN	1
define	PAR_EAERROR	2
define	PAR_EAQUIT	3
