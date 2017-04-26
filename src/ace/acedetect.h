# ACEALL parameter structure.
define	PAR_SZSTR	199		# Length of strings in par structure
define	PAR_LEN		244		# Length of parameter structure

define	PAR_TASK	Memc[P2C($1)]	# Task name (19)
define	PAR_IMLIST	Memi[$1+$2+9]	# List of images (2)
define	PAR_BPMLIST	Memi[$1+$2+11]	# List of bad pixel masks (2)
define	PAR_SKYLIST	Memi[$1+$2+13]	# List of skys (2)
define	PAR_SIGLIST	Memi[$1+$2+15]	# List of sigmas (2)
define	PAR_EXPLIST	Memi[$1+$2+17]	# List of sigmas (2)
define	PAR_GAINLIST	Memi[$1+$2+19]	# List of measurement gain maps (2)
define	PAR_SCALELIST	Memi[$1+$2+21]	# List of scales (2)
define	PAR_SPTLLIST	Memi[$1+$2+23]	# List of spatial scales (2)
define	PAR_OFFSET	Memc[P2C($1+26)] # Offsets for difference matching
define	PAR_INCATLIST	Memi[$1+126]	# List of input catalogs
define	PAR_OUTCATLIST	Memi[$1+127]	# List of output catalogs
define	PAR_INOMLIST	Memi[$1+128]	# List of input object masks
define	PAR_OUTOMLIST	Memi[$1+129]	# List of output object masks
define	PAR_CATDEFLIST	Memi[$1+130]	# List of catalog definitions
define	PAR_LOGLIST	Memi[$1+131]	# List of log files
define	PAR_OUTSKYLIST	Memi[$1+132]	# List of output sky images
define	PAR_OUTSIGLIST	Memi[$1+133]	# List of output sigma images
define	PAR_NMAXREC	Memi[$1+134]	# Maximum number of output records
define	PAR_VERBOSE	Memi[$1+135]	# Verbose?
define	PAR_UPDATE	Memi[$1+136]	# Update headers?

define	PAR_SKY		Memi[$1+137]	# Sky parameters
define	PAR_DET		Memi[$1+138]	# Detection parameters
define	PAR_SPT		Memi[$1+139]	# Split parameters
define	PAR_GRW		Memi[$1+140]	# Grow parameters
define	PAR_EVL		Memi[$1+141]	# Evaluate parameters
define	PAR_FLT		Memi[$1+142]	# Filter parameters

define	PAR_OMTYPE	Memi[$1+143]	# Output object mask type
define	PAR_EXTNAMES	Memc[P2C($1+144)] # Extensions names
