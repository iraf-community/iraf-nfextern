define	PI_LENSTR	199			# Length of strings

# PI -- Processing image structure.
define	PI_PILEN	632			# Length of image structure
define	PI_MAPPED	Memi[$1]		# Is PI mapped?
define	PI_TRIM		Memi[$1+1]		# Is PI trimmed?
define	PI_IM		Memi[$1+2]		# Image pointer
define	PI_OPEN		Memi[$1+3]		# Open method
define	PI_GLINE	Memi[$1+4]		# Get line method
define	PI_CLOSE	Memi[$1+5]		# Close method
define	PI_LEN		Memi[$1+5+$2]		# Image dimensions (3)
define	PI_LINE		Memi[$1+10]		# Image line
define	PI_DATA		Memi[$1+11]		# Image data
define	PI_OP		Memi[$1+12]		# Operand
define	PI_SORTVAL	Memd[P2D($1+14)]	# Sort value
define	PI_EXPTIME	Memr[P2R($1+16)]	# Exposure time
define	PI_IPI		Memi[$1+17]		# Link to input PI
define	PI_BPMPI	Memi[$1+18]		# Link to input mask PI
define	PI_OBMPI	Memi[$1+19]		# Link to object mask PI
define	PI_OPI		Memi[$1+20]		# Link to output PI
define	PI_OMPI		Memi[$1+21]		# Link to output mask PI
define	PI_FP		Memi[$1+22]		# Fixpix pointer
define	PI_MEAN		Memr[P2R($1+23)]	# Mean
define	PI_SIGMA	Memr[P2R($1+24)]	# Sigma
define	PI_NSTAT	Memr[P2R($1+25)]	# Number of pixel statistics
define	PI_SKYMODE	Memr[P2R($1+26)]	# Mode used for sky subtraction
define	PI_LIST		Memi[$1+27]		# List containing image
define	PI_LISTTYPE	Memi[$1+28]		# Processing list type
define	PI_PRCTYPE	Memi[$1+29]		# Processing type
define	PI_EXTI		Memi[$1+30]		# Extension index
define	PI_FLAG		Memi[$1+31]		# Flag
define	PI_NAME		Memc[P2C($1+32)]	# Image name
define	PI_EXTN		Memc[P2C($1+132)]	# Extension name
define	PI_TSEC		Memc[P2C($1+232)]	# Trim section
define	PI_IMAGEID	Memc[P2C($1+332)]	# Image id
define	PI_FILTER	Memc[P2C($1+432)]	# Filter string
define	PI_IMDONE	Memc[P2C($1+532)]	# Done string

define	PIFLAG_LIST	1			# List only
