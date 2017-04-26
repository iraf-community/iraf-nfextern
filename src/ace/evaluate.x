include	<error.h>
include	<mach.h>
include	<evvexpr.h>
include	<imhdr.h>
include	<pmset.h>
include	"ace.h"
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>
include	<math.h>
include	"evaluate.h"
include	"eaflux.h"
include	"gwt.h"

# Parameters for FWHM normalization function and histogram.
define	FW_NI		100		# Normalization function sample
define	FW_I1		0.40		# Low FWHM point
define	FW_I2		0.60		# High FWHM point
define	FW_BIN1		1.0		# First bin
define	FW_BIN2		21.0		# Last bin
define	FW_BINWIDTH	0.02		# Bin width
define	FW_BINMODE	21		# Mode smoothing bin (odd)


# EVALUATE -- Evaluate object parameters.
#
# This only evaluates non-DARK detections.

procedure evaluate (evl, cat, im, om, skymap, sigmap, gainmap, expmap,
	sptlmap, logfd, verbose)

pointer	evl			#I Parameters
pointer	cat			#I Catalog structure
pointer	im			#I Image pointer
pointer	om			#I Object mask pointer
pointer	skymap			#I Sky map
pointer	sigmap			#I Sigma map
pointer	gainmap			#I Gain map
pointer	expmap			#I Exposure map
pointer	sptlmap			#I Spatial scale map
int	logfd			#I Log FD
int	verbose			#I Verbose level

bool	grw, bndry
bool	dogwt, docaf, doeaf
int	i, j, n, c, l, nc, nl, c1, c2, nummax, num, nobjsap, fw_nbins, nstar
real	x, x2, y, y2, r, s, s2, f, f2, wt, s2x, s2y, dfw, rstar
real	val, sky, pval, ssig, sptl
real	magzero, fwhm, nfwhm, sigma, fcore
pointer	stp, sym, objs, obj, rlptr, gwts, gwt, eafs, eaf, o
pointer	data, skydata, ssigdata, gaindata, expdata, sigdata, sptldata
pointer	sp, order, str, v, rl, ivals, xmin, ymin
pointer	sum_f1, sum_f2, sum_s2x, sum_s2y
pointer	stars, fw_norm, sum_fw, fw_bins

int	andi(), ctor()
real	imgetr()
bool	pm_linenotempty()
pointer	stfind(), catexpr()
errchk	salloc, evgdata, gwt_ginit, gwt_init, eaf_ginit, eaf_init
errchk	pm_linenotempty, pmglri
int	compare()

int	iter

