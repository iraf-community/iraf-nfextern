include	<error.h>
include	<mach.h>
include	<math.h>
include	<imhdr.h>
include	<acecat.h>
include	"acematch.h"

define	STRUCTDEF	"acesrc$acematch.h"
define	DEBUG		0
define	SZ_CMD		(4*SZ_LINE)

procedure t_acexymatch ()

int	icats			# List of image catalogs
pointer	icatdef			# Image catalog definitions
int	wcs			# List of image catalog WCS
pointer	ifilter			# Image catalog filter
int	rcats			# List of reference catalogs
pointer	rcatdef			# Reference catalog definitions
pointer	rfilter			# Reference catalog filter
int	mcats			# List of output matched catalogs
bool	mosaic			# Mosaic mode?
double	search			# Maximum search radius (may be zero)
double	rsearch			# Maximum rotation search (deg)
double	rstep			# Rotation step (deg)
pointer	hists			# List of histogram images
int	nim			# Maximum catalog objects for search
int	nref			# Maximum reference objects for search
double	fwhm			# FWHM for convolution (arcsec)
double	match			# Matching distance (arcsec)
bool	verbose			# Verbose?

int	i, j, ncats, isearch
double	scale, psigma, pmatch, xshift, yshift, theta
pointer	sp, icat, iwcs, rcat, mcat, histim, str
pointer	cat1, cat2, mw, mwa, im, newcat

bool	clgetb(), streq()
int	clgeti(), imtopenp(), imtlen(), imtgetim(), nowhite()
double	clgetd()
pointer	immap()
errchk	xym_gcat(), xym_match()

