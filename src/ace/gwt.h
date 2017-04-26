# GWT.H -- Definitions for Gaussian weighted measurements.

# Algorithm parameters.
define	GWTS_RAD	5			# Weight radius in sigma
define	GWTS_NWTS	501			# Number of weight points
define	GWTS_SIGDEF	2.			# Default sigma for flux
define	GWTS_NSIGDEF	2.			# Default sigma for centroid
define	GWTS_RMIN	3.			# Minimum aperture radius
define	GWTS_RMAX	12.			# Maximum aperture radius
define	GWTS_RSTEP	0.2			# Aperture radius step size

# Weighted moment global structure.
define	GWTS_LEN	(3+GWTS_NWTS+$1)	# Variable structure length
define	GWTS_SIG	Memr[P2R($1)]		# Sigma for flux weighting
define	GWTS_NSIG	Memr[P2R($1+1)]		# Number of sigma for centroids
define	GWTS_NSUB	Memi[$1+2]		# Pixel subsampling (1D)
define	GWTS_WTS	($1+3)			# Pointer to weights
define	GWTS_GWT	Memi[$1+3+GWTS_NWTS+$2]	# GWT structure (zero indexed)

# Weighted moment structure for an object.
# This has a global section for an object and then  substructures for each
# center to compute.

define	GWT_LEN		(5+9*$1)		# Structure length

define	GWT_XC		Memr[P2R($1)]		# X center
define	GWT_YC		Memr[P2R($1+1)]		# Y center
define	GWT_FCORE	Memr[P2R($1+2)]		# Core flux
define	GWT_SIG		Memr[P2R($1+3)]		# Sigma for weighting
define	GWT_NBINS	Memi[$1+4]		# Number of R bins

define	GWT_WT1		($1+5)			# Ptr to moment wts
define	GWT_WT2		($1+5+GWT_NBINS($1))	# Ptr to flux wts
define	GWT_N		($1+5+2*GWT_NBINS($1))	# Ptr to number of pix
define	GWT_F		($1+5+3*GWT_NBINS($1))	# Ptr to wted Flux
define	GWT_X		($1+5+4*GWT_NBINS($1))	# Ptr to wted X
define	GWT_Y		($1+5+5*GWT_NBINS($1))	# Ptr to wted Y
define	GWT_XX		($1+5+6*GWT_NBINS($1))	# Ptr to wted XX
define	GWT_YY		($1+5+7*GWT_NBINS($1))	# Ptr to wted YY
define	GWT_XY		($1+5+8*GWT_NBINS($1))	# Ptr to wted XY

# Used for accumulation array.
define	WT1	1
define	WT2	2
define	F	3
define	X	4
define	Y	5
define	XX	6
define	YY	7
define	XY	8
