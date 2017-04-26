include	<error.h>
include	<fset.h>
include	<imset.h>
include	<pmset.h>
include <plio.h>
include	<imhdr.h>
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>
include	"ace.h"
include	"acedetect.h"
include	"detect.h"
include	"filter.h"
include	"sky.h"
include	"skyblock.h"

include	<imio.h>

define	SINGLECAT	1	# Process each image to a single catalog
define	MULTICAT	2	# Process all images to a single catalog

define	ACEWARN		2	# Warning code


# ACEALL -- Expand input list and set filenames.
# This calls ACE for each image to be analyzed.

procedure aceall (par)

pointer	par			#I Parameters

int	mode, nim, ncat
int	i, j, k, list, imext
pointer	sp, imtype, str
pointer	image[4], bpmask[4], skyname[4], signame[4]
pointer	expname[4], gainname[4], spatial[4]
pointer	incat[2], outcat[2], inobjmask[2], outobjmask[2]
pointer	outsky[2], outsig[2], scalestr[2]
pointer	catdef, acestruct, logfile
pointer	im, cat, om, stp, sym, ptr

bool	streq()
int	nowhite(), xt_extns(), strldxs(), strlen(), errcode(), envgets()
int	afn_len(), afn_gfn(), catacc(), imtopen(), imtgetim(), locpr()
pointer	immap(), imgl2r()
pointer	stopen(), stfind(), stenter(), sthead(), stnext(), stname()
errchk	immap, stopen, imgstr
errchk	ace, ace_omulticat, ace_amulticat, ace_cmulticat
extern	f_catdef(), f_acestruct()

