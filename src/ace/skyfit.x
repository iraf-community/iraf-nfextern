include	<error.h>
include	<imhdr.h>
include	<mach.h>
include	<math/curfit.h>
include	<math/gsurfit.h>
include	"skyfit.h"

# http://en.wikipedia.org/wiki/Median_absolute_deviation
define SFACTOR 0.6745


# SKY_FIT -- Fit sky surface.
#
# Compute a sky and/or sky sigma surface fit using a subset of the input
# lines.  The input sky and sky sigma pointers are NULL.  The initial
# data for the surface fit is measured at a subset of lines with any
# masked pixels excluded.  Objects are removed by fitting a 1D curve
# to each line, rejecting points with large residuals, and iterating
# until only sky is left.  The sky points are then accumulated for a 2D
# surface fit and the residuals are added to a histogram.  The absolute
# deviations, scaled by 0.6745 to convert to an gausian sigma (see
# http://en.wikipedia.org/wiki/Median_absolute_deviation), are accumulated
# for a sky sigma surface fit.  After all the sample lines are accumulated
# the surface fits are computed.  The histogram of residuals is then fit by
# a gaussian to estimate an offset from the sky fit to the sky mode caused
# by unrejected object light.  The offset is applied to the sky surface.

procedure sky_fit (par, dosky, dosig, im, bpm, expmap, skyname, signame,
	skymap, sigmap, logfd, verbose)

pointer	par			#U Sky parameters
bool	dosky			#I Compute sky
bool	dosig			#I Compute sigma
pointer	im			#I Input image
pointer	bpm			#I Input mask
pointer	expmap			#I Exposure map
char	skyname[ARB]		#I Sky map name
char	signame[ARB]		#I Sigma map name
pointer	skymap			#U Sky map
pointer	sigmap			#U Sigma map
int	logfd			#I Log FD
int	verbose			#I Verbose level

# Parameters
real	step			# Line sample step
int	lmin			# Minimum number of lines to fit
int	func1d			# 1D fitting function
int	func2d			# 2D fitting function
int	xorder			# Sky fitting x order
int	yorder			# Sky fitting y order
int	xterms			# Sky fitting cross terms
int	blk1d			# Block average
real	hclip			# Sky fitting high sigma clip
real	lclip			# Sky fitting low sigma clip
int	niter			# Number of clipping iterations

int	l1, l2
int	i, j, c, l, m, n, nc, nl, nskyblk, nskyblk1, nused, ier
real	res, sigma, sigma2, med, sfactor
pointer	sp, x, y, z, r, a, x1, w1, w2, w3, skydata, sigdata, expdata, w, ptr
pointer	imbuf, skybuf, wdat, skydat
pointer	cvsky, cvsig, gssky, gssig

pointer	imgl2r(), imgl2i(), map_opengs(), map_glr()
bool	im_pmlne2()
int	aravr()
real	amedr()
errchk	map_opengs, map_glr, imgl2r, imgl2i

