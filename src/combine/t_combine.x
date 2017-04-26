include	<imhdr.h>
include	<error.h>
include	<syserr.h>
include	<mach.h>
include	<pmset.h>
include	<evvexpr.h>
include	"src/icombine.h"

# Symbol table definitions from hdrmap.x.
define	LEN_INDEX	32		# Length of symtab index
define	LEN_STAB	1024		# Length of symtab string buffer
define	SZ_SBUF		128		# Size of symtab string buffer

define	SZ_NAME		79		# Size of translation symbol name
define	SZ_DEFAULT	79		# Size of default string
define	SYMLEN		80		# Length of symbol structure

# Symbol table structure
define	NAME		Memc[P2C($1)]		# Translation name for symbol
define	DEFAULT		Memc[P2C($1+40)]	# Default value of parameter

define	ONEIMAGE	99	# Error code for one image to combine


# T_COMBINE -- Combine images.

procedure t_combine ()

int	i, list, nout, imtopenp()
pointer	sp, fname, outnames
errchk	cmbine

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	# Get the list of images.
	list = imtopenp ("input")
	call clgstr ("output", Memc[fname], SZ_FNAME)
	call xt_imroot (Memc[fname], Memc[fname], SZ_FNAME)

	iferr (call cmbine (list, Memc[fname], YES, outnames, nout, NO))
	    call erract (EA_WARN)

	do i = 1, nout
	    call mfree (Memi[outnames+i-1], TY_CHAR)
	call mfree (outnames, TY_POINTER)
	call imtclose (list)
	call sfree (sp)
end


# T_CGROUP -- List combine groupings.

procedure t_cgroup ()

int	i, list, nout, imtopenp()
pointer	sp, fname, outnames
errchk	cmbine

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	# Get the list of images.
	list = imtopenp ("input")
	call clgstr ("output", Memc[fname], SZ_FNAME)
	call xt_imroot (Memc[fname], Memc[fname], SZ_FNAME)

	iferr (call cmbine (list, Memc[fname], YES, outnames, nout, YES))
	    call erract (EA_WARN)

	do i = 1, nout
	    call mfree (Memi[outnames+i-1], TY_CHAR)
	call mfree (outnames, TY_POINTER)
	call imtclose (list)
	call sfree (sp)
end


# T_COUTPUT -- List of output images.

procedure t_coutput ()

int	list, imtopenp()
pointer	sp, fname

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	# Get the list of images.
	list = imtopenp ("input")
	call clgstr ("output", Memc[fname], SZ_FNAME)
	call xt_stripwhite (Memc[fname])

	iferr (call coutput (list, Memc[fname]))
	    call erract (EA_WARN)

	call imtclose (list)
	call sfree (sp)
end


# CMBINE -- Combine images.
#
# This is a version of IMCOMBINE which groups data by extensions and subsets
# (such as filter).
# The main routine takes care of sorting the input (both individual images
# and MEF files) by subset and amplifer using the routine cmb_images.  It
# then creates output root names and calls routines to do the combining of
# each group.

procedure cmbine (list, outroot, oneimage, outnames, nsubsets, listonly)

int	list			# List of images
char	outroot[SZ_FNAME]	# Output root image name
int	oneimage		# Allow only a single image to combine?
pointer	outnames		# Pointer to array of string pointers
int	nsubsets		# Number of subsets
int	listonly		# List output only?

pointer	images			# Images
pointer	hroot			# Headers root name
pointer	broot			# Bad pixel mask root name
pointer	rroot			# Rejection pixel mask root name
pointer	nrroot			# Number rejected mask root name
pointer	eroot			# Exposure mask root name
pointer	sigroot			# Sigma image name
pointer	logfile			# Log filename

pointer	scales			# Scales
pointer	zeros			# Zeros
pointer	wts			# Weights
pointer	seqvals			# Sequence values
pointer	extns			# Image extensions for each subset
pointer	subsets			# Subsets
pointer	nimages			# Number of images in each subset
int	delete			# Delete input images?

int	i, mef, list1
pointer	sp, output, headers, bmask, rmask, nrmask, emask, sigma

bool	clgetb()
int	clgeti(), clgwrd(), btoi(), errcode(), ic_mklist(), imtgetim()
real	clgetr()
errchk	cmb_images, icombine, mefcombine, ic_mklist

include	"src/icombine.com"