begin
	call smark (sp)
	call salloc (icat, SZ_FNAME, TY_CHAR)
	call salloc (icatdef, SZ_FNAME, TY_CHAR)
	call salloc (iwcs, SZ_FNAME, TY_CHAR)
	call salloc (ifilter, SZ_LINE, TY_CHAR)
	call salloc (rcat, SZ_FNAME, TY_CHAR)
	call salloc (rcatdef, SZ_FNAME, TY_CHAR)
	call salloc (rfilter, SZ_LINE, TY_CHAR)
	call salloc (mcat, SZ_FNAME, TY_CHAR)
	call salloc (histim, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get task parameters.
	icats = imtopenp ("imcats")
	call clgstr ("imcatdef", Memc[icatdef], SZ_LINE)
	wcs = imtopenp ("imwcs")
	call clgstr ("imfilter", Memc[ifilter], SZ_LINE)
	rcats = imtopenp ("refcats")
	call clgstr ("refcatdef", Memc[rcatdef], SZ_LINE)
	call clgstr ("reffilter", Memc[rfilter], SZ_LINE)
	mcats = imtopenp ("matchcats")
	mosaic = clgetb ("mosaic")
	search = clgetd ("search")
	rsearch = clgetd ("rsearch")
	rstep = clgetd ("rstep")
	hists = imtopenp ("histimages")
	nim = clgeti ("nim")
	nref = clgeti ("nref")
	fwhm = clgetd ("fwhm")
	match = clgetd ("match")
	verbose = clgetb ("verbose")

	rsearch = DEGTORAD(rsearch)
	rstep = DEGTORAD(rstep)
	i = nowhite (Memc[histim], Memc[histim], SZ_FNAME)

	# Check lists.
	ncats = imtlen (icats)
	i = imtlen (rcats)
	if (i != ncats && i != 1)
	    call error (1,
	        "Reference catalog list doesn't match image catalog list")
	i = imtlen (wcs)
	if (i != ncats && i > 1)
	    call error (1, "WCS list doesn't match image catalog list")
	i = imtlen (mcats)
	if (i != ncats && i > 0)
	    call error (1,
	         "Matched catalog list doesn't match image catalog list")

	# Allocate memory for the various pointers.  For a mosaic we
	# use an arrays of pointers while for independent data we just
	# have one set of pointers per loop.
	
	if (mosaic)
	    ncats = imtlen (icats)
	else
	    ncats = 1

	call salloc (cat1, ncats, TY_POINTER)
	call salloc (cat2, ncats, TY_POINTER)
	call aclri (Memi[cat1], ncats)
	call aclri (Memi[cat2], ncats)

	# Initialize.
	Memc[iwcs] = EOS; Memc[rcat] = EOS

	while (imtgetim (icats, Memc[icat], SZ_FNAME) != EOF) {
	    if (imtgetim (hists, Memc[histim], SZ_FNAME) == EOF)
	        Memc[histim] = EOS
	    else
	        j = nowhite (Memc[histim], Memc[histim], SZ_FNAME)

	    scale = 0
	    do i = 1, ncats {
		if (i > 1)
		    j = imtgetim (icats, Memc[icat], SZ_FNAME)
		if (imtgetim (wcs, Memc[str], SZ_LINE) != EOF)
		    j = nowhite (Memc[str], Memc[iwcs], SZ_FNAME)
		if (imtgetim (rcats, Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[rcat], SZ_FNAME)

		if (Memc[iwcs] == EOS || streq (Memc[iwcs], Memc[icat])) {
		    call catopen (Memi[cat1+i-1], Memc[icat], "",
		        Memc[icatdef], STRUCTDEF, NULL, 1)
		    im = CAT_HDR(Memi[cat1+i-1])
		    call xym_mw (im, mw, mwa, theta)
		} else {
		    im = immap (Memc[iwcs], READ_ONLY, 0)
		    call xym_mw (im, mw, mwa, theta)
		    call imunmap (im)
		}
		scale = scale + theta
	    
		call xym_gcat (Memc[icat], Memc[icatdef],
		    Memc[ifilter], mw, STDOUT, Memi[cat1+i-1])
		call xym_gcat (Memc[rcat], Memc[rcatdef],
		    Memc[rfilter], mw, STDOUT, Memi[cat2+i-1])
		call mw_close (mwa)
		call mw_close (mw)
	    }
	    scale = scale / ncats

	    isearch = nint (search / scale)
	    psigma = (fwhm / scale) / sqrt (2. * log (2.))
	    pmatch = match / scale

	    # Match the coordinates.
	    call xym_match (Memi[cat1], Memi[cat2], ncats, isearch, rsearch,
	        rstep, Memc[histim], nim, nref, psigma, pmatch,
		xshift, yshift, theta, verbose)

	    # Write matched output catalogs.
	    do i = 1, ncats {
		if (imtgetim (mcats, Memc[mcat], SZ_FNAME) == EOF)
		    break
		call catopen (newcat, "", Memc[mcat], "", STRUCTDEF, NULL, 1)
		call xym_wcat (newcat, Memi[cat1+i-1])
		call catclose (newcat, NO)
	    }

	    # Free data structures.
	    do i = 1, ncats {
		call catclose (Memi[cat2+i-1], NO)
		call catclose (Memi[cat1+i-1], NO)
	    }
	}

	call imtclose (mcats)
	call imtclose (rcats)
	call imtclose (wcs)
	call imtclose (icats)
	call sfree (sp)
end


procedure xym_mw (im, mw, mwa, scale)

pointer	im				#I Image header for WCS
pointer	mw				#O MWCS
pointer	mwa				#O MWCS for astrometry coordinates
double	scale				#O Scale (arcsec/pix)

int	axes[2]
double	x, r[2], w[2], cd[2,2]
pointer	sp, str

bool	streq()
pointer	mw_openim(), mw_open()

data	axes/1,2/

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open WCS.
	mw = mw_openim (im)

	# Compute scale at tangent point.
	call mw_gwtermd (mw, r, w, cd, 2)
	scale = 3600. * sqrt ((cd[1,1]**2+cd[2,1]**2+cd[1,2]**2+cd[2,2]**2)/2.)

	# Check if world axes are reversed from desired order.
	call mw_gwattrs (mw, 1, "axtype", Memc[str], SZ_LINE)
	if (!streq (Memc[str], "ra")) {
	    if (!streq (Memc[str], "dec"))
		call error (1, "WCS axis type not supported")

	    # Swap world axes.
	    call mw_swattrs (mw, 1, "axtype", "ra")
	    call mw_swattrs (mw, 2, "axtype", "dec")

	    x = w[1]
	    w[1] = w[2]
	    w[2] = x
	    x = cd[1,1]
	    cd[1,1] = cd[1,2]
	    cd[1,2] = x
	    x = cd[2,2]
	    cd[2,2] = cd[2,1]
	    cd[2,1] = x
	    call mw_swtermd (mw, r, w, cd, 2)
	}

	# Set astrometric WCS.
	mwa = mw_open (NULL, 2)
	call mw_gsystem (mw, Memc[str], SZ_LINE)
	if (!streq (Memc[str], "physical")) {
	    iferr {
		call mw_newsystem (mwa, Memc[str], 2)
		call mw_swtype (mwa, axes, 2, "tan", "")
		call mw_gwattrs (mw, 1, "axtype", Memc[str], SZ_LINE)
		call mw_swattrs (mwa, 1, "axtype", Memc[str])
		call mw_gwattrs (mw, 2, "axtype", Memc[str], SZ_LINE)
		call mw_swattrs (mwa, 2, "axtype", Memc[str])
		call mw_gwtermd (mw, r, w, cd, 2)
		r[1] = 0; r[2] = 0
		cd[1,1] = 1; cd[1,2] = 0; cd[2,1] = 0; cd[2,2] = 1
		call mw_swtermd (mwa, r, w, cd, 2)
	    } then {
		call erract (EA_WARN)
		call mw_close (mwa)
		mwa = mw_open (NULL, 2)
	    }
	}

	call sfree (sp)
end


procedure xym_gcat (catname, catdef, catfilter, mw, log, cat)

char	catname[ARB]			#I Catalog name
char	catdef[ARB]			#I Catalog definitions
char	catfilter[ARB]			#I Catalog filter
pointer	mw				#I MWCS
int	log				#I Log file descriptor
pointer	cat				#U Catalog pointer

int	i
pointer	ctlw, ctwl, rec

pointer	mw_sctran()
errchk	mw_sctran
errchk	catopen, catrrecs

begin
	if (log != NULL) {
	    call printf ("catname = '%s'\n")
		call pargstr (catname)
	    call printf ("catdef = '%s'\n")
		call pargstr (catdef)
	    call printf ("catfilter = '%s'\n")
		call pargstr (catfilter)
	}

	# Open the catalog.
	if (cat == NULL)
	    call catopen (cat, catname, "", catdef, STRUCTDEF, NULL, 1)

	# Read catalogs and set fields using the WCS.
	call catrrecs (cat, catfilter, -1)
	ctlw = mw_sctran (mw, "logical", "world", 3)
	ctwl = mw_sctran (mw, "world", "logical", 3)
	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    if (rec == NULL)
	        next
	    if ((IS_INDEFD(XYM_X(rec))||IS_INDEFD(XYM_Y(rec))) &&
		(IS_INDEFD(XYM_RA(rec))||IS_INDEFD(XYM_DEC(rec))))
		next
	    if (IS_INDEFD(XYM_X(rec))||IS_INDEFD(XYM_Y(rec))) {
		XYM_RA(rec) = XYM_RA(rec) * 15D0
		call mw_c2trand (ctwl, XYM_RA(rec), XYM_DEC(rec),
		    XYM_X(rec), XYM_Y(rec))
	    } else if (IS_INDEFD(XYM_RA(rec))||IS_INDEFD(XYM_DEC(rec))) {
		call mw_c2trand (ctlw, XYM_X(rec), XYM_Y(rec),
		    XYM_RA(rec), XYM_DEC(rec))
	    } else
		XYM_RA(rec) = XYM_RA(rec) * 15D0
	    XYM_PTR(rec) = NULL
	}
	call mw_ctfree (ctlw)
	call mw_ctfree (ctwl)

	if (DEBUG > 0) {
	    do i = 1, CAT_NRECS(cat) {
		rec = CAT_REC(cat,i)
		if (rec == NULL)
		    next
		call printf ("%.2H %.1h %.2f %.2f\n")
		    call pargd (XYM_RA(rec))
		    call pargd (XYM_DEC(rec))
		    call pargd (XYM_X(rec))
		    call pargd (XYM_Y(rec))
	    }
	    call flush (STDOUT)
	}
end


procedure xym_match (cat1, cat2, ncats, isearch, rsearch, rstep, voteim,
	nim, nrefmax, sigma, match, xshift, yshift, theta, verbose)

pointer	cat1[ARB]		#I Image catalogs
pointer	cat2[ARB]		#I Reference catalogs
int	ncats			#I Number of catalogs
int	isearch			#I Search radius (pixels)
double	rsearch			#I Rotation search (rad)
double	rstep			#I Rotation step (rad)
char	voteim[ARB]		#I Vote imagename for output
int	nim			#I Maximum number of sources to use
int	nrefmax			#I Maximum number of reference regions
double	sigma			#I Convolution sigma (pix)
double	match			#I Matching distance (pix)
double	xshift, yshift		#O Shift (pixels)
double	theta			#O Rotation (rad)
bool	verbose			#I Verbose?

int	i, j, nc, nl, nt, nwts, nreg, nim1
double	y2, r2, dsint
pointer	votes, im, convolve, wts, ptr

int	errget()
pointer	immap(), imps2s(), imps3s()
errchk	immap, imps2s, imps3s, xym_accum, xym_convolve

begin
	# Initialize the search bins and histogram.
	nc = 2 * isearch + 1
	nl = 2 * isearch + 1
	if (rstep > 0.) {
	    nt = nint (rsearch / rstep)
	    if (nt > 0)
		dsint = sin (rsearch) / nt
	    nt = 2 * nt + 1
	} else
	    nt = 1

	# Do search if needed.
	if (nc > 1 || nl > 1 || nt > 1) {
	    if (voteim[1] == EOS)
		call malloc (votes, nc*nl*nt, TY_SHORT)
	    else {
		im = immap (voteim, NEW_IMAGE, 0)
		IM_PIXTYPE(im) = TY_SHORT
		IM_LEN(im,1) = nc
		IM_LEN(im,2) = nl
		if (nt == 1) {
		    IM_NDIM(im) = 2
		    votes = imps2s (im, 1, nc, 1, nl)
		} else {
		    IM_NDIM(im) = 3
		    IM_LEN(im,3) = nt
		    votes = imps3s (im, 1, nc, 1, nl, 1, nt)
		}
	    }
	    call aclrs (Mems[votes], nc*nl*nt)
	    nreg = 0

	    # Accumulate the vote array over all the catalogs.
	    # Sort image catalog by Y and reference catalog by magnitude.

	    do i = 1, ncats {
	        nim1 = min (nim, CAT_NRECS(cat1[i]))
		if (nim1 < CAT_NRECS(cat1[i]))
		    call catsort (cat1[i], CAT_REC(cat1[i],1),
		        CAT_NRECS(cat1[i]), ID_MAG, 1)
		call catsort (cat1[i], CAT_REC(cat1[i],1), nim1, ID_Y, 1)
		call catsort (cat2[i], CAT_REC(cat2[i],1), CAT_NRECS(cat2[i]),
		    ID_MAG, 1)

		call xym_accum (cat1[i], CAT_REC(cat1[i],1), nim1,
		    CAT_REC(cat2[i],1), CAT_NRECS(cat2[i]),
		    Mems[votes], nc, nl, nt, dsint, nrefmax, nreg)

		# Resort the full source catalog if needed.
		if (nim1 < CAT_NRECS(cat1[i]))
		    call catsort (cat1[i], CAT_REC(cat1[i],1),
		        CAT_NRECS(cat1[i]), ID_Y, 1)
	    }

	    # Convolve the vote array if desired.
	    nwts = 2 * nint (2 * sigma) + 1
	    if (nwts > 1) {
		call calloc (convolve, nc*nl*nt, TY_DOUBLE)
		call calloc (wts, nwts*nwts, TY_DOUBLE)
		ptr = wts
		do j = 1, nwts {
		    y2 = ((j - (nwts+1)/2) / sigma) ** 2
		    do i = 1, nwts {
			r2 = y2 + ((i - (nwts+1)/2) / sigma) ** 2
			if (r2 <= 4.)
			    Memd[ptr] = exp (-0.5 * r2)
			ptr = ptr + 1
		    }
		}
		call xym_convolve (Mems[votes], Memd[convolve], nc, nl, nt,
		    Memd[wts], nwts, nwts)
		call achtds (Memd[convolve], Mems[votes], nc*nl*nt)
		call mfree (convolve, TY_DOUBLE)
		call mfree (wts, TY_DOUBLE)
	    }

	    # Compute the coarse match from the vote array.
	    iferr (call xym_shift (Mems[votes], nc, nl, nt, dsint, nreg,
	        xshift, yshift, theta, verbose)) {
		call salloc (ptr, SZ_LINE, TY_CHAR)
		i = errget (Memc[ptr], SZ_LINE)
		if (im != NULL)
		    call imunmap (im)
		call error (i, Memc[ptr])
	    }
	} else {
	    xshift = 0.
	    yshift = 0.
	    theta = 0.
	    do i = 1, ncats
		call catsort (cat1[i], CAT_REC(cat1[i],1), CAT_NRECS(cat1[i]),
		    ID_Y, 1)
	}

	# Update the coordinates in the catalogs.
	do i = 1, ncats {
	    call xym_pixel (cat1[i], cat2[i], CAT_REC(cat1[i],1),
	        CAT_NRECS(cat1[i]), CAT_REC(cat2[i],1), CAT_NRECS(cat2[i]),
		xshift, yshift, theta, match, verbose)
	}

	if (im == NULL)
	    call mfree (votes, TY_SHORT)
	else
	    call imunmap (im)
	
#	do j = 1, CAT_NRECS(cat2) {
#	    k = xym_search (CAT_REC(cat1,1), CAT_NRECS(cat),
#	        XYM_Y(CAT_REC(cat2,j)))
#
#	    do i = k, CAT_NRECS(cat1) {
#	        rec = CAT_REC(cat1,i)
#
#	    if (DEBUG > 0) {
#		call printf ("%3d %6.2f : ")
#		    call pargi (j)
#		    call pargd (XYM_Y(CAT_REC(cat2,j)))
#		if (i > 1) {
#		    call printf ("%3d %6.2f")
#			call pargi (i-1)
#			call pargd (XYM_Y(CAT_REC(cat1,i-1)))
#		} else
#		    call printf ("%10w")
#		call printf (" : %3d %6.2f\n")
#		    call pargi (i)
#		    call pargd (XYM_Y(CAT_REC(cat1,i)))
#		call flush (STDOUT)
#	    }
#	}
end


# XYM_ACCUM -- Accumulate vote array.
#
# The votes array and number of regions must be initialized externally.
# This routine assumes the image records are sorted by y.

procedure xym_accum (cat, rec, nrec, ref, nref, votes, nc, nl, nt, dsint,
	nrefmax, nreg)

pointer	cat				#I Image catalog
pointer	rec[ARB]			#I Image catalog records
int	nrec				#I Number of image records
pointer	ref[ARB]			#I Reference catalog records
int	nref				#I Number of reference records
short	votes[nc,nl, nt]		#U Vote array
int	nc, nl, nt			#I Vote array dimensions
double	dsint				#I Step in sin(theta)
int	nrefmax				#I Maximum number of regions to use
int	nreg				#U Number of regions

int	i, j, k, l, m
double	isearch, crpix1, crpix2, crmin1, crmax1, crmin2, crmax2
double	x1, y1, x2, y2, dx, dy, sint, cost
pointer	hdr

int	xym_search()
double	imgetd()

begin
	isearch = (min(nc,nl) - 1) / 2.

	hdr = CAT_HDR(cat)
	crpix1 = imgetd (hdr, "crpix1")
	crpix2 = imgetd (hdr, "crpix2")
	crmin1 = imgetd (hdr, "crmin1")
	crmax1 = imgetd (hdr, "crmax1")
	crmin2 = imgetd (hdr, "crmin2")
	crmax2 = imgetd (hdr, "crmax2")

	# Accumulate data.
	do l = 1, nref {
	    x2 = XYM_X(ref[l])
	    y2 = XYM_Y(ref[l])
	    if (x2 - isearch < crmin1 || x2 + isearch > crmax1)
		next
	    if (y2 - isearch < crmin2 || y2 + isearch > crmax2)
		next

	    do k = 1, nt {
		#if (k == nt / 2 + 1) {
		if (k == nt + 1) {
		    i = xym_search (rec, nrec, y2-isearch)
		    do m = i, nrec {
			x1 = XYM_X(rec[m])
			if (abs (x2-x1) > isearch)
			    next
			y1 = XYM_Y(rec[m])
			if (y1-y2 > isearch)
			    break
			i = nint (x2 - x1) + isearch + 1
			j = nint (y2 - y1) + isearch + 1
			votes[i,j,k] = votes[i,j,k] + 1
		    }
		} else {
		    sint = (k - 1 - (nt - 1) / 2.) * dsint
		    cost = sqrt (1. - sint * sint)

		    dx = (x2 - crpix1)
		    if (dx < 0)
			dx = dx - isearch
		    else
			dx = dx + isearch
		    dx = dx * sint
		    i = xym_search (rec, nrec, y2+dx-isearch)
		    do m = i, nrec {
			dx = XYM_X(rec[m]) - crpix1
			dy = XYM_Y(rec[m]) - crpix2
			x1 = dx * cost - dy * sint + crpix1
			y1 = dx * sint + dy * cost + crpix2
			if (abs (x2-x1) > isearch)
			    next
			if (y1-y2 > isearch)
			    break
			if (y1-y2 < -isearch)
			    next
			i = nint (x2 - x1) + isearch + 1
			j = nint (y2 - y1) + isearch + 1
			votes[i,j,k] = votes[i,j,k] + 1
		    }
		}
		nreg = nreg + 1
	    }
	    if (nint (real(nreg) / nt) >= nrefmax)
	        break
	}
	nreg = nint (real(nreg) / nt)
end

procedure xym_shift (votes, nc, nl, nt, dsint, nreg, xshift, yshift,
	theta, verbose)

short	votes[nc,nl,nt]			#I Vote array
int	nc, nl, nt			#I Vote array dimensions
double	dsint				#I Rotation step
int	nreg				#I Number of reference regions
double	xshift, yshift			#O Shift (pixels)
double	theta				#O Rotation (deg)
bool	verbose				#I Verbose?

int	i, j, k, maxval
double	sum, val, sint

begin
	# Find centroid above half the votes.
	maxval = nreg / 2
	xshift = 0
	yshift = 0
	theta = 0
	sum = 0
	do k = 1, nt {
	    sint = (k - 1 - (nt - 1) / 2.) * dsint
	    do j = 1, nl {
		do i = 1, nc {
		    val = votes[i,j,k] - maxval
		    if (val <= 0.)
			next
		    xshift = xshift + i * val
		    yshift = yshift + j * val
		    theta = theta + sint * val
		    sum = sum + val
		}
	    }
	}
	if (sum == 0)
	   call error (1, "Automatic search failed")

	xshift = xshift / sum - nc/2 - 1
	yshift = yshift / sum - nl/2 - 1
	theta = asin (theta / sum)

	if (verbose) {
	    call printf ("    search found offsets of (%.1f, %.1f) pixels")
		call pargd (xshift)
		call pargd (yshift)
	    call printf (" and rotation %.2f degrees\n")
	        call pargd (RADTODEG(theta))
	}
end


# XYM_PIXEL -- Correct reference pixel coordinates.

procedure xym_pixel (cat1, cat2, rec, nrec, ref, nref, xshift, yshift, theta,
	match, verbose)

pointer	cat1				#I Image catalog
pointer	cat2				#I Reference catalog
pointer	rec[ARB]			#I Image catalog records
int	nrec				#I Number of image records
pointer	ref[ARB]			#I Reference catalog records
int	nref				#I Number of reference records
double	xshift, yshift			#I Shift (pixels)
double	theta				#I Rotation (deg)
double	match				#I Matching distance (pix)
bool	verbose				#I Verbose?

int	i, j, j1, nref1
double	crpix1, crpix2, crmin1, crmax1, crmin2, crmax2, sint, cost
double	x, y, x1, y1, match2, r2, lastr2
pointer	hdr

double	imgetd()

begin
	hdr = CAT_HDR(cat1)
	crpix1 = imgetd (hdr, "crpix1")
	crpix2 = imgetd (hdr, "crpix2")
	crmin1 = imgetd (hdr, "crmin1")
	crmax1 = imgetd (hdr, "crmax1")
	crmin2 = imgetd (hdr, "crmin2")
	crmax2 = imgetd (hdr, "crmax2")

	sint = sin (-theta)
	cost = cos (-theta)

	do i = 1, nref {
	    x = XYM_X(ref[i])
	    y = XYM_Y(ref[i])
	    x = (x - crpix1) * cost - (y - crpix2) * sint + crpix1 - xshift
	    y = (x - crpix1) * sint + (y - crpix2) * cost + crpix2 - yshift
#	    if (x<crmin1 || x>crmax1 || y<crmin2 || y>crmax2)
#	        next
	    XYM_X(ref[i]) = x
	    XYM_Y(ref[i]) = y

	    if (DEBUG > 0) {
		call printf ("%.2f %.2f\n")
		    call pargd (x)
		    call pargd (y)
		call flush (STDOUT)
	    }
	}
	call catsort (cat2, ref, nref, ID_Y, 1)

	# Now match measured pixel positions with predicted reference positions.
	# Sort the catalogs by Y and then scroll in Y.

	match2 = match * match
	j1 = 1
	nref1 = 0
	do i = 1, nref {
	    lastr2 = MAX_DOUBLE
	    XYM_PTR(ref[i]) = NULL
	    x = XYM_X(ref[i])
	    y = XYM_Y(ref[i])
	    if (x<crmin1 || x>crmax1 || y<crmin2 || y>crmax2)
	        next
	    nref1 = nref1 + 1
	    do j = j1, nrec {
		x1 = XYM_X(rec[j])
		y1 = XYM_Y(rec[j])
		if (y1 < y - match) {
		    j1 = j + 1
		    next
		}
		if (y1 > y + match)
		    break
		r2 = (x - x1) * (x - x1) + (y - y1) * (y - y1)
		if (r2 > match2 || r2 > lastr2)
		    next
		#XYM_X(ref[i]) = x1
		#XYM_Y(ref[i]) = y1
		if (XYM_PTR(ref[i]) != NULL)
		    XYM_PTR(XYM_PTR(ref[i])) = NULL
		XYM_PTR(rec[j]) = ref[i]
		XYM_PTR(ref[i]) = rec[j]
		lastr2 = r2
	    }
	}

	# Compute statistics.
	j = 0
	do i = 1, nref
	    if (XYM_PTR(ref[i]) != NULL)
		j = j + 1
	if (verbose) {
	    call printf ("    %d/%d found\n")
	        call pargi (j)
#		call pargi (nref)
		call pargi (nref1)
	}

	if (DEBUG > 0) {
	    do i = 1, nrec {
		if (XYM_PTR(rec[i]) == NULL)
		    next
		call printf ("%7.2f %7.2f %.2H %.1h\n")
		    call pargd (XYM_X(rec[i]))
		    call pargd (XYM_Y(rec[i]))
		    call pargd (XYM_RA(XYM_PTR(rec[i])))
		    call pargd (XYM_DEC(XYM_PTR(rec[i])))
	    }
	    call flush (STDOUT)
	}
end


procedure xym_wcat (newcat, oldcat)

pointer	newcat				#I New catalog
pointer	oldcat				#I Old catalog

int	i, j
pointer	oldrec, newrec
errchk	catwrec, catcreate

begin
	# Create the new catalog.
	call catcreate (newcat)

	# Copy the old catalog header to the new catalog.
	call im2im (CAT_HDR(oldcat), CAT_HDR(newcat))

	# Write the matched records.
	j = 0
	do i = 1, CAT_NRECS(oldcat) {
	    oldrec = CAT_REC(oldcat,i)
	    newrec = XYM_PTR(oldrec)
	    if (newrec == NULL)
		next
	    j = j + 1
	    #XYM_RA(newrec) = XYM_RA(oldrec) / 15.
	    #XYM_DEC(newrec) = XYM_DEC(oldrec)
	    #XYM_MAG(newrec) = XYM_MAG(oldrec)
	    XYM_RA(newrec) = XYM_RA(newrec) / 15.
	    XYM_X(newrec) = XYM_X(oldrec)
	    XYM_Y(newrec) = XYM_Y(oldrec)
	    call catwrec (newcat, newrec, j)
	}
end


# XYM_SEARCH -- Find the index of the record that is >= to the specified value.
# This requires the records to be sorted in Y.

int procedure xym_search (rec, nrec, val)

pointer	rec[ARB]			#I Records
int	nrec				#I Number of records
double	val				#I Value to find

int	i, i1, i2, di, n
double	v, v1, v2, dv
begin
	n = nrec
	i1 = 1
	do i2 = n, i1, -1
	    if (!IS_INDEFD(XYM_Y(rec[i2])))
	        break
	if (i2 < i1)
	    call error (1, "No Y values found in catalog")
	        
	n = i2
	v1 = XYM_Y(rec[i1])
	v2 = XYM_Y(rec[i2])
	if (val <= v1)
	    return (i1)
	if (val >= v2)
	    return (i2)

	repeat {
	    di = i2 - i1
	    if (di <= 1)
		return (i2)
	    dv = v2 - v1
	    if (dv == 0)
		return (i1)

	    i = nint (di / dv * (val - v1) + i1)
	    v = XYM_Y(rec[i])

	    if (v >= val) {
		i2 = i
		v2 = v
		di = 1
		for (i1=i2-1; i1 > 0; i1=i1-di) {
		    v1 = XYM_Y(rec[i1])
		    if (v1 == val)
		        return (i1)
		    if (v1 < val)
		        break
		    v2 = v1
		    i2 = i1
		    di = 2 * di
		}
		if (i1 < 1)
		    i1 = 1
	    } else {
		i1 = i
		v1 = v
		di = 1
		for (i2=i1+1; i2 <= n; i2=i2+di) {
		    v2 = XYM_Y(rec[i2])
		    if (v2 == val)
		       return (i2)
		    if (v2 > val)
		        break
		    v1 = v2
		    i1 = i2
		    di = 2 * di
		}
		if (i2 > n)
		    i2 = n
	    }
	}
end


# XYM_CONVOLVE -- Convolve input vote array using specified weights.
# This version leaves a region of zero votes around the edge.

procedure xym_convolve (input, output, nc, nl, nt, wts, nx, ny)

short	input[nc,nl,nt]			#I Vote array
double	output[nc,nl,nt]		#O Convolved vote array
int	nc, nl, nt			#I Vote array dimensions
double	wts[nx,ny]			#I Convolutions weights
int	nx, ny				#I Weight dimensions

int	i, j, k, ii, jj, i1, i2, j1, j2, nx2, ny2, dx, dy
double	wt
errchk	xym_convolve1

begin
	nx2 = (nx - 1) / 2
	ny2 = (ny - 1) / 2
	i1 = 1 + nx2
	i2 = nc - nx2
	j1 = 1 + ny2
	j2 = nl - ny2
	do k = 1, nt {
	    do dy = -ny2, ny2 {
		do dx = -nx2, nx2 {
		    wt = wts[i1+dx,j1+dy]
		    if (wt == 0D0)
		        next
		    do j = j1, j2 {
		        jj = j + dy
			do i = i1, i2 {
			   ii = i + dx
			    output[i,j,k] = output[i,j,k] +
			        wt * input[ii,jj,k]
			}
		    }
		}
	    }
	}
end
