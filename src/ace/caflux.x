include	<imhdr.h>
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>

define	CAF_NSUB	5		# Number of subpixels per axis

define	CAF_LEN		(5+4*NAPFLUX+($1))	    # Structure length
define	CAF_NOBJS	Memi[$1]		    # Num of objs to evaluate
define	CAF_NAPS	Memi[$1+1]		    # Num of aps per object
define	CAF_RMAX	Memr[P2R($1+2)]		    # Max ap radius
define	CAF_YSTART	Memi[$1+3]		    # Index of 1st obj
define	CAF_OBJS	Memi[$1+4]		    # Ptr to objects
define	CAF_R2APS	Memr[P2R($1+$2+4)]	    # Array of ap radii squared
define	CAF_R2MIN	Memr[P2R($1+$2+4+NAPFLUX)]  # Limit for subsampling
define	CAF_R2MAX	Memr[P2R($1+$2+4+2*NAPFLUX)]# Max limit for subsampling
define	CAF_IDS		Memi[$1+$2+4+3*NAPFLUX]	    # Array of ids
define	CAF_YSORT	Memi[$1+$2+4+4*NAPFLUX]	    # Y sorted obj indices


# CAF_INIT -- Initialize aperture photometry.

procedure caf_init (cat, nobjs, r, cafwhm, logfd, verbose)

pointer	cat			#I Catalog
int	nobjs			#O Number of objects for aperture evaluation
real	r			#I Default radius
real	cafwhm			#I CAFWHM parameter
int	logfd			#I Log file descriptor
int	verbose			#I Verbose level

bool	doobj
real	rap, rmax
int	i, j, naps, nummax
pointer	stp, sym, obj, objs, sthead(), stnext()

int	ycompare(), ctor()
extern	ycompare
errchk	calloc

pointer	caf
common	/caf_com/ caf

begin
	# Initialize.
	nobjs = 0
	naps = 0
	rmax = 0.

	stp = CAT_STP(cat)
	objs = CAT_RECS(cat)
	nummax = CAT_NUMMAX(cat)

	# Allocate memory.
	call calloc (caf, CAF_LEN(nummax), TY_STRUCT)

	# Find the aperture flux entries that need to be evaluated.
	# Get the maximum radius since that will define the line
	# limits needed for each object.  Compute array of radii squared
	# for the apertures.  Pixels are checked for being in the aperture
	# in r^2 to avoid square roots.

	for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
	    if (ENTRY_ID(sym) < ID_CAFLUX_0 || ENTRY_ID(sym) > ID_CAFLUX_9)
		next
	    if (ENTRY_EVAL(sym) != YES)
	        next
	    i = 1
	    if (ENTRY_ARGS(sym) == EOS)
	        rap = INDEFR
	    else if (ctor (ENTRY_ARGS(sym), i, rap) == 0)
	        call error (1, "Bad radius for aperture flux")
	    if (IS_INDEFR(rap)) {
	        rap = r
		call catputr (cat, "CAFWHM", cafwhm)
		call catputr (cat, "CARADIUS", rap)
		if (logfd != NULL) {
		    call fprintf (logfd,
		        "    Automatic circular aperture diameter (FWHM) = %g\n")
			call pargr (cafwhm)
		    call fprintf (logfd,
		        "    Automatic circular aperture radius = %g\n")
			call pargr (rap)
		}
		if (verbose > 1) {
		    call printf (
		        "    Automatic circular aperture diameter (FWHM) = %g\n")
			call pargr (cafwhm)
		    call printf (
		        "    Automatic circular aperture radius = %g\n")
			call pargr (rap)
		}
	    }
	    rmax = max (rap, rmax)
	    naps = naps + 1
	    CAF_IDS(caf,naps) = ENTRY_ID(sym)
	    CAF_R2APS(caf,naps) = rap ** 2
	    CAF_R2MAX(caf,naps) = (rap + 0.71) ** 2
	    CAF_R2MIN(caf,naps) = max (0., (rap - 0.71) ** 2)
	}

	# If there are no apertures to evaluate free memory and return.
	if (naps == 0) {
	    call caf_free ()
	    return
	}

	# For the objects create a sorted index array by YAP so that we
	# can quickly find objects which include a particular line in
	# their apertures.

	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (IS_INDEFR(OBJ_XAP(obj)) || IS_INDEFR(OBJ_YAP(obj)))
	        next
	    if (OBJ_FLAG(obj,DARK) == 'D')
	        next
	    doobj = false
	    do j = 1, naps {
		if (IS_INDEFR(RECR(obj,CAF_IDS(caf,j)))) {
		    doobj = true
		    RECR(obj,CAF_IDS(caf,j)) = 0.
		}
	    }
	    if (doobj) {
		nobjs = nobjs + 1
		CAF_YSORT(caf,nobjs) = i
	    }
	}

	if (nobjs == 0) {
	    call caf_free ()
	    return
	}
	if (nobjs > 1)
	    call gqsort (CAF_YSORT(caf,1), nobjs, ycompare, objs)

	CAF_NOBJS(caf) = nobjs
	CAF_NAPS(caf) = naps
	CAF_RMAX(caf) = rmax
	CAF_YSTART(caf) = 1
	CAF_OBJS(caf) = objs

end


# CAF_FREE -- Free aperture photometry memory.

