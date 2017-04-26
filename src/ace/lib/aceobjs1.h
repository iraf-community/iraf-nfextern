# This file defines the object parameters for a single catalog.

# The following are appication structure definitions based on the
# object IDs in aceobjs.h.

define	OBJ_DETLEN	17			# Length for candidate objects

# Detection pass parameters.
define	OBJ_NUM		RECI($1,ID_NUM)		# Object number
define	OBJ_PNUM	RECI($1,ID_PNUM)	# Parent object number
define	OBJ_XPEAK	RECR($1,ID_XPEAK)	# X peak logical coordinate
define	OBJ_YPEAK	RECR($1,ID_YPEAK)	# Y peak logical coordinate
define	OBJ_FLUX	RECR($1,ID_FLUX)	# Isophotal flux (I - sky)
define	OBJ_NPIX	RECI($1,ID_NPIX)	# Number of pixels
define	OBJ_NDETECT	RECI($1,ID_NDETECT)	# Number of detected pixels
define	OBJ_SIG		RECR($1,ID_SIG)		# Sky sigma
define	OBJ_ISIGAVG	RECR($1,ID_ISIGAVG)	# Average (I - sky) / sig
define	OBJ_ISIGMAX	RECR($1,ID_ISIGMAX)	# Maximum (I - sky) / sig
define	OBJ_ISIGAV	RECR($1,ID_ISIGAV)	# Ref average (I - sky) / sig
define	OBJ_FLAGS	RECT($1,ID_FLAGS)	# Flags
define	OBJ_FLAG	RECC($1,ID_FLAGS,$2)	# Flag

define	OBJ_SKY		RECR($1,ID_SKY)		# Mean sky
define	OBJ_THRESH	RECR($1,ID_THRESH)	# Mean threshold above sky
define	OBJ_PEAK	RECR($1,ID_PEAK)	# Peak pixel value above sky
define	OBJ_FCORE	RECR($1,ID_FCORE)	# Core flux
define	OBJ_GWFLUX	RECR($1,ID_GWFLUX)	# Gaussian weighted flux
define	OBJ_CAFLUX	RECR($1,$2+ID_CAFLUX_0)# aperture flux (I - sky)
define	OBJ_FRACFLUX	RECR($1,ID_FRACFLUX)	# Apportioned flux
define	OBJ_FRAC	RECR($1,ID_FRAC)	# Approtioned fraction
define	OBJ_XMIN	RECI($1,ID_XMIN)	# Minimum X
define	OBJ_XMAX	RECI($1,ID_XMAX)	# Maximum X
define	OBJ_YMIN	RECI($1,ID_YMIN)	# Minimum Y
define	OBJ_YMAX	RECI($1,ID_YMAX)	# Maximum Y
define	OBJ_XAP		RECR($1,ID_XAP)		# X aperture coordinate
define	OBJ_YAP		RECR($1,ID_YAP)		# Y aperture coordinate
define	OBJ_X		RECR($1,ID_X)		# X centroid
define	OBJ_Y		RECR($1,ID_Y)		# Y centroid
define	OBJ_XX		RECR($1,ID_XX)		# X centroid
define	OBJ_YY		RECR($1,ID_YY)		# Y centroid
define	OBJ_XY		RECR($1,ID_XY)		# X centroid
define	OBJ_R		RECR($1,ID_R)		# R moment
define	OBJ_RII		RECR($1,ID_RII)		# RI2 moment
define	OBJ_FWHM	RECR($1,ID_FWHM)	# FWHM estimate
define	OBJ_EAELLIP	RECR($1,ID_EAELLIP)	# Ellip aperture ellipticity
define	OBJ_EATHETA	RECR($1,ID_EATHETA)	# Ellip aperture pos angle
define	OBJ_EAR		RECR($1,$2+ID_EAR_0)	# Ellip aperture radius (10)
define	OBJ_EAFLUX	RECR($1,$2+ID_EAFLUX_0)	# Ellip aperture flux (10)

define	OBJ_FLUXVAR	RECR($1,ID_FLUXVAR)	# Variance in flux
define	OBJ_XVAR	RECR($1,ID_XVAR)	# Variance in X centroid
define	OBJ_YVAR	RECR($1,ID_YVAR)	# Variance in Y centroid
define	OBJ_XYCOV	RECR($1,ID_XYCOV)	# Covariance of X and Y centroid

define	OBJ_ORDER	RECI($1,ID_ORDER)	# Order

define	NAPFLUX		10		# Number of aperture flux parameters.
define	SZ_FLAGS	6		# Size of flag string

define	SPLIT		0		# Split flag
define	DARK		1		# Dark flag
define	EVAL		2		# Evaluated flag
define	GROW		3		# Grown flag
define	BP		4		# Bad pixel flag
define	RCLIP		5		# R clipping source

# I/O Transformation functions.
define	FUNCS		"|MAG|"
define	FUNC_MAG	1		# Magnitude


define	NUMSTART	11		# First object number
