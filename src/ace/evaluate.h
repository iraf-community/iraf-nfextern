# EVALUATE definitions

define	EVL_STRLEN	99			# Length of strings
define	EVL_LEN		104			# Parameters structure length

define	EVL_MAGZERO	Memc[P2C($1)+$2-1]	# Magnitude zero point
define	EVL_ORDER	Memc[P2C($1)+$2+50]	# Order expression
define	EVL_FWHM	Memr[P2R($1+100)]	# Default FWHM
define	EVL_CAFWHM	Memr[P2R($1+101)]	# No. FWHM for default aperture
define	EVL_GWTSIG	Memr[P2R($1+102)]	# Sigma for stellar flux wt
define	EVL_GWTNSIG	Memr[P2R($1+103)]	# Number of sig for centroids
