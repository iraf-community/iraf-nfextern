include	<error.h>
include	<fset.h>
include	<mach.h>
include	<math.h>
include	<imhdr.h>
include	<acecat.h>
include	"acematch.h"

define	STRUCTDEF	"acesrc$acematch.h"
define	DEBUG		0
define	SZ_CMD		(4*SZ_LINE)
define	MINBOX		75		# Minimum pixel box
define	NSEARCH		3		# Number of search iterations
define	NVER		3		# Used for updating WCS


# T_ACEMATCH -- Match source and reference catalogs.

procedure t_acematch ()

int	icats			# List of image catalogs
pointer	icatdef			# Image catalog definitions
int	wcs			# List of image catalog WCS
pointer	ifilter			# Image catalog filter
int	rcats			# List of reference catalogs
pointer	rcatdef			# Reference catalog definitions
pointer	rfilter			# Reference catalog filter
int	mcats			# List of output matched catalogs
bool	all			# All mode?
double	search			# Maximum search radius (arcsec)
double	rsearch			# Maximum rotation search (deg)
double	rstep			# Rotation step (deg)
pointer	hists			# List of histogram images
double	nmin			# Minimum number of sources
int	nim			# Maximum catalog objects for search
int	nref			# Maximum reference objects for search
double	fwhm			# FWHM for convolution (arcsec)
double	match			# Matching distance (arcsec)
double	fmatch			# Minimum matching fraction
double	xi, eta			# Shift (arcsec)
double	theta			# Rotation (deg)
pointer	logs			# Logfiles
bool	verbose			# Verbose output?
int	erraction		# Error action

int	i, j, k, nalloc, ncats, nsources, ival
double	scale, psigma, pmatch, dval
pointer	sp, icat, iwcs, rcat, mcat, mcat1, histim, logfd, str
pointer	icats1, mcats1, cat1, cat2, mws, mwa, im, newcat, ptr