begin
	call smark (sp)
	call salloc (order, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get evaluation parameters.
	# The magnitude zero point may be defined by the parameter
	# file, the image header, or the catalog header.
	if (EVL_MAGZERO(evl,1) == '!') {
	    iferr (magzero = imgetr (im, EVL_MAGZERO(evl,2))) {
		call erract (EA_WARN)
		magzero = INDEFR
	    }
	} else {
	    i = 1
	    if (ctor (EVL_MAGZERO(evl,1), i, magzero) == 0)
		magzero = INDEFR
	}
	if (!IS_INDEFR(magzero))
	    call catputr (cat, "magzero", magzero) 
	call strcpy (EVL_ORDER(evl,1), Memc[order], SZ_LINE)

	# Print log information.
	if (logfd != NULL) {
	    call fprintf (logfd, "  Evaluate objects:\n")
	    call fprintf (logfd, "    magzero = %g\n")
		call pargr (magzero)
	}
	if (verbose > 1) {
	    call printf ("  Evaluate objects:\n")
	    call printf ("    magzero = %g\n")
		call pargr (magzero)
	}

	# Initialize.
	expdata = NULL
	gaindata = NULL
	sptldata = NULL; sptl = 1.
	stars = NULL

	call evgdata (0, im, skymap, sigmap, gainmap, expmap,
	    sptlmap, data, skydata, ssigdata, gaindata,
	    expdata, sigdata, sptldata)

	stp = CAT_STP(cat)
	objs = CAT_RECS(cat)
	nummax = CAT_NUMMAX(cat)

	nc = IM_LEN(im,1)
	nl = IM_LEN(im,2)
	fw_nbins = 1 + (FW_BIN2 - FW_BIN1) / FW_BINWIDTH

	# Allocate work arrays.
	call salloc (v, PM_MAXDIM, TY_LONG)
	call salloc (rl, 3+3*IM_LEN(im,1), TY_INT)

	call salloc (sigdata, nc, TY_REAL)
	call salloc (fw_norm, FW_NI, TY_REAL)
	call salloc (fw_bins, fw_nbins, TY_REAL)

	call salloc (ivals, nummax, TY_INT)
	call salloc (xmin, nummax, TY_INT)
	call salloc (ymin, nummax, TY_INT)
	call salloc (sum_fw, nummax, TY_REAL)
	call salloc (sum_f1, nummax, TY_REAL)
	call salloc (sum_f2, nummax, TY_REAL)
	call salloc (sum_s2x, nummax, TY_REAL)
	call salloc (sum_s2y, nummax, TY_REAL)

	call aclrr (Memr[fw_bins], fw_nbins)
	call aclri (Memi[ivals], nummax)
	call aclrr (Memr[sum_fw], nummax)
	call aclrr (Memr[sum_f1], nummax)
	call aclrr (Memr[sum_f2], nummax)
	call aclrr (Memr[sum_s2x], nummax)
	call aclrr (Memr[sum_s2y], nummax)

	# Initialize profile normalization function.
	dfw = (FW_I2 - FW_I1) / (FW_NI - 1)
	y = -4 * LN_2
	do i = 0, FW_NI-1 {
	    x = i * dfw + FW_I1
	    Memr[fw_norm+i] = sqrt (log (x) / y)
	}

	# Initialize.
	j = 0; l = 0
	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,DARK) == 'D') {
	        l = l + 1
	        next
	    }

	    j = j + 1
	    OBJ_ORDER(obj) = j

	    OBJ_PEAK(obj) = 0.

	    # Parameters related to the moments.
	    OBJ_X(obj) = 0.
	    OBJ_Y(obj) = 0.
	    OBJ_XX(obj) = 0.
	    OBJ_YY(obj) = 0.
	    OBJ_XY(obj) = 0.
	    OBJ_XVAR(obj) = 0.
	    OBJ_YVAR(obj) = 0.
	    OBJ_XYCOV(obj) = 0.

	    # Parameters that are accumulated based on source area.
	    OBJ_FCORE(obj) = INDEFR
	    OBJ_GWFLUX(obj) = INDEFR
	    OBJ_FWHM(obj) = 0.
	    OBJ_R(obj) = 0.
	    OBJ_RII(obj) = 0.
	    do j = 0, 9
	        OBJ_CAFLUX(obj,j) = INDEFR
	    OBJ_NPIX(obj) = 0
	    OBJ_SKY(obj) = 0.
	    OBJ_THRESH(obj) = 0.
	    OBJ_EAR(obj,0) = INDEFR
	    OBJ_FLUX(obj) = 0.
	    OBJ_SIG(obj) = 0.
	    OBJ_ISIGAVG(obj) = 0.
	    OBJ_ISIGAV(obj) = INDEFR
	    OBJ_FLUXVAR(obj) = 0.
	}
	if (l > 0 && Memc[order] == EOS) {
	    do i = NUMSTART-1, nummax-1 {
		obj = Memi[objs+i]
		if (obj == NULL)
		    next
		if (OBJ_FLAG(obj,DARK) == 'D') {
		    j = j + 1
		    OBJ_ORDER(obj) = j
		}
	    }
	}

	# Set flag for aperture fluxes.
	docaf = false; doeaf = false
	sym = stfind (stp, "CAFLUX_0")
	if (ENTRY_EVAL(sym) == YES)
	    docaf = (ENTRY_EVAL(sym) == YES)
	sym = stfind (stp, "EAR_0")
	if (ENTRY_EVAL(sym) == YES)
	    doeaf = (ENTRY_EVAL(sym) == YES)
	sym = stfind (stp, "EAFLUX_0")
	if (ENTRY_EVAL(sym) == YES)
	    doeaf = (ENTRY_EVAL(sym) == YES)

	# --- PASS1 ---
	#
	# Compute parameters that do not depend on a source center.
	# Compute peak position and unweighted centroid.

	Meml[v] = 1
	do l = 1, nl {
	    Meml[v+1] = l

	    # Note the data is read the first time it is needed.
	    data = NULL

	    # Check if there are any object regions in this line.
	    if (!pm_linenotempty (om, Meml[v]))
		next
	    call pmglri (om, Meml[v], Memi[rl], 0, nc, 0)

	    # Go through pixels which are parts of objects.
	    rlptr = rl
	    do i = 2, Memi[rl] {
		rlptr = rlptr + 3
		c1 = Memi[rlptr]
		c2 = c1 + Memi[rlptr+1] - 1
		num = MNUM(Memi[rlptr+2]) - 1
		bndry = MBNDRY(Memi[rlptr+2])

		# Do all unevaluated objects and their parents.
		while (num >= NUMSTART-1) {
		    obj = Memi[objs+num]
		    if (obj == NULL)
			break
		    if (OBJ_FLAG(obj,DARK) == 'D')
			break

		    if (data == NULL)
			call evgdata (l, im, skymap, sigmap, gainmap, expmap,
			    sptlmap, data, skydata, ssigdata, gaindata,
			    expdata, sigdata, sptldata)

		    if (OBJ_NPIX(obj) == 0) {
			val = Memr[data+c1-1]
			sky = Memr[skydata+c1-1]
			ssig = Memr[ssigdata+c1-1]

			Memi[xmin+num] = c1
			Memi[ymin+num] = l
			OBJ_XMIN(obj) = c1
			OBJ_XMAX(obj) = c2
			OBJ_YMIN(obj) = l
			OBJ_YMAX(obj) = l
			OBJ_ISIGMAX(obj) =  (val - sky) / ssig
		    } else {
		        OBJ_XMIN(obj) = min (OBJ_XMIN(obj), c1)
		        OBJ_XMAX(obj) = min (OBJ_XMAX(obj), c2)
			OBJ_YMAX(obj) = l
		    }

		    pval = OBJ_PEAK(obj)
		    s2x = Memr[sum_s2x+num]
		    s2y = Memr[sum_s2y+num]
		    do c = c1, c2 {
			sky = Memr[skydata+c-1]
			val = Memr[data+c-1] - sky
			ssig = Memr[ssigdata+c-1]
			s = Memr[sigdata+c-1]
			f2 = val * val

			x = c - Memi[xmin+num]
			y = l - Memi[ymin+num]
			x2 = x * x
			y2 = y * y
			s2 = s * s

			if (OBJ_PEAK(obj) < val) {
			    OBJ_PEAK(obj) = val
			    OBJ_XPEAK(obj) = c
			    OBJ_YPEAK(obj) = l
			}

			OBJ_NPIX(obj) = OBJ_NPIX(obj) + 1
			OBJ_SKY(obj) = OBJ_SKY(obj) + sky
			OBJ_SIG(obj) = OBJ_SIG(obj) + ssig

			if (bndry) {
			    OBJ_THRESH(obj) = OBJ_THRESH(obj) + val
			    Memi[ivals+num] = Memi[ivals+num] + 1
			}

			OBJ_FLUX(obj) = OBJ_FLUX(obj) + val
			OBJ_FLUXVAR(obj) = OBJ_FLUXVAR(obj) + s2

			Memr[sum_f1+num] = Memr[sum_f1+num] + val
			OBJ_X(obj) = OBJ_X(obj) + x * val
			OBJ_XX(obj) = OBJ_XX(obj) + x2 * val
			OBJ_XVAR(obj) = OBJ_XVAR(obj) + x2 * s2
			s2x = s2x + x * s2

			OBJ_Y(obj) = OBJ_Y(obj) + y * val
			OBJ_YY(obj) = OBJ_YY(obj) + y2 * val
			OBJ_YVAR(obj) = OBJ_YVAR(obj) + y2 * s2
			s2y = s2y + y * s2

			OBJ_XY(obj) = OBJ_XY(obj) + x * y * val
			OBJ_XYCOV(obj) = OBJ_XYCOV(obj) + x * y * s2

			Memr[sum_s2x+num] = s2x
			Memr[sum_s2y+num] = s2y

			val = val / ssig
			OBJ_ISIGAVG(obj) = OBJ_ISIGAVG(obj) + val
			OBJ_ISIGMAX(obj) = max (OBJ_ISIGMAX(obj), val)
		    }

		    num = OBJ_PNUM(obj) - 1
		}
	    }
	}

	# Finish up the evaluations.
	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,DARK) == 'D')
		next

	    n = OBJ_NPIX(obj)
	    if (n == 0) {
	        call mfree (Memi[objs+i], TY_STRUCT)
		next
	    }
	    if (OBJ_NDETECT(obj) == 0)
	        OBJ_NDETECT(obj) = n
	    f = OBJ_FLUX(obj)

	    # I don't think this can ever happen.
	    if (OBJ_PEAK(obj) == 0.) {
		OBJ_XPEAK(obj) = (OBJ_XMAX(obj) + OBJ_XMIN(obj)) / 2.
		OBJ_YPEAK(obj) = (OBJ_YMAX(obj) + OBJ_YMIN(obj)) / 2.
	    }

	    f = Memr[sum_f1+i]
	    if (f > 0.) {
		x = OBJ_X(obj) / f
		y = OBJ_Y(obj) / f
		OBJ_X(obj) = x + Memi[xmin+i]
		OBJ_Y(obj) = y + Memi[ymin+i]

		f2 = f * f
		s2x = Memr[sum_s2x+i]
		s2y = Memr[sum_s2y+i]

		OBJ_XX(obj) = OBJ_XX(obj) / f - x * x
		OBJ_XVAR(obj) = (OBJ_XVAR(obj) - 2 * x * s2x + 
		    x * x * OBJ_FLUXVAR(obj)) / f2

		OBJ_YY(obj) = OBJ_YY(obj) / f - y * y
		OBJ_YVAR(obj) = (OBJ_YVAR(obj) - 2 * y * s2y + 
		    y * y * OBJ_FLUXVAR(obj)) / f2

		OBJ_XY(obj) = OBJ_XY(obj) / f - x * y
		OBJ_XYCOV(obj) = (OBJ_XYCOV(obj) - x * s2x -
		    y * s2y + x * y * OBJ_FLUXVAR(obj)) / f2

		if (OBJ_XX(obj) < 0.01 || OBJ_YY(obj) < 0.01) {
		    #OBJ_X(obj) = INDEFR
		    OBJ_XX(obj) = INDEFR
		    OBJ_XVAR(obj) = INDEFR
		    #OBJ_Y(obj) = INDEFR
		    OBJ_YY(obj) = INDEFR
		    OBJ_YVAR(obj) = INDEFR
		    OBJ_XY(obj) = INDEFR
		    OBJ_XYCOV(obj) = INDEFR
		}
	    } else {
		OBJ_X(obj) = INDEFR
		OBJ_XX(obj) = INDEFR
		OBJ_XVAR(obj) = INDEFR
		OBJ_Y(obj) = INDEFR
		OBJ_YY(obj) = INDEFR
		OBJ_YVAR(obj) = INDEFR
		OBJ_XY(obj) = INDEFR
		OBJ_XYCOV(obj) = INDEFR
		OBJ_FLUXVAR(obj) = INDEFR
	    }

	    if (IS_INDEFR(OBJ_X(obj)) || IS_INDEFR(OBJ_Y(obj))) {
	        OBJ_X(obj) = OBJ_XPEAK(obj); OBJ_Y(obj) = OBJ_YPEAK(obj)
	    }
	    if (Memi[ivals+i] > 0)
		OBJ_THRESH(obj) = OBJ_THRESH(obj) / Memi[ivals+i]
	    else
		OBJ_THRESH(obj) = INDEFR
	    OBJ_SKY(obj) = OBJ_SKY(obj) / n
	    OBJ_SIG(obj) = OBJ_SIG(obj) / n
	    #OBJ_ISIGAVG(obj) = OBJ_ISIGAVG(obj) / sqrt(real(n))
	    OBJ_ISIGAVG(obj) = OBJ_ISIGAVG(obj) / real(n)
	    
	    OBJ_FLAG(obj,EVAL) = 'E'
	}

	# --- PASS2 ---
	#
	# Estimate FWHM and effective Gaussian sigma for the later
	# algorithms.  These will be recomputed later based on refined
	# centroids.

	Meml[v] = 1
	do l = 1, nl {
	    Meml[v+1] = l

	    # Note the data is read the first time it is needed.
	    data = NULL

	    # Check if there are any object regions in this line.
	    if (!pm_linenotempty (om, Meml[v]))
		next
	    call pmglri (om, Meml[v], Memi[rl], 0, nc, 0)

	    # Go through pixels which are parts of objects.
	    rlptr = rl
	    do i = 2, Memi[rl] {
		rlptr = rlptr + 3
		c1 = Memi[rlptr]
		c2 = c1 + Memi[rlptr+1] - 1
		num = MNUM(Memi[rlptr+2]) - 1
		grw = MGRW(Memi[rlptr+2])

		obj = Memi[objs+num]
		if (obj == NULL)
		    break
		if (OBJ_FLAG(obj,SPLIT)!='S' || OBJ_FLAG(obj,DARK)=='D')
		    next
		pval = OBJ_PEAK(obj)
		if (pval <= 0.)
		    next

		if (data == NULL)
		    call evgdata (l, im, skymap, sigmap, gainmap,
			expmap, sptlmap, data, skydata, ssigdata,
			gaindata, expdata, sigdata, sptldata)

		do c = c1, c2 {

		    r = (c - OBJ_X(obj)) ** 2 + (l - OBJ_Y(obj)) ** 2
		    if (r < 0.1)
		        next

		    r = sqrt (r)
		    sky = Memr[skydata+c-1]
		    val = Memr[data+c-1] - sky
		    x = val / pval

		    if (x > FW_I1 && x < FW_I2) {
			j = int ((x - FW_I1) / dfw) 
			y = r / Memr[fw_norm+j]
			wt = (1 - 2 * abs (x - 0.5)) / sqrt(y)
			OBJ_FWHM(obj) = OBJ_FWHM(obj) + y * wt
			Memr[sum_fw+num] = Memr[sum_fw+num]+wt
			if (y > FW_BIN1 && y < FW_BIN2) {
			    j = 1 + (y-FW_BIN1)/FW_BINWIDTH
			    Memr[fw_bins+j] = Memr[fw_bins+j]+wt
			} else
			    Memr[fw_bins] = Memr[fw_bins]+wt
		    }
		}
	    }
	}

	# Finish up the evaluations.
	nfwhm = 0.
	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,SPLIT)!='S' && OBJ_FLAG(obj,DARK)=='D')
		next

	    x = Memr[sum_fw+i]
	    if (x > 0.) {
		fwhm = fwhm + OBJ_FWHM(obj)
		nfwhm = nfwhm + x
		OBJ_FWHM(obj) = OBJ_FWHM(obj) / x
	    } else
		OBJ_FWHM(obj) = INDEFR
	}


	# Find the FWHM histogram peak.
	f = 0; f2 = 0
	num = FW_BINMODE
	n = num / 2
	do i = 0, num-1
	    f = f + Memr[fw_bins+i]
	do i = num, fw_nbins-1 {
	    f = f - Memr[fw_bins+i-num] + Memr[fw_bins+i]
	    x = (i-n-0.5)*FW_BINWIDTH + FW_BIN1
	   if (f >= f2) {
	       j = i - n
	       f2 = f
	    }
	}

	# If a good peak is found set the FWHM from the histogram
	# other use the average.
	if (Memr[fw_bins] < 0.5 * nfwhm)
	    fwhm = (j-0.5)*FW_BINWIDTH + FW_BIN1
	else if (nfwhm > 0.)
	    fwhm = fwhm / nfwhm
	else
	    fwhm = INDEFR

	# Estimate an equivalent Gaussian sigma.  If the FWHM failed
	# to be determined compute a sigma clipped estimate using the
	# second momemt radius.

	if (!IS_INDEFR(fwhm)) {
	    sigma = fwhm / sqrt (8 * LN_2)
	} else {
	    if (stars == NULL) {
		stars = ivals
		call evl_findstars (cat, Memi[stars], nstar, rstar, s,
		    20, 10, Memr[sum_fw])
	    }
	    if (!IS_INDEFR(rstar)) {
		sigma = rstar / SQRTOF2
		fwhm = sigma * sqrt (8 * LN_2)
	    } else {
		fwhm = EVL_FWHM(evl)
		sigma = fwhm / sqrt (8 * LN_2)
		rstar = SQRTOF2 * sigma
	    }
	}
	if (sigma < 0.1 || sigma > 100.)
	    sigma = INDEFR

	# --- PASS3 ---
	#
	# Given the unweighted moments we determine the weighted moments and
	# set the aperture center.

	if (IS_INDEFR(EVL_GWTSIG(evl))) {
	    if (IS_INDEFR(sigma))
		call gwt_ginit (cat, EVL_GWTSIG(evl),
		    EVL_GWTNSIG(evl), 3, gwts, NULL, 0)
	    else
		call gwt_ginit (cat, sigma,
		    EVL_GWTNSIG(evl), 3, gwts, NULL, 0)
	} else
	    call gwt_ginit (cat, EVL_GWTSIG(evl),
		EVL_GWTNSIG(evl), 3, gwts, logfd, verbose)

	call amovkr (1., Memr[sum_f1], nummax)
	do iter = 1, 10 {
	    Meml[v] = 1
	    dogwt = false
	    do l = 1, nl {
		Meml[v+1] = l

		# Note the data is read the first time it is needed.
		data = NULL

		# Check if there are any object regions in this line.
		if (!pm_linenotempty (om, Meml[v]))
		    next
		call pmglri (om, Meml[v], Memi[rl], 0, nc, 0)

		# Go through pixels which are parts of objects.
		rlptr = rl
		do i = 2, Memi[rl] {
		    rlptr = rlptr + 3
		    c1 = Memi[rlptr]
		    c2 = c1 + Memi[rlptr+1] - 1
		    num = MNUM(Memi[rlptr+2]) - 1
		    grw = MGRW(Memi[rlptr+2])
		    if (Memr[sum_f1+num] < 0.05)
			next

		    # Do all unevaluated objects and their parents.
		    while (num >= NUMSTART-1) {
			obj = Memi[objs+num]
			if (obj == NULL)
			    break
			if (OBJ_FLAG(obj,DARK) == 'D')
			    break
			if (Memr[sum_f1+num] < 0.05) {
			    num = OBJ_PNUM(obj) - 1
			    next
			}

			if (data == NULL)
			    call evgdata (l, im, skymap, sigmap, gainmap,
				expmap, sptlmap, data, skydata, ssigdata,
				gaindata, expdata, sigdata, sptldata)

			do c = c1, c2 {
			    sky = Memr[skydata+c-1]
			    val = Memr[data+c-1] - sky
			    if (sptldata != NULL)
				sptl = Memr[sptldata+c-1]

			    gwt = GWTS_GWT(gwts,num)
			    if (gwt == 0) {
				call gwt_init (gwts, gwt, OBJ_X(obj),
				    OBJ_Y(obj), OBJ_XX(obj), OBJ_YY(obj))
				GWTS_GWT(gwts,num) = gwt
			    }
			    if (gwt > 0)
				call gwt_accum (gwts, gwt, c, l, val, grw, sptl)
			}

			num = OBJ_PNUM(obj) - 1
		    }
		}

		# Deallocate memory for weighted moment measurements.
		rlptr = rl
		do i = 2, Memi[rl] {
		    rlptr = rlptr + 3
		    num = MNUM(Memi[rlptr+2]) - 1
		    obj = Memi[objs+num]
		    if (obj == NULL)
			next
		    if (l != OBJ_YMAX(obj))
			next
		    gwt = GWTS_GWT(gwts,num)
		    if (gwt > 0) {
			call gwt_done (gwts, gwt, x, y, r, OBJ_XX(obj),
			    OBJ_YY(obj), OBJ_XY(obj), fcore,
			    OBJ_GWFLUX(obj))
			if (!IS_INDEFR(fcore))
			    OBJ_FCORE(obj) = fcore
			GWTS_GWT(gwts,num) = gwt
			OBJ_X(obj) = OBJ_X(obj) + x
			OBJ_Y(obj) = OBJ_Y(obj) + y
			if (r < 5 * rstar)
			    Memr[sum_f1+num] = sqrt (x*x+y*y)
			else
			    Memr[sum_f1+num] = 0.
			if (Memr[sum_f1+num] > 0.05)
			    dogwt = true
		    }
		}
	    }
	}

	call gwt_gdone (cat, gwts)
	
	# Check and set final positions and core flux.
	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,DARK) == 'D')
		next
	    if (IS_INDEFR(OBJ_FCORE(obj)))
		OBJ_FCORE(obj) = OBJ_PEAK(obj)
	    if (IS_INDEFR(OBJ_X(obj)) || IS_INDEFR(OBJ_Y(obj))) {
		OBJ_X(obj) = OBJ_XPEAK(obj); OBJ_Y(obj) = OBJ_YPEAK(obj)
	    }
	    if (IS_INDEFR(OBJ_XAP(obj)) || IS_INDEFR(OBJ_YAP(obj))) {
		OBJ_XAP(obj) = OBJ_X(obj); OBJ_YAP(obj) = OBJ_Y(obj)
	    }
	    if (abs(OBJ_XAP(obj)-OBJ_X(obj))>5. ||
	        abs(OBJ_YAP(obj)-OBJ_Y(obj))>5.) {
		OBJ_XAP(obj) = OBJ_X(obj); OBJ_YAP(obj) = OBJ_Y(obj)
	    }
	}

	# --- PASS4 ---
	#
	# Compute revised FWHM and aperture fluxes (if requested).

	if (docaf)
	    call caf_init (cat, nobjsap, EVL_CAFWHM(evl)*fwhm/2,
	        EVL_CAFWHM(evl), logfd, verbose)
	if (doeaf)
	    call eaf_ginit (cat, eafs)
	else
	    eafs = NULL

	# Reinitialize FWHM.
	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,DARK) == 'D')
	        next
	    OBJ_FWHM(obj) = 0.
	    Memr[sum_fw+i] = 0.
	}
	call aclrr (Memr[fw_bins], fw_nbins)

	Meml[v] = 1
	do l = 1, nl {
	    Meml[v+1] = l

	    # Note the data is read the first time it is needed.
	    data = NULL

	    # Do circular aperture photometry.  Check nobjsap to avoid
	    # subroutine call.
	    if (docaf && nobjsap > 0)
		call caf_eval (l, im, skymap, sigmap, gainmap, expmap,
		    sptlmap, data, skydata, ssigdata, gaindata, expdata,
		    sigdata, sptldata)

	    # Check if there are any object regions in this line.
	    if (!pm_linenotempty (om, Meml[v]))
		next
	    call pmglri (om, Meml[v], Memi[rl], 0, nc, 0)

	    # Go through pixels which are parts of objects.
	    rlptr = rl
	    do i = 2, Memi[rl] {
		rlptr = rlptr + 3
		c1 = Memi[rlptr]
		c2 = c1 + Memi[rlptr+1] - 1
		num = MNUM(Memi[rlptr+2]) - 1
		grw = MGRW(Memi[rlptr+2])

		# Do all unevaluated objects and their parents.
		while (num >= NUMSTART-1) {
		    obj = Memi[objs+num]
		    if (obj == NULL)
			break
		    if (OBJ_FLAG(obj,DARK) == 'D')
			break

		    if (data == NULL)
			call evgdata (l, im, skymap, sigmap, gainmap,
			    expmap, sptlmap, data, skydata, ssigdata,
			    gaindata, expdata, sigdata, sptldata)

		    pval = OBJ_PEAK(obj)
		    do c = c1, c2 {
			sky = Memr[skydata+c-1]
			val = Memr[data+c-1] - sky

			f2 = val * val
			r = sqrt ((c - OBJ_X(obj)) ** 2 + (l - OBJ_Y(obj)) ** 2)

			if (pval > 0. && r > 0.) {
			    x = val / pval
			    if (x > FW_I1 && x < FW_I2) {
				j = int ((x - FW_I1) / dfw) 
				y = r / Memr[fw_norm+j]
				wt = (1 - 2 * abs (x - 0.5)) / sqrt(y)
				OBJ_FWHM(obj) = OBJ_FWHM(obj) + y * wt
				Memr[sum_fw+num] = Memr[sum_fw+num]+wt
				if (y > FW_BIN1 && y < FW_BIN2) {
				    j = 1 + (y-FW_BIN1)/FW_BINWIDTH
				    Memr[fw_bins+j] = Memr[fw_bins+j]+wt
				} else
				    Memr[fw_bins] = Memr[fw_bins]+wt
			    }
			}

			OBJ_R(obj) = OBJ_R(obj) + r * val
			OBJ_RII(obj) = OBJ_RII(obj) + r * f2
			Memr[sum_f2+num] = Memr[sum_f2+num] + f2

			if (eafs != NULL) {
			    eaf = EAFS_EAF(eafs,num)
			    if (eaf == 0) {
				call eaf_init (eaf, obj)
				EAFS_EAF(eafs,num) = eaf
			    }
			    if (eaf > 0)
				call eaf_accum (eaf, obj, c, l, val)
			}
		    }

		    num = OBJ_PNUM(obj) - 1
		}
	    }

	    # Deallocate memory.
	    if (eafs != NULL) {
		rlptr = rl
		do i = 2, Memi[rl] {
		    rlptr = rlptr + 3
		    num = MNUM(Memi[rlptr+2]) - 1
		    obj = Memi[objs+num]
		    if (obj == NULL)
			break
		    if (l != OBJ_YMAX(obj))
			next
		    if (eafs != NULL) {
			eaf = EAFS_EAF(eafs,num)
			if (eaf > 0) {
			    call eaf_done (eafs, eaf, obj)
			    EAFS_EAF(eafs,num) = eaf
			}
		    }
		}
	    }
	}

	# Finish up the evaluations.
	fwhm = 0.
	nfwhm = 0.
	do i = NUMSTART-1, nummax-1 {
	    obj = Memi[objs+i]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,DARK) == 'D')
		next

	    x = Memr[sum_fw+i]
	    if (x > 0.) {
		fwhm = fwhm + OBJ_FWHM(obj)
		nfwhm = nfwhm + x
		OBJ_FWHM(obj) = OBJ_FWHM(obj) / x
	    } else
		OBJ_FWHM(obj) = INDEFR

	    f = OBJ_FLUX(obj)
	    if (f > 0.)
		OBJ_R(obj) = OBJ_R(obj) / f
	    else
		OBJ_R(obj) = INDEFR

	    f2 = Memr[sum_f2+i]
	    if (f2 > 0.)
		OBJ_RII(obj) = SQRTOF2 * OBJ_RII(obj) / f2
	    else
		OBJ_RII(obj) = INDEFR

	    if (IS_INDEFR(OBJ_FCORE(obj)))
		OBJ_FCORE(obj) = OBJ_PEAK(obj)
	}

	if (docaf)
	    call caf_free ()
	if (eafs != NULL)
	    call eaf_gdone (cat, eafs)

	# Set apportioned fluxes.
	call evapportion (cat, Memr[sum_s2x])

	# Finish global evaluations.

	# Identify stars.
	if (stars == NULL) {
	    stars = ivals
	    call evl_findstars (cat, Memi[stars], nstar, rstar, s,
		20, 10, Memr[sum_fw])
	}

	# Adjust zero points.
	if (IS_INDEFR(magzero) && docaf) {
	    # Set aperture corrections for fixed aperture fluxes.
	    f = 0.; f2 = 0.
	    do i = 0, nstar-1 {
		obj = Memi[stars+i]
		if (IS_INDEFR(OBJ_GWFLUX(obj)) ||
		    IS_INDEFR(OBJ_FRACFLUX(obj)) || OBJ_GWFLUX(obj) <= 0.)
		    next
		f = f + OBJ_FCORE(obj) * OBJ_FRACFLUX(obj) / OBJ_GWFLUX(obj)
		f2 = f2 + OBJ_FCORE(obj)
	    }
	    if (f2 > 0) {
		f = f / f2
		do i = NUMSTART-1, nummax-1 {
		    obj = Memi[objs+i]
		    if (obj == NULL)
			next
		    if (IS_INDEFR(OBJ_GWFLUX(obj)))
			next
		    OBJ_GWFLUX(obj) = f * OBJ_GWFLUX(obj)
		}
		call catputr (cat, "GWMAGZ", -2.5*log10(f))
	    }
	    if (docaf) {
		do j = 0, 9 {
		    call sprintf (Memc[str], SZ_LINE, "CAFLUX_%d")
		        call pargi (j)
		    sym = stfind (stp, Memc[str])
		    if (ENTRY_EVAL(sym) == NO)
		        break
		    f = 0.; f2 = 0.
		    do i = 0, nstar-1 {
			obj = Memi[stars+i]
			if (IS_INDEFR(OBJ_CAFLUX(obj,j)) ||
			    IS_INDEFR(OBJ_FRACFLUX(obj)) ||
			    OBJ_CAFLUX(obj,j) <= 0.)
			    next
			f = f + OBJ_FCORE(obj) * OBJ_FRACFLUX(obj) /
			    OBJ_CAFLUX(obj,j)
			f2 = f2 + OBJ_FCORE(obj)
		    }
		    if (f2 > 0) {
			f = f / f2
			do i = NUMSTART-1, nummax-1 {
			    obj = Memi[objs+i]
			    if (obj == NULL)
				next
			    if (IS_INDEFR(OBJ_CAFLUX(obj,j)))
				next
			    OBJ_CAFLUX(obj,j) = f * OBJ_CAFLUX(obj,j)
			}
			call sprintf (Memc[str], SZ_LINE, "CAMAGZ%d")
			    call pargi (j)
			call catputr (cat, Memc[str], -2.5*log10(f))
		    }
		}
	    }
	}

	# Find the FWHM histogram peak.
	f = 0; f2 = 0
	num = FW_BINMODE
	n = num / 2
	do i = 0, num-1
	    f = f + Memr[fw_bins+i]
	do i = num, fw_nbins-1 {
	    f = f - Memr[fw_bins+i-num] + Memr[fw_bins+i]
	    x = (i-n-0.5)*FW_BINWIDTH + FW_BIN1
	   if (f >= f2) {
	       j = i - n
	       f2 = f
	    }
	}

	# Record FWHM
	if (Memr[fw_bins] < 0.5 * nfwhm)
	    fwhm = (j-0.5)*FW_BINWIDTH + FW_BIN1
	else if (nfwhm > 0.)
	    fwhm = fwhm / nfwhm
	else
	    fwhm = INDEFR
	if (!IS_INDEFR(fwhm))
	    call catputr (cat, "FWHM", fwhm)

	# Set sort index if requested.
	if (Memc[order] != EOS) {
	    do i = 0, nummax-NUMSTART+1 {
		obj = Memi[objs+i+NUMSTART-1]
		if (obj == NULL)
		    next
		OBJ_ORDER(obj) = i
		Memr[sum_fw+i] = MAX_REAL
		if (OBJ_FLAG(obj,DARK) == 'D')
		    next
		ifnoerr (o = catexpr (Memc[order], cat, obj)) {
		    switch (O_TYPE(o)) {
		    case TY_BOOL, TY_INT:
		        Memr[sum_fw+i] = O_VALI(o)
		    case TY_REAL:
		        Memr[sum_fw+i] = O_VALR(o)
		    case TY_DOUBLE:
		        Memr[sum_fw+i] = O_VALD(o)
		    }
		    call evvfree (o)
		}
	    }
	    call gqsort (Memi[objs+NUMSTART-1], nummax-NUMSTART+1, compare,
		sum_fw)
	    j = 0
	    do i = 0, nummax-1 {
	        #obj = Memi[objs+Memi[ivals+i]]
	        obj = Memi[objs+i]
		if (obj == NULL)
		    next
		j = j + 1
		OBJ_ORDER(obj) = j
	    }
	}

	call sfree (sp)
