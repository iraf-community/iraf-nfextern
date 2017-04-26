# Sky subtraction structure.

define	SKY_LEN		(13+$1)
define	SKY_MODE	Memi[$1]		# Sky mode ID
define	SKY_WINDOW	Memi[$1+1]		# Sky window
define	SKY_NC		Memi[$1+2]		# Number of columns
define	SKY_NL		Memi[$1+3]		# Number of lines
define	SKY_INDEX1	Memi[$1+4]		# First sky index in buffer
define	SKY_INDEX2	Memi[$1+5]		# Last sky index in buffer
define	SKY_EINDEX	Memi[$1+6]		# Exclusion index
define	SKY_IPI		Memi[$1+7]		# Input PI
define	SKY_NAVG	Memi[$1+8]		# Central average
define	SKY_NCLIP	Memr[P2R($1+9)]		# Median clipping factor
define	SKY_BLANK	Memr[P2R($1+10)]	# Blank value
define	SKY_RMS		Memi[$1+11]		# Array of RM pointers
define	SKY_NPI		Memi[$1+12]		# Number of PIs
define	SKY_PI		Memi[$1+13+$2]		# Array of PIs

# Sky modes.
define  SKYMODES        "|nearest|before|after|median|"
define  SKY_NEAREST     SRT_NEAREST
define  SKY_BEFORE      SRT_BEFORE
define  SKY_AFTER       SRT_AFTER
define  SKY_MEDIAN      4

