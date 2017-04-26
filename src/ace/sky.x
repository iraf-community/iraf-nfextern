include	<error.h>
include	<imhdr.h>
include	<imset.h>
include	"sky.h"
include	"skyblock.h"


# SKY -- Determine sky and sky sigma in an image.
#
# Get the sky and sigma map pointers.  This is layered on the MAPIO routines
# and lower level sky algorithms.  The sky parameter structure will be
# allocated if needed and must be freed by the calling program.
#
# If they are not defined compute an initial
# sky and/or sky sigma surface fit using a subset of the input lines.
# Whether the sky and/or the sigma are fit is determined by whether the input
# sky and sky sigma pointers are NULL.  The initial data for the surface fit
# is measured at a subset of lines with any masked pixels excluded.  Objects
# are removed by fitting a 1D curve to each line, rejection points with large
# residuals and iterating until only sky is left.  The sky points are then
# accumulated for a 2D surface fit and the residuals are added to a
# histogram.  The absolute deviations, scaled by 0.7979 to convert to an
# gausian sigma, are accumulated for a sky sigma surface fit.  After all the
# sample lines are accumulated the surface fits are computed.  The histogram
# of residuals is then fit by a gaussian to estimate an offset from the sky
# fit to the sky mode caused by unrejected object light.  The offset is
# applied to the sky surface.

procedure sky (par, im, bpm, obm, expmap, skyname, signame, skymap, sigmap,
	skyout, sigout, dosky, dosig, logfd, verbose)

pointer	par			#I Parameters
pointer	im			#I Input image
pointer	bpm			#I Input mask
pointer	obm			#I Object mask
pointer	expmap			#I Exposure map
char	skyname[ARB]		#I Sky map name
char	signame[ARB]		#I Sigma map name
pointer	skymap			#O Sky map
pointer	sigmap			#O Sigma map
bool	skyout			#I Need sky?
bool	sigout			#I Need sigma?
bool	dosky			#O Sky computed?
bool	dosig			#O Sigma computed?
int	logfd			#I Log FD
int	verbose			#I Verbose level

int	l, ival
real	rval
pointer	pl, pm
pointer	sp, intro, namesky, namesig

int	imstati(), errcode()
real	imgetr()
pointer	map_open(), pl_newcopy(), im_pmmapo(), imgl2i(), impl2i()
errchk	map_open, sky_fit, sky_block, pl_newcopy, im_pmmapo, imgl2i, impl2i

pointer	buf