end


# COMPARE -- Compare values of two objects for sorting.

int procedure compare (vals, i1, i2)

pointer	vals			#I Pointer to array of sort values
int	i1			#I Index of first object to compare
int	i2			#I Index of second object to compare

int	j1, j2

begin
	if (i1 == i2)
	    return (0)
	else if (i2 == NULL)
	    return (-1)
	else if (i1 == NULL)
	    return (1)

	j1 = OBJ_ORDER(i1)
	j2 = OBJ_ORDER(i2)

	if (Memr[vals+j1] < Memr[vals+j2])
	    return (-1)
	else if (Memr[vals+j1] > Memr[vals+j2])
	    return (1)
	else
	    return (0)
end


# EVAPPORTION -- Compute apportioned fluxes after the object isophotoal
# fluxes have been computed.

procedure evapportion (cat, sum_flux)

pointer	cat			#I Catalog
real	sum_flux[ARB]		#I Work array of size NUMMAX

int	nummax, num, pnum, nindef
pointer	objs, obj, pobj

begin
	objs = CAT_RECS(cat)
	nummax = CAT_NUMMAX(cat)

	call aclrr (sum_flux, nummax)
	do num = NUMSTART, nummax {
	    obj = Memi[objs+num-1]
	    if (obj == NULL)
		next
	    pnum = OBJ_PNUM(obj)
	    if (pnum == 0 || IS_INDEFI(pnum)) {
		OBJ_FRAC(obj) = 1.
		OBJ_FRACFLUX(obj) = OBJ_FLUX(obj)
		next
	    }

	    sum_flux[pnum] = sum_flux[pnum] + max (0., OBJ_FLUX(obj))
	    OBJ_FRACFLUX(obj) = INDEFR
	}

	nindef = 0
	do num = NUMSTART, nummax {
	    obj = Memi[objs+num-1]
	    if (obj == NULL)
		next
	    pnum = OBJ_PNUM(obj)
	    if (pnum == 0 || IS_INDEFI(pnum))
		next
	    pobj = Memi[objs+pnum-1]

	    if (sum_flux[pnum] > 0.) {
		OBJ_FRAC(obj) = max (0., OBJ_FLUX(obj)) / sum_flux[pnum]
		if (IS_INDEFR(OBJ_FRACFLUX(pobj)))
		    nindef = nindef + 1
		else
		    OBJ_FRACFLUX(obj) = OBJ_FRACFLUX(pobj) * OBJ_FRAC(obj)
	    } else {
		OBJ_FRAC(obj) = INDEFR
		OBJ_FRACFLUX(obj) = OBJ_FLUX(obj)
	    }
	}

	while (nindef > 0) {
	    nindef = 0
	    do num = NUMSTART, nummax {
		obj = Memi[objs+num-1]
		if (obj == NULL)
		    next
		pnum = OBJ_PNUM(obj)
		if (pnum == 0)
		    next

		pobj = Memi[objs+pnum-1]
		if (IS_INDEFR(OBJ_FRACFLUX(pobj)))
		    nindef = nindef + 1
		else {
		    if (IS_INDEFR(OBJ_FRAC(obj)))
			OBJ_FRACFLUX(obj) = OBJ_FLUX(obj)
		    else
			OBJ_FRACFLUX(obj) = OBJ_FRACFLUX(pobj) * OBJ_FRAC(obj)
		}
	    }
	}