begin
	if (!(dosky||dosig))
	    return

	# Set parameters.
	if (par == NULL)
	    call skf_pars ("open", "", par)
	step = SKF_STEP(par)
	lmin = SKF_LMIN(par)
	xorder = SKF_XORDER(par)
	yorder = SKF_YORDER(par)
	xterms = SKF_XTERMS(par)
	blk1d = SKF_BLK1D(par)
	hclip = SKF_HCLIP(par)
	lclip = SKF_LCLIP(par)
	func1d = SKF_FUNC1D(par)
	func2d = SKF_FUNC2D(par)
	niter = SKF_NITER(par)

	nc = IM_LEN(im,1)
	nl = IM_LEN(im,2)
	l1 = 1 + step / 2
	l2 = nl - step / 2
	step = real (l2-l1) / max (nint((l2-l1)/step),xorder+2,lmin)

	if (logfd != NULL) {
	    if (dosky && dosig)
		call fprintf (logfd,
		    "    Determine sky and sigma by surface fits:\n")
	    else if (dosky)
		call fprintf (logfd, "    Determine sky by surface fit:\n")
	    else
		call fprintf (logfd, "    Determine sigma by constant fit:\n")
	    call fprintf (logfd,
		"      start line = %d, end line = %d, step = %.1f\n")
		call pargi (l1)
		call pargi (l2)
		call pargr (step)
	    call fprintf (logfd,
		"      xorder = %d, yorder = %d, xterms = %s\n")
		call pargi (xorder)
		call pargi (yorder)
		switch (xterms) {
		case GS_XNONE:
		    call pargstr ("none")
		case GS_XFULL:
		    call pargstr ("full")
		case GS_XHALF:
		    call pargstr ("half")
		}
	    call fprintf (logfd, "      hclip = %g, lclip = %g\n")
		call pargr (hclip)
		call pargr (lclip)
	}
	if (verbose > 1) {
	    if (dosky && dosig)
		call printf ("    Determine sky and sigma by surface fits:\n")
	    else if (dosky)
		call printf ("    Determine sky by surface fit:\n")
	    else
		call printf ("    Determine sigma by constant fit:\n")
	    call printf ("      start line = %d, end line = %d, step = %.1f\n")
		call pargi (l1)
		call pargi (l2)
		call pargr (step)
	    call printf ("      xorder = %d, yorder = %d, xterms = %s\n")
		call pargi (xorder)
		call pargi (yorder)
		switch (xterms) {
		case GS_XNONE:
		    call pargstr ("none")
		case GS_XFULL:
		    call pargstr ("full")
		case GS_XHALF:
		    call pargstr ("half")
		}
	    call printf ("      hclip = %g, lclip = %g\n")
		call pargr (hclip)
		call pargr (lclip)
	}

	# Allocate memory and initialize.
	call smark (sp)
	call salloc (skydat, nc, TY_REAL)
	call salloc (wdat, nc, TY_REAL)
	call salloc (x1, nc, TY_REAL)
	call salloc (w1, nc, TY_REAL)
	call salloc (w2, nc, TY_REAL)

	nskyblk = nc / blk1d
	call salloc (x, nskyblk, TY_REAL)
	call salloc (y, nskyblk, TY_REAL)
	call salloc (z, nskyblk, TY_REAL)
	call salloc (r, nskyblk, TY_REAL)
	call salloc (a, nskyblk, TY_REAL)
	call salloc (skydata, nskyblk, TY_REAL)
	call salloc (sigdata, nskyblk, TY_REAL)
	if (expmap != NULL)
	    call salloc (expdata, nskyblk, TY_REAL)

	do c = 1, nc
	    Memr[x1+c-1] = c
	call amovkr (1., Memr[w1], nc)

	# Initialize the 1D and 2D fitting pointers as needed.
	if (dosky) {
	    call cvinit (cvsky, func1d, xorder, Memr[x1],
		Memr[x1+nc-1])
	    call gsinit (gssky, func2d, xorder, yorder,
		xterms, 1., real(nc), 1., real(nl))
	}
	if (dosig) {
	    call cvinit (cvsig, CHEBYSHEV, 1, Memr[x1], Memr[x1+nc-1])
	    call gsinit (gssig, GS_CHEBYSHEV, 1, 1, xterms,
		1., real(nc), 1., real(nl))
	}

	# For each sample line find sky points by 1D fitting and sigma
	# rejection and then accumulate 2D surface fitting points.
	nused = 0
	do m = 1, 2 {
	    do j = 0, ARB {
		l = nint (l1 + j * step)
		if (l > l2)
		    break

		# Get input data and block average.
		if (m == 2 || bpm == NULL) {
		    w3 = w1
		    w = w1
		    nused = nused + nc
		} else if (!im_pmlne2 (bpm, l)) {
		    w3 = w1
		    w = w1
		    nused = nused + nc
		} else {
		    w = imgl2i (bpm, l)
		    n = nc
		    do c = 0, nc-1 {
			if (Memi[w+c] != 0) {
			    Memr[w2+c] = 0
			    n = n - 1
			} else
			    Memr[w2+c] = Memr[w1+c]
		    }
		    w3 = wdat
		    w = w2
		    if (n < 10)
			next
		    call amovr (Memr[w], Memr[wdat], nc)
		    nused = nused + n
		}

		# Block average.
		if (skymap != NULL) {
		    ptr = map_glr (skymap, l, READ_ONLY)
		    call amovr (Memr[skybuf], Memr[skydat], nc)
		    call blkavg1 (Memr[skydat], Memr[w], nc, Memr[skydata],
			nskyblk, nskyblk1, blk1d)
		}
		if (expmap != NULL) {
		    ptr = map_glr (expmap, l, READ_ONLY)
		    call blkavg1 (Memr[ptr], Memr[w], nc, Memr[expdata],
			nskyblk, nskyblk1, blk1d)
		}
		if (sigmap != NULL) {
		    ptr = map_glr (sigmap, l, READ_ONLY)
		    call blkavg1 (Memr[ptr], Memr[w], nc, Memr[sigdata],
			nskyblk, nskyblk1, blk1d)
		    call adivkr (Memr[sigdata], sqrt(real(blk1d)),
		        Memr[sigdata], nskyblk)
		    if (expmap != NULL)
			call expsigma (Memr[sigdata], Memr[expdata], nskyblk, 0)
		}
		imbuf = imgl2r (im, l)
		call blkavg (Memr[x1], Memr[imbuf], Memr[w], nc, Memr[x],
		    Memr[z], Memr[w2], nskyblk, nskyblk1, blk1d)
		w = w2

		# Too few blocks.
		if (nskyblk1 < 3) {
		    nused = nused - n
		    next
		}

		# Iterate using line fitting.
		do i = 1, niter {

		    # Fit sky.
		    if (dosky) {
			call cvfit (cvsky, Memr[x], Memr[z], Memr[w], nskyblk1,
			    WTS_USER, ier)
			if (ier == NO_DEG_FREEDOM)
			    call error (1, "Fitting error")
			call cvvector (cvsky, Memr[x], Memr[skydata], nskyblk1)
			if (i == 1 && skymap == NULL)
			    call cvvector (cvsky, Memr[x1], Memr[skydat], nc)
		    }

		    # Compute residuals.
		    call asubr (Memr[z], Memr[skydata], Memr[r], nskyblk1)

		    if (dosig) {
		    # Compute sigma for determining sfactor.
			if (i == 1) {
			    call asubr (Memr[imbuf], Memr[skydat],
			        Memr[skydat], nc)
			    if (w3 == wdat) {
				n = 0
				do c = 0, nc-1 {
				    if (Memr[w3+c] == 0)
					next
				    Memr[skydat+n] = Memr[skydat+c]
				    n = n + 1
				}
			    } else
				n = nc
			    ier = aravr (Memr[skydat], n, sfactor, sigma2, 0.)
			    sigma2 = sigma2 / sqrt(real(blk1d))
			}

			# Check for constant data.
			if (sigma2 <= 0.)
			    next

			# Fit sky sigma.
		        if (i == 1) {
			    do c = 0, nskyblk1-1
				Memr[a+c] = abs(Memr[r+c])
			    med = amedr (Memr[a], nskyblk1)
			    sfactor = max (0.1, med / sigma2)
			    if (sfactor > 0.9 * SFACTOR)
				sfactor = SFACTOR
			    do c = 0, nskyblk1-1
				Memr[a+c] = Memr[a+c] / sfactor
			    med = med / sfactor
			} else {
			    do c = 0, nskyblk1-1
				Memr[a+c] = abs(Memr[r+c]) / sfactor
			    med = amedr (Memr[a], nskyblk1)
			}
			if (med <= 0.)
			    next
			if (expmap != NULL)
			    call expsigma (Memr[a], Memr[expdata], nskyblk1, 1)
			if (i == 1)
			    call amovkr (med, Memr[sigdata], nskyblk1)
			else {
			    call cvfit (cvsig, Memr[x], Memr[a], Memr[w],
			        nskyblk1, WTS_USER, ier)
			    if (ier == NO_DEG_FREEDOM)
				call error (1, "Fitting error")
			    call cvvector (cvsig, Memr[x], Memr[sigdata],
			        nskyblk1)
			}
			if (expmap != NULL)
			    call expsigma (Memr[sigdata], Memr[expdata],
			        nskyblk1, 0)
		    }

		    # Reject deviant points.
		    n = 0
		    do c = 0, nskyblk1-1 {
			if (Memr[w+c] == 0.)
			    next
			res = Memr[r+c]
			sigma = Memr[sigdata+c]
			if (res > hclip * sigma || res < -lclip * sigma) {
			    Memr[w+c] = 0.
			    n = n + 1
			}
		    }
		    if (n == 0) {
			if (i == 1 && dosig) {
			    call cvfit (cvsig, Memr[x], Memr[a], Memr[w],
			        nskyblk1, WTS_USER, ier)
			    if (ier == NO_DEG_FREEDOM)
				call error (1, "Fitting error")
			}
			break
		    }
		}

		# Accumulate the sky data for the line.
		call amovkr (real(l), Memr[y], nskyblk1)
		if (dosky && dosig) {
		    call amulkr (Memr[a], sqrt(real(blk1d)), Memr[a], nskyblk1)
		    call gsacpts (gssky, Memr[x], Memr[y], Memr[z], Memr[w],
			nskyblk1, WTS_USER)
		    call gsacpts (gssig, Memr[x], Memr[y], Memr[a], Memr[w],
			nskyblk1, WTS_USER)
		} else if (dosky) {
		    call gsacpts (gssky, Memr[x], Memr[y], Memr[z], Memr[w],
			nskyblk1, WTS_USER)
		} else {
		    call amulkr (Memr[a], sqrt(real(blk1d)), Memr[a], nskyblk1)
		    call gsacpts (gssig, Memr[x], Memr[y], Memr[a],
			Memr[w], nskyblk1, WTS_USER)
		}
	    }
	    if (nused != 0)
	        break

	    iferr (call error (1, "Only constant or masked data for sky fitting")) {
	        if (m == 1)
		    call erract (EA_WARN)
		else
		    call erract (EA_ERROR)
	    }
	}

	# Compute the surface fits, store in header, and set output pointers.
	if (dosky) {
	    if (skymap != NULL)
	        call map_close (skymap)
	    call cvfree (cvsky)
	    call gssolve (gssky, ier)
	    if (ier == NO_DEG_FREEDOM)
		call error (1, "Fitting error")
	    if (skyname[1] != EOS)
		call mgs_pgs (im, skyname, gssky)
	    skydata = map_opengs (gssky, im); skymap = skydata
	}
	if (dosig) {
	    if (sigmap != NULL)
	        call map_close (sigmap)
	    call cvfree (cvsig)
	    call gssolve (gssig, ier)
	    if (ier == NO_DEG_FREEDOM)
		call error (1, "Fitting error")
	    if (signame[1] != EOS)
		call mgs_pgs (im, signame, gssig)
	    sigdata = map_opengs (gssig, im); sigmap = sigdata
	}

	call sfree (sp)