procedure caf_free ()

pointer	caf
common	/caf_com/ caf

begin
	call mfree (caf, TY_STRUCT)
end


# CAF_EVAL -- Do circular aperture photometry.  Maintain the
# first entry in the sorted index array to be considered.  All
# earlier entries will have all aperture lines less than the
# current line.  Break on the first object whose minimum aperture
# line is greater than the current line.

procedure caf_eval (l, im, skymap, sigmap, gainmap, expmap, sptlmap,
	data, skydata, ssigdata, gaindata, expdata, sigdata, sptldata)

int	l			#I Line
pointer	im			#I Image
pointer	skymap			#I Sky map
pointer	sigmap			#I Sigma map
pointer	gainmap			#I Gain map
pointer	expmap			#I Exposure map
pointer	sptlmap			#I Spatial scale map
pointer	data			#O Image data
pointer	skydata			#O Sky data
pointer	ssigdata		#O Sky sigma data
pointer	gaindata		#O Gain data
pointer	expdata			#O Exposure data
pointer	sigdata			#O Total sigma data
pointer	sptldata		#O Spatial scale data

int	i, j, id, nc, c
real	xsub, ysub, darea, rmax, dc, dl, l2, r2, f, f1, area, sptl2
real	x, y, dx, dy, dx2, dy2
pointer	obj, objs

pointer	caf
common	/caf_com/ caf

begin
	nc = IM_LEN(im,1)
	sptl2 = 1
	xsub = 1. / CAF_NSUB
	ysub = 1. / CAF_NSUB
	darea = xsub * ysub

	rmax = CAF_RMAX(caf)
	objs = CAF_OBJS(caf)

	# Allow for variation in scale.
	if (sptlmap != NULL) {
	    if (data == NULL)
		call evgdata (l, im, skymap, sigmap, gainmap, expmap,
		    sptlmap, data, skydata, ssigdata, gaindata, expdata,
		    sigdata, sptldata)
	    sptl2 = 0
	    do c = 0, nc-1, 50
		sptl2 = max (sptl2, Memr[sptldata+c])
	    rmax = rmax * sptl2
	}

	do i = CAF_YSTART(caf), CAF_NOBJS(caf) {
	    obj = Memi[objs+CAF_YSORT(caf,i)]
	    y = OBJ_YAP(obj)
	    if (y - 0.5 - rmax > l)
		break
	    if (y + 0.5 + rmax < l) {
		CAF_YSTART(caf) = CAF_YSTART(caf) + 1
		next
	    }
	    x = OBJ_XAP(obj)
	    if (data == NULL)
		call evgdata (l, im, skymap, sigmap, gainmap, expmap,
		    sptlmap, data, skydata, ssigdata, gaindata, expdata,
		    sigdata, sptldata)

	    # Accumulate data within in the apertures using the r^2
	    # values.  Currently partial pixels are not considered and
	    # errors are not evaluated.
	    # Note that bad pixels or object overlaps are not excluded
	    # in the apertures.

	    dy = l - y
	    dy2 = dy * dy
	    do c = max (1, int(x-0.5-rmax)), min (nc, int(x+0.5+rmax)) {
	        dx = c - x
		dx2 = dx * dx
		f = (Memr[data+c-1] - Memr[skydata+c-1])
		if (sptlmap != NULL)
		    sptl2 = Memr[sptldata+c-1] ** 2
		r2 = (dx2 + dy2) / sptl2

		do j = 1, CAF_NAPS(caf) {
		    if (r2 > CAF_R2MAX(caf,j))
		        next
		    if (r2 > CAF_R2MIN(caf,j)) {
			area = 0.
			for (dl=-CAF_NSUB/2*ysub; dl<0.5; dl=dl+ysub) {
			    l2 = (dy + dl) ** 2
			    for (dc=-CAF_NSUB/2*xsub; dc<0.5; dc=dc+xsub) {
				r2 = ((dx + dc) ** 2 + l2) / sptl2
				if (r2 < CAF_R2APS(caf,j))
				    area = area + darea
			    }
			}
			f1 = f * area
		    } else
		        f1 = f

		    id = CAF_IDS(caf,j)
		    RECR(obj,id) = RECR(obj,id) + f1
#if (abs(x-1950)<1 && abs(y-1450)<1) {
#if (RECR(obj,id) == f1) {
#call printf ("%8.2f %8.2f %5.2f:\n")
#call pargr (x)
#call pargr (y)
#call pargr (sqrt(CAF_R2APS(caf,j)))
#}
#call printf ("%d %d %8.2f %8.2f %8.2f\n")
#call pargi (c)
#call pargi (l)
#call pargr (Memr[data+c-1])
#call pargr (f)
#call pargr (f1)
#}
		}
	    }
	}
end


# YCOMPARE -- Compare Y values of two objects for sorting.

int procedure ycompare (objs, i1, i2)

pointer	objs			#I Pointer to array of objects
int	i1			#I Index of first object to compare
int	i2			#I Index of second object to compare

real	y1, y2

begin
	y1 = OBJ_YAP(Memi[objs+i1])
	y2 = OBJ_YAP(Memi[objs+i2])
	if (y1 < y2)
	    return (-1)
	else if (y1 > y2)
	    return (1)
	else
	    return (0)
end
