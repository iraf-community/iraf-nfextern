include	<math.h>
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>


procedure catshape (obj, a, b, theta, elong, ellip, r, cxx, cyy, cxy,
	aerr, berr, thetaerr, cxxerr, cyyerr, cxyerr)

pointer	obj			#I Object structure
real	a			#O Semimajor axis based on second moments
real	b			#O Semiminor axis based on second moments
real	theta			#O Position angle based on second moments
real	elong			#O Elongation (A/B)
real	ellip			#O Ellipticity (1 - B/A)
real	r			#O Radius based on second moments
real	cxx, cyy, cxy		#O Ellipse parameters based on second moments
real	aerr, berr, thetaerr	#O Errors
real	cxxerr, cyyerr, cxyerr	#O Errors

bool	doerr
real	x2, y2, xy, r2, d, f
real	xvar, yvar, xycov, rvar, dvar, fvar

begin
	a = INDEFR
	b = INDEFR
	theta = INDEFR
	elong = INDEFR
	ellip = INDEFR
	r = INDEFR
	aerr = INDEFR
	berr = INDEFR
	thetaerr = INDEFR
	cxxerr = INDEFR
	cyyerr = INDEFR
	cxyerr = INDEFR
	x2 = OBJ_XX(obj)
	y2 = OBJ_YY(obj)
	xy = OBJ_XY(obj)
	xvar = OBJ_XVAR(obj)
	yvar = OBJ_YVAR(obj)
	xycov = OBJ_XYCOV(obj)

	if (IS_INDEFR(x2) || IS_INDEFR(y2) || IS_INDEFR(xy))
	    return

	if (x2 <= 0.)
	    x2 = 0.01
	if (y2 <= 0.)
	    y2 = 0.01

	r2 = x2 + y2
	if (r2 < 0.)
	    return

	doerr = !(IS_INDEF(xvar) || IS_INDEF(yvar) || IS_INDEF(xycov))
	if (doerr) {
	    rvar = xvar + yvar
	    if (rvar < 0.)
	       doerr = false
	}

	r = sqrt (r2 / 2)
	#r = sqrt (r2)

	d = x2 - y2
	theta = RADTODEG (atan2 (2 * xy, d) / 2.)

	if (doerr) {
	    dvar = xvar - yvar
	    thetaerr = atan2 (2 * xycov, dvar) / 2.
	    if (thetaerr < 0.)
		thetaerr = INDEF
	    else
		thetaerr = DEGTORAD (sqrt (thetaerr))
	}

	f = sqrt (d**2 + 4 * xy**2)
	if (f > r2)
	    return

	if (doerr) {
	    fvar = sqrt (dvar**2 + 4 * xycov**2)
	    if (fvar > rvar)
		doerr = false
	}

	a = sqrt ((r2 + f) / 2)
	b = sqrt ((r2 - f) / 2)

	if (doerr) {
	    aerr = sqrt ((rvar + fvar) / 2)
	    berr = sqrt ((rvar - fvar) / 2)
	}

	ellip = 1 - b / a
	if (b > 0.)
	    elong = a / b

	if (f == 0) {
	    cxx = 1. / (a * a)
	    cyy = 1. / (a * a)
	    cxy = 0
	} else {
	    cxx = y2 / f
	    cyy = x2 / f
	    cxy = -2 * xy / f
	}

	if (doerr) {
	    if (fvar == 0) {
		cxxerr = 1. / (aerr * aerr)
		cyyerr = 1. / (berr * berr)
		cxyerr = 0.
	    } else {
		cxxerr = yvar / fvar
		cyyerr = xvar / fvar
		cxyerr = -2 * xycov / fvar
	    }
	}

end
