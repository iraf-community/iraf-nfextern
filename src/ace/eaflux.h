# EAFLUX.H -- Definitions for ellipical aperture fluxes.

# Algorithm parameters.
define	EAFS_DR		0.05			# Radial profile resolution
define	EAFS_NMAX	1000			# Maximum profile length
define	EAFS_NSUB	5			# Subpixels per axis
define	EAFS_R1		-1.5			# Annulus inner edge
define	EAFS_R2		1.5			# Annulus outer edge
define	EAFS_PR1	0.			# Linear fit lower SB ratio
define	EAFS_PR2	0.1			# Linear fit upper SB ratio

# Elliptical aperture global structure.
define	EAFS_LEN	($1+31)			# Variable structure length
define	EAFS_NAP	Memi[$1]		# Number of apertures
define	EAFS_PR		Memr[P2R($1+$2+1)]	# Petrosian SB ratios (zero ind)
define	EAFS_RID	Memi[$1+$2+11]		# Object rec (zero index)
define	EAFS_FID	Memi[$1+$2+21]		# Object rec (zero index)
define	EAFS_EAF	Memi[$1+$2+31]		# EAF structure (zero indexed)

# Elliptical aperture structure for an object.
define	EAF_LEN		(4+2*$1)		# Variable structure length
define	EAF_C		Memr[P2R($1)]		# Cos(Theta)
define	EAF_S		Memr[P2R($1+1)]		# Sin(Theta)
define	EAF_E		Memr[P2R($1+2)]		# A/B
define	EAF_N		Memi[$1+3]		# Length of arrays
define	EAF_PN		($1+4)			# Pointer to number array
define	EAF_PF		($1+4+EAF_N($1))	# Pointer to flux array