bool	clgetb(), streq()
int	clgeti(), imgeti(), clgwrd(), nowhite(), open()
int	xt_extns(), catacc(), imaccess()
int	afn_cl(), afn_opn(), afn_opno(), afn_len(), afn_gfn(), afn_rfn()
double	clgetd(), imgetd()
pointer	immap()
errchk	catopen, immap, acm_mw, acm_gcat, acm_match, acm_wcat, acm_phot, open

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
	call salloc (mcat1, SZ_FNAME, TY_CHAR)
	call salloc (histim, SZ_FNAME, TY_CHAR)
	call salloc (logfd, 2, TY_INT)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get task parameters.
	all = clgetb ("all")
	if (all) {
	    call clgstr ("imcats", Memc[str], SZ_LINE)
	    ptr = xt_extns (Memc[str],"","","","",NO,YES,NO,NO,"",NO,i)
	    icats = afn_opno (ptr, "catalog")
	} else
	    icats = afn_cl ("imcats", "catalog", NULL)
	call clgstr ("imcatdef", Memc[icatdef], SZ_LINE)
	wcs = afn_cl ("imwcs", "image", icats)
	call clgstr ("imfilter", Memc[ifilter], SZ_LINE)
	rcats = afn_cl ("refcats", "catalog", icats)
	call clgstr ("refcatdef", Memc[rcatdef], SZ_LINE)
	call clgstr ("reffilter", Memc[rfilter], SZ_LINE)
	mcats = afn_cl ("matchcats", "catalog", icats)
	search = clgetd ("search")
	rsearch = clgetd ("rsearch")
	rstep = clgetd ("rstep")
	hists = afn_cl ("histimages", "image", NULL)
	nmin = clgetd ("nmin")
	nim = clgeti ("nim")
	nref = clgeti ("nref")
	fwhm = clgetd ("fwhm")
	match = clgetd ("match")
	fmatch = clgetd ("fracmatch")
	xi = clgetd ("xi")
	eta = clgetd ("eta")
	theta = clgetd ("theta")
	erraction = clgwrd ("erraction", Memc[str], SZ_LINE, "|abort|warn|")
	logs = afn_cl ("logfiles", "file", NULL)
	verbose = clgetb ("verbose")

	switch (erraction) {
	case 2:
	    erraction = EA_WARN
	default:
	    erraction = EA_ERROR
	}

	# Set logfiles.
	call aclri (Memi[logfd], 2)
	if (verbose) {
	    Memi[logfd] = open ("STDOUT", APPEND, TEXT_FILE)
	    call fseti (Memi[logfd], F_FLUSHNL, YES)
	    call sysid (Memc[str], SZ_LINE)
	    call fprintf (Memi[logfd], "ACEMATCH: %s\n")
		call pargstr (Memc[str])
	}

	rsearch = DEGTORAD(rsearch)
	rstep = DEGTORAD(rstep)
	i = nowhite (Memc[histim], Memc[histim], SZ_FNAME)

	# Check lists.
	ncats = afn_len (icats)
	i = afn_len (rcats)
	if (i != ncats && i != 1)
	    call error (1,
	        "Reference catalog list doesn't match image catalog list")
	i = afn_len (wcs)
	if (i != ncats && i > 1)
	    call error (1, "WCS list doesn't match image catalog list")
	i = afn_len (mcats)
	if (i != ncats && i > 0)
	    call error (1,
	         "Matched catalog list doesn't match image catalog list")

	# Loop through list.  Note that a catalog file may still expand
	# to multiple extensions.

	nalloc = 0; icats1 = NULL; mcats1 = NULL
	cat1 = NULL; cat2 = NULL; mws = NULL
	for (k=1; afn_rfn(icats,k,Memc[icat],SZ_FNAME)!=EOF; k=k+1) {
	    iferr {
		# Set associated files.
		if (afn_rfn (mcats, k, Memc[mcat], SZ_FNAME) == EOF)
		    Memc[mcat] = EOS
		call strcpy (Memc[mcat], Memc[mcat1], SZ_FNAME)
		if (afn_rfn (hists, k, Memc[histim], SZ_FNAME) == EOF)
		    Memc[histim] = EOS
		else
		    j = nowhite (Memc[histim], Memc[histim], SZ_FNAME)
		if (afn_rfn (logs, k, Memc[str], SZ_LINE) != EOF) {
		    if (Memi[logfd+1] != NULL)
		        call close (Memi[logfd+1])
		    Memi[logfd+1] = open (Memc[str], APPEND, TEXT_FILE)
		    call sysid (Memc[str], SZ_LINE)
		    call fprintf (Memi[logfd+1], "ACEMATCH: %s\n")
			call pargstr (Memc[str])
		}

		# Determine number of catalogs to do together.
		if (all) {
		    icats1 = icats
		    mcats1 = mcats
		    ncats = afn_len (icats1)
		} else {
		    ptr = xt_extns (Memc[icat], "", "", "", "",
		        NO, YES, NO, NO, "", NO, i)
		    if (i == 0) {
			icats1 = icats
			mcats1 = mcats
			ncats = 1
		    } else {
			icats1 = afn_opno (ptr, "catalog")
			if (Memc[mcat] != EOS)
			    mcats1 = afn_opn (Memc[mcat], "catalog", icats1)
			ncats = afn_len (icats1)
			i = afn_gfn (icats1, Memc[icat], SZ_FNAME)
		    }
		}

		# Check output so that we don't spend a lot of time only
		# to find the output can't be written.
		Memc[mcat1] = EOS
		if (Memc[mcat] != EOS) {
		    if (afn_rfn (mcats1, 1, Memc[mcat1], SZ_FNAME) != EOF) {
			if (catacc (Memc[mcat1], NEW_FILE) == YES) {
			    call sprintf (Memc[str], SZ_LINE,
				"Matched catalog already exists (%s)")
				call pargstr (Memc[mcat1])
			    call error (1, Memc[str])
			}
		    }
		}

		if (nalloc == 0) {
		    nalloc = ncats
		    call malloc (cat1, nalloc, TY_POINTER)
		    call malloc (cat2, nalloc, TY_POINTER)
		    call malloc (mws, nalloc, TY_POINTER)
		} else if (ncats > nalloc) {
		    nalloc = ncats
		    call realloc (cat1, nalloc, TY_POINTER)
		    call realloc (cat2, nalloc, TY_POINTER)
		    call realloc (mws, nalloc, TY_POINTER)
		}

		# Initialize.
		call aclri (Memi[cat1], ncats)
		call aclri (Memi[cat2], ncats)
		call aclri (Memi[mws], ncats)
		Memc[iwcs] = EOS; Memc[rcat] = EOS

	        nsources = 0; scale = 0
		do i = 0, ncats-1 {
		    if (i > 0)
			j = afn_gfn (icats1, Memc[icat], SZ_FNAME)
		    if (afn_gfn (wcs, Memc[str], SZ_LINE) != EOF)
			j = nowhite (Memc[str], Memc[iwcs], SZ_FNAME)
		    if (afn_gfn (rcats, Memc[str], SZ_LINE) != EOF)
			call strcpy (Memc[str], Memc[rcat], SZ_FNAME)

		    if (Memc[iwcs] == EOS || streq (Memc[iwcs], Memc[icat])) {
			call catopen (Memi[cat1+i], Memc[icat], "",
			    Memc[icatdef], STRUCTDEF, NULL, 1)
			call catputs (Memi[cat1+i], "catalog", Memc[icat])
			im = CAT_IHDR(Memi[cat1+i])
			call acm_mw (im, Memi[mws+i], mwa, psigma)
		    } else {
			im = immap (Memc[iwcs], READ_ONLY, 0)
			call acm_mw (im, Memi[mws+i], mwa, psigma)
			call imunmap (im)
		    }
		    scale = scale + psigma
		
		    do j = 1, 2 {
		        if (Memi[logfd+j-1] == NULL)
			    next
			call fprintf (Memi[logfd+j-1], "  match %s and %s\n")
			    call pargstr (Memc[icat])
			    call pargstr (Memc[rcat])
		    }
		    call acm_gcat (Memc[icat], Memc[icatdef],
			Memc[ifilter], Memi[mws+i], Memi[cat1+i], Memi[logfd])
		    call acm_gcat (Memc[rcat], Memc[rcatdef],
			Memc[rfilter], Memi[mws+i], Memi[cat2+i], Memi[logfd])
		    call mw_close (mwa)
		    nsources = nsources + CAT_NRECS(Memi[cat1+i])
		}
		if (icats1 != icats)
		    call afn_cls (icats1)
		scale = scale / ncats

		if (nsources < nmin) {
		    call sprintf (Memc[str], SZ_LINE,
		        "Number of detections to low (%d < %d)")
			call pargi (nsources)
			call pargd (nmin)
		    call error (1, Memc[str])
		}

		psigma = (fwhm / scale) / sqrt (2. * log (2.))
		pmatch = match / scale

		# Match the coordinates.
		call acm_match (Memi[mws], Memi[cat1], Memi[cat2], ncats,
		    scale, search, rsearch, rstep, xi, eta, theta,
		    Memc[histim], nim, nref, nmin, psigma, pmatch, fmatch,
		    Memi[logfd])

		call clputd ("xi", xi)
		call clputd ("eta", eta)
		call clputd ("theta", theta)

		# Do photometry.
		call acm_phot (Memi[cat1], ncats, Memi[logfd])

		# Write matched output catalog.
		# Create multiextension output if needed.
		if (Memc[mcat] != EOS) {
		    do i = 1, ncats {
			if (mcats1 != mcats) {
			    if (afn_rfn (mcats1, i, Memc[mcat1], SZ_FNAME) == EOF)
				next
			} else
			    call strcpy (Memc[mcat], Memc[mcat1], SZ_FNAME)
			do j = 1, 2 {
			    if (Memi[logfd+j-1] == NULL)
				next
			    call fprintf (Memi[logfd+j-1], "  write %s\n")
				call pargstr (Memc[mcat1])
			}
			call catopen (newcat, "", Memc[mcat1], "",
			    STRUCTDEF, NULL, 1)
			call acm_wcat (newcat, Memi[cat1+i-1])
			call catclose (newcat, NO)

			im = CAT_IHDR(Memi[cat1+i-1])
			ifnoerr (call imgstr (im,"image",Memc[str],SZ_FNAME)) {
			    if (imaccess (Memc[str], READ_WRITE) == YES) {
			        ptr = immap (Memc[str], READ_WRITE, 0)
				call imastr (ptr, "mcatalog", Memc[mcat1])
				ifnoerr (dval = imgetd (im, "MAGZERO1"))
				    call imaddd (ptr, "MAGZERO1", dval)
				ifnoerr (dval = imgetd (im, "MAGZSIG1"))
				    call imaddd (ptr, "MAGZSIG1", dval)
				ifnoerr (dval = imgetd (im, "MAGZERR1"))
				    call imaddd (ptr, "MAGZERR1", dval)
				ifnoerr (ival = imgeti (im, "MAGZNAV1"))
				    call imaddi (ptr, "MAGZNAV1", ival)
				ifnoerr (dval = imgetd (im, "MAGZERO"))
				    call imaddd (ptr, "MAGZERO", dval)
				ifnoerr (dval = imgetd (im, "MAGZSIG"))
				    call imaddd (ptr, "MAGZSIG", dval)
				ifnoerr (dval = imgetd (im, "MAGZERR"))
				    call imaddd (ptr, "MAGZERR", dval)
				ifnoerr (ival = imgeti (im, "MAGZNAV"))
				    call imaddi (ptr, "MAGZNAV", ival)
				call imunmap (ptr)
			    }
			}
		    }
		    if (mcats1 != mcats)
			call afn_cls (mcats1)
		}
	    } then
	        call erract (erraction)

	    # Free data structures.
	    do i = 0, ncats-1 {
		if (cat2 != NULL) {
		    if (Memi[cat2+i] != NULL)
			call catclose (Memi[cat2+i], NO)
		}
		if (cat1 != NULL) {
		    if (Memi[cat1+i] != NULL)
			call catclose (Memi[cat1+i], NO)
		}
		if (mws != NULL) {
		    if (Memi[mws+i] != NULL)
			call mw_close (Memi[mws+i])
		}
	    }
	}

	do i = 1, 2 {
	    if (Memi[logfd+i-1] != NULL)
		call close (Memi[logfd+i-1])
	}
	call mfree (cat1, TY_POINTER)
	call mfree (cat2, TY_POINTER)
	call mfree (mws, TY_POINTER)
	call afn_cls (logs)
	if (mcats1 != NULL && mcats1 != mcats)
	    call afn_cls (mcats1)
	call afn_cls (mcats)
	call afn_cls (rcats)
	call afn_cls (wcs)
	if (icats1 != NULL && icats1 != icats)
	    call afn_cls (icats1)
	call afn_cls (icats)
	call sfree (sp)