begin
	call smark (sp)
	call salloc (hroot, SZ_FNAME, TY_CHAR)
	call salloc (broot, SZ_FNAME, TY_CHAR)
	call salloc (rroot, SZ_FNAME, TY_CHAR)
	call salloc (nrroot, SZ_FNAME, TY_CHAR)
	call salloc (eroot, SZ_FNAME, TY_CHAR)
	call salloc (sigroot, SZ_FNAME, TY_CHAR)
	call salloc (logfile, SZ_FNAME, TY_CHAR)
	call salloc (headers, SZ_FNAME, TY_CHAR)
	call salloc (bmask, SZ_FNAME, TY_CHAR)
	call salloc (rmask, SZ_FNAME, TY_CHAR)
	call salloc (nrmask, SZ_FNAME, TY_CHAR)
	call salloc (emask, SZ_FNAME, TY_CHAR)
	call salloc (sigma, SZ_FNAME, TY_CHAR)
	call salloc (expkeyword, SZ_FNAME, TY_CHAR)
	call salloc (statsec, SZ_FNAME, TY_CHAR)
	call salloc (gain, SZ_FNAME, TY_CHAR)
	call salloc (snoise, SZ_FNAME, TY_CHAR)
	call salloc (rdnoise, SZ_FNAME, TY_CHAR)

	# Get the input images.  There must be a least one image to continue.
	call cmb_images (list, images, scales, zeros, wts, seqvals, extns,
	    subsets, nimages, nsubsets, mef, listonly)
	if (nsubsets == 0) {
	    call cmb_images_free (images, scales, zeros, wts, seqvals,
	        extns, NULL, subsets, nimages, nsubsets)
	    call error (0, "No data to combine")
	}

	# Check for more than one image.  MEF files are handled later.
	if (mef == NO && oneimage == NO) {
	    do i = 1, nsubsets {
		if (Memi[nimages+i-1] > 1)
		    break
	    }
	    if (i > nsubsets) {
		call cmb_images_free (images, scales, zeros, wts, seqvals,
		    extns, NULL, subsets, nimages, nsubsets)
		call error (ONEIMAGE, "Only a single image to combine") 
		return
	    }
	}

	# Set task parameters.  Additional parameters are obtained later.
	if (listonly == YES) {
	    call strcpy ("STDOUT", Memc[logfile], SZ_FNAME)
	    Memc[hroot] = EOS; Memc[broot] = EOS; Memc[rroot] = EOS
	    Memc[nrroot] = EOS; Memc[eroot] = EOS; Memc[sigroot] = EOS
	} else {
	    call clgstr ("headers", Memc[hroot], SZ_FNAME)
	    call clgstr ("bpmasks", Memc[broot], SZ_FNAME)
	    call clgstr ("rejmasks", Memc[rroot], SZ_FNAME)
	    call clgstr ("nrejmasks", Memc[nrroot], SZ_FNAME)
	    call clgstr ("expmasks", Memc[eroot], SZ_FNAME)
	    call clgstr ("sigmas", Memc[sigroot], SZ_FNAME)
	    call clgstr ("logfile", Memc[logfile], SZ_FNAME)
	    call xt_stripwhite (Memc[hroot])
	    call xt_stripwhite (Memc[broot])
	    call xt_stripwhite (Memc[rroot])
	    call xt_stripwhite (Memc[nrroot])
	    call xt_stripwhite (Memc[eroot])
	    call xt_stripwhite (Memc[sigroot])
	    call xt_stripwhite (Memc[logfile])

	    #project = clgetb ("project")
	    project = false
	    combine = clgwrd ("combine", Memc[statsec], SZ_FNAME, COMBINE)
	    medtype = MEDAVG
	    reject = clgwrd ("reject", Memc[statsec], SZ_FNAME, REJECT)
	    blank = clgetr ("blank")
	    call strcpy ("exptime", Memc[expkeyword], SZ_FNAME)
	    call clgstr ("statsec", Memc[statsec], SZ_FNAME)
	    call clgstr ("gain", Memc[gain], SZ_FNAME)
	    call clgstr ("rdnoise", Memc[rdnoise], SZ_FNAME)
	    call clgstr ("snoise", Memc[snoise], SZ_FNAME)
	    lthresh = clgetr ("lthreshold")
	    hthresh = clgetr ("hthreshold")
	    lsigma = clgetr ("lsigma")
	    pclip = clgetr ("pclip")
	    flow = clgetr ("nlow")
	    fhigh = clgetr ("nhigh")
	    nkeep = clgeti ("nkeep")
	    hsigma = clgetr ("hsigma")
	    grow = clgetr ("grow")
	    mclip = clgetb ("mclip")
	    sigscale = clgetr ("sigscale")
	    delete = btoi (clgetb ("delete"))

	    # Check parameters, map INDEFs, and set threshold flag
	    if (pclip == 0. && reject == PCLIP)
		call error (1, "Pclip parameter may not be zero")
	    if (IS_INDEFR (blank))
		blank = 0.
	    if (IS_INDEFR (lsigma))
		lsigma = MAX_REAL
	    if (IS_INDEFR (hsigma))
		hsigma = MAX_REAL
	    if (IS_INDEFR (pclip))
		pclip = -0.5
	    if (IS_INDEFR (flow))
		flow = 0.
	    if (IS_INDEFR (fhigh))
		fhigh = 0.
	    if (IS_INDEFR (grow))
		grow = 0.
	    if (IS_INDEF (sigscale))
		sigscale = 0.

	    if (IS_INDEF(lthresh) && IS_INDEF(hthresh))
		dothresh = false
	    else {
		dothresh = true
		if (IS_INDEF(lthresh))
		    lthresh = -MAX_REAL
		if (IS_INDEF(hthresh))
		    hthresh = MAX_REAL
	    }
	}

	# Combine each input subset.
	call calloc (outnames, nsubsets, TY_POINTER)
	do i = 1, nsubsets {
	    # Set the output, names with subset extension.
	    call malloc (Memi[outnames+i-1], SZ_FNAME, TY_CHAR)

	    output = Memi[outnames+i-1]
	    call strcpy (outroot, Memc[output], SZ_FNAME)
	    call sprintf (Memc[output], SZ_FNAME, "%s%s")
		call pargstr (outroot)
		call pargstr (Memc[Memi[extns+i-1]])
	    if (listonly == NO)
	        call strcat (".fits", Memc[output], SZ_FNAME)

	    call strcpy (Memc[hroot], Memc[headers], SZ_FNAME)
	    if (Memc[headers] != EOS) {
		call sprintf (Memc[headers], SZ_FNAME, "%s%s")
		    call pargstr (Memc[hroot])
		    call pargstr (Memc[Memi[extns+i-1]])
	    }

	    call strcpy (Memc[broot], Memc[bmask], SZ_FNAME)
	    if (Memc[bmask] != EOS) {
		call sprintf (Memc[bmask], SZ_FNAME, "%s%s")
		    call pargstr (Memc[broot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    call strcpy (Memc[rroot], Memc[rmask], SZ_FNAME)
	    if (Memc[rmask] != EOS) {
		call sprintf (Memc[rmask], SZ_FNAME, "%s%s")
		    call pargstr (Memc[rroot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    call strcpy (Memc[nrroot], Memc[nrmask], SZ_FNAME)
	    if (Memc[nrmask] != EOS) {
		call sprintf (Memc[nrmask], SZ_FNAME, "%s%s")
		    call pargstr (Memc[nrmask])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    call strcpy (Memc[eroot], Memc[emask], SZ_FNAME)
	    if (Memc[emask] != EOS) {
		call sprintf (Memc[emask], SZ_FNAME, "%s%s")
		    call pargstr (Memc[eroot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    call strcpy (Memc[sigroot], Memc[sigma], SZ_FNAME)
	    if (Memc[sigma] != EOS) {
		call sprintf (Memc[sigma], SZ_FNAME, "%s%s")
		    call pargstr (Memc[sigroot])
		    call pargstr (Memc[Memi[extns+i-1]])
	    }

	    # Combine all images from the (subset) list.
	    iferr {
		if (mef == YES)
		    call mefcombine (Memc[Memi[images+i-1]],
			Memr[Memi[scales+i-1]], Memr[Memi[zeros+i-1]],
			Memr[Memi[wts+i-1]], Memd[Memi[seqvals+i-1]],
			Memi[nimages+i-1], Memc[output], Memc[headers],
			Memc[bmask], Memc[rmask], Memc[nrmask],
			Memc[emask], Memc[sigma], Memc[logfile], NO,
			delete, oneimage, listonly)
		else {
		    list1 = ic_mklist (Memi[images+i-1], Memi[nimages+i-1], NO)

		    call icombine (list1, Memc[output], Memc[headers],
			Memc[bmask], Memc[rmask], Memc[nrmask],
			Memc[emask], Memc[sigma], Memc[logfile],
			Memr[Memi[scales+i-1]], Memr[Memi[zeros+i-1]],
			Memr[Memi[wts+i-1]], NO, NO, listonly)

		    if (!project && delete == YES && listonly == NO) {
			call imtrew (list1)
			while (imtgetim (list1, Memc[output], SZ_FNAME) != EOF)
			    call imdelete (Memc[output])
		    }
		    call imtclose (list1)
		}
	    } then {
		if (errcode() == ONEIMAGE)
		    call erract (EA_ERROR)
		call erract (EA_WARN)
	    }
	}

	# Finish up.
	call cmb_images_free (images, scales, zeros, wts, seqvals,
	    extns, NULL, subsets, nimages, nsubsets)
	call sfree (sp)
end


# CMB_IMAGES_FREE -- Free memory allocated by CMB_IMAGES.

procedure cmb_images_free (images, scales, zeros, wts, seqvals,
	extns, iimage, subsets, nimages, nsubsets)

pointer	images			#U Pointer to image names in subset
pointer	scales			#U Pointer to scales in subset
pointer	zeros			#U Pointer to zeros in subset
pointer	wts			#U Pointer to weights in subset
pointer	seqvals			#U Pointer to sequence values in subset
pointer	extns			#U Pointer to extension name in subset
pointer	iimage			#U Pointer to extension index in subset
pointer	subsets			#U Pointer to subset name in subset
pointer	nimages			#U Pointer to number of images in subset
int	nsubsets		#I Number of subsets

int	i

begin
	do i = 1, nsubsets {
	    call mfree (Memi[images+i-1], TY_CHAR)
	    call mfree (Memi[scales+i-1], TY_REAL)
	    call mfree (Memi[zeros+i-1], TY_REAL)
	    call mfree (Memi[wts+i-1], TY_REAL)
	    call mfree (Memi[seqvals+i-1], TY_DOUBLE)
	    if (extns != NULL)
		call mfree (Memi[extns+i-1], TY_CHAR)
	    if (iimage != NULL)
		call mfree (Memi[iimage+i-1], TY_INT)
	    call mfree (Memi[subsets+i-1], TY_CHAR)
	}
	call mfree (images, TY_POINTER)
	call mfree (scales, TY_POINTER)
	call mfree (zeros, TY_POINTER)
	call mfree (wts, TY_POINTER)
	call mfree (seqvals, TY_POINTER)
	if (extns != NULL)
	    call mfree (extns, TY_POINTER)
	if (iimage != NULL)
	    call mfree (iimage, TY_POINTER)
	call mfree (subsets, TY_POINTER)
	call mfree (nimages, TY_INT)
end


# COUTPUT -- Print list of combine output images.
#
# This routine prints the output names that COMBINE will use.

procedure coutput (inlist, outroot)

int	inlist			# List of input images
char	outroot[ARB]		# Output root image name
pointer	images			# Images
pointer	hroot			# Headers
pointer	broot			# Bad pixels masks
pointer	rroot			# Rejection pixel masks
pointer	nrroot			# Number rejected pixel masks
pointer	eroot			# Exposure masks
pointer	sigroot			# Output root sigma image name

pointer	scales			# Scales
pointer	zeros			# Zeros
pointer	wts			# Weights
pointer	seqvals			# Sequence values
pointer	extns			# Image extensions for each subset
pointer	subsets			# Subsets
pointer	nimages			# Number of images in each subset
int	nsubsets		# Number of subsets

int	i, mef
pointer	sp

errchk	cmb_images, open

include	"src/icombine.com"

begin
	call smark (sp)
	call salloc (hroot, SZ_FNAME, TY_CHAR)
	call salloc (broot, SZ_FNAME, TY_CHAR)
	call salloc (rroot, SZ_FNAME, TY_CHAR)
	call salloc (nrroot, SZ_FNAME, TY_CHAR)
	call salloc (eroot, SZ_FNAME, TY_CHAR)
	call salloc (sigroot, SZ_FNAME, TY_CHAR)

	# Get the input images.  There must be a least one image to continue.
	call cmb_images (inlist, images, scales, zeros, wts, seqvals,
	    extns, subsets, nimages, nsubsets, mef, YES)
	if (nsubsets == 0) {
	    call cmb_images_free (images, scales, zeros, wts, seqvals,
	        extns, NULL, subsets, nimages, nsubsets)
	    call error (0, "No data to combine")
	}

	# Get task parameters.  Some additional parameters are obtained later.

	call clgstr ("headers", Memc[hroot], SZ_FNAME)
	call clgstr ("bpmasks", Memc[broot], SZ_FNAME)
	call clgstr ("rejmasks", Memc[rroot], SZ_FNAME)
	call clgstr ("nrejmasks", Memc[nrroot], SZ_FNAME)
	call clgstr ("expmasks", Memc[eroot], SZ_FNAME)
	call clgstr ("sigmas", Memc[sigroot], SZ_FNAME)
	call xt_stripwhite (Memc[hroot])
	call xt_stripwhite (Memc[broot])
	call xt_stripwhite (Memc[rroot])
	call xt_stripwhite (Memc[nrroot])
	call xt_stripwhite (Memc[eroot])
	call xt_stripwhite (Memc[sigroot])

	# Print output images.
	do i = 1, nsubsets {
	    call printf ("%s%s")
		call pargstr (outroot)
		call pargstr (Memc[Memi[extns+i-1]])
	    if (Memc[hroot] != EOS) {
		call printf (" %s%s")
		    call pargstr (Memc[hroot])
		    call pargstr (Memc[Memi[extns+i-1]])
	    }
	    if (Memc[broot] != EOS) {
		call printf (" %s%s")
		    call pargstr (Memc[broot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }
	    if (Memc[rroot] != EOS) {
		call printf (" %s%s")
		    call pargstr (Memc[rroot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }
	    if (Memc[nrroot] != EOS) {
		call printf (" %s%s")
		    call pargstr (Memc[nrroot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }
	    if (Memc[eroot] != EOS) {
		call printf (" %s%s")
		    call pargstr (Memc[eroot])
		    # Use this if we can append pl files.
		    #call pargstr (Memc[Memi[extns+i-1]])
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }
	    if (Memc[sigroot] != EOS) {
		call printf (" %s%s")
		    call pargstr (Memc[sigroot])
		    call pargstr (Memc[Memi[extns+i-1]])
	    }
	    call printf ("\n")
	}

	# Finish up.
	call cmb_images_free (images, scales, zeros, wts, seqvals,
	    extns, NULL, subsets, nimages, nsubsets)
	call sfree (sp)
end


# CMB_IMAGES -- Get images, scales, zeros, and weights from a list of images.
# The images are filtered by type and sorted by group.
# The allocated lists must be freed by the caller.

procedure cmb_images (list, images, scales, zeros, wts, seqvals, extns, subsets,
	nimages, nsubsets, mef, listonly)

int	list		# List of input images
pointer	images		# Pointer to lists of subsets (allocated)
pointer	scales		# Pointer to array of scales (allocated)
pointer	zeros		# Pointer to array of zeros (allocated)
pointer	wts		# Pointer to array of weights (allocated)
pointer	seqvals		# Pointer to array of sequence values (allocated)
pointer	extns		# Image extensions for each subset (allocated)
pointer	subsets		# Subset names (allocated)
pointer	nimages		# Number of images in subset (allocated)
int	nsubsets	# Number of subsets
int	mef		#O MEF data?
int	listonly	# List input and output only?

int	i, j, nims, nimage, fd
double	seqval, gap
pointer	sp, group, seqexpr, type, image, extn, subset, str
pointer	scale, zero, wt
pointer	ptr, im, o

bool	streq()
int	imtlen(), imtgetim(), errcode(), locpr()
int	nowhite(), open(), fscan(), nscan(), strlen()
double	clgetd()
pointer	immap(), evvexpr()
extern	getkey, getkeys, getfunc
errchk	immap, open, evvexpr

begin
	# Check that there is at least one image.
	nsubsets = 0
	nims = imtlen (list)
	if (nims == 0)
	    return

	call smark (sp)
	call salloc (group, SZ_LINE, TY_CHAR)
	call salloc (seqexpr, SZ_LINE, TY_CHAR)
	call salloc (type, SZ_FNAME, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (extn, SZ_FNAME, TY_CHAR)
	call salloc (subset, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call salloc (scale, nims, TY_REAL)
	call salloc (zero, nims, TY_REAL)
	call salloc (wt, nims, TY_REAL)

	# Determine whether to divide images into subsets and append extensions.
	call clgstr ("group", Memc[group], SZ_LINE)
	call xt_stripwhite (Memc[group])
	call clgstr ("seqval", Memc[seqexpr], SZ_LINE)
	call xt_stripwhite (Memc[seqexpr])

	# Since we may eliminate images or reorder them we need to get the
	# scale, zero and weight values from input files where the values
	# are in the same order as the input images.

	if (listonly == NO) {
	    call clgstr ("scale", Memc[str], SZ_FNAME)
	    j = nowhite (Memc[str], Memc[str], SZ_FNAME)
	    if (Memc[str] == '@') {
		fd = open (Memc[str+1], READ_ONLY, TEXT_FILE)
		j = 0
		while (fscan (fd) != EOF) {
		    call gargr (Memr[scale+j])
		    if (nscan() != 1)
			next
		    if (j == nims) {
		      call eprintf (
			   "Warning: Ignoring additional %s values in %s\n")
			   call pargstr ("scale")
			   call pargstr (Memc[str+1])
		       break
		    }
		    j = j + 1
		}
		call close (fd)

		if (j < nims) {
		    call sprintf (Memc[type], SZ_FNAME,
			"Insufficient scale values in %s")
			call pargstr (Memc[str+1])
		    call error (1, Memc[type])
		}
	    } else
		call amovkr (INDEFR, Memr[scale], nims)

	    call clgstr ("zero", Memc[str], SZ_FNAME)
	    j = nowhite (Memc[str], Memc[str], SZ_FNAME)
	    if (Memc[str] == '@') {
		fd = open (Memc[str+1], READ_ONLY, TEXT_FILE)
		j = 0
		while (fscan (fd) != EOF) {
		    call gargr (Memr[zero+j])
		    if (nscan() != 1)
			next
		    if (j == nims) {
		      call eprintf (
			   "Warning: Ignoring additional %s values in %s\n")
			   call pargstr ("zero")
			   call pargstr (Memc[str+1])
		       break
		    }
		    j = j + 1
		}
		call close (fd)

		if (j < nims) {
		    call sprintf (Memc[type], SZ_FNAME,
			"Insufficient zero values in %s")
			call pargstr (Memc[str+1])
		    call error (1, Memc[type])
		}
	    } else
		call amovkr (INDEFR, Memr[zero], nims)

	    call clgstr ("weight", Memc[str], SZ_FNAME)
	    j = nowhite (Memc[str], Memc[str], SZ_FNAME)
	    if (Memc[str] == '@') {
		fd = open (Memc[str+1], READ_ONLY, TEXT_FILE)
		j = 0
		while (fscan (fd) != EOF) {
		    call gargr (Memr[wt+j])
		    if (nscan() != 1)
			next
		    if (j == nims) {
		      call eprintf (
			   "Warning: Ignoring additional %s values in %s\n")
			   call pargstr ("weight")
			   call pargstr (Memc[str+1])
		       break
		    }
		    j = j + 1
		}
		call close (fd)

		if (j < nims) {
		    call sprintf (Memc[type], SZ_FNAME,
			"Insufficient weight values in %s")
			call pargstr (Memc[str+1])
		    call error (1, Memc[type])
		}
	    } else
		call amovkr (INDEFR, Memr[wt], nims)
	}

	# Go through the input list and eliminate images not satisfying the
	# observation type.  Separate into subsets if desired.  Create image,
	# scale, zero, weight, and subset lists.  Determine if the input
	# is MEF data.

	call clgstr ("select", Memc[type], SZ_FNAME)

	mef = INDEFI
	j = 0
	while (imtgetim (list, Memc[image], SZ_FNAME)!=EOF) {
	    j = j + 1
	    iferr {
		if (IS_INDEFI(mef)) {
		    ifnoerr (im = immap (Memc[image], READ_ONLY, 0))
			mef = NO
		    else {
			switch (errcode()) {
			case SYS_FXFOPNOEXTNV:
			    call sprintf (Memc[str], SZ_FNAME, "%s[1]")
				call pargstr (Memc[image])
			    im = immap (Memc[str], READ_ONLY, 0)
			    mef = YES
			default:
			    call erract (EA_ERROR)
			}
		    }
		} else if (mef == NO)
		    im = immap (Memc[image], READ_ONLY, 0)
		else {
		    call sprintf (Memc[str], SZ_FNAME, "%s[1]")
			call pargstr (Memc[image])
		    im = immap (Memc[str], READ_ONLY, 0)
		}
	    } then {
		call erract (EA_WARN)
		next
	    }

	    # Check observation type if desired.
	    if (Memc[type] != EOS) {
	        o = evvexpr (Memc[type], locpr(getkeys), im,
		    locpr(getfunc), im, O_FREEOP)
		if (O_TYPE(o) != TY_BOOL)
		    call xvverror1 ("selection expression not boolean (%s)",
		        Memc[type])
		if (O_VALI(o) == NO) {
		    call evvfree (o)
		    next
		}
		call evvfree (o)
	    }
	    
	    Memc[extn] = EOS
	    Memc[subset] = EOS
	    seqval = INDEFD
	    if (Memc[group] != EOS) {
		o = evvexpr (Memc[group], locpr(getkeys), im, locpr(getfunc),
		    im, O_FREEOP)
		call strcat (O_VALC(o), Memc[extn], SZ_FNAME)
		call strcat (O_VALC(o), Memc[subset], SZ_FNAME)
		call evvfree (o)
		i = strlen (Memc[extn])
		if (Memc[extn+i-1] == '.')
		    Memc[extn+i-1] = EOS
		i = strlen (Memc[subset])
		if (Memc[subset+i-1] == '.')
		    Memc[subset+i-1] = EOS
	    }
	    if (Memc[seqexpr] != EOS) {
		o = evvexpr (Memc[seqexpr], locpr(getkey), im,
		    locpr(getfunc), im, O_FREEOP)
		switch (O_TYPE(o)) {
		case TY_SHORT:
		    seqval = O_VALS(o)
		case TY_INT:
		    seqval = O_VALI(o)
		case TY_LONG:
		    seqval = O_VALL(o)
		case TY_REAL:
		    seqval = O_VALR(o)
		case TY_DOUBLE:
		    seqval = O_VALD(o)
		default:
		    call error (1, "Sequence expression must be numeric")
		}
		call evvfree (o)
	    }
	    i = nowhite (Memc[extn], Memc[extn], SZ_FNAME)
	    i = nowhite (Memc[subset], Memc[subset], SZ_FNAME)
	    for (i=1; i <= nsubsets; i=i+1)
		if (streq (Memc[subset], Memc[Memi[subsets+i-1]]))
		    break

	    if (i > nsubsets) {
		if (nsubsets == 0) {
		    call malloc (images, nims, TY_POINTER)
		    call malloc (scales, nims, TY_POINTER)
		    call malloc (zeros, nims, TY_POINTER)
		    call malloc (wts, nims, TY_POINTER)
		    call malloc (seqvals, nims, TY_POINTER)
		    call malloc (extns, nims, TY_POINTER)
		    call malloc (subsets, nims, TY_POINTER)
		    call malloc (nimages, nims, TY_INT)
		} else if (mod (nsubsets, nims) == 0) {
		    call realloc (images, nsubsets+nims, TY_POINTER)
		    call realloc (scales, nsubsets+nims, TY_POINTER)
		    call realloc (zeros, nsubsets+nims, TY_POINTER)
		    call realloc (wts, nsubsets+nims, TY_POINTER)
		    call realloc (seqvals, nsubsets+nims, TY_POINTER)
		    call realloc (extns, nsubsets+nims, TY_POINTER)
		    call realloc (subsets, nsubsets+nims, TY_POINTER)
		    call realloc (nimages, nsubsets+nims, TY_INT)
		}
		nsubsets = i
		nimage = 1
		Memi[nimages+i-1] = nimage
		call malloc (Memi[images+i-1], nimage * SZ_FNAME, TY_CHAR)
		call malloc (Memi[scales+i-1], nimage, TY_REAL)
		call malloc (Memi[zeros+i-1], nimage, TY_REAL)
		call malloc (Memi[wts+i-1], nimage, TY_REAL)
		call malloc (Memi[seqvals+i-1], nimage, TY_DOUBLE)
		call malloc (Memi[extns+i-1], SZ_FNAME, TY_CHAR)
		call malloc (Memi[subsets+i-1], SZ_FNAME, TY_CHAR)

		call strcpy (Memc[extn], Memc[Memi[extns+i-1]], SZ_FNAME)
		call strcpy (Memc[subset], Memc[Memi[subsets+i-1]], SZ_FNAME)
	    } else {
		nimage = Memi[nimages+i-1] + 1
		Memi[nimages+i-1] = nimage
		call realloc (Memi[images+i-1], nimage * SZ_FNAME, TY_CHAR)
		call realloc (Memi[scales+i-1], nimage, TY_REAL)
		call realloc (Memi[zeros+i-1], nimage, TY_REAL)
		call realloc (Memi[wts+i-1], nimage, TY_REAL)
		call realloc (Memi[seqvals+i-1], nimage, TY_DOUBLE)
	    }

	    nimage = Memi[nimages+i-1]
	    ptr = Memi[images+i-1] + (nimage - 1) * SZ_FNAME
	    call strcpy (Memc[image], Memc[ptr], SZ_FNAME-1)
	    Memr[Memi[scales+i-1]+nimage-1] = Memr[scale+j-1]
	    Memr[Memi[zeros+i-1]+nimage-1] = Memr[zero+j-1]
	    Memr[Memi[wts+i-1]+nimage-1] = Memr[wt+j-1]
	    Memd[Memi[seqvals+i-1]+nimage-1] = seqval

	    call imunmap (im)
	}

	# Break up into sequences if desired.
	if (Memc[seqexpr] != EOS) {
	    gap = clgetd ("seqgap")
	    if (!IS_INDEFD(gap))
		call cmb_sequences (images, seqvals, scales, zeros, wts, extns,
		    subsets, nimages, nsubsets, gap)
	}

	call realloc (images, nsubsets, TY_POINTER)
	call realloc (scales, nsubsets, TY_POINTER)
	call realloc (zeros, nsubsets, TY_POINTER)
	call realloc (wts, nsubsets, TY_POINTER)
	call realloc (seqvals, nsubsets, TY_POINTER)
	call realloc (extns, nsubsets, TY_POINTER)
	call realloc (subsets, nsubsets, TY_POINTER)
	call realloc (nimages, nsubsets, TY_INT)

	call sfree (sp)
end


# MEFCOMBINE -- Combine MEF data.
#
# This routine receives a list of input MEF files already sorted by
# subset (i.e. filter) with appropriate output file names.  This routine
# must then group the image extensions by amplifier and set up the
# scaling factors, which are the same for all extensions from the
# same image.  At the end of combining all the extensions it averages
# any PROCMEAN keywords so that there is a common value for all the extensions.
#
# If there is only one output extension then an PHU only image is produced.

procedure mefcombine (ims, scale, zero, wt, seqval, nims, output, headers,
	broot, rroot, nrroot, eroot, sigma, logfile, stack, delete, oneimage,
	listonly)

char	ims[SZ_FNAME-1, nims]		# Input images
real	scale[nims]			# Scales
real	zero[nims]			# Zeros
real	wt[nims]			# Weights
double	seqval[nims]			# Sequence values
int	nims				# Number of images in list
char	output[ARB]			# Output image
char	headers[ARB]			# Header files
char	broot[ARB]			# Bad pixel mask
char	rroot[ARB]			# Rejection pixel mask
char	nrroot[ARB]			# Number rejected pixel mask
char	eroot[ARB]			# Exposure mask
char	sigma[ARB]			# Output sigma image
char	logfile[ARB]			# Log filename
int	stack				# Stack input images?
int	delete				# Delete input images?
int	oneimage			# Allow just a single image?
int	listonly			# List input and output only?

int	i, j, k, nsubsets, nimage, ghdr, list
real	procmean, sum
pointer	sp, extension, image, subset, bmask, rmask, nrmask, emask, im, ptr
pointer	images, iimage, scales, zeros, wts, seqvals, subsets, nimages, o

real	imgetr()
bool	streq()
int	errcode(), errget(), imaccess(), ic_mklist(), locpr()
pointer	immap(), evvexpr()
extern	getkeys, getfunc
errchk	immap, imcopy, icombine, mefscales, ic_mklist, evvexpr

include	"src/icombine.com"

begin
	call smark (sp)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (subset, SZ_FNAME, TY_CHAR)
	call salloc (bmask, SZ_FNAME, TY_CHAR)
	call salloc (rmask, SZ_FNAME, TY_CHAR)
	call salloc (nrmask, SZ_FNAME, TY_CHAR)
	call salloc (emask, SZ_FNAME, TY_CHAR)
	call salloc (extension, SZ_LINE, TY_CHAR)

	call clgstr ("extension", Memc[extension], SZ_LINE)
	call xt_stripwhite (Memc[extension])

	# Expand MEF files and group by extension.
	ghdr = NO
	nsubsets = 0
	do k = 1, nims {
	    do j = 0, ARB {
		call sprintf (Memc[image], SZ_FNAME, "%s[%d]")
		    call pargstr (ims[1,k])
		    call pargi (j)
		iferr (im = immap (Memc[image], READ_ONLY, 0)) {
		    switch (errcode()) {
		    case SYS_FXFRFEOF, SYS_IKIOPEN:
			break
		    case SYS_IKIEXTN:
			next
		    default:
			call erract (EA_ERROR)
		    }
		}
		if (IM_NDIM(im) == 0) {
		    if (j == 0)
			ghdr = YES
		    call imunmap (im)
		    next
		}

		Memc[subset] = EOS
		if (Memc[extension] != EOS) {
		    o = evvexpr (Memc[extension], locpr(getkeys), im,
			locpr(getfunc), im, O_FREEOP)
		    call strcat (O_VALC(o), Memc[subset], SZ_FNAME)
		    call evvfree (o)
		}

		# Following forces combining by extensions if not requested
		# explicitly.
		#if (Memc[subset] == EOS) {
		#    call sprintf (Memc[subset], SZ_FNAME, "%d")
		#	call pargi (j)
		#}

		for (i=1; i <= nsubsets; i=i+1)
		    if (streq (Memc[subset], Memc[Memi[subsets+i-1]]))
			break

		if (i > nsubsets) {
		    if (nsubsets == 0) {
			call malloc (images, nims, TY_POINTER)
			call malloc (iimage, nims, TY_POINTER)
			call malloc (scales, nims, TY_POINTER)
			call malloc (zeros, nims, TY_POINTER)
			call malloc (wts, nims, TY_POINTER)
			call malloc (seqvals, nims, TY_POINTER)
			call malloc (subsets, nims, TY_POINTER)
			call malloc (nimages, nims, TY_INT)
		    } else if (mod (nsubsets, nims) == 0) {
			call realloc (images, nsubsets+nims, TY_POINTER)
			call realloc (iimage, nsubsets+nims, TY_POINTER)
			call realloc (scales, nsubsets+nims, TY_POINTER)
			call realloc (zeros, nsubsets+nims, TY_POINTER)
			call realloc (wts, nsubsets+nims, TY_POINTER)
			call realloc (seqvals, nsubsets+nims, TY_POINTER)
			call realloc (subsets, nsubsets+nims, TY_POINTER)
			call realloc (nimages, nsubsets+nims, TY_INT)
		    }
		    nsubsets = i
		    nimage = 1
		    Memi[nimages+i-1] = nimage
		    call malloc (Memi[images+i-1], nimage * SZ_FNAME, TY_CHAR)
		    call malloc (Memi[iimage+i-1], nimage, TY_INT)
		    call malloc (Memi[scales+i-1], nimage, TY_REAL)
		    call malloc (Memi[zeros+i-1], nimage, TY_REAL)
		    call malloc (Memi[wts+i-1], nimage, TY_REAL)
		    call malloc (Memi[seqvals+i-1], nimage, TY_DOUBLE)
		    call malloc (Memi[subsets+i-1], SZ_FNAME, TY_CHAR)

		    call strcpy (Memc[subset], Memc[Memi[subsets+i-1]],
			SZ_FNAME)
		} else {
		    nimage = Memi[nimages+i-1] + 1
		    Memi[nimages+i-1] = nimage
		    call realloc (Memi[images+i-1], nimage * SZ_FNAME, TY_CHAR)
		    call realloc (Memi[iimage+i-1], nimage, TY_INT)
		    call realloc (Memi[scales+i-1], nimage, TY_REAL)
		    call realloc (Memi[zeros+i-1], nimage, TY_REAL)
		    call realloc (Memi[wts+i-1], nimage, TY_REAL)
		    call realloc (Memi[seqvals+i-1], nimage, TY_DOUBLE)
		}

		nimage = Memi[nimages+i-1]
		ptr = Memi[images+i-1] + (nimage - 1) * SZ_FNAME
		call strcpy (Memc[image], Memc[ptr], SZ_FNAME-1)
		Memi[Memi[iimage+i-1]+nimage-1] = k
		Memr[Memi[scales+i-1]+nimage-1] = scale[k]
		Memr[Memi[zeros+i-1]+nimage-1] = zero[k]
		Memr[Memi[wts+i-1]+nimage-1] = wt[k]
		Memd[Memi[seqvals+i-1]+nimage-1] = seqval[k]

		call imunmap (im)
	    }
	}

	call realloc (images, nsubsets, TY_POINTER)
	call realloc (iimage, nsubsets, TY_POINTER)
	call realloc (scales, nsubsets, TY_POINTER)
	call realloc (zeros, nsubsets, TY_POINTER)
	call realloc (wts, nsubsets, TY_POINTER)
	call realloc (seqvals, nsubsets, TY_POINTER)
	call realloc (subsets, nsubsets, TY_POINTER)
	call realloc (nimages, nsubsets, TY_INT)

	# Check number of images.
	if (oneimage == NO) {
	    do i = 1, nsubsets {
		if (Memi[nimages+i-1] > 1)
		    break
	    }
	    if (i > nsubsets) {
		call cmb_images_free (images, scales, zeros, wts, seqvals,
		    NULL, iimage, subsets, nimages, nsubsets)
		call error (ONEIMAGE, "Only single images to combine") 
	    }
	}

	if (listonly == NO) {
	    # Compute scaling factors if needed.
	    call mefscales (Memi[images], Memi[iimage], Memi[nimages], nsubsets,
		scale, zero, wt, nims)
	    do i = 1, nsubsets {
		do j = 1, Memi[nimages+i-1] {
		    k = Memi[Memi[iimage+i-1]+j-1]
		    Memr[Memi[scales+i-1]+j-1] = scale[k]
		    Memr[Memi[zeros+i-1]+j-1] = zero[k]
		    Memr[Memi[wts+i-1]+j-1] = wt[k]
		}
	    }

	    # Create the global headers.
	    if (ghdr == YES && nsubsets > 1) {
		if (imaccess (output, 0) == YES) {
		    call sprintf (Memc[image], SZ_FNAME,
			"Output `%s' already exists")
			call pargstr (output)
		    call error (1, Memc[image])
		}
		call sprintf (Memc[image], SZ_FNAME, "%s[0]")
		    call pargstr (ims[1,1])
		im = immap (Memc[image], READ_ONLY, 0)
		call sprintf (Memc[image], SZ_FNAME, "%s[noappend]")
		    call pargstr (output)
		ptr = immap (Memc[image], NEW_COPY, im)
		call imunmap (ptr)
		if (sigma[1] != EOS) {
		    call sprintf (Memc[image], SZ_FNAME, "%s[noappend]")
			call pargstr (sigma)
		    ptr = immap (Memc[image], NEW_COPY, im)
		    call imunmap (ptr)
		}
		call imunmap (im)
	    }
	}

	# Combine each extension.
	do i = 1, nsubsets {

	    # Add inherit parameter to output name.
	    if (listonly == YES) {
		call sprintf (Memc[image], SZ_FNAME, "%s%s")
		    call pargstr (output)
		    call pargstr (Memc[Memi[subsets+i-1]])
	    } else if (nsubsets > 1) {
		call sprintf (Memc[image], SZ_FNAME, "%s[append,inherit]")
		    call pargstr (output)
	    } else
		call strcpy (output, Memc[image], SZ_FNAME)

	    # Since we can't append pl files add an extension.
	    call strcpy (broot, Memc[bmask], SZ_FNAME)
	    if (Memc[bmask] != EOS) {
		call sprintf (Memc[bmask], SZ_FNAME, "%s%s")
		    call pargstr (broot)
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    # Since we can't append pl files add an extension.
	    call strcpy (rroot, Memc[rmask], SZ_FNAME)
	    if (Memc[rmask] != EOS) {
		call sprintf (Memc[rmask], SZ_FNAME, "%s%s")
		    call pargstr (rroot)
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    # Since we can't append pl files add an extension.
	    call strcpy (nrroot, Memc[nrmask], SZ_FNAME)
	    if (Memc[nrmask] != EOS) {
		call sprintf (Memc[nrmask], SZ_FNAME, "%s%s")
		    call pargstr (rroot)
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    # Since we can't append pl files add an extension.
	    call strcpy (eroot, Memc[emask], SZ_FNAME)
	    if (Memc[emask] != EOS) {
		call sprintf (Memc[emask], SZ_FNAME, "%s%s")
		    call pargstr (eroot)
		    call pargstr (Memc[Memi[subsets+i-1]])
	    }

	    # Combine all images from the (subset) list.
	    list = ic_mklist (Memi[images+i-1], Memi[nimages+i-1], NO)

	    iferr (call icombine (list, Memc[image],  headers, Memc[bmask],
		Memc[rmask], Memc[nrmask], Memc[emask], sigma, logfile,
		Memr[Memi[scales+i-1]], Memr[Memi[zeros+i-1]],
		Memr[Memi[wts+i-1]], stack, NO, listonly)) {
		i = errget (Memc[image], SZ_FNAME)
		if (listonly == NO) {
		    iferr (call imdelete (output))
			;
		}
		call error (1, Memc[image])
	    }
	    call imtclose (list)
	}

	call cmb_images_free (images, scales, zeros, wts, seqvals, NULL,
	    iimage, subsets, nimages, nsubsets)

	if (listonly == NO) {
	    # Reset MEF header.
	    # Set global procmean.
	    if (nsubsets > 1) {
		sum = 0
		i = 0.
		do j = nsubsets, 0, -1 {
		    call sprintf (Memc[image], SZ_FNAME, "%s[%d]")
			call pargstr (output)
			call pargi (j)
		    im = immap (Memc[image], READ_WRITE, 0)
		    if (j > 0) {
			ifnoerr (procmean = imgetr (im, "procmean")) {
			    sum = sum + procmean
			    i = i + 1
			    call imdelf (im, "procmean")
			}
		    } else if (i > 0) {
			procmean = sum / i
			call imaddr (im, "procmean", procmean)
		    }
		    call imunmap (im)
		}
	    }
	}

	# Delete input images.
	if (delete == YES && listonly == NO) {
	    do i = 1, nims
		call imdelete (ims[1,i])
	}

	call sfree (sp)
end


# IC_MKLIST -- Convert images names into an image list.
#
# The list may be sorted because image templates are not sorted.

int procedure ic_mklist (images, nimages, sort)

pointer	images			#I Image names (SZ_FNAME-1xnimages)
int	nimages			#I Number of images
int	sort			#I Sort list?
int	list			#O Image list

int	i, fd, stropen(), imtopen()
pointer	sp, ptrs, str
errchk	salloc, stropen, imtopen

begin
	call smark (sp)
	call salloc (ptrs, nimages, TY_POINTER)
	call salloc (str, nimages*SZ_FNAME, TY_CHAR)

	# Sort the list.
	do i = 0, nimages-1
	    Memi[ptrs+i] = 1 + i * SZ_FNAME
	if (sort == YES)
	    call strsrt (Memi[ptrs], Memc[images], nimages)

	# Write a list.
	fd = stropen (Memc[str], nimages*SZ_FNAME, NEW_FILE)
	do i = 0, nimages-1 {
	    call fprintf (fd, "%s,")
		call pargstr (Memc[images+Memi[ptrs+i]-1])
	}
	call close (fd)

	# Open list.
	list = imtopen (Memc[str])

	call sfree (sp)
	return (list)
end


# CMB_SEQUENCES -- Break up into sequences defined by a minimum gap.
#
# This reallocates all the arrays and changes the number of subsets.

procedure cmb_sequences (images, seqvals, scales, zeros, wts, extns,
	subsets, nimages, nsubsets, gap)

pointer images		#U Pointer to lists of subsets (reallocated)
pointer seqvals		#U Pointer to array of sequence values (reallocated)
pointer scales		#U Pointer to array of scales (reallocated)
pointer zeros		#U Pointer to array of zeros (reallocated)
pointer wts		#U Pointer to array of weights (reallocated)
pointer extns		#U Image extensions for each subset (reallocated)
pointer subsets		#U Subset names (reallocated)
pointer nimages		#U Number of images in subset (reallocated)
int	nsubsets	#U Number of subsets (reset)
double	gap		#I Sequence value gap

int	i, j, k, n, ns, nseq, nalloc
pointer ims, ses, scs, zes, wss, exs, sus, nis, seqoff
pointer	im, se, sc, ze, ws, ex, su, ni

begin
	ns = 0
	do i = 0, nsubsets-1 {

	    im = Memi[images+i]
	    se = Memi[seqvals+i]
	    sc = Memi[scales+i]
	    ze = Memi[zeros+i]
	    ws = Memi[wts+i]
	    ex = Memi[extns+i]
	    su = Memi[subsets+i]
	    ni = Memi[nimages+i]

	    # Find sequences.
	    call cmb_sequences1 (se, im, sc, ze, ws, ni, nseq, seqoff, gap)

	    do j = 1, nseq {
		if (ns == 0) {
		    nalloc = nseq * nsubsets
		    call malloc (ims, nalloc, TY_POINTER)
		    call malloc (ses, nalloc, TY_POINTER)
		    call malloc (scs, nalloc, TY_POINTER)
		    call malloc (zes, nalloc, TY_POINTER)
		    call malloc (wss, nalloc, TY_POINTER)
		    call malloc (exs, nalloc, TY_POINTER)
		    call malloc (sus, nalloc, TY_POINTER)
		    call malloc (nis, nalloc, TY_POINTER)
		} else if (mod (ns, nalloc) == 0) {
		    call realloc (ims, ns+nalloc, TY_POINTER)
		    call realloc (ses, ns+nalloc, TY_POINTER)
		    call realloc (scs, ns+nalloc, TY_POINTER)
		    call realloc (zes, ns+nalloc, TY_POINTER)
		    call realloc (wss, ns+nalloc, TY_POINTER)
		    call realloc (exs, ns+nalloc, TY_POINTER)
		    call realloc (sus, ns+nalloc, TY_POINTER)
		    call realloc (nis, ns+nalloc, TY_POINTER)
		}

		k = Memi[seqoff+j-1]
		n = Memi[seqoff+j] - k
		call malloc (Memi[ims+ns], n*SZ_FNAME, TY_CHAR)
		call malloc (Memi[ses+ns], n, TY_DOUBLE)
		call malloc (Memi[scs+ns], n, TY_REAL)
		call malloc (Memi[zes+ns], n, TY_REAL)
		call malloc (Memi[wss+ns], n, TY_REAL)
		call malloc (Memi[sus+ns], SZ_FNAME, TY_CHAR)
		call malloc (Memi[exs+ns], SZ_FNAME, TY_CHAR)
		call amovc (Memc[im+k*SZ_FNAME], Memc[Memi[ims+ns]], n*SZ_FNAME)
		call amovd (Memd[se+k], Memd[Memi[ses+ns]], n)
		call amovr (Memr[sc+k], Memr[Memi[scs+ns]], n)
		call amovr (Memr[ze+k], Memr[Memi[zes+ns]], n)
		call amovr (Memr[ws+k], Memr[Memi[wss+ns]], n)
		if (nseq > 1) {
		    call sprintf (Memc[Memi[exs+ns]], SZ_FNAME, "%s_%d")
			call pargstr (Memc[ex])
			call pargi (j)
		    call sprintf (Memc[Memi[sus+ns]], SZ_FNAME, "%s_%d")
			call pargstr (Memc[su])
			call pargi (j)
		} else {
		    call strcpy (Memc[ex], Memc[Memi[exs+ns]], SZ_FNAME)
		    call strcpy (Memc[su], Memc[Memi[sus+ns]], SZ_FNAME)
		}
		Memi[nis+ns] = n
		ns = ns + 1
	    }
	}

	# Free old memory.
	call cmb_images_free (images, scales, zeros, wts, seqvals, extns,
	    NULL, subsets, nimages, nsubsets)

	# Reset new memory.
	images = ims
	seqvals = ses
	scales = scs
	zeros = zes
	wts = wss
	extns = exs
	subsets = sus
	nimages = nis
	nsubsets = ns
end


# CMB_SEQUENCES1 -- Break a single subset into sequences.
# This sorts the images by sequence value and defines sequences by a
# minimum gap in the sequence values.  Note that this sorts the input arrays.
# The returned values are the number of sequences and the offsets in
# the sorted input arrays.

procedure cmb_sequences1 (se, im, sc, ze, ws, ni, nseq, seqoff, gap)

pointer	se			#I Pointer to sequence values
pointer	im			#I Pointer image names
pointer	sc			#I Pointer to sc
pointer	ze			#I Pointer to ze
pointer	ws			#I Pointer to weights
int	ni			#I Number of im
int	nseq			#O Number of sequences
pointer	seqoff			#O Sequence offsets
double	gap			#I Sequence value gap

int	i
pointer	sp, indices, rtmp, dtmp, ctmp

int	cmb_compare()
extern	cmb_compare()

begin
	call malloc (seqoff, ni+1, TY_INT)

	# Check for valid sequence values.
	do i = 0, ni-1 {
	    if (IS_INDEFD(Memd[se+i]))
		break
	}
	if (i < ni) {
	    Memi[seqoff] = 0
	    Memi[seqoff+1] = ni
	    nseq = 1
	    return
	}

	call smark (sp)
	call salloc (indices, ni, TY_INT)
	call salloc (rtmp, ni, TY_REAL)
	call salloc (dtmp, ni, TY_DOUBLE)
	call salloc (ctmp, ni*SZ_FNAME, TY_CHAR)

	# Sort arrays by the sequence values.
	do i = 0, ni-1
	    Memi[indices+i] = i
	call gqsort (Memi[indices], ni, cmb_compare, se)
	do i = 0, ni-1
	    call strcpy (Memc[im+Memi[indices+i]*SZ_FNAME],
	        Memc[ctmp+i*SZ_FNAME], SZ_FNAME-1)
	call amovc (Memc[ctmp], Memc[im], ni*SZ_FNAME)
	do i = 0, ni-1
	    Memd[dtmp+i] = Memd[se+Memi[indices+i]]
	call amovd (Memd[dtmp], Memd[se], ni)
	do i = 0, ni-1
	    Memr[rtmp+i] = Memr[sc+Memi[indices+i]]
	call amovr (Memr[rtmp], Memr[sc], ni)
	do i = 0, ni-1
	    Memr[rtmp+i] = Memr[ze+Memi[indices+i]]
	call amovr (Memr[rtmp], Memr[ze], ni)
	do i = 0, ni-1
	    Memr[rtmp+i] = Memr[ws+Memi[indices+i]]
	call amovr (Memr[rtmp], Memr[ws], ni)

	# Find gaps between sequences.
	Memi[seqoff] = 0
	nseq = 1
	do i = 1, ni-1 {
	    if (Memd[se+i] - Memd[se+i-1] > gap) {
		Memi[seqoff+nseq] = i
		nseq = nseq + 1
	    }
	}
	Memi[seqoff+nseq] = ni

	call sfree (sp)
end


# CMB_COMPARE -- GQSORT comparison function for sequence values.

int procedure cmb_compare (se, i, j)

pointer	se			#I Pointer to sequence values
int	i, j			#I Comparison indices (zero indexed)

begin
	if (Memd[se+i] < Memd[se+j])
	    return (-1)
	else if (Memd[se+i] > Memd[se+j])
	    return (1)
	else
	    return (0)
end