begin
	call smark (sp)

	# Allocate memory for all the file names.  The first half of each
	# array of names is for image names including extensions and the
	# second half is for cluster names.   The names are initialized
	# to EOS and are only filled in if specified.

	do j = 1, 4 {
	    call salloc (image[j], SZ_FNAME, TY_CHAR)
	    call salloc (bpmask[j], SZ_FNAME, TY_CHAR)
	    call salloc (skyname[j], SZ_FNAME, TY_CHAR)
	    call salloc (signame[j], SZ_FNAME, TY_CHAR)
	    call salloc (expname[j], SZ_FNAME, TY_CHAR)
	    call salloc (gainname[j], SZ_FNAME, TY_CHAR)
	    call salloc (spatial[j], SZ_FNAME, TY_CHAR)
	    Memc[image[j]] = EOS
	    Memc[bpmask[j]] = EOS
	    Memc[skyname[j]] = EOS
	    Memc[signame[j]] = EOS
	    Memc[expname[j]] = EOS
	    Memc[gainname[j]] = EOS
	    Memc[spatial[j]] = EOS
	}
	do j = 1, 2 {
	    call salloc (inobjmask[j], SZ_FNAME, TY_CHAR)
	    call salloc (outobjmask[j], SZ_FNAME, TY_CHAR)
	    call salloc (incat[j], SZ_FNAME, TY_CHAR)
	    call salloc (outcat[j], SZ_FNAME, TY_CHAR)
	    call salloc (outsky[j], SZ_FNAME, TY_CHAR)
	    call salloc (outsig[j], SZ_FNAME, TY_CHAR)
	    call salloc (scalestr[j], SZ_FNAME, TY_CHAR)
	    Memc[inobjmask[j]] = EOS
	    Memc[outobjmask[j]] = EOS
	    Memc[incat[j]] = EOS
	    Memc[outcat[j]] = EOS
	    Memc[outsky[j]] = EOS
	    Memc[outsig[j]] = EOS
	    Memc[scalestr[j]] = EOS
	}
	call salloc (catdef, SZ_FNAME, TY_CHAR)
	call salloc (acestruct, SZ_FNAME, TY_CHAR)
	call salloc (logfile, SZ_FNAME, TY_CHAR)
	Memc[catdef] = EOS
	Memc[logfile] = EOS
	call sprintf (Memc[acestruct], SZ_FNAME, "proc:%d")
	    call pargi (locpr(f_acestruct))

	call salloc (str, SZ_LINE, TY_CHAR)

	# Check lists match. 
	nim = afn_len (PAR_IMLIST(par,1))
	i = afn_len (PAR_BPMLIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and bad pixel mask lists do not match")
	i = afn_len (PAR_SKYLIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and sky lists do not match")
	i = afn_len (PAR_SIGLIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and sky sigma lists do not match")
	i = afn_len (PAR_EXPLIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and exposure map lists do not match")
	i = afn_len (PAR_GAINLIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and measurement gain lists do not match")
	i = afn_len (PAR_SCALELIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and scale lists do not match")
	i = afn_len (PAR_SPTLLIST(par,1))
	if (i > 1 && i != nim)
	    call error (1,
		"Image and spatial map lists do not match")

	k = afn_len (PAR_IMLIST(par,2))
	if (k > 1 && i != k)
	    call error (1,
		"Image and reference lists do not match")
	i = afn_len (PAR_BPMLIST(par,2))
	if (i > 1 && i != k)
	    call error (1,
		"Reference image  bad pixel mask lists do not match")
	i = afn_len (PAR_SKYLIST(par,2))
	if (i > 1 && i != k)
	    call error (1,
		"Reference image and sky lists do not match")
	i = afn_len (PAR_SIGLIST(par,2))
	if (i > 1 && i != k)
	    call error (1,
		"Reference image and sky sigma lists do not match")
	i = afn_len (PAR_EXPLIST(par,2))
	if (i > 1 && i != k)
	    call error (1,
		"Reference image and exposure map lists do not match")
	i = afn_len (PAR_GAINLIST(par,2))
	if (i > 1 && i != nim)
	    call error (1,
		"Reference image and measurement gain lists do not match")
	i = afn_len (PAR_SCALELIST(par,2))
	if (i > 1 && i != k)
	    call error (1,
		"Reference image and scale lists do not match")
	i = afn_len (PAR_SPTLLIST(par,2))
	if (i > 1 && i != k)
	    call error (1,
		"Reference image and spatial map lists do not match")
	i = afn_len (PAR_LOGLIST(par))
	if (i > 1 && i != nim)
	    call error (1,
		"Input image and logfile lists do not match")
	i = afn_len (PAR_OUTSKYLIST(par))
	if (i > 0 && i != nim)
	    call error (1,
		"Input image and output sky lists do not match")
	i = afn_len (PAR_OUTSIGLIST(par))
	if (i > 0 && i != nim)
	    call error (1,
		"Input image and output sigma lists do not match")


	i = afn_len (PAR_OUTCATLIST(par))
	if (i > 0 && i != nim) {
	    if (i <= 1)
	        mode = MULTICAT
	    else
		call error (1,
		    "Input image and output catalog lists do not match")
	} else
	    mode = SINGLECAT
	switch (mode) {
	case SINGLECAT:
	    i = afn_len (PAR_INCATLIST(par))
	    if (i > 0 && i != nim)
		call error (1,
		    "Input image and input catalog lists do not match")
	    i = afn_len (PAR_CATDEFLIST(par))
	    if (i > 1 && i != nim)
		call error (1,
		    "Input image and catalog definition lists do not match")
	    i = afn_len (PAR_OUTOMLIST(par))
	    if (i > 0 && i != nim)
		call error (1,
		    "Input image and object mask lists do not match")
	case MULTICAT:
	    i = afn_len (PAR_INCATLIST(par))
	    k = afn_len (PAR_OUTOMLIST(par))
	    if (i > 1)
		call error (1, "Only a single input catalog is allowed")
	    else if (k > 1)
		call error (1, "Only a single object mask is allowed")

	    i = afn_len (PAR_CATDEFLIST(par))
	    if (i > 1)
		call error (1, "Single catalog definition list is required")
	}

	# Set default file type.
	call salloc (imtype, 6, TY_CHAR)
	Memc[imtype] = '.'
	if (envgets ("imtype", Memc[imtype+1], 5) == 0)
	    call strcpy ("fits", Memc[imtype+1], 5)

	# Do each input image cluster.
	ncat = 0
	while (afn_gfn (PAR_IMLIST(par,1), Memc[image[1]], SZ_FNAME) != EOF) {
	    if (afn_gfn (PAR_IMLIST(par,2), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[image[2]], SZ_FNAME)

	    # Get associated cluster names.
	    # Initialize image names to the cluster names.
	    # Strip whitespace to check for no name.
	    do j = 1, 2 {
		if (afn_gfn (PAR_BPMLIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[bpmask[j]], SZ_FNAME)
		if (afn_gfn (PAR_SKYLIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[skyname[j]], SZ_FNAME)
		if (afn_gfn (PAR_SIGLIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[signame[j]], SZ_FNAME)
		if (afn_gfn (PAR_EXPLIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[expname[j]], SZ_FNAME)
		if (afn_gfn (PAR_GAINLIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[gainname[j]], SZ_FNAME)
		if (afn_gfn (PAR_SCALELIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[scalestr[j]], SZ_FNAME)
		if (afn_gfn (PAR_SPTLLIST(par,j), Memc[str], SZ_LINE) != EOF)
		    call strcpy (Memc[str], Memc[spatial[j]], SZ_FNAME)

		i = nowhite (Memc[bpmask[j]], Memc[bpmask[j]], SZ_FNAME)
		i = nowhite (Memc[skyname[j]], Memc[skyname[j]], SZ_FNAME)
		i = nowhite (Memc[signame[j]], Memc[signame[j]], SZ_FNAME)
		i = nowhite (Memc[expname[j]], Memc[expname[j]], SZ_FNAME)
		i = nowhite (Memc[gainname[j]], Memc[gainname[j]], SZ_FNAME)
		i = nowhite (Memc[scalestr[j]], Memc[scalestr[j]], SZ_FNAME)
		i = nowhite (Memc[spatial[j]], Memc[spatial[j]], SZ_FNAME)
	    }

	    if (afn_gfn (PAR_INCATLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[incat[1]], SZ_FNAME)
	    if (afn_gfn (PAR_OUTCATLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[outcat[1]], SZ_FNAME)
	    if (afn_gfn (PAR_INOMLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[inobjmask[1]], SZ_FNAME)
	    if (afn_gfn (PAR_OUTOMLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[outobjmask[1]], SZ_FNAME)
	    if (afn_gfn (PAR_OUTSKYLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[outsky[1]], SZ_FNAME)
	    if (afn_gfn (PAR_OUTSIGLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[outsig[1]], SZ_FNAME)
	    if (afn_gfn (PAR_CATDEFLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[catdef], SZ_FNAME)
	    if (afn_gfn (PAR_LOGLIST(par), Memc[str], SZ_LINE) != EOF)
		call strcpy (Memc[str], Memc[logfile], SZ_FNAME)

	    i = nowhite (Memc[incat[1]], Memc[incat[1]], SZ_FNAME)
	    i = nowhite (Memc[outcat[1]], Memc[outcat[1]], SZ_FNAME)
	    i = nowhite (Memc[inobjmask[1]], Memc[inobjmask[1]], SZ_FNAME)
	    i = nowhite (Memc[outobjmask[1]], Memc[outobjmask[1]], SZ_FNAME)
	    i = nowhite (Memc[outsky[1]], Memc[outsky[1]], SZ_FNAME)
	    i = nowhite (Memc[outsig[1]], Memc[outsig[1]], SZ_FNAME)
	    i = nowhite (Memc[catdef], Memc[catdef], SZ_FNAME)
	    i = nowhite (Memc[logfile], Memc[logfile], SZ_FNAME)

	    if (Memc[catdef] == EOS) {
	        call sprintf (Memc[catdef], SZ_FNAME, "proc:%d")
		    call pargi (locpr(f_catdef))
	    }

	    # Expand clusters to images.  As a special case, if the input is
	    # an explicit extension image then don't treat the filenames as MEF.
	    if (streq (Memc[image[1]], "NONE")) {
	        list = imtopen (Memc[image[1]])
		imext = NO
	    } else {
		list = xt_extns (Memc[image[1]], "IMAGE", "0-",
		    PAR_EXTNAMES(par), "", NO, YES, NO, NO, "", NO, imext)
		if (strldxs ("[", Memc[image[1]]) != 0)
		    imext = NO
	    }
	    while (imtgetim (list, Memc[image[3]], SZ_FNAME) != EOF) {
		iferr {
		    call strcpy (Memc[image[2]], Memc[image[4]], SZ_FNAME)
		    do j = 1, 2 {
			call strcpy (Memc[bpmask[j]], Memc[bpmask[j+2]],
			    SZ_FNAME)
			call strcpy (Memc[skyname[j]], Memc[skyname[j+2]],
			    SZ_FNAME)
			call strcpy (Memc[signame[j]], Memc[signame[j+2]],
			    SZ_FNAME)
			call strcpy (Memc[expname[j]], Memc[expname[j+2]],
			    SZ_FNAME)
			call strcpy (Memc[gainname[j]], Memc[gainname[j+2]],
			    SZ_FNAME)
			call strcpy (Memc[spatial[j]], Memc[spatial[j+2]],
			    SZ_FNAME)
		    }
		    call strcpy (Memc[incat[1]], Memc[incat[2]], SZ_FNAME)
		    call strcpy (Memc[outcat[1]], Memc[outcat[2]], SZ_FNAME)
		    call strcpy (Memc[inobjmask[1]], Memc[inobjmask[2]],
		        SZ_FNAME)
		    call strcpy (Memc[outobjmask[1]], Memc[outobjmask[2]],
		        SZ_FNAME)
		    call strcpy (Memc[outsky[1]], Memc[outsky[2]], SZ_FNAME)
		    call strcpy (Memc[outsig[1]], Memc[outsig[2]], SZ_FNAME)

		    # Add extensions if needed.
		    i = strldxs ("[", Memc[image[3]])
		    if (imext == YES && i > 0) {
			i = image[3]+i-1
			call strcpy (Memc[i], Memc[str], SZ_LINE)
			Memc[str+strldxs ("]", Memc[str])-1] = EOS
			call strcat (",append]", Memc[str], SZ_LINE)

			if (Memc[image[2]]!=EOS && Memc[image[2]]!='!' &&
			    strldxs ("[", Memc[image[2]]) == 0)
			    call strcat (Memc[i], Memc[image[4]], SZ_FNAME)
			do j = 1, 2 {
			    if (Memc[bpmask[j]]!=EOS && Memc[bpmask[j]]!='!' &&
				strldxs ("[", Memc[bpmask[j]]) == 0)
				call strcat (Memc[i], Memc[bpmask[j+2]],
				    SZ_FNAME)
			    if (Memc[skyname[j]]!=EOS&&Memc[skyname[j]]!='!'&&
				strldxs ("[", Memc[skyname[j]]) == 0)
				call strcat (Memc[str], Memc[skyname[j+2]],
				    SZ_FNAME)
			    if (Memc[signame[j]]!=EOS&&Memc[signame[j]]!='!'&&
				strldxs ("[", Memc[signame[j]]) == 0)
				call strcat (Memc[str], Memc[signame[j+2]],
				    SZ_FNAME)
			    if (Memc[expname[j]]!=EOS&&Memc[expname[j]]!='!'&&
				strldxs ("[", Memc[expname[j]]) == 0)
				call strcat (Memc[i], Memc[expname[j+2]],
				    SZ_FNAME)
			    if (Memc[gainname[j]]!=EOS&&Memc[gainname[j]]!='!'&&
				strldxs ("[", Memc[gainname[j]]) == 0)
				call strcat (Memc[i], Memc[gainname[j+2]],
				    SZ_FNAME)
			    if (Memc[spatial[j]]!=EOS&&Memc[spatial[j]]!='!'&&
				strldxs ("[", Memc[spatial[j]]) == 0)
				call strcat (Memc[i], Memc[spatial[j+2]],
				    SZ_FNAME)
			}
			if (Memc[incat[1]]!=EOS && Memc[incat[1]]!='!' &&
			    strldxs ("[", Memc[incat[1]]) == 0) {
			    k = strlen (Memc[incat[1]])
			    if (!(streq(Memc[incat[1]+k-5],Memc[imtype]) ||
				streq(Memc[incat[1]+k-4],".fit") ||
				(Memc[incat[1]+k-4]=='.' &&
				 Memc[incat[1]+k-1]=='f')))
				call strcat (Memc[imtype], Memc[incat[2]], SZ_FNAME)
			    call strcat (Memc[i], Memc[incat[2]], SZ_FNAME)
			}
			if (Memc[outcat[1]]!=EOS && Memc[outcat[1]]!='!' &&
			    strldxs ("[", Memc[outcat[1]]) == 0) {
			    k = strlen (Memc[outcat[1]])
			    if (!(streq(Memc[outcat[1]+k-5],Memc[imtype]) ||
				streq(Memc[outcat[1]+k-4],".fit") ||
				(Memc[outcat[1]+k-4]=='.' &&
				 Memc[outcat[1]+k-1]=='f')))
				call strcat (Memc[imtype], Memc[outcat[2]], SZ_FNAME)
			    call strcat (Memc[i], Memc[outcat[2]], SZ_FNAME)
			}
			if (Memc[outsky[1]]!=EOS && Memc[outsky[1]]!='!' &&
			    strldxs ("[", Memc[outsky[1]]) == 0)
			    call strcat (Memc[str], Memc[outsky[2]], SZ_FNAME)
			if (Memc[outsig[1]]!=EOS && Memc[outsig[1]]!='!' &&
			    strldxs ("[", Memc[outsig[1]]) == 0)
			    call strcat (Memc[str], Memc[outsig[2]], SZ_FNAME)
			if (Memc[inobjmask[1]]!=EOS &&
			    Memc[inobjmask[1]]!='!' &&
			    strldxs ("[", Memc[inobjmask[1]]) == 0) {
			    k = strlen (Memc[inobjmask[1]])
			    if (streq(Memc[inobjmask[1]+k-3],".pl")) {
				call strcpy (Memc[inobjmask[1]],
				    Memc[inobjmask[2]], k-3)
				call strcat (Memc[imtype], Memc[inobjmask[2]],
				    SZ_FNAME)
			    } else if (!(streq(Memc[inobjmask[1]+k-5],
			        Memc[imtype]) ||
				streq(Memc[inobjmask[1]+k-4],".fit") ||
				(Memc[inobjmask[1]+k-4]=='.' &&
				 Memc[inobjmask[1]+k-1]=='f')))
				call strcat (Memc[imtype], Memc[inobjmask[2]],
				    SZ_FNAME)
			    call strcat (Memc[str], Memc[inobjmask[2]],
			        SZ_FNAME)
			}
			if (Memc[outobjmask[1]]!=EOS &&
			    Memc[outobjmask[1]]!='!' &&
			    strldxs ("[", Memc[outobjmask[1]]) == 0) {
			    k = strlen (Memc[outobjmask[1]])
			    if (streq(Memc[outobjmask[1]+k-3],".pl")) {
				call strcpy (Memc[outobjmask[1]],
				    Memc[outobjmask[2]], k-3)
				call strcat (Memc[imtype], Memc[outobjmask[2]],
				    SZ_FNAME)
			    } else if (!(streq(Memc[outobjmask[1]+k-5],
			        Memc[imtype]) ||
				streq(Memc[outobjmask[1]+k-4],".fit") ||
				(Memc[outobjmask[1]+k-4]=='.' &&
				 Memc[outobjmask[1]+k-1]=='f')))
				call strcat (Memc[imtype], Memc[outobjmask[2]],
				    SZ_FNAME)
			    call strcat (Memc[str], Memc[outobjmask[2]],
			        SZ_FNAME)
			}
		    }

		    # Resolve reference image reference and append DATASEC.
		    do i = 3, 4 {
			if (Memc[image[i]] == EOS)
			    next
			iferr {
			    im = NULL
			    ptr = immap (Memc[image[i]], READ_ONLY, 0); im = ptr
			    if (i == 3 && Memc[image[2]] == '!') {
				iferr (call imgstr (im, Memc[image[2]+1],
				    Memc[image[4]], SZ_FNAME)) {
				    call eprintf (
					"Can't resolve image reference %s (%s)\n")
					call pargstr (Memc[image[2]+1])
					call pargstr (Memc[image[3]])
				    Memc[image[4]] = EOS
				}
			    }
			    j = strlen (Memc[image[i]])
			    call imgstr (im, "DATASEC", Memc[image[i]+j],
				SZ_FNAME-j)
			    ptr = immap (Memc[image[i]], READ_ONLY, 0); im = ptr
			    iferr (ptr = imgl2r(im,1)) {
				Memc[image[i]+j] = EOS
				call eprintf (
				    "WARNING: Ignoring DATASEC keyword (%s)\n")
				    call pargstr (Memc[image[i]])
			    }
			} then
			    ;
			if (im != NULL)
			    call imunmap (im)
		    }

		    # Add catalog extensions if desired.
		    if (Memc[incat[2]] != EOS && Memc[incat[2]] != '!')
			call catextn (Memc[incat[2]], Memc[incat[2]], SZ_FNAME)
		    if (Memc[outcat[2]] != EOS)
			call catextn (Memc[outcat[2]], Memc[outcat[2]],
			    SZ_FNAME)

		    # Process the image.
		    switch (mode) {
		    case SINGLECAT:
			cat = NULL; om = NULL
			iferr (call ace (par, image[3], bpmask[3], skyname[3],
			    signame[3], expname[3], gainname[3], scalestr,
			    spatial[3], Memc[incat[2]], Memc[outcat[2]], "",
			    Memc[inobjmask[2]], Memc[outobjmask[2]],
			    Memc[outsky[2]], Memc[outsig[2]],
			    Memc[catdef], Memc[acestruct], Memc[logfile],
			    cat, om)) {

			    if (cat != NULL)
				call catclose (cat, YES)
			    if (om != NULL)
				call pm_close (om)
			    call erract (EA_ERROR)
			}
			call catclose (cat, NO)
			call pm_close (om)
		    case MULTICAT:
			if (stp == NULL)
			    stp = stopen ("multicat", 16, 32, 10*SZ_LINE)
			if (Memc[outcat[2]] != EOS)
			    sym = stfind (stp, Memc[outcat[2]])
			else
			    sym = stfind (stp, "dummy")
			if (sym == NULL) {
			    if (catacc (Memc[outcat[2]], 0) == YES) {
				call sprintf (Memc[str], SZ_LINE,
				    "Catalog already exists (%s)")
				    call pargstr (Memc[outcat[2]])
				call error (ACEWARN, Memc[str])
			    }
			    cat = NULL; om = NULL
			    iferr (call ace (par, image[3], bpmask[3],
				skyname[3], signame[3], expname[3],
				gainname[3], scalestr, spatial[3],
				Memc[incat[2]], "", Memc[outcat[2]],
				Memc[inobjmask[2]], Memc[outobjmask[2]],
				Memc[outsky[2]], Memc[outsig[2]], Memc[catdef],
				Memc[acestruct], Memc[logfile], cat, om)) {

				if (cat != NULL)
				    call catclose (cat, YES)
				if (om != NULL)
				    call pm_close (om)
				call erract (EA_ERROR)
			    }
			    if (Memc[outcat[2]] != EOS)
				sym = stenter (stp, Memc[outcat[2]], 3)
			    else
				sym = stenter (stp, "dummy", 3)
			    Memi[sym] = NULL
			    call ace_omulticat (Memc[outcat[2]], Memi[sym],
				    Memc[catdef], Memc[acestruct], nim)
			    Memi[sym+1] = cat
			    Memi[sym+2] = om

			} else {
			    cat = Memi[sym+1]
			    om = Memi[sym+2]
			    iferr (call ace (par, image[3], bpmask[3],
				skyname[3], signame[3], expname[3],
				gainname[3], scalestr, spatial[3],
				Memc[incat[2]], "", Memc[outcat[2]],
				Memc[inobjmask[2]], Memc[outobjmask[2]],
				Memc[outsky[2]], Memc[outsig[2]], Memc[catdef],
				Memc[acestruct], Memc[logfile], cat, om)) {

				if (cat != NULL)
				    call catclose (cat, YES)
				if (om != NULL)
				    call pm_close (om)
				call erract (EA_ERROR)
			    }
			}
			call ace_amulticat (cat, ncat, Memi[sym])

			# To allow registration of the mask we close it.
			if (om != NULL) {
			    call pm_close (om)
			    Memi[sym+2] = NULL
			}
		    }

		} then {
		    switch (errcode()) {
		    case ACEWARN:
			call erract (EA_WARN)
		    default:
			call erract (EA_ERROR)
		    }
		}
	    }
	    call imtclose (list)

	    ncat = ncat + 1
	}

	# Finish up.
	switch (mode) {
	case MULTICAT:
	    if (stp != NULL) {
		for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
		    if (Memi[sym+1] != NULL)
			call catclose (Memi[sym+1], NO)
		    if (Memi[sym+2] != NULL)
			call pm_close (Memi[sym+2])
		    call ace_cmulticat (par, Memi[sym], nim,
		        Memc[stname(stp,sym)], Memc[catdef], Memc[acestruct],
			Memc[logfile])
		}
		call stclose (stp)
	    }
	}

	call sfree (sp)
end


# ACE -- Do all the primary steps for a single input image/catalog.
#
# This will return a catalog pointer whether or not an output catalog is
# written to allow the caller to do other things with the catalog.
# The caller needs to call catclose.

procedure ace (par, image, bpmask, skyname, signame, expname, gainname,
	scalestr, spatial, incat, outcat, extcat, inobjmask, outobjmask,
	outsky, outsig, catdef, acestruct, logfile, cat, om)

pointer	par				#I Parameters
pointer	image[2]			#I Input and reference images
pointer bpmask[2]			#U Input and reference bad pixel masks
pointer skyname[2]			#I Input and reference sky maps
pointer signame[2]			#I Input and reference sigma maps
pointer expname[2]			#I Input and reference exposure maps
pointer	gainname[2]			#I Input and reference gain maps
pointer scalestr[2]			#I Input and reference scales
pointer	spatial[2]			#I Map of spatial scale variations
char	incat[ARB]			#I Input catalog
char	outcat[ARB]			#I Output catalog (produced internally)
char	extcat[ARB]			#I Output catalog (produced externally)
char	inobjmask[ARB]			#U Input object mask
char	outobjmask[ARB]			#U Output object mask
char	outsky[ARB]			#I Output sky image
char	outsig[ARB]			#I Output sigma image
char	catdef[ARB]			#I Catalog definition file
char	logfile[ARB]			#I Log file
char	acestruct[ARB]			#I ACE structure definition file
pointer	cat				#U Catalog pointer
pointer	om				#U Object mask pointer

bool	skyout, sigout, obmout, catout, det, spt, evl, sky1, sig1
bool	updsky,, dosky[2], dosig[2]
int	i, j, logfd, verbose, offset[2,2], err
real	scale[2]
pointer	sp, icat, bpname[2], inobm, outobm, str
pointer	im[2], bpm[2], skymap[2], sigmap[2], expmap[2], gainmap[2], sptlmap[2]
pointer	ptr, omim, siglevmap, siglevels

bool	strne()
real	imgetr()
int	ctor(), imstati(), errget()
int	open(), catacc(), imaccess()
pointer	immap(), im_pmmap(),  yt_pmmap(), pm_open(), map_open(), im_pmmapo()

extern	acefunc()
int	locpr()

errchk	open, immap, im_pmmap, yt_pmmap, pm_newmask, im_pmmapo, imgstr, imaddr
errchk	cnvparse, sky, detect, split, grow, evaluate, map_open
errchk	catdefine, catopen, catgets

begin
	call smark (sp)
	call salloc (icat, SZ_FNAME, TY_CHAR) 
	call salloc (bpname[1], SZ_FNAME, TY_CHAR) 
	call salloc (bpname[2], SZ_FNAME, TY_CHAR) 
	call salloc (inobm, SZ_FNAME, TY_CHAR)
	call salloc (outobm, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    # Initialize for error recovery.
	    err = 0
	    do j = 1, 2 {
		im[j] = NULL; bpm[j] = NULL; skymap[j] = NULL
		sigmap[j] = NULL; expmap[j] = NULL; gainmap[j] = NULL
		sptlmap[j] = NULL
	    }
	    omim = NULL; logfd = NULL

	    # Determine desired outputs and steps.
	    # Haven't handled case where one wants to filter an existing
	    # object mask.

	    skyout = (Memc[skyname[1]]!=EOS || outsky[1]!=EOS)
	    sigout = (Memc[signame[1]]!=EOS || outsig[1]!=EOS)
	    #obmout = (om==NULL && incat[1]==EOS &&
	    #    (outobjmask[1]!=EOS && imaccess(outobjmask,0)==NO))
	    obmout = (om==NULL && (outobjmask[1]!=EOS && imaccess(outobjmask,0)==NO))
	    catout = (outcat[1]!=EOS || extcat[1]!=EOS)

	    det = (PAR_DET(par) != NULL)
	    det = (det && om==NULL && incat[1]==EOS &&
	       (outobjmask[1]==EOS || imaccess(outobjmask,0)==NO))
	    det = (det && (skyout || obmout || catout))

	    spt = (PAR_SPT(par) != NULL)
	    spt = (spt && det && (obmout || catout))

	    evl = (PAR_EVL(par) != NULL)
	    evl = (evl && (catout || obmout))
	    if (evl && !catout) {
	        if (PAR_FLT(par) == NULL)
		    evl = false
		else if (FLT_FILTER(PAR_FLT(par)) == EOS)
		    evl = false
	    }

	    sky1 = (skyout || det || evl)
	    sig1 = (sigout || det || evl)

	    # Log and verbose output.
	    if (logfile[1] != EOS) {
		ptr = open (logfile, APPEND, TEXT_FILE)
		logfd = ptr
		call fseti (logfd, F_FLUSHNL, YES)

		call sysid (Memc[str], SZ_LINE)
		call fprintf (logfd, "ACE: %s\n")
		    call pargstr (Memc[str])
	    }
	    verbose = PAR_VERBOSE(par)
	    if (verbose > 0)
		call fseti (STDOUT, F_FLUSHNL, YES)
	    if (verbose > 1) {
		call sysid (Memc[str], SZ_LINE)
		call printf ("ACE: %s\n")
		    call pargstr (Memc[str])
	    }

	    # Open image if needed.
	    if (strne (Memc[image[1]], "NONE")) {
		iferr (ptr = immap (Memc[image[1]], READ_WRITE, 0))
		    ptr = immap (Memc[image[1]], READ_ONLY, 0)
		im[1] = ptr
	    }

	    # Set input catalog.
	    if (incat[1] != EOS && incat[1] == '!') {
	        call imgstr (im[1], incat[2], Memc[icat], SZ_FNAME)
		call catextn (Memc[icat], Memc[icat], SZ_FNAME)
	    } else
	    	call strcpy (incat, Memc[icat], SZ_FNAME)

	    # Set object mask.
	    if (inobjmask[1] != EOS && inobjmask[1] != '!')
		call xt_maskname (inobjmask, "pl", NEW_IMAGE, inobjmask,
		    SZ_FNAME)
	    if (outobjmask[1] != EOS && outobjmask[1] != '!')
		call xt_maskname (outobjmask, "pl", NEW_IMAGE, outobjmask,
		    SZ_FNAME)

	    if (!det && !evl) {
		# Not detecting or evaluating occurs when filtering.
		# This requires at least a catalog and maybe an
		# object mask.
	        if (Memc[icat] != EOS) {
		    # Get catalog.
		    if (cat == NULL) {
			call catopen (cat, Memc[icat], outcat, "", "", NULL, 1)
			if (PAR_FLT(par) == NULL)
			    call catrrecs (cat, "", -1)
			else
			    call catrrecs (cat, FLT_FILTER(PAR_FLT(par)), -1)
		    }

		    # Get object mask.
		    call strcpy (inobjmask, Memc[inobm], SZ_FNAME)
		    if (Memc[inobm] == EOS && im[1] != NULL)
			call strcpy ("!objmask", Memc[inobm], SZ_FNAME)

		    # Check catalog header first for keyword reference.
		    if (cat != NULL && Memc[inobm] == '!') {
		        call strcpy (Memc[inobm], Memc[str], SZ_LINE)
		        ptr = CAT_OHDR(cat)
			if (ptr == NULL)
			    ptr = CAT_IHDR(cat)
			iferr (call imgstr (ptr, Memc[inobm+1], Memc[inobm],
			    SZ_FNAME))
			    call strcpy (Memc[str], Memc[inobm], SZ_FNAME)
		    }

		    # Get object mask and match to image.
		    if (om == NULL && Memc[inobm] != EOS &&
		        imaccess(Memc[inobm],0) == YES) {
			if (im[1] == NULL)
			    ptr = im_pmmap (Memc[inobm], READ_ONLY, im[1])
			else
			    ptr = yt_pmmap (Memc[inobm], im[1], Memc[inobm],
				SZ_FNAME)
			omim = ptr
			if (omim != NULL)
			    om = imstati (omim, IM_PMDES)
		    }
		}
	    } else if (!det) {
		if (Memc[icat] == EOS && cat == NULL) {
		    if (om == NULL && outobjmask[1] == EOS) {
			call imgstr (im[1], "objmask", Memc[str], SZ_FNAME)
			if (Memc[str] == EOS || imaccess(Memc[str],0)==NO) {
			    call sprintf (Memc[str], SZ_LINE,
				"No input catalog/mask for image (%s)")
				call pargstr (Memc[image[1]])
			    call error (1, Memc[str])
			}
		    }
		} else if (cat == NULL) {
		    if (catacc (Memc[icat], 0) != YES) {
			call sprintf (Memc[str], SZ_LINE,
			    "Catalog does not exist (%s)")
			    call pargstr (Memc[icat])
			call error (1, Memc[str])
		    }
		}
		if (outcat[1]!=EOS && strne(Memc[icat],outcat)) {
		    if (catacc (outcat, 0) == YES) {
			call sprintf (Memc[str], SZ_LINE,
			    "Catalog already exists (%s)")
			    call pargstr (outcat)
			call error (ACEWARN, Memc[str])
		    }
		}
		if (Memc[icat] == EOS && cat == NULL) {
		    call catopen (cat, "", "", "", "", locpr(acefunc), 1)
		    call catdefine (cat, NULL, NULL, catdef, acestruct, 1)
		    call im2im (im, CAT_OHDR(cat))
		    call catputs (cat, "image", Memc[image[1]])
		    if (outobjmask[1] != EOS)
			call catputs (cat, "objmask", outobjmask)
		    call catputs (cat, "catalog", outcat)
		    call catputs (cat, "objid", outcat)
		    if (om == NULL) {
			ptr = yt_pmmap (outobjmask, im[1], outobjmask, SZ_FNAME)
			omim = ptr
			om = imstati (omim, IM_PMDES)
		    }
		    call omcat (om, im[1], cat, logfd, verbose)
		    call bndry (om, NULL)
		} else {
		    if (cat == NULL) {
			call catopen (cat, Memc[icat], outcat, catdef,
			    acestruct, locpr(acefunc), 1)
			call catrrecs (cat, "", ID_NUM)
		    }
		    call catputs (cat, "image", Memc[image[1]])
		    if (inobjmask[1] == EOS) {
			call catgets (cat, "objmask", Memc[inobm], SZ_FNAME)
			call strcpy (Memc[inobm], inobjmask, SZ_FNAME)
		    } else if (imaccess(inobjmask,0) == NO)
			call catgets (cat, "objmask", Memc[inobm], SZ_FNAME)
		    else
			call strcpy (inobjmask, Memc[inobm], SZ_FNAME)
		    if (outobjmask[1] == EOS) {
			call catgets (cat, "objmask", Memc[outobm], SZ_FNAME)
			call strcpy (Memc[outobm], outobjmask, SZ_FNAME)
		    } else if (imaccess(outobjmask,0) == NO)
			call catgets (cat, "objmask", Memc[outobm], SZ_FNAME)
		    else
			call strcpy (outobjmask, Memc[outobm], SZ_FNAME)
		    if (om == NULL && Memc[inobm] != EOS) {
			ptr = yt_pmmap (Memc[inobm], im[1], Memc[inobm],
			    SZ_FNAME)
			if (ptr == NULL) {
			    call sprintf (Memc[str], SZ_LINE,
				"Object mask is required (%s)")
				call pargstr (Memc[str])
			    call error (1, Memc[str])
			}
			omim = ptr
			om = imstati (omim, IM_PMDES)
		    } else if (om == NULL && Memc[outobm] != EOS) {
			ptr = yt_pmmap (Memc[outobm], im[1], Memc[outobm],
			    SZ_FNAME)
			if (ptr == NULL) {
			    call sprintf (Memc[str], SZ_LINE,
				"Object mask is required (%s)")
				call pargstr (Memc[str])
			    call error (1, Memc[str])
			}
			omim = ptr
			om = imstati (omim, IM_PMDES)
		    }

		    # Force evaluation of certain quantities.
		    # This is used for evaluating a new image with the input
		    # detections and mask.
		    do i = 1, CAT_NRECS(cat) {
			ptr = Memi[CAT_RECS(cat)+i-1]
			if (ptr != NULL) {
			    OBJ_PEAK(ptr) = INDEFR
			    OBJ_X(ptr) = INDEFR
			}
		    }

		    # Here is where we could add a transformation from the
		    # logical catalog coordinates to the logical image
		    # coordinates using the physical coordinates.
		}
	    } else {
		# Check for existing catalog.  Check catalog definitions.
		if (outcat[1] != EOS) {
		    if (catacc (outcat, 0) == YES) {
			call sprintf (Memc[str], SZ_LINE,
			    "Catalog already exists (%s)")
			    call pargstr (outcat)
			call error (ACEWARN, Memc[str])
		    }
		}
		call catopen (cat, "", "", "", "", locpr(acefunc), 1)
		call catdefine (cat, NULL, NULL, catdef, acestruct, 1)
		call im2im (im, CAT_OHDR(cat))
		call catputs (cat, "image", Memc[image[1]])
		if (outobjmask[1] != EOS)
		    call catputs (cat, "objmask", outobjmask)
		call catputs (cat, "catalog", outcat)
		call catputs (cat, "objid", outcat)

		# Check for existing mask and initialize.
		if (om == NULL && outobjmask[1] != EOS) {
		    if (imaccess (outobjmask, 0) == YES) {
			call sprintf (Memc[str], SZ_LINE,
			    "Object mask already exists (%s)")
			    call pargstr (outobjmask)
			call error (ACEWARN, Memc[str])
		    }
		}
	    }

	    # Open bad pixel mask.
	    if (Memc[bpmask[1]] != EOS && Memc[bpmask[1]] != '!')
		call xt_maskname (Memc[bpmask[1]], "pl", READ_ONLY,
		    Memc[bpmask[1]], SZ_FNAME)
	    if (im[1] != NULL) {
		ptr = yt_pmmap (Memc[bpmask[1]], im[1], Memc[bpname[1]],
		    SZ_FNAME)
		bpm[1] = ptr
	    }

	    # Set reference image.
	    if (Memc[image[2]] != EOS) {

		iferr (ptr = immap (Memc[image[2]], READ_WRITE, 0))
		    ptr = immap (Memc[image[2]], READ_ONLY, 0)
		im[2] = ptr

		# Set offsets.
		call get_offsets (im, 2, PAR_OFFSET(par), offset)
		offset[1,2] = offset[1,2] - offset[1,1]
		offset[2,2] = offset[2,2] - offset[2,1]

		if (Memc[bpmask[2]] != EOS && Memc[bpmask[2]] != '!')
		    call xt_maskname (Memc[bpmask[2]], "pl", READ_ONLY,
			Memc[bpmask[2]], SZ_FNAME)
		ptr = yt_pmmap (Memc[bpmask[2]], im[2], Memc[bpname[2]],
		    SZ_FNAME)
		bpm[2] = ptr

		i = 1
		if (Memc[scalestr[1]] == EOS)
		    scale[1] = 1.
		else if (Memc[scalestr[1]] == '!') {
		    iferr (scale[1] = imgetr (im[1], Memc[scalestr[1]+1]))
			call error (1, "Bad scale for input image")
		} else if (ctor (Memc[scalestr[1]], i, scale[1]) == 0)
		    call error (1, "Bad scale for image")

		i = 1
		if (Memc[scalestr[2]] == EOS)
		    scale[2] = 1.
		else if (Memc[scalestr[2]] == '!') {
		    iferr (scale[2] = imgetr (im[2], Memc[scalestr[2]+1]))
			call error (1, "Bad scale for reference image")
		} else if (ctor (Memc[scalestr[2]], i, scale[2]) == 0)
		    call error (1, "Bad scale for reference image")
	    }

	    # Log images and masks.
	    if (logfd != NULL) {
		if (im[1] != NULL) {
		    call fprintf (logfd, "  Image: %s - %s\n")
			call pargstr (Memc[image[1]])
			call pargstr (IM_TITLE(im[1]))
		    if (bpm[1] != NULL) {
			call fprintf (logfd, "  Bad pixel mask: %s\n")
			    call pargstr (Memc[bpname[1]])
		    }
		    if (scale[1] != 1.) {
			call fprintf (logfd, "  Image scale: %g\n")
			    call pargr (scale[1])
		    }
		}
		if (im[2] != NULL) {
		    call fprintf (logfd, "  Reference image: %s - %s\n")
			call pargstr (Memc[image[2]])
			call pargstr (IM_TITLE(im[2]))
		    if (bpm[2] != NULL) {
			call fprintf (logfd,
			    "  Reference bad pixel mask: %s\n")
			    call pargstr (Memc[bpname[2]])
		    }
		    if (scale[2] != 1.) {
			call fprintf (logfd, "  Reference scale: %g\n")
			    call pargr (scale[2])
		    }
		}
	    }
	    switch (verbose) {
	    case 1:
	        i = 0
		if (catout)
		    i = i + 1
		if (obmout)
		    i = i + 1
		if (skyout)
		    i = i + 1
		if (sigout)
		    i = i + 1
	        call printf ("%s:")
		    call pargstr (Memc[image[1]])
		if (i > 2)
		    call printf ("\n")
		if (catout) {
		    if (outcat[1] != EOS) {
			call printf (" %s")
			    call pargstr (outcat)
		    }
		    if (extcat[1] != EOS) {
			call printf (" %s")
			    call pargstr (extcat)
		    }
		    if (i > 2)
		        call printf ("\n")
		}
		if (obmout) {
		    call printf (" %s")
		        call pargstr (outobjmask)
		    if (i > 2)
		        call printf ("\n")
		}
		if (skyout) {
		    if (Memc[skyname[1]] != EOS) {
		        call printf (" %s")
			    call pargstr (Memc[skyname[1]])
		    }
		    if (outsky[1] != EOS) {
		        call printf (" %s")
			    call pargstr (outsky)
		    }
		    if (i > 2)
		        call printf ("\n")
		}
		if (sigout) {
		    if (Memc[signame[1]] != EOS) {
		        call printf (" %s")
			    call pargstr (Memc[signame[1]])
		    }
		    if (outsig[1] != EOS) {
		        call printf (" %s")
			    call pargstr (outsig)
		    }
		    if (i > 2)
		        call printf ("\n")
		}
		if (i <= 2)
		    call printf ("\n")
	    case 2:
		if (im[1] != NULL) {
		    call printf ("  Image: %s - %s\n")
			call pargstr (Memc[image[1]])
			call pargstr (IM_TITLE(im[1]))
		    if (bpm[1] != NULL) {
			call printf ("  Bad pixel mask: %s\n")
			    call pargstr (Memc[bpname[1]])
		    }
		    if (scale[1] != 1.) {
			call printf ("  Image scale: %g\n")
			    call pargr (scale[1])
		    }
		}
		if (im[2] != NULL) {
		    call printf ("  Reference image: %s - %s\n")
			call pargstr (Memc[image[2]])
			call pargstr (IM_TITLE(im[2]))
		    if (bpm[2] != NULL) {
			call printf (
			    "  Reference bad pixel mask: %s\n")
			    call pargstr (Memc[bpname[2]])
		    }
		    if (scale[2] != 1.) {
			call printf ("  Reference scale: %g\n")
			    call pargr (scale[2])
		    }
		}
	    }

	    # Open optional maps.
	    do j = 1, 2 {
		if (im[j] == NULL)
		    next
		if (Memc[expname[j]] != EOS) {
		    ptr = map_open (Memc[expname[j]], im[j]); expmap[j] = ptr
		}
	    }
	    do j = 1, 2 {
		if (im[j] == NULL)
		    next
		if (Memc[gainname[j]] != EOS) {
		    ptr = map_open (Memc[gainname[j]], im[j]); gainmap[j] = ptr
		}
	    }
	    do j = 1, 1 {
		if (im[j] == NULL)
		    next
		if (Memc[spatial[j]] != EOS) {
		    ptr = map_open (Memc[spatial[j]], im[j]); sptlmap[j] = ptr
		    if (logfd != NULL) {
		        call fprintf (logfd, "  Spatial variation map: %s\n")
			    call pargstr (Memc[spatial[j]])
		    }
		    if (verbose > 1) {
		        call printf ("  Spatial variation map: %s\n")
			    call pargstr (Memc[spatial[j]])
		    }
		}
	    }

	    # Get sky and sky sigma.
	    if (det && PAR_SKY(par) != NULL)
		updsky = (DET_UPDSKY(PAR_DET(par))==YES &&
		    SKY_TYPE(PAR_SKY(par)) != SKY_FIT)
	    else
		updsky = false
	    do j = 1, 2 {
		dosky[j] = false
		dosig[j] = false
		if (im[j] == NULL)
		    next
		if (PAR_SKY(par) == NULL) {
		    if (Memc[skyname[j]] != EOS) {
			ptr = map_open (Memc[skyname[j]], im[j])
			skymap[j] = ptr
		    }
		    if (Memc[signame[j]] != EOS) {
			ptr = map_open (Memc[signame[j]], im[j])
			skymap[j] = ptr
		    }
		} else if (updsky) {
		    if (j == 1 && om != NULL)
			call sky (PAR_SKY(par), im[j], bpm[j], omim, expmap[j],
			    "", "", skymap[j], sigmap[j], sky1, sig1,
			    dosky[j], dosig[j], logfd, verbose)
		    else
			call sky (PAR_SKY(par), im[j], bpm[j], NULL, expmap[j],
			    "", "", skymap[j], sigmap[j], sky1, sig1,
			    dosky[j], dosig[j], logfd, verbose)
		} else {
		    if (j == 1 && om != NULL)
			call sky (PAR_SKY(par), im[j], bpm[j], omim, expmap[j],
			    Memc[skyname[j]], Memc[signame[j]],
			    skymap[j], sigmap[j], sky1, sig1,
			    dosky[j], dosig[j], logfd, verbose)
		    else
			call sky (PAR_SKY(par), im[j], bpm[j], NULL, expmap[j],
			    Memc[skyname[j]], Memc[signame[j]],
			    skymap[j], sigmap[j], sky1, sig1,
			    dosky[j], dosig[j], logfd, verbose)
		}
		if (skymap[j] != NULL)
		    call map_seti (skymap[j], "sample", 5)
		if (sigmap[j] != NULL)
		    call map_seti (sigmap[j], "sample", 5)
	    }

	    # Detect objects.
	    if (det) {
		# Open object mask.
		om = pm_open (NULL)
		call pm_ssize (om, IM_NDIM(im[1]), IM_LEN(im[1],1), 27)

		# Detect with or without splitting.
		if (spt) {
		    siglevmap = pm_open (NULL)
		    call pm_ssize (siglevmap, IM_NDIM(im[1]),
			IM_LEN(im[1],1), 27)
		    call detect (PAR_DET(par), PAR_SKY(par), PAR_SPT(par),
			dosky, dosig, Memc[skyname[1]], Memc[signame[1]],
			im, bpm, skymap, sigmap, expmap, scale, offset[1,2],
			om, siglevmap, siglevels, logfd, verbose, cat)
		    call split (PAR_SPT(par), cat, om, siglevmap,
			Memr[siglevels], logfd, verbose)
		} else {
		    siglevmap = NULL
		    call detect (PAR_DET(par), PAR_SKY(par), NULL,
			dosky, dosig, Memc[skyname[1]], Memc[signame[1]],
			im, bpm, skymap, sigmap, expmap, scale, offset[1,2],
			om, siglevmap, siglevels, logfd, verbose, cat)
		}

		# Grow objects.
		if (PAR_GRW(par) != NULL)
		    call grow (PAR_GRW(par), cat, om, logfd, verbose)

		# Set boundary flags.
		call bndry (om, NULL)

		# Update sky.
		if (updsky) {
		    ifnoerr (ptr = im_pmmapo (om, im[1])) {
			IM_NPHYSDIM(ptr) = IM_NPHYSDIM(im[1])
			call map_close (sigmap)
			call map_close (skymap)
			call sky (PAR_SKY(par), im[1], bpm[1], ptr, expmap,
			    Memc[skyname[1]], Memc[signame[1]],
			    skymap, sigmap, sky1, sig1, dosky, dosig,
			    logfd, verbose)
			call imunmap (ptr)
			# There doesn't appear to be any other way to cancel
			# the changes made to om by im_pmmapo.
			PM_REFIM(om) = NULL
			PM_MAPXY(om) = NO
			if (skymap[1] != NULL)
			    call map_seti (skymap[1], "sample", 5)
			if (sigmap[1] != NULL)
			    call map_seti (sigmap[1], "sample", 5)
		    }
		}
	    }

	    # Evaluate and write out the catalog.
	    if (evl || catout) {
		if ((logfd != NULL || verbose > 1) && PAR_FLT(par) != NULL) {
		    if (FLT_FILTER(PAR_FLT(par)) != EOS) {
			if (logfd != NULL) {
			    call fprintf (logfd, "  Filter: %s\n")
				call pargstr (FLT_FILTER(PAR_FLT(par)))
			}
			if (verbose > 1) {
			    call printf ("  Filter: %s\n")
				call pargstr (FLT_FILTER(PAR_FLT(par)))
			}
		    }
		}

	        if (outcat[1] != EOS) {
		    if (Memc[icat] == EOS) {
			call catopen (cat, "", outcat, catdef, acestruct,
			    locpr(acefunc), 1)
		    }
		    if (im[1] == NULL)
			call im2im (CAT_IHDR(cat), CAT_OHDR(cat))
		    else
			call im2im (im, CAT_OHDR(cat))
		    if (PAR_UPDATE(par) == YES) {
			call catputs (cat, "image", Memc[image[1]])
			if (outobjmask[1] != EOS)
			    call catputs (cat, "objmask", outobjmask)
			call catputs (cat, "catalog", outcat)
			call catputs (cat, "objid", outcat)
		    }

		    # Evaluate objects.
		    if (evl)
			call evaluate (PAR_EVL(par), cat, im[1], om, skymap[1],
			    sigmap[1], gainmap[1], expmap[1], sptlmap[1],
			    logfd, verbose)

		    if (logfd != NULL) {
			call fprintf (logfd, "  Write catalog: catalog = %s\n")
			    call pargstr (outcat)
		    }
		    if (verbose > 1) {
			call printf ("  Write catalog: catalog = %s\n")
			    call pargstr (outcat)
		    }

		    ifnoerr (call catcreate (cat)) {
			if (im[1] == NULL)
			    call catwcs (cat, CAT_IHDR(cat))
			else
			    call catwcs (cat, im)
			if (PAR_FLT(par) == NULL)
			    call catwrecs (cat, "", PAR_NMAXREC(par))
			else
			    call catwrecs (cat, FLT_FILTER(PAR_FLT(par)),
			        PAR_NMAXREC(par))
			if (im[1] != NULL && PAR_UPDATE(par) == YES)
			    call imastr (im, "CATALOG", outcat)
		    } else
		        call erract (EA_WARN)
		} else if (evl && obmout && FLT_FILTER(PAR_FLT(par))!=EOS) {
		    call evaluate (PAR_EVL(par), cat, im[1], om, skymap[1],
			sigmap[1], gainmap[1], expmap[1], sptlmap[1],
			logfd, verbose)
		} else {
		    call evaluate (PAR_EVL(par), cat, im[1], om, skymap[1],
			sigmap[1], gainmap[1], expmap[1], sptlmap[1],
			logfd, verbose)
		    if (PAR_UPDATE(par) == YES && extcat[1] != EOS)
			call imastr (im[1], "CATALOG", extcat)
		}
	    }

	    # Write out the object mask.
	    if (obmout) {
		if (imaccess (outobjmask, 0) == NO) {
		    call omwrite (om, outobjmask, PAR_FLT(par), PAR_OMTYPE(par),
		        im[1], cat, outcat, outcat, PAR_UPDATE(par),
			logfd, verbose)
		}
	    } else if (outobjmask[1] != EOS)
		call omwrite (NULL, outobjmask, NULL, PAR_OMTYPE(par), im[1],
			cat, outcat, outcat, PAR_UPDATE(par), logfd,
			verbose)

	    # Output sky images.
	    call skyimages (PAR_SKY(par), outsky, outsig, im[1], skymap[1],
		sigmap[1], gainmap[1], expmap[1], logfd, verbose)

	    # Update image.
	    if (PAR_UPDATE(par) == YES && PAR_SKY(par) != NULL) {
	        if (SKY_SKB(PAR_SKY(par)) != NULL) {
		    if (!IS_INDEFR(SKB_AVSKY(SKY_SKB(PAR_SKY(par)))))
			call imaddr (im[1], "AVSKY",
			    SKB_AVSKY(SKY_SKB(PAR_SKY(par))))
		    if (!IS_INDEFR(SKB_AVSIG(SKY_SKB(PAR_SKY(par)))))
			call imaddr (im[1], "AVSIG",
			    SKB_AVSIG(SKY_SKB(PAR_SKY(par))))
		}
	    }

	} then
	    err = errget (Memc[str], SZ_LINE)
	    
	if (logfd != NULL)
	    call close (logfd)
	if (siglevmap != NULL) {
	    call pm_close (siglevmap)
	    call mfree (siglevels, TY_REAL)
	}
	if (omim != NULL) {
	    call imseti (omim, IM_PLDES, NULL)
	    call imunmap (omim)
	}

	do j = 1, 2 {
	    if (gainmap[j] != NULL)
		call map_close (gainmap[j])
	    if (expmap[j] != NULL)
		call map_close (expmap[j])
	    if (sigmap[j] != NULL)
		call map_close (sigmap[j])
	    if (skymap[j] != NULL)
		call map_close (skymap[j])
	    if (bpm[j] != NULL)
		call imunmap (bpm[j])
	    if (im[j] != NULL)
		call imunmap (im[j])
	}

        if (err > 0)
	    call error (err, Memc[str])
	call sfree (sp)
end
