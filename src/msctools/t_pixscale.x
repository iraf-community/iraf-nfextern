include	<error.h>
include	<imhdr.h>
include	<mach.h>
include <math/iminterp.h>


# T_PIXSCALE -- Compute standard coordinate pixel scales.

procedure t_pixscale ()

char	input[SZ_FNAME]		# Input file
char	output[SZ_FNAME]	# Output file
char	image[SZ_FNAME]		# Input WCS image

int	c, l, nc, nl, nc1, nl1, nstep
real	x, y, x1, y1, xider[2,2], etader[2,2]
pointer	im, in, out, wcs, xi, eta, ximsi, etamsi, xip, etap

int	open(), fscan(), nscan()
pointer	immap(), msc_openim(), msc_sctran()
errchk	immap, msc_openim, msc_sctran, open, msider

begin
	# Get parameters.
	call clgstr ("input", input, SZ_FNAME)
	call clgstr ("output", output, SZ_FNAME)
	call clgstr ("image", image, SZ_FNAME)

	# Loop through input and output images computing the scale.
	iferr {
	    im = NULL; in = NULL; out = NULL; wcs = NULL
	    xi = NULL; eta = NULL; ximsi = NULL; etamsi = NULL

	    # Open image and WCS.
	    xip = immap (image, READ_ONLY, 0); im = xip
	    xip = msc_openim (im, wcs)
	    xip = msc_sctran (wcs, 1, "logical", "astrometry", 3)

	    # Compute standard coordinates on low resolution grid.
	    # b = (a - 0.5) / nstep + 1.5
	    nstep = 100
	    nc = IM_LEN(im,1);
	    nl = IM_LEN(im,2)
	    nc1 = real (nc) / nstep + 2.5
	    nl1 = real (nl) / nstep + 2.5
	    call malloc (xi, nc1*nl1, TY_REAL)
	    call malloc (eta, nc1*nl1, TY_REAL)

	    xip = xi; etap = eta
	    do l = 1, nl1 {
		y = (l - 1.5) * nstep + 0.5
		do c = 1, nc1 {
		    x = (c - 1.5) * nstep + 0.5
		    call msc_c2tranr (wcs, 1, x, y, Memr[xip], Memr[etap])
		    xip = xip + 1; etap = etap + 1
		}
	    }

	    # Fit surface to grid.
	    call msiinit (ximsi, II_LINEAR);
	    call msiinit (etamsi, II_LINEAR)
	    call msifit (ximsi, Memr[xi], nc1, nl1, nc1)
	    call msifit (etamsi, Memr[eta], nc1, nl1, nc1)
	    call mfree (xi, TY_REAL)
	    call mfree (eta, TY_REAL)

	    # We're finished with the image and WCS.
	    call msc_close (wcs)
	    call imunmap (im)

	    # Now evaluate at input coordinates.
	    xip = open (input, READ_ONLY, TEXT_FILE); in = xip
	    xip = open (output, NEW_FILE, TEXT_FILE); out = xip
	    while (fscan (in) != EOF) {
	        call gargr (x)
		call gargr (y)
		if (nscan() != 2)
		    next

		x1 = max (1., min (real(nc1), (x - 0.5) / nstep + 1.5))
		y1 = max (1., min (real(nl1), (y - 0.5) / nstep + 1.5))
		call msider (ximsi, x1, y1, xider, 2, 2, 2)
		call msider (etamsi, x1, y1, etader, 2, 2, 2)
		call fprintf (out, "%g %g %g %g %g %g\n")
		    call pargr (x)
		    call pargr (y)
		    call pargr (xider[2,1] / nstep)
		    call pargr (xider[1,2] / nstep)
		    call pargr (etader[2,1] / nstep)
		    call pargr (etader[1,2] / nstep)
	    }

	    call close (out)
	    call close (in)
	    call msifree (ximsi)
	    call msifree (etamsi)
	} then {
	    call mfree (xi, TY_REAL)
	    call mfree (eta, TY_REAL)
	    if (wcs != NULL)
		call msc_close(wcs)
	    if (im != NULL)
		call imunmap (im)
	    if (out != NULL)
		call close (out)
	    if (in != NULL)
		call close (in)
	    if (ximsi != NULL)
		call msifree (ximsi)
	    if (etamsi != NULL)
		call msifree (etamsi)
	    call erract (EA_WARN)
	}
end