end


# EVL_FINDSTARS -- Find stars as the lower bound of the moment radii.

procedure evl_findstars (cat, stars, nstar, r, s, nmin, nit, work)

pointer	cat				#I Catalog
pointer	stars[ARB]			#O Array of stars (>= CAT_NUMMAX)
int	nstar				#O Number of stars
real	r				#O Average moment radius
real	s				#O Sigma of moment radius
int	nmin				#I Minimum number of stars
int	nit				#I Maximum number of iterations
real	work[ARB]			#O Work array (>= CAT_NUMMAX)

int	i, j, k, nummax
real	isigavg, xx, yy, xy
pointer	objs, obj

int	awvgr()

begin
	    objs = CAT_RECS(cat)
	    nummax = CAT_NUMMAX(cat)

	    # Preselect brighter, single, objects with measured moment radius.
	    nstar = 0
	    for (isigavg=50.; nstar<nmin&&isigavg>=20.; isigavg=isigavg-10.) {
		nstar = 0
		do i = NUMSTART-1, nummax-1 {
		    obj = Memi[objs+i]
		    if (obj == NULL)
			next
		    xx = OBJ_XX(obj); yy = OBJ_YY(obj); xy = OBJ_XY(obj)
		    if (OBJ_ISIGAVG(obj) < isigavg || IS_INDEFR(xx) ||
			IS_INDEFR(yy) || IS_INDEFR(xy))
			next
		    if (OBJ_FLAG(obj,DARK) == 'D' || OBJ_FLAG(obj,SPLIT) == 'M')
			next

		    # Axis ratio > 0.9.
		    if (xx <= 0.01 || yy <= 0.01)
			next
		    xy = sqrt (max (0., xx - yy + 4 * xy**2))
		    if (xx + yy - xy < 0.81 * (xx + yy + xy))
			next

		    nstar = nstar + 1
		    stars[nstar] = obj
		    work[nstar] = sqrt (OBJ_XX(obj) + OBJ_YY(obj))
		}
		if (nstar == 0)
		    next

		# Do asymmetric sigma clipping.
		j = awvgr (work, nstar, r, s, 0., 0.)
		if (IS_INDEFR(r) || IS_INDEFR(s))
		    next
		do i = 1, nit {
		    k = awvgr (work, nstar, r, s, r-3*s, r+s)
		    if (k == j || k == 0 || IS_INDEFR(r) || IS_INDEFR(s))
			break
		    j = k
		}

		# Eliminate rejected objects and flag those accepted.
		if (IS_INDEFR(r) || IS_INDEFR(s))
		    next
		xx = r - s; yy = 2 * s
		j = nstar
		nstar = 0; r = 0.
		do i = 1, j {
		    if (abs (work[i] - xx) > yy)
			next
		    nstar = nstar + 1
		    r = r + work[i]
		    stars[nstar] = stars[i]
		}
		if (nstar > 0)
		    r = r / nstar
	    }

	    # Finish up.
	    do i = 1, nstar
		OBJ_FLAG(stars[i],RCLIP) = 'R'
	    if (nstar == 0) {
	        r = INDEFR
		s = INDEFR
	    }
