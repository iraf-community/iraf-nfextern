# Sky parameter structure

define	SKY_LEN		10		# Length of parameter structure
define	SKY_STRLEN	9		# Length of string

define	SKY_TYPE	Memi[$1]	# Type of sky
define	SKY_OTYPE	Memi[$1+1]	# Type of output sky
define	SKY_SCNV	Memi[$1+2]	# Convolve sky?
define	SKY_SKF		Memi[$1+3]	# Sky fit parameters
define	SKY_SKB		Memi[$1+4]	# Sky block parameters
define	SKY_STR		Memc[P2C($1+5)]	# String

define	SKY_TYPES	"|fit|block|"
define	SKY_FIT		1		# Sky fitting algorithm
define	SKY_BLOCK	2		# Sky block algorithm

define	SKY_OTYPES	"|subsky|sky|"
define	SKY_OSUB	1		# Output sky subtracted image
define	SKY_OSKY	2		# Output sky image