end


procedure blkavg (xin, yin, win, nin, xout, yout, wout, nmax, nout, blksize)

real	xin[nin]		#I Input values
real	yin[nin]		#I Input values
real	win[nin]		#I Input weights
int	nin			#I Number of input values
real	xout[nmax]		#O Output values
real	yout[nmax]		#O Output values
real	wout[nmax]		#O Output weights
int	nmax			#I Maximum number of output values
int	nout			#O Number of output values
int	blksize			#I Block size

int	i, j, n, imax
real	xavg, yavg, wsum, w

begin
	if (blksize == 1) {
	    nout = nin
	    call amovr (xin, xout, nout)
	    call amovr (yin, yout, nout)
	    call amovr (win, wout, nout)
	    return
	}

	n = blksize
	imax = nin - 2 * blksize + 1
	nout = 0
	for (i=1; i<=nin; ) {
	    if (i > imax)
		n = nin - i + 1
	    xavg = 0.
	    yavg = 0.
	    wsum = 0.
	    do j = 1, n {
		w = win[i]
		xavg = xavg + w * xin[i] 
		yavg = yavg + w * yin[i] 
		wsum = wsum + w
		i = i + 1
	    }
	    if (wsum > 0.) {
		nout = nout + 1
		xout[nout] = xavg / wsum
		yout[nout] = yavg / wsum
		wout[nout] = wsum
	    }
	}
end


procedure blkavg1 (in, win, nin, out, nmax, nout, blksize)

real	in[nin]			#I Input values
real	win[nin]		#I Input weights
int	nin			#I Number of input values
real	out[nmax]		#O Output values
int	nmax			#I Maximum number of output values
int	nout			#O Number of output values
int	blksize			#I Block size

int	i, j, n, imax
real	avg, wsum, w

begin
	if (blksize == 1) {
	    nout = nin
	    call amovr (in, out, nout)
	    return
	}

	n = blksize
	imax = nin - 2 * blksize + 1
	nout = 0
	for (i=1; i<=nin; ) {
	    if (i > imax)
		n = nin - i + 1
	    avg = 0.
	    wsum = 0.
	    do j = 1, n {
		w = win[i]
		avg = avg + w * in[i] 
		wsum = wsum + w
		i = i + 1
	    }
	    if (wsum > 0.) {
		nout = nout + 1
		out[nout] = avg / wsum
	    }
	}
end