end


procedure acm_mw (im, mw, mwa, scale)

pointer	im				#I Image header for WCS
pointer	mw				#O MWCS
pointer	mwa				#O MWCS for astrometry coordinates
double	scale				#O Scale (arcsec/pix)

int	axes[2]
double	x, r[2], w[2], cd[2,2]
pointer	sp, str

bool	streq()
pointer	mw_openim(), mw_open()
errchk	mw_openim()

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

#	    call mw_saveim (mw, im)
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


procedure acm_gcat (catname, catdef, catfilter, mw, cat, logfd)

char	catname[ARB]			#I Catalog name
char	catdef[ARB]			#I Catalog definitions
char	catfilter[ARB]			#I Catalog filter
pointer	mw				#I MWCS
pointer	cat				#U Catalog pointer
int	logfd[2]			#I Log file descriptors

int	i
pointer	ctlw, ctwl, rec

pointer	mw_sctran()
errchk	mw_sctran
errchk	catopen, catrrecs

begin
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
	    if ((IS_INDEFD(ACM_X(rec))||IS_INDEFD(ACM_Y(rec))) &&
		(IS_INDEFD(ACM_RA(rec))||IS_INDEFD(ACM_DEC(rec))))
		next
	    if (IS_INDEFD(ACM_X(rec))||IS_INDEFD(ACM_Y(rec))) {
		call mw_c2trand (ctwl, ACM_RA(rec)*15D0, ACM_DEC(rec),
		    ACM_X(rec), ACM_Y(rec))
	    } else if (IS_INDEFD(ACM_RA(rec))||IS_INDEFD(ACM_DEC(rec))) {
		call mw_c2trand (ctlw, ACM_X(rec), ACM_Y(rec),
		    ACM_RA(rec), ACM_DEC(rec))
		ACM_RA(rec) = ACM_RA(rec) / 15D0
	    }
	    if (ACM_FLAGS(rec) != EOS) {
	        if (ACM_BP(rec) == 'B')
		    call strcpy ("S", ACM_FLAGS(rec), ARB)
		else
		    call strcpy ("-", ACM_FLAGS(rec), ARB)
	    } else
		call strcpy ("-", ACM_FLAGS(rec), ARB)
	    ACM_PTR(rec) = NULL
	}
	call mw_ctfree (ctlw)
	call mw_ctfree (ctwl)
end


# ACM_MATCH -- Match reference and source catalogs.

procedure acm_match (mws, cat1, cat2, ncats, scale, search, rsearch, rstep,
	xi, eta, theta, voteim, nim, nrefmax, nmin, sigma, match, fmatch, logfd)

pointer	mws[ARB]		#I MWCS pointers
pointer	cat1[ARB]		#I Image catalogs
pointer	cat2[ARB]		#I Reference catalogs
int	ncats			#I Number of catalogs
double	scale			#I Scale (arcsec/pixel)
double	search			#I Search radius (pixels)
double	rsearch			#I Rotation search (rad)
double	rstep			#I Rotation step (rad)
double	xi, eta			#U Shift (arcsec)
double	theta			#U Rotation (deg)
char	voteim[ARB]		#I Vote imagename for output
int	nim			#I Maximum number of sources to use
int	nrefmax			#I Maximum number of reference regions
double	nmin			#I Minumum number of sources
double	sigma			#I Convolution sigma (pix)
double	match			#I Matching distance (pix)
double	fmatch			#I Minimum matching fraction
int	logfd[2]		#I Log file descriptors

int	i, j, k, l, m, mm, n, nc, nl, nt, nwts, errno
int	nsearch, isearch, irsearch, nreg, nim1, ndetect, nmatch, nrefmatch
double	xi1, eta1, theta1, y2, r2, dsint
pointer	sp, votes, im, convolve, wts, errstr, ptr

int	errget(), imaccess()
pointer	immap(), imps2s(), imps3s()
errchk	immap, imdelete, imps2s, imps3s
errchk	acm_accum, acm_convolve, acm_ftp, acm_pixel, acm_crval
errchk	calloc, malloc

define	revote_	10

