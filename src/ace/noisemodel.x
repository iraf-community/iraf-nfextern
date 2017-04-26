# NOISEMODEL -- Compute noise model.
#
# var = (var(sky) + (image-sky)/gain) / sqrt (exposure)
#
# What is actually returned is the square root of the variance.
# The variance of the sky and the effective gain are for a unit
# exposure in the exposure map.

procedure noisemodel (image, sky, sig, gain, exp, sigma, npix)

real	image[npix]		#I Image
real	sky[npix]		#I Sky
real	sig[npix]		#I Sky sigma
real	gain[npix]		#I Gain
real	exp[npix]		#I Exposure
real	sigma[npix]		#O Sigma
int	npix			#I Number of pixels

int	i
real	f, s, g, e, elast, sqrte

begin
	g = gain[1]
	e = exp[1]
	if (IS_INDEFR(e)) {
	    if (IS_INDEFR(g))
		call amovr (sig, sigma, npix)
	    else {
		do i = 1, npix {
		    f = image[i] - sky[i]
		    s = sig[i] * sig[i]
		    g = gain[i]
		    if (g <= 0.)
		        sigma[i] = sig[i]
		    else
			sigma[i] = sqrt (s + max (-0.5 * s, f / g))
		}
	    }
	} else if (IS_INDEFR(g)) {
	    elast = INDEFR
	    do i = 1, npix {
		e = exp[i]
		if (e <= 0.) {
		    sigma[i] = sig[i]
		    next
		}
		if (e != elast) {
		    sqrte = sqrt (e)
		    elast = e
		}
		sigma[i] = sig[i] / sqrte
	    }
	} else {
	    elast = INDEFR
	    do i = 1, npix {
		f = image[i] - sky[i]
		s = sig[i] * sig[i]
		g = gain[i]
		e = exp[i]
		if (e <= 0.) {
		    if (g <= 0.)
		        sigma[i] = sig[i]
		    else
			sigma[i] = sqrt (s + max (-0.5 * s, f / g))
		} else {
		    if (e != elast) {
			sqrte = sqrt (e)
			elast = e
		    }
		    if (g <= 0.)
			sigma[i] = sig[i] / sqrte
		    else
			sigma[i] = sqrt (s + max (-0.5 * s, f / g)) / sqrte
		}
	    }
	}
end


# EXPSIGMA -- Apply exposure map to correct sky sigma.
# Assume the exposure map has region of contiguous constant values so
# that the number of square roots can be minimized.  An exposure map
# value of zero leaves the sigma unchanged.

procedure expsigma (sigma, expmap, npix, mode)

real	sigma[npix]		#U Sigma values
real	expmap[npix]		#I Exposure map values
int	npix			#I Number of pixels
int	mode			#I 0=divide, 1=multiply

int	i
real	exp, lastexp, scale

begin
	switch (mode) {
	case 0:
	    lastexp = INDEFR
	    do i = 1, npix {
		exp = expmap[i]
		if (exp == 0.)
		    next
		if (exp != lastexp) {
		    scale = sqrt (exp)
		    lastexp = exp
		}
		sigma[i] = sigma[i] / scale
	    }
	case 1:
	    lastexp = INDEFR
	    do i = 1, npix {
		exp = expmap[i]
		if (exp == 0.)
		    next
		if (exp != lastexp) {
		    scale = sqrt (exp)
		    lastexp = exp
		}
		sigma[i] = sigma[i] * scale
	    }
	}
end
