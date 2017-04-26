# AP.H -- ACEPAIRS task

define	NALLOC		100		# Alloc increment
define	AP_SZFNAME	199		# Length of filenames

# Catalog data structure.
define	AP_LEN		203				# Length for one cat
define	AP_NAME		Memc[P2C($1+$2*AP_LEN)]		# Ptr to cat name
define	AP_DEF		Memc[P2C($1+$2*AP_LEN+100)]	# Cat def file
define	AP_RECS		Memi[$1+$2*AP_LEN+200]		# Ptr to cat records
define	AP_NRECS	Memi[$1+$2*AP_LEN+201]		# Number of cat records
define	AP_LIST		Memi[$1+$2*AP_LEN+202]		# Cat list

# Parameter structure.
define	APP_LEN		114				# Length of parameters
define	APP_FILTER	Memc[P2C($1)+$2-1]		# Input catalog filter
define	APP_IWIN	Memi[$1+100]			# Pairing window
define	APP_MINSEP	Memr[P2R($1+101)]		# Min separation
define	APP_MAXSEP	Memr[P2R($1+102)]		# Max separation
define	APP_MINRATE	Memr[P2R($1+103)]		# Min rate
define	APP_MAXRATE	Memr[P2R($1+104)]		# Max rate
define	APP_MAXDM	Memr[P2R($1+105)]		# Max PA diff
define	APP_MAXDW	Memr[P2R($1+106)]		# Max source FWHM diff
define	APP_MAXDE	Memr[P2R($1+107)]		# Max source ellip diff
define	APP_MAXDP	Memr[P2R($1+108)]		# Max source PA diff
define	APP_MAXDPP	Memr[P2R($1+109)]		# Max PA diff
define	APP_MAXDR	Memr[P2R($1+110)]		# Max rate diff
define	APP_ALIGN	Memr[P2R($1+111)]		# Alignment angle
define	APP_TYPE	Memi[$1+112]			# Pair type
define	APP_WEMPTY	Memi[$1+113]			# Write empty catalogs?

# Dictionary for APP_TYPE parameter.
define	APPTYPES	"|general|image|moving|"
define	TY_GENERAL	1		# Any pair
define	TY_IMAGE	2		# Same image (based on ID)
define	TY_MOVING	3		# Moving (separate image IDs)