begin
	call smark (sp)
	call salloc (intro, SZ_FNAME, TY_CHAR)
	call salloc (namesky, SZ_FNAME, TY_CHAR)
	call salloc (namesig, SZ_FNAME, TY_CHAR)

	call strcpy ("  Set sky and sigma:\n", Memc[intro], SZ_FNAME)

	# Check whether to compute a sky.
	skymap = NULL
	if (skyname[1] != EOS) {
	    iferr (skymap = map_open (skyname, im)) {
		skymap = NULL
		if (errcode() != 2)
		   call erract (EA_ERROR)
	    }
	    if (skymap != NULL) {
		iferr (call map_getr (skymap, "constant", rval)) {
		    ifnoerr (call map_geti (skymap, "im", ival)) {
			iferr (SKB_AVSKY(SKY_SKB(par)) = imgetr (ival, "MEAN"))
			    SKB_AVSKY(SKY_SKB(par)) = INDEFR
			call map_geti (skymap, "interp", ival)
			if (ival == NO)
			    #SKY_SCNV(par) = YES
			    SKY_SCNV(par) = NO
		    }
		}
	    }
	    if (skymap != NULL) {
		if (logfd != NULL) {
		    call putline (logfd, Memc[intro])
		    ifnoerr (call map_getr (skymap, "constant", rval)) {
			call fprintf (logfd, "    Use constant input sky: %g\n")
			    call pargr (rval)
		    } else if (SKY_SCNV(par) == YES) {
			call fprintf (logfd,
			    "    Use convolved input sky: %s\n")
			    call pargstr (skyname)
		    } else {
			call fprintf (logfd, "    Use input sky: %s\n")
			    call pargstr (skyname)
		    }
		}
		if (verbose > 1) {
		    call putline (STDOUT, Memc[intro])
		    ifnoerr (call map_getr (skymap, "constant", rval)) {
			call printf ("    Use constant input sky: %g\n")
			    call pargr (rval)
		    } else if (SKY_SCNV(par) == YES) {
			call printf ("    Use convolved input sky: %s\n")
			    call pargstr (skyname)
		    } else {
			call printf ("    Use input sky: %s\n")
			    call pargstr (skyname)
		    }
		}
		if (logfd != NULL || verbose > 1)
		    Memc[intro] = EOS
	    }
	}
	if (skyout)
	    dosky = (skymap == NULL)
	else
	    dosky = false

	# Check whether to compute a sky sigma.
	sigmap = NULL
	if (signame[1] != EOS) {
	    iferr (sigmap = map_open (signame, im)) {
		sigmap = NULL
		if (errcode() != 2)
		   call erract (EA_ERROR)
	    }
	    if (sigmap != NULL) {
		iferr (call map_getr (sigmap, "constant", rval)) {
		    ifnoerr (call map_geti (skymap, "im", ival)) {
			iferr (SKB_AVSKY(SKY_SKB(par)) = imgetr (ival, "MEAN"))
			    SKB_AVSKY(SKY_SKB(par)) = INDEFR
		    }
		}
	    }
	    if (sigmap != NULL) {
		if (logfd != NULL) {
		    call putline (logfd, Memc[intro])
		    ifnoerr (call map_getr (sigmap, "constant", rval)) {
			call fprintf (logfd,
			    "    Use constant input sigma: %g\n")
			    call pargr (rval)
		    } else {
			call fprintf (logfd, "    Use input sigma: %s\n")
			    call pargstr (signame)
		    }
		}
		if (verbose > 1) {
		    call putline (STDOUT, Memc[intro])
		    ifnoerr (call map_getr (sigmap, "constant", rval)) {
			call printf ("    Use constant input sigma: %g\n")
			    call pargr (rval)
		    } else {
			call printf ("    Use input sigma: %s\n")
			    call pargstr (signame)
		    }
		}
		if (logfd != NULL || verbose > 1)
		    Memc[intro] = EOS
	    }
	}
	if (dosky || sigout)
	    dosig = (sigmap == NULL)
	else
	    dosig = false

	# Compute the sky.
	if (dosky || dosig) {
	    if (logfd != NULL)
		call putline (logfd, Memc[intro])
	    if (verbose > 1)
		call putline (STDOUT, Memc[intro])
	    Memc[intro] = EOS

	    # Set parameters.
	    call sky_pars ("open", "", par)

	    # Merge masks if both are given.
	    if (bpm != NULL && obm != NULL) {
	        pm = imstati (bpm, IM_PMDES)
	        pl = pl_newcopy (pm)
		pm = im_pmmapo (pl, NULL)
		ival = IM_LEN(im,1)
		do l = 1, IM_LEN(im,2) {
buf = impl2i (pm, l)
		    call amaxi (Memi[imgl2i(bpm,l)], Memi[imgl2i(obm,l)],
		        Memi[buf], ival)
		}
	    } else if (bpm != NULL)
	        pm = bpm
	    else
	        pm = obm

	    # Do the sky determination.
	    switch (SKY_TYPE(par)) {
	    case SKY_FIT:
		call sky_fit (SKY_SKF(par), dosky, dosig, im, pm, expmap,
		    skyname, signame, skymap, sigmap, logfd, verbose)
	    case SKY_BLOCK:
		call sky_fit (SKY_SKF(par), dosky, dosig, im, pm, expmap,
		    "", "", skymap, sigmap, logfd, verbose)
		call map_seti (skymap, "sample", 5)
		call map_seti (sigmap, "sample", 5)
		call sky_block (SKY_SKB(par), dosky, dosig, im, pm,
		    expmap, skyname, signame, skymap, sigmap, logfd, verbose)
	    default:
		call error (1, "Unknown sky type")
	    }

	    # Free memory for merged mask.
	    if (pm != bpm && pm != obm) {
	        call imunmap (pm)
		call pl_close (pl)
	    }
	}

	call sfree (sp)
end
