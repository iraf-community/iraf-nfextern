include	<error.h>
include	<imhdr.h>
include	"sky.h"
include	"skyblock.h"


# SKYIMAGES -- Write out sky or sky subtracted images.

procedure skyimages (par, outsky, outsig, im, skymap, sigmap, gainmap,
	expmap, logfd, verbose)

pointer	par			#I Sky parameters
char	outsky[ARB]		#I Output sky image name
char	outsig[ARB]		#I Output sigma image name
pointer	im			#I Image pointer
pointer	skymap			#I Sky map
pointer	sigmap			#I Sigma map
pointer	gainmap			#I Gain map
pointer	expmap			#I Exposure map
int	logfd			#I Logfile
int	verbose			#I Verbose level

int	l, nc, nl
pointer	skyim, sigim, data, skydata, ssigdata, gaindata, expdata, sigdata, ptr

int	imaccess()
pointer	immap(), imgl2r(), impl2r(), map_glr()
errchk	immap, imgl2r, map_glr, imaddr

begin
	# Return if no output is needed.
	if (outsky[1] == EOS && outsig[1] == EOS || im == NULL)
	    return

	if (outsky[1] != EOS && imaccess(outsky,0)==YES)
	    call error (1, "Output sky image already exists")
	if (outsig[1] != EOS && imaccess(outsig[1],0)==YES)
	    call error (1, "Output sky sigma image already exists")

	# Write log information.
	if (logfd != NULL) {
	    call fprintf (logfd, "  Output sky images:")
	    if (outsky[1] != EOS) {
		switch (SKY_OTYPE(par)) {
		case SKY_OSUB:
		    call fprintf (logfd, " sky subtracted = %s")
		default:
		    call fprintf (logfd, " sky = %s")
		}
		call pargstr (outsky)
	    }
	    if (outsig[1] != EOS) {
		call fprintf (logfd, " sigma = %s")
		    call pargstr (outsig)
	    }
	    call fprintf (logfd, "\n")
	}
	if (verbose > 1) {
	    call printf ("  Output sky images:")
	    if (outsky[1] != EOS) {
		switch (SKY_OTYPE(par)) {
		case SKY_OSUB:
		    call printf (" sky subtracted = %s")
		default:
		    call printf (" sky = %s")
		}
		call pargstr (outsky)
	    }
	    if (outsig[1] != EOS) {
		call printf (" sigma = %s")
		    call pargstr (outsig)
	    }
	    call printf ("\n")
	}

	iferr {
	    skyim = NULL; sigim = NULL

	    # Map output image(s)
	    if (outsky[1] != EOS && skymap != NULL) {
		ptr = immap (outsky, NEW_COPY, im)
		skyim = ptr
	    }
	    if (outsig[1] != EOS && sigmap != NULL) {
		ptr = immap (outsig, NEW_COPY, im)
		sigim = ptr
	    }

	    # Output the sky image data.
	    nc = IM_LEN(im,1)
	    nl = IM_LEN(im,2)
	    do l = 1, nl {
		data = NULL
		skydata = NULL
		if (skyim != NULL) {
		    skydata = map_glr (skymap, l, READ_ONLY)
		    switch (SKY_OTYPE(par)) {
		    case SKY_OSUB:
			call asubr (Memr[imgl2r(im,l)], Memr[skydata],
			    Memr[impl2r(skyim,l)], nc)
		    default:
			call amovr (Memr[skydata], Memr[impl2r(skyim,l)], nc)
		    }
		}
		if (sigim != NULL) {
		    ssigdata = map_glr (sigmap, l, READ_ONLY)
		    if (gainmap == NULL && expmap == NULL)
			sigdata = ssigdata
		    else if (expmap == NULL) {
			if (data == NULL)
			    data = imgl2r (im, l)
			if (skydata == NULL)
			    skydata = map_glr (skymap, l, READ_ONLY)
			gaindata = map_glr (gainmap, l, READ_ONLY)
			call noisemodel (Memr[data], Memr[skydata],
			    Memr[ssigdata], Memr[gaindata], INDEFR,
			    Memr[sigdata], nc)
		    } else if (gainmap == NULL) {
			expdata = map_glr (expmap, l, READ_WRITE)
			call noisemodel (Memr[expdata], Memr[expdata],
			    Memr[ssigdata], INDEFR, Memr[expdata],
			    Memr[sigdata], nc)
		    } else {
			if (data == NULL)
			    data = imgl2r (im, l)
			if (skydata == NULL)
			    skydata = map_glr (skymap, l, READ_ONLY)
			gaindata = map_glr (gainmap, l, READ_ONLY)
			expdata = map_glr (expmap, l, READ_WRITE)
			call noisemodel (Memr[data], Memr[skydata],
			    Memr[ssigdata], Memr[gaindata],
			    Memr[expdata], Memr[sigdata], nc)
		    }
		    if (skyim != NULL)
			call amovr (Memr[sigdata], Memr[impl2r(sigim,l)], nc)
		}
	    }

	    # Finish up.
	    if (skyim != NULL) {
	        if (!IS_INDEFR(SKB_AVSKY(SKY_SKB(par)))) {
		    if (SKY_OTYPE(par) == SKY_OSKY)
		        call imaddr (skyim, "MEAN", SKB_AVSKY(SKY_SKB(par)))
		}
		call imunmap (skyim)
	    }
	    if (sigim != NULL) {
	        if (!IS_INDEFR(SKB_AVSIG(SKY_SKB(par)))) {
		    if (SKY_OTYPE(par) == SKY_OSKY)
		        call imaddr (skyim, "MEAN", SKB_AVSIG(SKY_SKB(par)))
		}
		call imunmap (sigim)
	    }
	} then {
	    call erract (EA_WARN)

	    # Close and delete output images on an errror.
	    if (skyim != NULL) {
		call imunmap (skyim)
		iferr (call imdelete (outsky))
		    ;
	    }
	    if (sigim != NULL) {
		call imunmap (sigim)
		iferr (call imdelete (outsig))
		    ;
	    }
	}
end