begin
	call smark (sp)
	errstr = NULL

	call acm_crval (mws[1], cat2[1], ncats, xi, eta, theta, 0, logfd)

	nsearch = search / scale / ((MINBOX + 1.) / 2.)
	do m = 1, nsearch {
	    votes = NULL; im = NULL; errno = 0; mm = 0
	    iferr {
revote_
		# Initialize the search bins and histogram.
		isearch = m * nint (search / scale / nsearch)
		nc = 2 * isearch + 1
		nl = 2 * isearch + 1
		if (rstep > 0.) {
		#    if (nsearch > 1)
		#	irsearch = (m - 1) * nint (rsearch / rstep /
		#	    (nsearch - 1))
		#    else
			irsearch = m * nint (rsearch / rstep / nsearch)
		    if (irsearch > 0)
			dsint = sin (rsearch) / nint (rsearch / rstep)
		    nt = 2 * irsearch + 1
		} else
		    nt = 1
		n = nc * nl * nt

		do i = 1, 2 {
		    if (logfd[i] == NULL)
		        next
		    if (nt > 1) {
			call fprintf (logfd[i],
			    "  Search %.5g arcsec and %.5g deg ...\n")
			    call pargd (scale * isearch)
			    call pargd (RADTODEG(rstep*irsearch))
		    } else {
			call fprintf (logfd[i],
			    "  Search %.5g arcsec ...\n")
			    call pargd (scale * isearch)
		    }
		}

		# Do search if needed.
		if (n > 1) {
		    if (voteim[1] == EOS)
			call malloc (votes, n, TY_SHORT)
		    else {
			if (imaccess (voteim, 0) == YES)
			    call imdelete (voteim)
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
		    call aclrs (Mems[votes], n)
		    nreg = 0

		    # Accumulate the vote array over all the catalogs.
		    # Sort image catalog by Y and reference catalog by mag.

		    do i = 1, ncats {
			nim1 = min (nim, CAT_NRECS(cat1[i]))
			if (nim1 < CAT_NRECS(cat1[i]))
			    call catsort (cat1[i], CAT_REC(cat1[i],1),
				CAT_NRECS(cat1[i]), ID_MAG, 1)
			call catsort (cat1[i], CAT_REC(cat1[i],1), nim1,
			    ID_Y, 1)
			call catsort (cat2[i], CAT_REC(cat2[i],1),
			    CAT_NRECS(cat2[i]), ID_MREF, 1)

			call acm_accum (mws[i], cat1[i], CAT_REC(cat1[i],1),
			    nim1, CAT_REC(cat2[i],1), CAT_NRECS(cat2[i]),
			    Mems[votes], scale, search, nc, nl, nt, dsint,
			    nrefmax, nreg)

			# Resort the full source catalog if needed.
			if (nim1 < CAT_NRECS(cat1[i]))
			    call catsort (cat1[i], CAT_REC(cat1[i],1),
				CAT_NRECS(cat1[i]), ID_Y, 1)
		    }

		    # Convolve the vote array if desired.
		    nwts = 2 * nint (2 * sigma) + 1
		    if (nwts > 1) {
			iferr {
			    call calloc (convolve, nc*nl*nt, TY_REAL)
			    call calloc (wts, nwts*nwts, TY_REAL)
			    ptr = wts
			    do j = 1, nwts {
				y2 = ((j - (nwts+1)/2) / sigma) ** 2
				do i = 1, nwts {
				    r2 = y2 + ((i - (nwts+1)/2) / sigma) ** 2
				    if (r2 <= 4.)
					Memr[ptr] = exp (-0.5 * r2)
				    ptr = ptr + 1
				}
			    }
			    call acm_convolve (Mems[votes], Memr[convolve],
				nc, nl, nt, Memr[wts], nwts, nwts)
			    call achtrs (Memr[convolve], Mems[votes], nc*nl*nt)
			} then
			    ;
			call mfree (convolve, TY_REAL)
			call mfree (wts, TY_REAL)
		    }

		    # Find the tangent point from the vote array.
		    call acm_ftp (Mems[votes], nc, nl, nt, dsint, nreg,
			scale, xi1, eta1, theta1, logfd)

		    if (im == NULL)
			call mfree (votes, TY_SHORT)
		    else {
			call imunmap (im)
			votes = NULL
		    }
		} else {
		    xi1 = 0.
		    eta1 = 0.
		    theta1 = 0.
		    do i = 1, ncats
			call catsort (cat1[i], CAT_REC(cat1[i],1),
			    CAT_NRECS(cat1[i]), ID_Y, 1)
		}

		# Adjust tangent point and recompute reference pixel coords.
		call acm_crval (mws, cat2, ncats, xi1, eta1, theta1, 1, logfd)

		# Check for large shift.
		if (sqrt ((xi1-xi)**2+(eta1-eta)**2) / scale > isearch) {
		    #m = 1
		    mm = mm + 1
		    if (mm > 1)
			goto revote_
		}

		# Match the reference and source catalogs.
		ndetect = 0
		nmatch = 0
		nrefmatch = 0
		do i = 1, ncats {
		    iferr (call acm_pixel (mws[i], cat1[i], cat2[i],
		        CAT_REC(cat1[i],1), CAT_NRECS(cat1[i]),
			CAT_REC(cat2[i],1), CAT_NRECS(cat2[i]),
			match, j, k, l, fmatch, logfd)) {
			    # Undo the WCS update.
			    call acm_crval (mws, cat2, ncats, xi1, eta1,
				theta1, 2, logfd)
			    call error (1, "Matching fraction too low")
		    }
		    nmatch = nmatch + j
		    ndetect = ndetect + k
		    nrefmatch = nrefmatch + l
		}

		do i = 1, 2 {
		    if (logfd[i] == NULL)
		        next
		    call fprintf (logfd[i],
		"    total matched %d out of %d detections and %d references\n")
			call pargi (nmatch)
			call pargi (ndetect)
			call pargi (nrefmatch)
		}

		# Check that number of detections is sufficient.
	        if (nmin < 1. && ndetect < nmin * nrefmatch)
		    call error (11,
		    "Number of detections relative to references is too low")
		else if (ndetect < nmin)
		    call error (11, "Number of detections is too low")

		# Require a minimum matching fraction.
		if (nrefmatch == 0)
		    y2 = 0.
		else
		    y2 = double (nmatch) /
		        double (max(10,min(ndetect/2,nrefmatch)))
		if (y2 < fmatch) {
		    # Undo the WCS update.
		    call acm_crval (mws, cat2, ncats, xi1, eta1, theta1, 2,
		        logfd)
		    call error (1, "Matching fraction too low")
		}
	    } then {
	        if (errstr == NULL)
		    call salloc (errstr, SZ_LINE, TY_CHAR)
		errno = errget (Memc[errstr], SZ_LINE)
		if (im == NULL)
		    call mfree (votes, TY_SHORT)
		else {
		    call imunmap (im)
		    votes = NULL
		}
	    }

	    # If there is no error or the error doesn't depend on the search
	    # radius we are done.

	    if (errno == 0 || n == 1 || errno > 11)
	        break
	}

	# Post an error if needed.
	if (errno > 0)
	    call error (errno, Memc[errstr])

	# Get and print final tangent point.
	call acm_crval (mws, cat2, ncats, xi, eta, theta, 3, logfd)

	call sfree (sp)
end


# ACM_ACCUM -- Accumulate tangent point vote array.
#
# The tangent point vote array and number of regions must be initialized
# externally.  This routine assumes the image records are sorted by y.

procedure acm_accum (mw, cat, rec, nrec, ref, nref, votes, scale, search,
	nc, nl, nt, dsint, nrefmax, nreg)

pointer	mw				#I MWCS
pointer	cat				#I Image catalog
pointer	rec[ARB]			#I Image catalog records
int	nrec				#I Number of image records
pointer	ref[ARB]			#I Reference catalog records
int	nref				#I Number of reference records
short	votes[nc,nl,nt]			#U Vote array
double	scale				#I Scale (arcsec/pixel)
double	search				#I Search (arcsec)
int	nc, nl, nt			#I Vote array dimensions
double	dsint				#I Step in sin(theta)
int	nrefmax				#I Maximum number of regions to use
int	nreg				#U Number of regions

int	i, j, k, l, m
double	isearch, crpix1, crpix2, crmin1, crmax1, crmin2, crmax2
double	ra, dec, xi, eta, theta, x1, y1, x2, y2, dx, dy, sint, cost
pointer	hdr, tp

int	acm_search()
double	imgetd()

begin
	# Set limits.
	hdr = CAT_IHDR(cat)
	crpix1 = imgetd (hdr, "crpix1")
	crpix2 = imgetd (hdr, "crpix2")
	crmin1 = imgetd (hdr, "crmin1")
	crmax1 = imgetd (hdr, "crmax1")
	crmin2 = imgetd (hdr, "crmin2")
	crmax2 = imgetd (hdr, "crmax2")

	# Retrieve current values.  This is for theta.
	call acm_crval (mw, cat, 1, xi, eta, theta, 4, NULL)

	# Accumulate data.
	isearch = (min(nc,nl) - 1) / 2.
	do l = 1, nref {

	    # Set reference source and exclude those near the edge of OOB.
	    x2 = ACM_X(ref[l]); y2 = ACM_Y(ref[l])
	    if (x2 + isearch < crmin1 || x2 - isearch > crmax1 ||
	        y2 + isearch < crmin2 || y2 - isearch > crmax2)
		next
	    ra = ACM_RA(ref[l]) * 15D0; dec = ACM_DEC(ref[l])

	    # Initialize tangent point evaluation at reference coordinate.
	    tp = NULL
	    call acm_tpinit (tp, mw, scale, search, ra, dec)

	    # Find observed sources near reference position and compute
	    # tangent point assuming observed is the reference.  Each
	    # tangent point becomes a vote in the tangent point array.

	    do k = 1, nt {
		sint = DEGTORAD(-theta) + (k - 1 - (nt - 1) / 2.) * dsint
		cost = sqrt (1. - sint * sint)

		dx = (x2 - crpix1)
		if (dx < 0)
		    dx = dx - isearch
		else
		    dx = dx + isearch
		dx = dx * sint
		i = acm_search (rec, nrec, y2+dx-isearch)
		do m = i, nrec {
		    x1 = ACM_X(rec[m]); y1 = ACM_Y(rec[m])
		    dx = x1 - crpix1; dy = y1 - crpix2
		    x1 = dx * cost - dy * sint + crpix1
		    y1 = dx * sint + dy * cost + crpix2
		    if (abs (x2-x1) > isearch)
			next
		    if (y1-y2 > isearch)
			break
		    if (y1-y2 < -isearch)
			next
		    call acm_tpeval (tp, ra, dec, x1, y1, xi, eta)
		    i = nint (xi / scale) + isearch + 1
		    j = nint (eta / scale) + isearch + 1
		    if (i < 1 || i > nc || j < 1 || j > nl)
			next
		    votes[i,j,k] = votes[i,j,k] + 1
		}
		nreg = nreg + 1
	    }

	    call acm_tpfree (tp)

	    if (nint (real(nreg) / nt) >= nrefmax)
	        break
	}
	nreg = nint (real(nreg) / nt)
end


# ACM_SHIFT -- Find tangent point.

procedure acm_ftp (votes, nc, nl, nt, dsint, nreg, scale, xi, eta, theta, logfd)

short	votes[nc,nl,nt]			#I Vote array
int	nc, nl, nt			#I Vote array dimensions
double	dsint				#I Rotation step
int	nreg				#I Number of reference regions
double	scale				#I Vote array scale (arcsec/pixel)
double	xi, eta				#O Tangent point (arcsec)
double	theta				#O Rotation (deg)
int	logfd[2]			#I Log file descriptors

int	i, j, k, maxval
double	x, y, r, sum, val, sint, xshift, yshift

begin
	# Find centroid of tangent point votes above some number of sigma.

	call acm_stat (votes, nc*nl*nt, x, y, r, sum)
	if ((y - r) < 10 * sum)
	   call error (1, "Automatic search failed")
	maxval = max (1, nint ((y - r) / 2) + r)
	xshift = 0; yshift = 0; theta = 0
	r = 0; sum = 0
	do k = 1, nt {
	    sint = (k - 1 - (nt - 1) / 2.) * dsint
	    do j = 1, nl {
		do i = 1, nc {
		    val = votes[i,j,k] - maxval
		    if (val <= 0.)
			next
		    x = i
		    y = j
		    xshift = xshift + x * val
		    yshift = yshift + y * val
		    theta = theta + sint * val
		    r = r + (x * x + y * y) * val
		    sum = sum + val
		}
	    }
	}
	if (sum == 0)
	   call error (1, "Automatic search failed")

	xshift = xshift / sum
	yshift = yshift / sum
	theta = RADTODEG (asin (theta / sum))
	r = r / sum - (xshift * xshift + yshift * yshift)
	if (r > 0.)
	    r = sqrt (r)

	if (r > 10.)
	   call error (1, "Automatic search failed")

	xshift = xshift - nc/2 - 1
	yshift = yshift - nl/2 - 1

	xi = -xshift * scale
	eta = -yshift * scale
	theta = -theta
end


# ACM_STAT -- Compute statistics of the tangent point vote array.

procedure acm_stat (votes, n, vmin, vmax, vavg, vsig)

short	votes[n]		#I Vote array
int	n			#I Array size
double	vmin, vmax, vavg, vsig	#O Statistics

int	i
double	val

begin
	val = votes[1]

	vmin = val
	vmax = val
	vavg = val
	vsig = val * val
	do i = 2, n {
	    val = votes[i]
	    vmin = min (val, vmin)
	    vmax = max (val, vmax)
	    vavg = vavg + val
	    vsig = vsig + val * val
	}
	vavg = vavg / n
	vsig = (vsig - vavg * vavg * n) / (n - 1)
	vsig = sqrt (max (0D0, vsig))
end


# ACM_CRVAL -- Set new tangent point.

procedure acm_crval (mws, cat, ncats, xi, eta, theta, flag, logfd)

pointer	mws[ARB]		#I MWCS pointers
pointer	cat[ARB]		#I Reference catalogs
int	ncats			#I Number of catalogs
double	xi, eta			#U Standard tangent point (arcsec)
double	theta			#U Rotation (deg)
int	flag			#I Flag
int	logfd[2]		#I Log file descriptors

int	i, j, ver
double	r[2], w[2,NVER], w1[2], cd[2,2], t[NVER], sint, cost
pointer	ct, rec

pointer	mw_sctran()

begin
	# Initialize, update, undo, or print WCS.
	# Note this assumes all catalogs have same tangent point.

	switch (flag) {
	case 0:			# Initialize
	    ver = 1
	    call mw_gwtermd (mws[1], r, w[1,ver], cd, 2)
	    t[ver] = 0D0
	    ver = ver + 1
	    call slDPSC (DEGTORAD(-xi/3600D0), DEGTORAD(-eta/3600D0),
		DEGTORAD(w[1,ver-1]), DEGTORAD(w[2,ver-1]), w[1,ver],
		w[2,ver], r[1], r[2], i)
	    w[1,ver] = RADTODEG(w[1,ver]); w[2,ver] = RADTODEG(w[2,ver])
	    t[ver] = t[ver-1] - theta
	case 1:			# Update
	    ver = ver + 1
	    call slDPSC (DEGTORAD(-xi/3600D0), DEGTORAD(-eta/3600D0),
		DEGTORAD(w[1,ver-1]), DEGTORAD(w[2,ver-1]), w[1,ver],
		w[2,ver], r[1], r[2], i)
	    w[1,ver] = RADTODEG(w[1,ver]); w[2,ver] = RADTODEG(w[2,ver])
	    t[ver] = t[ver-1] - theta
	    do j = 1, 2 {
		if (logfd[j] == NULL)
		    next
		call slDSTP (DEGTORAD(w[1,ver]), DEGTORAD(w[2,ver]),
		    DEGTORAD(w[1,1]), DEGTORAD(w[2,1]), xi, eta, i)
		xi = RADTODEG(xi) * 3600D0
		eta = RADTODEG(eta) * 3600D0
		theta = -t[ver]
#		call fprintf (logfd[j], "    try ra shift of %.4g arcsec\n")
#		     call pargd (xi)
#		call fprintf (logfd[j], "    try dec shift of %.4g arcsec\n")
#		     call pargd (eta)
#		if (abs(t[ver]-t[1]) > 0.01) {
#		    call fprintf (logfd[j], "    try rotation of %.2f deg\n")
#			 call pargd (theta)
#		}
	    }
	case 2:			# Undo
	    ver = ver - 1
	case 3:			# Log
	    do j = 1, 2 {
		if (logfd[j] == NULL)
		    next
		call slDSTP (DEGTORAD(w[1,ver]), DEGTORAD(w[2,ver]),
		    DEGTORAD(w[1,1]), DEGTORAD(w[2,1]), xi, eta, i)
		xi = RADTODEG(xi) * 3600D0
		eta = RADTODEG(eta) * 3600D0
		theta = -t[ver]
		call fprintf (logfd[j], "    ra shift is %.4g arcsec\n")
		     call pargd (xi)
		call fprintf (logfd[j], "    dec shift is %.4g arcsec\n")
		     call pargd (eta)
		call fprintf (logfd[j], "    rotation is %.2f deg\n")
		     call pargd (theta)
		call fprintf (logfd[j], "    tangent point is %.2H %.1h\n")
		    call pargd (w[1,ver])
		    call pargd (w[2,ver])
	    }
	    return
	case 4:			# Retrieve
	    theta = -t[ver]
	    return
	}

	# Set tangent point and update pixel coordinates.
	sint = sin (DEGTORAD(-t[ver]))
	cost = cos (DEGTORAD(-t[ver]))
	do i = 1, ncats {
	    call mw_gwtermd (mws[i], r, w1, cd, 2)
	    call mw_swtermd (mws[i], r, w[1,ver], cd, 2)
	    ct = mw_sctran (mws[i], "world", "logical", 3)
	    do j = 1, CAT_NRECS(cat[i]) {
		rec = CAT_REC(cat[i],j)
		call mw_c2trand (ct, ACM_RA(rec)*15D0, ACM_DEC(rec),
		   cd[1,1], cd[1,2])
		if (sint != 0D0) {
		    cd[2,1] = cd[1,1] - r[1]
		    cd[2,2] = cd[1,2] - r[2]
		    cd[1,1] = (cd[2,1] * cost - cd[2,2] * sint) + r[1]
		    cd[1,2] = (cd[2,1] * sint + cd[2,2] * cost) + r[2]
		}
		ACM_X(rec) = cd[1,1]; ACM_Y(rec) = cd[1,2]
	    }
	    call mw_ctfree (ct)
	}
end


# ACM_PIXEL -- Match reference and source entries by pixel coordinates.

procedure acm_pixel (mw, cat1, cat2, rec, nrec, ref, nref,
	match, nmatch, ndetect, nrefmatch, fmatch, logfd)

pointer	mw				#I MWCS pointer
pointer	cat1				#I Image catalog
pointer	cat2				#I Reference catalog
pointer	rec[ARB]			#I Image catalog records
int	nrec				#I Number of image records
pointer	ref[ARB]			#I Reference catalog records
int	nref				#I Number of reference records
double	match				#I Matching distance (pix)
int	nmatch				#I Number of image records matched
int	ndetect				#I Number of candidate detections
int	nrefmatch			#I Number of candidate references
double	fmatch				#I Minimum matching fraction
int	logfd[2]			#I Log file descriptors

int	i, j, j1
double	crmin1, crmax1, crmin2, crmax2
double	x, y, x1, y1, match2, r2, lastr2
pointer	hdr, rec2

double	imgetd()

begin
	# Initialize.
	hdr = CAT_IHDR(cat1)
	crmin1 = imgetd (hdr, "crmin1")
	crmax1 = imgetd (hdr, "crmax1")
	crmin2 = imgetd (hdr, "crmin2")
	crmax2 = imgetd (hdr, "crmax2")

	do i = 1, nref
	    ACM_PTR(ref[i]) = NULL
	do j = 1, nrec
	    ACM_PTR(rec[j]) = NULL

	# Sort the catalogs by Y and move through entries in Y.
	call catsort (cat2, ref, nref, ID_Y, 1)
	match2 = match * match
	j1 = 1
	ndetect = nrec
	nrefmatch = 0
	do i = 1, nref {
	    lastr2 = MAX_DOUBLE
	    x = ACM_X(ref[i])
	    y = ACM_Y(ref[i])
	    if (x<crmin1 || x>crmax1 || y<crmin2 || y>crmax2)
	        next
	    nrefmatch = nrefmatch + 1
	    do j = j1, nrec {
		x1 = ACM_X(rec[j])
		y1 = ACM_Y(rec[j])
		if (y1 < y - match) {
		    j1 = j + 1
		    next
		}
		if (y1 > y + match)
		    break
		r2 = (x - x1) * (x - x1) + (y - y1) * (y - y1)
		if (r2 > match2 || r2 > lastr2)
		    next
		#ACM_X(ref[i]) = x1
		#ACM_Y(ref[i]) = y1
		rec2 = ACM_PTR(ref[i])
		if (rec2 == NULL) {
		    ACM_PTR(rec[j]) = ref[i]
		    ACM_PTR(ref[i]) = rec[j]
		    lastr2 = r2
		} else if (ACM_MAG(rec2) > ACM_MAG(rec[j])) {
		    ACM_PTR(rec2) = NULL
		    ACM_PTR(rec[j]) = ref[i]
		    ACM_PTR(ref[i]) = rec[j]
		    lastr2 = r2
		}
	    }
	}

	# Compute statistics.
	nmatch = 0
	do i = 1, nref
	    if (ACM_PTR(ref[i]) != NULL)
		nmatch = nmatch + 1
	do i = 1, 2 {
	    if (logfd[i] == NULL)
		next
	    call fprintf (logfd[i],
		"    matched %d out of %d detections and %d references\n")
	        call pargi (nmatch)
	        call pargi (ndetect)
		call pargi (nrefmatch)
	}

	# Require a minimum matching fraction.
	if (nrefmatch == 0)
	    y = 0.
	else
	    y = double (nmatch) /
		double (max(10,min(ndetect/2,nrefmatch)))
	#if (y < fmatch)
	if (y < fmatch/2)
	    call error (1, "Matching fraction too low")
end


# ACM_PHOT -- Determine photometric zeropoint from matched sources.
#
# For each CCD:
# 1. Sources with the 'S' flag set are excluded.
# 2. Sources which are grossly different in magnitude are rejected.
# 3. The remaining sources are sorted.
# 4. The brightest 10% and faintest 20% are excluded.
# 5. An sigma clipping estimate of the zeropoint is computed.
# A global average is computed over all the extensions.

procedure acm_phot (cats, ncats, logfd)

pointer	cats[ncats]			#I Input catalogs
int	ncats				#I Number of catalogs
int	logfd[2]			#I Log file descriptors

int	i, j, k, n, n1, magznav, aravd()
double	dm, dm1, dm2
double	magzero, magzsig, magzerr
pointer	cat, im, rec, ref, recs, dms, tmp

begin

	do i = 1, 2 {
	    if (logfd[i] == NULL)
		next
	    call fprintf (logfd[i], "  find magnitude zeropoint\n")
	}

	im = CAT_IHDR(cats[1])
	dms = NULL
	n = 0
	do j = 1, ncats {
	    cat = cats[j]
	    im = CAT_IHDR(cat)

	    n1 = 0
	    do k = 1, CAT_NRECS(cat) {
		rec = CAT_REC(cat,k)
		ref = ACM_PTR(rec)
		if (ref == NULL)
		    next
		if (ACM_FLAGS(rec) == 'S')
		    next
		dm = ACM_MREF(ref) - ACM_MAG(rec)
		if (abs (dm) > 50.)
		    next
		if (n == 0) {
		    call malloc (recs, 1000, TY_POINTER)
		    call malloc (dms, 1000, TY_DOUBLE)
		} else if (mod (n, 1000) == 0) {
		    call realloc (recs, n+1000, TY_POINTER)
		    call realloc (dms, n+1000, TY_DOUBLE)
		}
		Memi[recs+n] = rec
		Memd[dms+n] = dm
		n1 = n1 + 1
		n = n + 1
	    }
	    if (ncats > 1 && n1 > 2) {
		call malloc (tmp, n1, TY_DOUBLE)
		call amovd (Memd[dms+n-n1], Memd[tmp], n1)
		call asrtd (Memd[tmp], Memd[tmp], n1)
		k = (max(n1,10) - 10) * 0.1
		magznav = aravd (Memd[tmp+k], n1-3*k, magzero, magzsig, 0D0)
		magzerr = magzsig / sqrt (double(max(magznav-1,1)))
		call mfree (tmp, TY_DOUBLE)
		do i = 1, 2 {
		    if (logfd[i] == NULL)
		        next
		    call fprintf (logfd[i],
		        "      %s: magzero = %.3f +- %.3f\n")
			call pargstr (IM_HDRFILE(im))
			call pargd (magzero)
			call pargd (magzerr)
		}
		call imaddd (im, "MAGZERO1", magzero)
		call imaddd (im, "MAGZSIG1", magzsig)
		call imaddd (im, "MAGZERR1", magzerr)
		call imaddi (im, "MAGZNAV1", magznav)
	    }
	}

	if (n > 2) {
	    call malloc (tmp, n, TY_DOUBLE)
	    call amovd (Memd[dms], Memd[tmp], n)
	    call asrtd (Memd[tmp], Memd[tmp], n)
	    k = (max(n,10) - 10) * 0.1
	    magznav = aravd (Memd[tmp+k], n-3*k, magzero, magzsig, 0D0)
	    magzerr = magzsig / sqrt (double(max(magznav-1,1)))
	    call mfree (tmp, TY_DOUBLE)
	    do i = 1, 2 {
		if (logfd[i] == NULL)
		    next
		call fprintf (logfd[i],
		    "    magzero = %.3f +- %.3f\n")
		    call pargd (magzero)
		    call pargd (magzerr)
	    }
	    do j = 1, ncats {
		cat = cats[j]
		im = CAT_IHDR(cat)
		call imaddd (im, "MAGZERO", magzero)
		call imaddd (im, "MAGZSIG", magzsig)
		call imaddd (im, "MAGZERR", magzerr)
		call imaddi (im, "MAGZNAV", magznav)
	    }

	    # Flag those sources within 3 sigma.
	    dm1 = magzero - 3 * magzsig
	    dm2 = magzero + 3 * magzsig
	    do j = 0, n-1 {
	        dm = Memd[dms+j]
	        if (dm < dm1 || dm > dm2)
		    next
		ACM_FLAGS(Memi[recs+j]) = 'P'
	    }
	}

	call mfree (recs, TY_POINTER)
	call mfree (dms, TY_DOUBLE)
end


procedure acm_wcat (newcat, oldcat)

pointer	newcat				#I New catalog
pointer	oldcat				#I Old catalog

int	i, j
pointer	oldrec, newrec
errchk	catwrec, catcreate

begin
	# Create the new catalog.
	call catcreate (newcat)

	# Copy the old catalog header to the new catalog.
	call im2im (CAT_IHDR(oldcat), CAT_OHDR(newcat))

	# Write the matched records.
	j = 0
	do i = 1, CAT_NRECS(oldcat) {
	    oldrec = CAT_REC(oldcat,i)
	    newrec = ACM_PTR(oldrec)
	    if (newrec == NULL)
		next
	    j = j + 1
	    ACM_X(newrec) = ACM_X(oldrec)
	    ACM_Y(newrec) = ACM_Y(oldrec)
	    ACM_MAG(newrec) = ACM_MAG(oldrec)
	    ACM_A(newrec) = ACM_A(oldrec)
	    ACM_B(newrec) = ACM_B(oldrec)
	    call strcpy (ACM_FLAGS(oldrec), ACM_FLAGS(newrec), ARB)
	    call catwrec (newcat, newrec, j)
	}
end


# ACM_SEARCH -- Find the index of the record that is >= to the specified value.
# This requires the records to be sorted in Y.

int procedure acm_search (rec, nrec, val)

pointer	rec[ARB]			#I Records
int	nrec				#I Number of records
double	val				#I Value to find

int	i, i1, i2, di, n
double	v, v1, v2, dv
begin
	n = nrec
	i1 = 1
	do i2 = n, i1, -1
	    if (!IS_INDEFD(ACM_Y(rec[i2])))
	        break
	if (i2 < i1)
	    call error (1, "No Y values found in catalog")
	        
	n = i2
	v1 = ACM_Y(rec[i1])
	v2 = ACM_Y(rec[i2])
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
	    v = ACM_Y(rec[i])

	    if (v >= val) {
		i2 = i
		v2 = v
		di = 1
		for (i1=i2-1; i1 > 0; i1=i1-di) {
		    v1 = ACM_Y(rec[i1])
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
		    v2 = ACM_Y(rec[i2])
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


# ACM_CONVOLVE -- Convolve input vote array using specified weights.
# This version leaves a region of zero votes around the edge.

procedure acm_convolve (input, output, nc, nl, nt, wts, nx, ny)

short	input[nc,nl,nt]			#I Vote array
real	output[nc,nl,nt]		#O Convolved vote array
int	nc, nl, nt			#I Vote array dimensions
real	wts[nx,ny]			#I Convolutions weights
int	nx, ny				#I Weight dimensions

int	i, j, k, ii, jj, i1, i2, j1, j2, nx2, ny2, dx, dy
real	wt
errchk	acm_convolve1

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
		    if (wt == 0.)
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


include	<math/gsurfit.h>

define	TP_NGRID	9			# Grid size for function
define	TP_TYPE		GS_CHEBYSHEV		# Function type
define	TP_ORDER	3			# Function order
define	TP_XTERMS	GS_XHALF		# Function cross terms
define	TP_WTS		WTS_UNIFORM		# Fitting weights

define	TP_LEN		20			# Structure length
define	TP_MW		Memi[$1]		# MWCS
define	TP_SCALE	Memd[P2D($1+2)]		# Scale (arcsec/pixel)
define	TP_SEARCH	Memd[P2D($1+4)]		# Search (pixel)
define	TP_RA0		Memd[P2D($1+6)]		# Tangent point RA (deg)
define	TP_DEC0		Memd[P2D($1+8)]		# Tangent point DEC (deg)
define	TP_RA		Memd[P2D($1+10)]	# Source RA (deg)
define	TP_DEC		Memd[P2D($1+12)]	# Source DEC (deg)
define	TP_X0		Memd[P2D($1+14)]	# Offset origin (pixel)
define	TP_Y0		Memd[P2D($1+16)]	# Offset origin (pixel)
define	TP_XSF		Memi[$1+18]		# X correction function
define	TP_YSF		Memi[$1+19]		# X correction function

# ACM_TPINIT -- Tangent point mapping initialization.
#
# The tangent point mapping is a function of observed pixel offset from the
# pixel position of the reference coordinate using the current tangent point.
# The function value is the tangent point standard coordinate which maps the
# observed pixel position to the reference coordinate.

procedure acm_tpinit (tp, mw, scale, search, ra, dec)

pointer	tp			#O Tangent point mapping pointer
pointer	mw			#I Current WCS
double	scale			#I Standard coordinate scale (arcsec/pixel)
double	search			#I Search radius (arcsec)
double	ra, dec			#I Source coordinate (deg)

int	i, j, hgrid, iflag
double	ragrid[TP_NGRID,TP_NGRID], decgrid[TP_NGRID,TP_NGRID]
double	r[2], w[2], w0[2], cd[2,2]
double	s, xi, eta, x, y, x0, y0, dx, dy, wts, ra2, dec2, lim
pointer	ct, xsf, ysf

pointer	mw_sctran()

begin
	# Make grid of tangent points.  This only needs to be done once.
	if (tp == NULL) {
	    # Allocate and initialize tangent point mapping.
	    call calloc (tp, TP_LEN, TY_STRUCT)
	    TP_MW(tp) = mw
	    TP_SCALE(tp) = scale
	    TP_SEARCH(tp) = search

	    # Get current tangent point information.
	    call mw_gwtermd (mw, r, w0, cd, 2)
	    TP_RA0(tp) = w0[1]; TP_DEC0(tp) = w0[2]

	    # Set tangent point grid.
	    s = DEGTORAD (search / 3600D0)
	    w[1] = DEGTORAD(TP_RA0(tp)); w[2] = DEGTORAD(TP_DEC0(tp))
	    hgrid = TP_NGRID / 2
	    do j = 1, TP_NGRID {
		eta = s * (j - 1 - hgrid) / hgrid
		do i = 1, TP_NGRID {
		    xi = s * (i - 1 - hgrid) / hgrid
		    call slDPSC (xi, eta, w[1], w[2], ragrid[i,j], decgrid[i,j],
		        ra2, dec2, iflag)
		    ragrid[i,j] = RADTODEG(ragrid[i,j])
		    decgrid[i,j] = RADTODEG(decgrid[i,j])
		}
	    }
	}
	
	# Set origin of fitting coordinates for given reference coordinate.
	ct = mw_sctran (mw, "world", "logical", 3)
	call mw_c2trand (ct, ra, dec, x0, y0)
	call mw_ctfree (ct)

	TP_RA(tp) = ra; TP_DEC(tp) = dec
	TP_X0(tp) = x0; TP_Y0(tp) = y0

	# Initialize fitting.
	xsf = TP_XSF(tp); ysf = TP_YSF(tp)
	if (xsf != NULL)
	    call dgsfree (xsf)
	if (ysf != NULL)
	    call dgsfree (ysf)

	lim = 2 * search / scale
	call dgsinit (xsf, TP_TYPE, TP_ORDER, TP_ORDER, TP_XTERMS, -lim,
	    lim, -lim, lim)
	call dgsinit (ysf, TP_TYPE, TP_ORDER, TP_ORDER, TP_XTERMS, -lim,
	    lim, -lim, lim)
	TP_XSF(tp) = xsf; TP_YSF(tp) = ysf

	# Compute tangent point mapping function fit to grid of tangent
	# point coordinates.

	do j = 1, TP_NGRID {
	    eta = search * (j - 1 - hgrid) / hgrid
	    do i = 1, TP_NGRID {
		xi = search * (i - 1 - hgrid) / hgrid
		w[1] = ragrid[i,j]; w[2] = decgrid[i,j]
		call mw_swtermd (mw, r, w, cd, 2)
		ct = mw_sctran (mw, "world", "logical", 3)
		call mw_c2trand (ct, ra, dec, x, y)
		call mw_ctfree (ct)
		dx = x - x0
		dy = y - y0
		call dgsaccum (xsf, dx, dy, xi, wts, TP_WTS)
		call dgsaccum (ysf, dx, dy, eta, wts, TP_WTS)
	    }
	}
	call mw_swtermd (mw, r, w0, cd, 2)

	# Fit tangent point mapping functions.
	call dgssolve (xsf, iflag)
	call dgssolve (ysf, iflag)
end


# ACM_TPEVAL --  Evaluate tangent point.
#
# Given a source celestial and pixel coordinate evaluate the tangent point
# as standard coordinate relative to the current tangent point.

procedure acm_tpeval (tp, ra, dec, x, y, xi, eta)

pointer	tp			#I Tangent point mapping pointer
double	ra, dec			#I Source celestial coordinate (deg)
double	x, y			#I Observed pixel coordinate (pixel)
double	xi, eta			#O Standard tangent point coordinate

double	dx, dy, dgseval()
errchk	acm_tpinit

begin
	if (TP_XSF(tp) == NULL) {
	    dx = x - TP_X0(tp)
	    dy = y - TP_Y0(tp)
	    xi = dx * TP_SCALE(tp)
	    eta = dy * TP_SCALE(tp)
	    return
	}

	if (ra != TP_RA(tp) || dec != TP_DEC(tp))
	    call acm_tpinit (tp, TP_MW(tp), TP_SCALE(tp), TP_SEARCH(tp),
	        ra, dec)
	dx = x - TP_X0(tp)
	dy = y - TP_Y0(tp)
	xi = dgseval (TP_XSF(tp), dx, dy)
	eta = dgseval (TP_YSF(tp), dx, dy)
end


# ACM_TPFREE -- Free tangent point mapping pointer.

procedure acm_tpfree (tp)

pointer	tp			#U Tangent point mapping pointer

begin
	call dgsfree (TP_XSF(tp))
	call dgsfree (TP_YSF(tp))
	call mfree (tp, TY_STRUCT)
end
