# Persistence mask structure.

define	PER_LEN		(10+$1)
define	PER_WINDOW	Memi[$1]		# Sky window
define	PER_NC		Memi[$1+1]		# Number of columns
define	PER_NL		Memi[$1+2]		# Number of lines
define	PER_INDEX1	Memi[$1+3]		# First sky index in buffer
define	PER_INDEX2	Memi[$1+4]		# Last sky index in buffer
define	PER_EINDEX	Memi[$1+5]		# Exclusion index
define	PER_IPI		Memi[$1+6]		# Input PI
define	PER_BLANK	Memr[P2R($1+7)]		# Blank value
define	PER_RMS		Memi[$1+8]		# Array of RM pointers
define	PER_NPI		Memi[$1+9]		# Number of PIs
define	PER_PI		Memi[$1+10+$2]		# Array of PIs