end


# EVGDATA -- Get evaluation data for an image line.

procedure evgdata (l, im, skymap, sigmap, gainmap, expmap, sptlmap,
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

int	i, nc
real	sptlnorm, asumr()
pointer	ptr, imgl2r(), map_glr()
errchk	imgl2r, map_glr, noisemodel

begin
	# Initialize if line is zero.
	if (l == 0) {
	    sptlnorm = 1
	    if (sptlmap == NULL)
	        return
	    iferr (call map_geti (sptlmap, "im", ptr))
	        return
	    sptlnorm = 0
	    nc = IM_LEN(ptr,1)
	    do i = 1, IM_LEN(ptr,2)
	        sptlnorm = sptlnorm + asumr (Memr[imgl2r(ptr,i)], nc) / nc
	    sptlnorm = sptlnorm / IM_LEN(ptr,2)
	    return
	}

	nc = IM_LEN(im,1)
	data = imgl2r (im, l)
	skydata = map_glr (skymap, l, READ_ONLY)
	ssigdata = map_glr (sigmap, l, READ_ONLY)
	if (gainmap == NULL && expmap == NULL)
	    sigdata = ssigdata
	else if (expmap == NULL) {
	    gaindata = map_glr (gainmap, l, READ_ONLY)
	    call noisemodel (Memr[data], Memr[skydata],
		Memr[ssigdata], Memr[gaindata], INDEFR,
		Memr[sigdata], nc)
	} else if (gainmap == NULL) {
	    expdata = map_glr (expmap, l, READ_WRITE)
	    call noisemodel (Memr[data], Memr[skydata],
		Memr[ssigdata], INDEFR, Memr[expdata],
		Memr[sigdata], nc)
	} else {
	    gaindata = map_glr (gainmap, l, READ_ONLY)
	    expdata = map_glr (expmap, l, READ_WRITE)
	    call noisemodel (Memr[data], Memr[skydata],
		Memr[ssigdata], Memr[gaindata],
		Memr[expdata], Memr[sigdata], nc)
	}
	if (sptlmap != NULL) {
	    sptldata = map_glr (sptlmap, l, READ_ONLY)
	    if (sptlnorm != 1.)
		call adivkr (Memr[sptldata], sptlnorm, Memr[sptldata], nc)
	}
end
