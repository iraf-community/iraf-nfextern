include	<math.h>
include	<acecat.h>
include	<acecat1.h>
include	"gwt.h"


# GWT_GINIT -- Global initialization.
#	1. Allocate memory
#	2. Set weights

procedure gwt_ginit (cat, sig, nsig, nsub, gwts, logfd, verbose)

pointer	cat			#I Catalog structure
real	sig			#I Sigma for stellar flux weighting (pixel)
real	nsig			#I Number of sigma for centroid weighting
int	nsub			#I Subpixel sampling (1D)
pointer	gwts			#O GWT global structure
int	logfd			#I Log file descriptor
int	verbose			#I Verbose level

int	i
real	wtstep
pointer	wts

errchk	calloc

begin
	# Allocate memory.
	call calloc (gwts, GWTS_LEN(CAT_NUMMAX(cat)), TY_STRUCT)

	# Compute the weights on a normalized scale and discrete sampling.
	# Note the weights include the pixel subsampling size.

	if (IS_INDEFR(sig) || sig <= 0.)
	    GWTS_SIG(gwts) = GWTS_SIGDEF
	else
	    GWTS_SIG(gwts) = sig
	if (IS_INDEFR(nsig))
	    GWTS_NSIG(gwts) = GWTS_NSIGDEF
	else
	    GWTS_NSIG(gwts) = nsig
	if (IS_INDEFI(nsub))
	    GWTS_NSUB(gwts) = 1
	else
	    GWTS_NSUB(gwts) = nsub

	wtstep = real(GWTS_RAD) / (GWTS_NWTS - 1)
	wts = GWTS_WTS(gwts)
	do i = 0, GWTS_NWTS-2
	    Memr[P2R(wts+i)] = exp (-0.5 * (i*wtstep)**2)

	# Log parameters.
	call catputr (cat, "GWTSIG", GWTS_SIG(gwts))
	call catputr (cat, "GWTNSIG", GWTS_NSIG(gwts))
	if (logfd != NULL) {
	    call fprintf (logfd,
	        "    gwtsig = %4.2f, gwtnsig = %3.1f, gwtnsub = %g\n")
		call pargr (GWTS_SIG(gwts))
		call pargr (GWTS_NSIG(gwts))
		call pargi (GWTS_NSUB(gwts))
	}
	if (verbose > 1) {
	    call printf ("    gwtsig = %4.2f, gwtnsig = %3.1f, gwtnsub = %g\n")
		call pargr (GWTS_SIG(gwts))
		call pargr (GWTS_NSIG(gwts))
		call pargi (GWTS_NSUB(gwts))
	}
end


# GWT_GDONE -- Global done for the weighted moments measurements.

procedure gwt_gdone (cat, gwts)

pointer	cat			#I Catalog structure
pointer	gwts			#O GWT global structure

begin
	call mfree (gwts, TY_STRUCT)
end


# GWT_INIT -- Initialize weighted moments measurements for an object.

procedure gwt_init (gwts, gwt, xc, yc, xx, yy)

pointer	gwts		#I Global structure
pointer gwt		#O GWT pointer for object
real	xc, yc		#I Starting center
real	xx, yy		#I Second central moments for setting sigma

int	nbins
errchk	calloc

begin
	# Check if center is defined.
	if (IS_INDEFR(xc) || IS_INDEF(yc)) {
	    gwt = -1
	    return
	}

	nbins = GWTS_RMAX / GWTS_RSTEP + 1
	call calloc (gwt, GWT_LEN(nbins), TY_STRUCT)

	if (IS_INDEFR(xx) || IS_INDEF(yy))
	    GWT_SIG(gwt) = GWTS_SIG(gwts)
	else
	    GWT_SIG(gwt) =  sqrt ((xx + yy) / 2.)
	GWT_NBINS(gwt) = nbins

	GWT_XC(gwt) = xc
	GWT_YC(gwt) = yc
	GWT_FCORE(gwt) = 0.
end


# GWT_ACCUM -- Accumulate pixels for weighted moment measurements.
# We accumulate over a set of centers near the starting center.  At the
# end we will take the average centroid value.

procedure gwt_accum (gwts, gwt, c, l, v, grw, sptl)

pointer	gwts			#I GWT global structure
pointer	gwt			#I GWT pointer for object
int	c, l			#I Pixel coordinate
real	v			#I Sky subtracted flux value
bool	grw			#I Grown pixel?
real	sptl			#I Spatial scale

