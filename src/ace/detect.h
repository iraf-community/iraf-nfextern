# Detection parameter structure.
define	DET_NBP		32		# Maximum number of BP ranges
define	DET_BPLEN	(32*3)		# Length of BP ranges
define	DET_LEN		(64+2*DET_BPLEN)	# Length of parameter structure
define	DET_STRLEN	99		# Length of strings in structure

define	DET_CNV		P2C($1)		# Convolution string
define	DET_SCNV	Memi[$1+51]	# Convovle sky?
define	DET_HSIG	Memr[P2R($1+52)]# High detection sigma
define	DET_LSIG	Memr[P2R($1+53)]# Low detection sigma
define	DET_HDETECT	Memi[$1+54]	# Detect above sky?
define	DET_LDETECT	Memi[$1+55]	# Detect below sky?
define	DET_NEIGHBORS	Memi[$1+56]	# Neighbor type
define	DET_MINPIX	Memi[$1+57]	# Minimum number of pixels
define	DET_SIGAVG	Memr[P2R($1+58)]# Minimum average above sky in sigma
define	DET_SIGPEAK	Memr[P2R($1+59)]# Minimum peak above sky in sigma
define	DET_FRAC2	Memr[P2R($1+60)]# Fraction of difference relative to 2
define	DET_BPVAL	Memi[$1+61]	# Output bad pixel value
define	DET_SKB		Memi[$1+62]	# Parameters for sky update
define	DET_UPDSKY	Memi[$1+63]	# Update sky?
define	DET_BPDET	Memi[$1+64]		# BP ranges
define	DET_BPFLG	Memi[$1+64+DET_BPLEN]	# BP ranges
