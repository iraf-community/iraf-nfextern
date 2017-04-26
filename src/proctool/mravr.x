# These are slightly modified versions of VOPS routines to use a short
# integer mask array.

# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<mach.h>

# MRAV -- Compute the mean and standard deviation of a sample array by
# iteratively rejecting points further than KSIG from the mean.  If the
# value of KSIG is given as 0.0, a cutoff value will be automatically
# calculated from the standard deviation and number of points in the sample.
# The number of pixels remaining in the sample upon termination is returned
# as the function value.

int procedure mravr (a, m, npix, mean, sigma, ksig)

real	a[ARB]			# input data array
short	m[ARB]			# input mask array
real	mean, sigma, ksig, deviation, lcut, hcut, lgpx
int	npix, ngpix, old_ngpix, mwvgr()

begin
	lcut = -MAX_REAL				# no rejection to start
	hcut =  MAX_REAL
	ngpix = MAX_INT

	# Iteratively compute mean, sigma and reject outliers until no
	# more pixels are rejected, or until there are no more pixels.

	repeat {
	    old_ngpix = ngpix
	    ngpix = mwvgr (a, m, npix, mean, sigma, lcut, hcut)
		if (ngpix <= 1 || sigma <= EPSILONR)
		    break

	    if (ksig == 0.0) {				# Chauvenet's relation
		lgpx = log10 (real(ngpix))
		deviation = (lgpx * (-0.1042 * lgpx + 1.1695) + .8895) * sigma
	    } else
		deviation = sigma * abs(ksig)

	    lcut = mean - deviation			# compute window
	    hcut = mean + deviation

	} until (ngpix >= old_ngpix)

	return (ngpix)
end


# MWVG -- Compute the mean and standard deviation (sigma) of a sample.  Pixels
# whose value lies outside the specified lower and upper limits are not used.
# If the upper and lower limits have the same value (e.g., zero), no limit
# checking is performed.  The number of pixels in the sample is returned as the
# function value.

int procedure mwvgr (a, m, npix, mean, sigma, lcut, hcut)

real	a[ARB]
short	m[ARB]
real	mean, sigma, lcut, hcut
double	sum, sumsq, value, temp
int	npix, i, ngpix

begin
	sum = 0.0
	sumsq = 0.0
	ngpix = 0

	# Accumulate sum, sum of squares.  The test to disable limit checking
	# requires numerical equality of two floating point numbers; this should
	# be ok since they are used as flags not as numbers (they are not used
	# in computations).

	if (hcut == lcut) {
	    do i = 1, npix {
		if (m[i] != 0)
		    next
		value = a[i]
		ngpix = ngpix + 1
		sum = sum + value
		sumsq = sumsq + value ** 2
	    }

	} else {
	    do i = 1, npix {
		if (m[i] != 0)
		    next
		value = a[i]
		if (value >= lcut && value <= hcut) {
		    ngpix = ngpix + 1
		    sum = sum + value
		    sumsq = sumsq + value ** 2
		}
	    }
	}

	switch (ngpix) {		# compute mean and sigma
	case 0:
	    mean = INDEFR
	    sigma = INDEFR
	case 1:
	    mean = sum
	    sigma = INDEFR
	default:
	    mean = sum / ngpix
	    temp = (sumsq - (sum/ngpix) * sum) / (ngpix - 1)
	    if (temp < 0)		# possible with roundoff error
		sigma = 0.0
	    else
		sigma = sqrt (temp)
	}

	return (ngpix)
end