int	i, j, k, nsub, nbins, iwt
real	x, y, xx, yy, xy, r, wt
real	sig, val, xc, yc, nsub0, nsub1, wtstep1, wtstep2, rstep
real	pfrac
pointer	wts, wp1, wp2, np, fp, xp, yp, xxp, yyp, xyp


begin
	# Initialize.
	grw = false
	nsub = GWTS_NSUB(gwts) - 1
	nsub0 = nsub / 2.
	nsub1 = 1. / (nsub + 2)
	nbins = GWT_NBINS(gwt)
	rstep = GWTS_RSTEP
	wts = GWTS_WTS(gwts)
	sig = GWTS_SIG(gwts) * sptl
	wtstep1 = (GWTS_NWTS-1) / real(GWTS_RAD) / sig
	wtstep2 = (GWTS_NWTS-1) / real(GWTS_RAD) /
	    (GWTS_NSIG(gwts) *GWT_SIG(gwt))
	pfrac = 1. / (GWTS_NSUB(gwts) * GWTS_NSUB(gwts))
	val = TWOPI * sig * sig * v * pfrac

	xc = c - GWT_XC(gwt)
	yc = l - GWT_YC(gwt)
	wp1 = GWT_WT1(gwt)
	wp2 = GWT_WT2(gwt)
	np = GWT_N(gwt)
	fp = GWT_F(gwt)
	xp = GWT_X(gwt)
	yp = GWT_Y(gwt)
	xxp = GWT_XX(gwt)
	yyp = GWT_YY(gwt)
	xyp = GWT_XY(gwt)

	if (nsub > 1) {
	    do j = 0, nsub {
		y = yc + (j - nsub0) * nsub1
		yy = y * y
		do i = 0, nsub {
		    x = xc + (i - nsub0) * nsub1
		    xx = x * x
		    xy = x * y
		    r = sqrt (xx + yy)
		    if (r > GWTS_RMIN && grw)
			next
		    k = min (int(r/rstep), nbins-1)
		    Memr[P2R(np+k)] = Memr[P2R(np+k)] + pfrac

		    if (r < 1.1)
			GWT_FCORE(gwt) = GWT_FCORE(gwt) + v * pfrac

		    iwt = min (GWTS_NWTS-1, nint (r * wtstep1))
		    wt = Memr[P2R(wts+iwt)]**2
		    if (wt > 0.) {
			Memr[P2R(wp1+k)] = Memr[P2R(wp1+k)] + wt * wt
			Memr[P2R(fp+k)] = Memr[P2R(fp+k)] + wt * val
		    }

		    iwt = min (GWTS_NWTS-1, nint (r * wtstep2))
		    wt = Memr[P2R(wts+iwt)]
		    if (wt > 0.) {
			wt = wt * val
			Memr[P2R(wp2+k)] = Memr[P2R(wp2+k)] + wt
			Memr[P2R(xp+k)] = Memr[P2R(xp+k)] + wt * x
			Memr[P2R(yp+k)] = Memr[P2R(yp+k)] + wt * y
			Memr[P2R(xxp+k)] = Memr[P2R(xxp+k)] + wt * xx
			Memr[P2R(yyp+k)] = Memr[P2R(yyp+k)] + wt * yy
			Memr[P2R(xyp+k)] = Memr[P2R(xyp+k)] + wt * xy
		    }
		}
	    }
	} else {
	    xx = xc * xc
	    yy = yc * yc
	    xy = xc * yc
	    r = sqrt (xx + yy)
	    if (r <= GWTS_RMIN || !grw) {
		k = min (int(r/rstep), nbins-1)
		Memr[P2R(np+k)] = Memr[P2R(np+k)] + pfrac

		if (r < 1.1)
		    GWT_FCORE(gwt) = GWT_FCORE(gwt) + v * pfrac

		iwt = min (GWTS_NWTS-1, nint (r * wtstep1))
		wt = Memr[P2R(wts+iwt)]
		if (wt > 0.) {
		    Memr[P2R(wp1+k)] = Memr[P2R(wp1+k)] + wt * wt
		    Memr[P2R(fp+k)] = Memr[P2R(fp+k)] + wt * val
		}

		iwt = min (GWTS_NWTS-1, nint (r * wtstep2))
		wt = Memr[P2R(wts+iwt)]
		if (wt > 0.) {
		    wt = wt * val
		    Memr[P2R(wp2+k)] = Memr[P2R(wp2+k)] + wt
		    Memr[P2R(xp+k)] = Memr[P2R(xp+k)] + wt * xc
		    Memr[P2R(yp+k)] = Memr[P2R(yp+k)] + wt * yc
		    Memr[P2R(xxp+k)] = Memr[P2R(xxp+k)] + wt * xx
		    Memr[P2R(yyp+k)] = Memr[P2R(yyp+k)] + wt * yy
		    Memr[P2R(xyp+k)] = Memr[P2R(xyp+k)] + wt * xy
		}
	    } 
	}
