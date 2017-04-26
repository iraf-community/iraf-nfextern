define	PRC_LENSTR	199			# Length of strings
define	PRC_LENFLAGS	19			# Length of flag strings

# PRC -- Processing structure
define	PRC_LEN		150			# Length of parameter structure
define	PRC_PI		Memi[$1]		# Input being processed
define	PRC_PIKEY	Memi[$1+1]		# Image for keywords
define	PRC_PIAKEY	Memi[$1+2]		# Image for keywords
define	PRC_PIBKEY	Memi[$1+3]		# Image for keywords
define	PRC_TYKEY	Memi[$1+4]		# Datatype for keywords
define	PRC_PIS		Memi[$1+5]		# List of PIs
define	PRC_LINE	Memi[$1+6]		# Current line
define	PRC_GETOP	Memi[$1+7]		# Get operand function
define	PRC_FUNC	Memi[$1+8]		# Evaluate function
define	PRC_PAR		Memi[$1+9]		# Parameter structure
define	PRC_STP		Memi[$1+10]		# Symbol table pointer
define	PRC_GNMEAN	Memi[$1+11]		# Number in global mean
define	PRC_GMEAN	Memr[P2R($1+12)]	# Global mean
define	PRC_ORDER1	Memc[P2C($1+20)+$2-1]	# First pass processing order
define	PRC_ORDER2	Memc[P2C($1+30)+$2-1]	# Second pass processing order
define	PRC_DONE	Memc[P2C($1+40)]	# Processing order
define	PRC_STR		Memc[P2C($1+50)]	# Working string

define	PRCTYPES	"|input|bpmask|objmask|output|outmask|bias|zero|dark|\
			|fflat|gflat|sky|object|mask|linearity|replace|\
			|normalize|trim|fixpix|saturation|persist|user|"
define	PRC_INPUT	1
define	PRC_BPM		2
define	PRC_OBM		3
define	PRC_OUTPUT	4
define	PRC_OUTMASK	5
define	PRC_BIAS	6
define	PRC_ZERO	7
define	PRC_DARK	8
define	PRC_FFLAT	10
define	PRC_GFLAT	11
define	PRC_SKY		12
define	PRC_OBJECT	13
define	PRC_MASK	14
define	PRC_LIN		15
define	PRC_REP		16
define	PRC_NORM	18
define	PRC_TRIM	19
define	PRC_FIXPIX	20
define	PRC_SAT		21
define	PRC_PER		22
define	PRC_USER	23

define	PRC_NOPROC	"+LIST+"	# Special name for no ouptut


# Error codes.
define	PRCERR_EXPRS	101	# Bad string expression
define	PRCERR_EXPRN	102	# Bad numeric expression
define	PRCERR_EXPRB	103	# Bad boolean expression
define	PRCERR_IMREFUK	104	# Unknown image reference
define	PRCERR_IMREFNF	105	# Image reference not found
define	PRCERR_IMKEYNF	106	# Image keyword not found
define	PRCERR_CALNF	107	# Calibration not found