end


# GWT_DONE -- Finish weighted moment measurements.

procedure gwt_done (gwts, gwt, dx, dy, r, xx, yy, xy, fcore, gwflux)

pointer	gwts			#I GWTS pointer
pointer	gwt			#U GWT pointer for object
real	dx, dy			#O Correction
real	r			#O Object moment radius
real	xx, yy, xy		#O New moments
real	fcore			#O New core flux
real	gwflux			#O Gaussian weighted flux

real	wt1, wt2, asumr()
pointer	wp1, wp2, np, fp, xp, yp, xxp, yyp, xyp

begin
	# Initialize.
	wp1 = GWT_WT1(gwt)
	wp2 = GWT_WT2(gwt)
	np = GWT_N(gwt)
	fp = GWT_F(gwt)
	xp = GWT_X(gwt)
	yp = GWT_Y(gwt)
	xxp = GWT_XX(gwt)
	yyp = GWT_YY(gwt)
	xyp = GWT_XY(gwt)

	# Photometry
	wt1 = asumr (Memr[P2R(wp1)], GWT_NBINS(gwt))
	if (wt1 > 0.) {
	    Memr[P2R(fp)] = asumr (Memr[P2R(fp)], GWT_NBINS(gwt))
	    gwflux = Memr[P2R(fp)] / wt1
	}
	fcore = GWT_FCORE(gwt)

	# Astrometry
	dx = 0.; dy = 0.; r = 1.
	call gwt_wt1d (gwts, gwt, Memr[P2R(GWTS_WTS(gwts))], GWTS_NWTS,
	    Memr[P2R(wp2)], Memr[P2R(np)], Memr[P2R(xp)], Memr[P2R(yp)],
	    Memr[P2R(xxp)], Memr[P2R(yyp)], Memr[P2R(xyp)], GWT_NBINS(gwt))
	wt2 = Memr[P2R(wp2)]
	if (wt2 > 0.) {
	    dx = Memr[P2R(xp)] / wt2
	    dy = Memr[P2R(yp)] / wt2
	    Memr[P2R(xxp)] = Memr[P2R(xxp)] / wt2 - dx * dx
	    Memr[P2R(yyp)] = Memr[P2R(yyp)] / wt2 - dy * dy
	    Memr[P2R(xyp)] = Memr[P2R(xyp)] / wt2 - dx * dy

#	    if (Memr[P2R(xxp)] >= 0.01 && Memr[P2R(yyp)] >= 0.01) {
#		xx = Memr[P2R(xxp)]
#		yy = Memr[P2R(yyp)]
#		xy = Memr[P2R(xyp)]
#	    }
	    dx = dx * 1.5
	    dy = dy * 1.5
	    r = sqrt (xx + yy)
	}

	# Free memory.
	call mfree (gwt, TY_STRUCT)
end


# GWT_WT1D -- Combine the ring accumulations with possible weights.
#
# Experiments did not find that applying weights or
# eliminating the outer rings made a difference.

procedure gwt_wt1d (gwts, gwt, wts, nwts, np, w, x, y, xx, yy, xy, n)

pointer	gwts, gwt
real	wts[nwts]
real	np[n], w[n], x[n], y[n], xx[n], yy[n], xy[n]
int	nwts, n

int	i

begin
	do i = 2, n {
	    np[1] = np[1] + np[i]
	    w[1] = w[1] + w[i]
	    x[1] = x[1] + x[i]
	    y[1] = y[1] + y[i]
	    xx[1] = xx[1] + xx[i]
	    yy[1] = yy[1] + yy[i]
	    xy[1] = xy[1] + xy[i]
	}
end
