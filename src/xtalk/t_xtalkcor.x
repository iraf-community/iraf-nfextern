include	<error.h>
include	<imhdr.h>
include	<imset.h>
include	<time.h>

define	INSTRUME	"|DECam|"
define	DECAM		1


# XTALKCOR -- Apply a crosstalk correction.
# The output may be the crosstalk corrected data, masks flagging affected
# data or both.  The input is a list of input MEF exposures and a list
# of crosstalk coefficient files.

procedure t_xtalkcor ()

int	inlist			# List of input exposures
int	outlist			# List of output exposures
int	bpmlist			# List of bad pixel masks
pointer	section			# Section value or keyword
int	xtfiles			# List of crosstalk files
bool	split			# Split input?
real	bpmthresh		# BPM threshold
int	pixeltype		# Output pixel type
bool	noproc			# List operations only?

pointer	fextn			# File extension
int	verbose			# Verbose output?
int	logfd			# Logfile
int	bufsize			# I/O buffer size in Mb

int	i, j, k, instrume, nstps, nimages, pixtypes[7], ierr
pointer	stps, stp, sym, ins, outs, bpms
pointer	sp, infile, infile1, outfile, bpmfile, xtfile, xtfile1
pointer	pat, tempfile, str, err, p

bool	clgetb(), streq()
int	clpopnu(), clplen(), clgfil()
int	imtopenp(), imtlen(), imtgetim()
int	btoi(), open(), strdic(), strmatch(), access(), imaccess(), ctowrd()
int	errget(), strlen(), nowhite()
real	clgetr()
pointer	sthead(), stnext(), stname(), immap(), ctimmap()

errchk	fcopy, open, immap, imdelete, imrename
errchk	ctcopy, ctread, ctimmap, ctalk

data	pixtypes /0, TY_USHORT, TY_SHORT, TY_INT, TY_LONG, TY_REAL, TY_DOUBLE/


real	imgetr()

begin
	call smark (sp)
	call salloc (infile, SZ_FNAME, TY_CHAR)
	call salloc (infile1, SZ_FNAME, TY_CHAR)
	call salloc (outfile, SZ_FNAME, TY_CHAR)
	call salloc (bpmfile, SZ_FNAME, TY_CHAR)
	call salloc (section, SZ_FNAME, TY_CHAR)
	call salloc (xtfile, SZ_FNAME, TY_CHAR)
	call salloc (xtfile1, SZ_FNAME, TY_CHAR)
	call salloc (fextn, SZ_FNAME, TY_CHAR)
	call salloc (pat, SZ_FNAME, TY_CHAR)
	call salloc (tempfile, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (err, SZ_LINE, TY_CHAR)

	# Get the task parameters.
	inlist = imtopenp ("input")
	outlist = imtopenp ("output")
	bpmlist = imtopenp ("bpmasks")
	call clgstr ("section", Memc[section], SZ_FNAME)
	xtfiles = clpopnu ("xtalkfiles")
	split = clgetb ("split")
	bpmthresh = clgetr ("bpmthreshold")
	call clgstr ("fextn", Memc[fextn+1], SZ_FNAME)
	noproc = clgetb ("noproc")

	#call clgstr ("pixeltype", Memc[str], SZ_FNAME)
	call strcpy ("real", Memc[str], SZ_FNAME)
	call clgstr ("logfile", Memc[infile], SZ_FNAME)
	verbose = btoi (clgetb ("verbose"))
	#bufsize = max (1024., 1E6 * clgetr ("im_bufsize"))
	bufsize = 1E6 * 0.065536

	# Open logfile if requested.
	logfd = NULL
	if (nowhite (Memc[infile], Memc[infile], SZ_FNAME) != 0)
	    logfd = open (Memc[infile], APPEND, TEXT_FILE)

	# Check requested output pixel type.
	i = 1
	if (ctowrd (Memc[str], i, Memc[pat], SZ_FNAME) == 0)
	    call strcpy ("real", Memc[pat], SZ_FNAME)
	pixeltype = pixtypes[1+strdic (Memc[pat], Memc[str], SZ_LINE,
	    "|ushort|short|integer|long|real|double|"))
	if (pixeltype == 0) {
	    call sprintf (Memc[str], SZ_LINE,
		"xtalkcor: Unknown pixel type (%s)")
		call pargstr (Memc[pat])
	    call error (2, Memc[str])
	}

	# Set extension pattern.
	Memc[fextn] = '.'
	call sprintf (Memc[pat], SZ_FNAME, "%s$")
	    call pargstr (Memc[fextn])

	# Check the input lists match up.
	# If splitting and the output list is longer than the input then
	# the output list is assumed to contain all the output files.

	i = imtlen (inlist)
	j = imtlen (outlist)

	if (j > 0 && j != i)
	    call error (2, "xtalkcor: input and output lists don't match")
	j = imtlen (bpmlist)
	if (j > 0 && j != i)
	    call error (2, "xtalkcor: input and bad pixel lists don't match")
	j = clplen (xtfiles)
	if (j == 0)
	    Memc[xtfile] = EOS
#	    call error (2, "xtalkcor: no crosstalk file specified")
	if (j > 1 && j != i)
	    call error (2,
		"xtalkcor: input and crosstalk file lists don't match")
	i = imtlen (outlist)
	j = imtlen (bpmlist)
	if (i == 0 && j == 0)
	    call error (2, "xtalkcor: no output images or masks specified")

	call mktemp ("tmp", Memc[tempfile], SZ_FNAME)

	# Loop through each input file and correct it to the output file.
	while (imtgetim (inlist, Memc[infile], SZ_FNAME) != EOF) {
	    if (imtgetim (outlist, Memc[outfile], SZ_FNAME) == EOF)
		Memc[outfile] = EOS
	    if (imtgetim (bpmlist, Memc[bpmfile], SZ_FNAME) == EOF)
		Memc[bpmfile] = EOS
	    if (clgfil (xtfiles, Memc[xtfile], SZ_FNAME) == EOF)
		;
	    if (strmatch (Memc[infile], Memc[pat]) == 0)
		call strcat (Memc[fextn], Memc[infile], SZ_FNAME)
	    if (Memc[outfile] != EOS) {
		if (strmatch (Memc[outfile], Memc[pat]) == 0)
		    call strcat (Memc[fextn], Memc[outfile], SZ_FNAME)
	    }
	    i = strlen (Memc[infile]) - strlen (Memc[fextn])
	    call strcpy (Memc[infile], Memc[infile1], i)
	    if (split) {
		i = strlen (Memc[outfile]) - strlen (Memc[fextn])
		call strcpy (Memc[outfile], Memc[tempfile], i)
	    }

	    ins = NULL; outs = NULL; bpms = NULL; stps = NULL
	    iferr {
		# Check for existing output.
		if (!split) {
		    if (Memc[outfile]!=EOS && access(Memc[outfile],0,0)==YES) {
			call sprintf (Memc[str], SZ_LINE,
			    "xtalkcor: Output already exists (%s)")
			    call pargstr (Memc[outfile])
			call error (2, Memc[str])
		    }
		}

		# No processing option.
		if (noproc) {
		    if (Memc[xtfile] != EOS) {
			call sprintf (Memc[str], SZ_LINE,
			    "%s\n  [TO BE DONE] Crosstalk file is %s\n")
			    call pargstr (Memc[infile])
			    call pargstr (Memc[xtfile])
			call printf (Memc[str])
		    } else
		        Memc[str] = EOS
		    call error (1, Memc[str])
		}

		# Read the crosstalk file.
		call ctread (Memc[xtfile], Memc[infile], instrume,
		    Memc[xtfile1], stps, nimages, nstps)

		# Loop on the groups.
		do j = nstps, 1, -1 {
		    stp = Memi[stps+j-1]

		    k = 0
		    for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym))
		        k = k + 1
		    if (k < 2)
		        next

		    # Open input and check for missing extensions or a previous
		    # correction.
		    k = 0; ierr = 0
		    call calloc (ins, nimages, TY_POINTER)
		    for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
			i = Memi[sym] - 1
			iferr (p = ctimmap (Memc[infile], instrume,
			    Memc[stname(stp,sym)], Memc[str], SZ_LINE)) {
			    ierr = errget (Memc[err], SZ_LINE)
			    if (k > 0)
			        break
			    next
			}
			k = k + 1
			Memi[ins+i] = p
			if (ierr > 0)
			    break
			call imseti (p, IM_BUFSIZE, bufsize)
			ifnoerr (call imgstr (p, "XTALKCOR", Memc[str],
			    SZ_LINE)) {
			    call sprintf (Memc[str], SZ_LINE,
				"xtalkcor: Correction already done (%s)")
				call pargstr (Memc[infile1])
			    call error (1, Memc[str])
			}
		    }
		    if (ierr > 0 ) {
		        if (k > 0)
			    iferr (call error (ierr, Memc[err]))
			        call erract (EA_WARN)
		        call mfree (ins, TY_POINTER)
		        next
		    }

		    # Setup the output.
		    call calloc (outs, nimages, TY_POINTER)
		    if (Memc[outfile] != EOS) {
			for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
			    k = 0
			    for (p=sthead(stp); p!=NULL; p=stnext(stp,p)) {
			        i = Memi[p]
				if (Memi[sym] == i || Memr[P2R(sym+i)] == 0.)
				    next
				k = k + 1
			    }
			    if (k == 0)
			        next
#			    do i = 1, nimages {
#				if (i != Memi[sym] && Memr[P2R(sym+i)] != 0.)
#				    break
#			    }
#			    if (i > nimages)
#				next
			    i = Memi[sym] - 1
			    call sprintf (Memc[str], SZ_LINE, "%s_%s")
				call pargstr (Memc[tempfile])
				call pargstr (Memc[stname(stp,sym)])
			    if (imaccess (Memc[str], 0) == YES) {
				call sprintf (Memc[tempfile], SZ_LINE,
				    "xtalkcor: Output already exists (%s)")
				    call pargstr (Memc[str])
				call error (2, Memc[tempfile])
			    }
			    p = immap (Memc[str], NEW_COPY, Memi[ins+i])
			    Memi[outs+i] = p
			    call imseti (p, IM_BUFSIZE, bufsize)
			    IM_PIXTYPE(p) = pixeltype
			}
		    }

		    # Setup the bad pixel masks.
		    call calloc (bpms, nimages, TY_POINTER)
		    if (Memc[bpmfile] != EOS) {
			for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
			    do i = 1, nimages {
				if (i != Memi[sym] && Memr[P2R(sym+i)] != 0.)
				    break
			    }
			    if (i > nimages)
				next
			    i = Memi[sym] - 1
			    if (Memi[ins+i] == NULL)
				next
			    call sprintf (Memc[str], SZ_LINE, "%s_%s.pl")
				call pargstr (Memc[bpmfile])
				call pargstr (Memc[stname(stp,sym)])
			    if (imaccess (Memc[str], 0) == YES) {
				call sprintf (Memc[tempfile], SZ_LINE,
				    "xtalkcor: Output already exists (%s)")
				    call pargstr (Memc[str])
				call error (2, Memc[tempfile])
			    }
			    p = immap (Memc[str], NEW_COPY, Memi[ins+i])
			    Memi[bpms+i] = p
			}
		    }

		    # Do the crosstalk corrections.
		    call ctalk (stp, instrume, Memi[ins], Memi[outs],
		        Memi[bpms], nimages, Memc[infile1], Memc[xtfile1],
			Memc[section], bpmthresh, logfd, verbose)

		    # Close images.
		    do i = 1, nimages
			if (Memi[outs+i-1] != NULL)
			    call imunmap (Memi[outs+i-1])
		    call mfree (outs, TY_POINTER)
		    do i = 1, nimages
			if (Memi[bpms+i-1] != NULL)
			    call imunmap (Memi[bpms+i-1])
		    call mfree (bpms, TY_POINTER)
		    do i = 1, nimages
			if (Memi[ins+i-1] != NULL)
			    call imunmap (Memi[ins+i-1])
		    call mfree (ins, TY_POINTER)
		}

		# Join single images to MEF if not splitting.
		if (!split && Memc[outfile] != EOS) {
		    if (streq (Memc[outfile], Memc[infile]))
			call imdelete (Memc[infile])
		    call ctjoin (Memc[infile], instrume, Memc[outfile],
		        Memc[tempfile], bufsize, Memc[xtfile1])

		# Copy the images without a correction if splitting.
		} else if (split && Memc[outfile] != EOS)
		    call ctsplit (Memc[infile], instrume, Memc[outfile],
		        Memc[tempfile], bufsize, Memc[xtfile1])
	    } then {
		ierr = errget (Memc[err], SZ_LINE)
		if (ierr > 1) {
		    do i = 1, nimages {
			if (outs != NULL) {
			    p = Memi[outs+i-1]
			    if (p != NULL) {
				call imstats (p, IM_IMAGENAME,
				    Memc[str], SZ_LINE)
				call imunmap (Memi[outs+i-1])
				iferr (call imdelete (Memc[str]))
				    ;
			    }
			}
			if (bpms != NULL) {
			    p = Memi[bpms+i-1]
			    if (p != NULL) {
				call imstats (p, IM_IMAGENAME,
				    Memc[str], SZ_LINE)
				call imunmap (Memi[bpms+i-1])
				iferr (call imdelete (Memc[str]))
				    ;
			    }
			}
		    }
		    iferr (call error (ierr, Memc[err]))
			call erract (EA_WARN)
		}
	    }

	    # Finish up and clean up after an error.
	    # If the correction was successful the temporary files will
	    # have been joined to create the output so the deletes will
	    # be no-ops.  However if there is an error we want to get rid
	    # of the temporary files.
	    if (outs != NULL) {
		do i = 1, nimages {
		    if (Memi[outs+i-1] != 0)
			call imunmap (Memi[outs+i-1])
		}
		call mfree (outs, TY_POINTER)
	    }
	    if (bpms != NULL) {
		do i = 1, nimages
		    if (Memi[bpms+i-1] != NULL)
			call imunmap (Memi[bpms+i-1])
	    }
	    if (ins != NULL) {
		do i = 1, nimages {
		    if (Memi[ins+i-1] != 0)
			call imunmap (Memi[ins+i-1])
		}
		call mfree (ins, TY_POINTER)
	    }
	    if (stps != NULL) {
		do i = 1, nstps {
		    stp = Memi[stps+i-1]
		    if (stp != NULL) {
			if (!split) {
			    for (sym=sthead(stp); sym!=NULL;
				sym=stnext(stp,sym)) {
				call sprintf (Memc[str], SZ_LINE, "%s_%s")
				    call pargstr (Memc[tempfile])
				    call pargstr (Memc[stname(stp,sym)])
				iferr (call imdelete (Memc[str]))
				    ;
			    }
			}
			call stclose (stp)
		    }
		}
		call mfree (stps, TY_POINTER)
	    }
	}

	# Close the lists.
	if (logfd != NULL)
	    call close (logfd)
	call clpcls (xtfiles)
	call imtclose (outlist)
	call imtclose (inlist)
	call sfree (sp)
end


# CTREAD -- Read the crosstalk file and setup a symbol table.
# The symbol table is keyed by the names in the first column.
# Images are assigned integer IDs and the array of coefficients
# are ordered by the IDs.  The symbol data structure is the integer
# ID for the image followed by an array of real coefficients indexed
# by the image IDs.  The coefficient for the image itself is set to 1
# and any source images which do not affect the target image have
# coefficients of 0.

procedure ctread (xtfile, infile, instrume, xtfile1, stps, nimages, nstps)

char	xtfile[ARB]		#I Crosstalk file reference
char	infile[ARB]		#I Input file
int	instrume		#O Instrument identifier
char	xtfile1[SZ_FNAME]	#O Crosstalk file used
pointer	stps			#O Pointer to array of symbol tables
int	nimages			#O Number of images
int	nstps			#I Number of groups

int	i, j, k, xt, nalloc, symlen
real	coeff1
pointer	im, stp, stp1, sym1, sym2, sym3, extname
pointer	sp, ext1, ext2, extnames, syms

int	strdic(), open(), errget(), fscan(), nscan()
pointer	immap(), stopen(), stfind(), stenter(), sthead(), stnext(), stname()

errchk	immap, open, stopen

begin
	call smark (sp)
	call salloc (ext1, SZ_FNAME, TY_CHAR)
	call salloc (ext2, SZ_FNAME, TY_CHAR)

	# Determine the instrument.
	call sprintf (Memc[ext1], SZ_FNAME, "%s[1]")
	    call pargstr (infile)
	im = immap (Memc[ext1], READ_ONLY, 0)
	ifnoerr (call imgstr (im, "INSTRUME", Memc[ext2], SZ_FNAME))
	    instrume = strdic (Memc[ext2], Memc[ext2], SZ_FNAME, INSTRUME)
	else
	    instrume = 0

	# Identify the crosstalk file.
	if (xtfile[1] != '!')
	    call strcpy (xtfile, xtfile1, SZ_FNAME)
	else {
	    iferr (call imgstr (im, xtfile[2], xtfile1, SZ_FNAME)) {
		xt = errget (Memc[ext2], SZ_FNAME)
		call imunmap (im)
		call error (xt, Memc[ext2])
	    }
	}

	call imunmap (im)

	# Open the crosstalk file.
	if (xtfile1[1] == EOS) {
	    nimages = 0
	    nstps = 0
	    return
	}

	xt = open (xtfile1, READ_ONLY, TEXT_FILE)

	# Read through the crosstalk file and create a symbol table.
	# We don't know in advance how many images might be referenced
	# so we start with up to 32 and then redo the reading if more
	# are found.

	for (nalloc=32;; nalloc=2*nalloc) {
	    symlen = 1 + nalloc
	    stp = stopen (xtfile1, nalloc, symlen, 1024)
	    nimages = 0
	    while (fscan (xt) != EOF) {
		call gargwrd (Memc[ext1], SZ_FNAME)
		call gargwrd (Memc[ext2], SZ_FNAME)
		call gargr (coeff1)
		if (nscan() < 3)
		    next
		if (Memc[ext1] == '#')
		    next

		# Add limit on coefficients.
		#if (abs(coeff1) < 0.0001)
		#    next
		#call eprintf ("%s %s %g\n")
		#call pargstr (Memc[ext1])
		#call pargstr (Memc[ext2])
		#call pargr (coeff1)

		# Don't use aclrr below because of the way we address reals.
		sym1 = stfind (stp, Memc[ext1])
		if (sym1 == NULL) {
		    sym1 = stenter (stp, Memc[ext1], symlen)
		    nimages = nimages + 1
		    Memi[sym1] = nimages
		    do i = 1, 1+nalloc
		        Memr[P2R(sym1+i)] = 0.
		    #call aclrr (Memr[P2R(sym1+1)], nalloc)
		}
		sym2 = stfind (stp, Memc[ext2])
		if (sym2 == NULL) {
		    sym2 = stenter (stp, Memc[ext2], symlen)
		    nimages = nimages + 1
		    Memi[sym2] = nimages
		    do i = 1, 1+nalloc
		        Memr[P2R(sym2+i)] = 0.
		    #call aclrr (Memr[P2R(sym2+1)], nalloc)

		    # We must get the pointer again because adding a new
		    # symbol may reallocate memory and change the pointer. 
		    sym1 = stfind (stp, Memc[ext1])
		}
		if (nimages > nalloc)
		    break
		Memr[P2R(sym1+Memi[sym1])] = 1.
		Memr[P2R(sym1+Memi[sym2])] = coeff1
		Memr[P2R(sym2+Memi[sym2])] = 1.
	    }

	    if (nimages <= nalloc)
		break

	    call stclose (stp)
	    call seek (xt, BOF)
	}
	call close (xt)

	call salloc (extnames, max (1, nimages), TY_POINTER)
	call salloc (syms, max (1, nimages), TY_POINTER)
	for (sym1 = sthead (stp); sym1 != NULL; sym1 = stnext (stp, sym1)) {
	    i = Memi[sym1]
	    Memi[extnames+i-1] = stname(stp,sym1)
	    Memi[syms+i-1] = sym1
	}

	# Dump input.
	if (false) {
	    do i = 1, nimages {
		sym1 = Memi[syms+i-1]
		call eprintf ("%d %s:")
		call pargi (i)
		call pargstr (Memc[Memi[extnames+i-1]])
		do j = 1, nimages {
		    if (j == i || Memr[P2R(sym1+j)] == 0.)
			next
		    call eprintf (" %s")
		    call pargstr (Memc[Memi[extnames+j-1]])
		    call eprintf (" %8.5f")
		    call pargr (Memr[P2R(sym1+j)])
		}
		call eprintf ("\n")
	    }
	}

	# Group dependencies.
	nstps = 0
	call calloc (stps, max (1, nimages), TY_POINTER)
	do i = nimages, 1, -1 {
	    sym1 = Memi[syms+i-1]
	    sym2 = NULL
	    sym3 = NULL
	    extname = Memi[extnames+i-1]
	    do j = 1, nstps {
		stp1 = Memi[stps+j-1]
		sym2 = stfind (stp1, Memc[extname])
		if (sym2 != NULL)
		    break
		do k = 1, nimages {
		    if (Memr[P2R(sym1+k)] == 0.)
			next
		    sym3 = stfind (stp1, Memc[Memi[extnames+k-1]])
		    if (sym3 != NULL)
			break
		}
		if (sym3 != NULL)
		    break
	    }
	    if (sym2 != NULL)
		next

	    if (j > nstps) {
		stp1 = stopen (xtfile1, nimages, symlen, 1024)
		Memi[stps+nstps] = stp1
		nstps = nstps + 1
	    }

	    sym2 = stenter (stp1, Memc[extname], symlen)
	    call amovi (Memi[sym1], Memi[sym2], symlen)
	    repeat {
		for (sym1=sthead(stp1); sym1!=NULL; sym1=stnext(stp1, sym1)) {
		    sym2 = NULL
		    do j = nimages, 1, -1 {
			if (Memr[P2R(sym1+j)] == 0.)
			    next
			extname = Memi[extnames+j-1]
			if (stfind (stp1, Memc[extname]) == NULL) {
			    sym2 = stenter (stp1, Memc[extname], symlen)
			    call amovi (Memi[Memi[syms+j-1]], Memi[sym2],
				symlen)
			}
		    }
		}
	    } until (sym2 == NULL)
	}

	# Eliminate duplicates.
	do i = nimages, 1, -1 {
	    extname = Memi[extnames+i-1]
	    k = 0
	    do j = 1, nstps {
	        stp1 = Memi[stps+j-1]
		if (stp1 == NULL)
		    next
		sym1 = stfind (stp1, Memc[extname])
		if (sym1 == NULL)
		    next
		k = k + 1
		if (k > 1) {
		    call stclose (stp1)
		    Memi[stps+j-1] = NULL
		}
	    }
	    if (k == 0)
	        call error (2, "Duplication elimination failed")
	}
	j = 0
	do i = 1, nstps {
	    stp1 = Memi[stps+i-1]
	    if (stp1 == NULL)
	        next
	    Memi[stps+j] = stp1
	    j = j + 1
	}
	nstps = j

	call stclose (stp)
	call sfree (sp)
end
		

# CTALK -- Do the crosstalk correction from the set of input images to the
# set of output images.  The routine checks the sizes of the images match
# and sets up the relative flips of the readout direction.  The actual work
# is done in the type specific routines to minimize datatype conversions
# through IMIO.

procedure ctalk (stp, instrume, ins, outs, bpms, nimages, infile, xtfile,
	section, bpmthresh, logfd, verbose)

pointer	stp			#I Symbol table
int	instrume		#I Instrument
pointer	ins[nimages]		#I Input image pointers
pointer	outs[nimages]		#I Output image pointers
pointer	bpms[nimages]		#I Output bad pixel masks
int	nimages			#I Number of images
char	infile[ARB]		#I Input file name
char	xtfile[ARB]		#I Crosstalk file name
char	section[ARB]		#I Section value or keyword
real	bpmthresh		#I Threshold for bpm flags
int	logfd			#I Logfile
int	verbose			#I Verbose?

bool	doout, dobpm, doxflip, doyflip
int	i, j, k, nc, nl, pixtype, fd, stropen()
long	clktime()
real	rval, atm, imgetr()
pointer	sp, inbufs, bufs, coeffs, x1, x2, y1, y2, str
pointer	sym1, sym2, sthead(), stnext(), stname()

errchk	ctalks, ctalkr, ccd_section

begin
	call smark (sp)
	call salloc (inbufs, 2*nimages, TY_POINTER)
	call salloc (bufs, nimages, TY_POINTER)
	call salloc (coeffs, nimages, TY_REAL)
	call salloc (x1, nimages, TY_INT)
	call salloc (x2, nimages, TY_INT)
	call salloc (y1, nimages, TY_INT)
	call salloc (y2, nimages, TY_INT)
	call salloc (str, 10000, TY_CHAR)

	# Select processing.
	doout = false
	dobpm = false
	do i = 1, nimages {
	    if (outs[i] != NULL)
		doout = true
	    if (bpms[i] != NULL)
		dobpm = true
	}
	if (!(doout || dobpm))
	    call error (2, "No output defined")

	# Check image dimensions and pixel types.
	nc = INDEFI
	do i = 1, nimages {
	    if (ins[i] == NULL)
		next
	    if (IS_INDEFI(nc)) {
		nc = IM_LEN(ins[i],1)
		nl = IM_LEN(ins[i],2)
		pixtype = IM_PIXTYPE(ins[i])
	    } else {
		if (IM_LEN(ins[i],1) != nc || IM_LEN(ins[i],2) != nl)
		    call error (2, "xtalkcor: Image dimensions don't match")
		if (IM_PIXTYPE(ins[i]) != pixtype)
		    pixtype = TY_REAL
	    }
	}

	# Get data pixel limits.
	call amovki (1, Memi[x1], nimages)
	call amovki (nc, Memi[x2], nimages)
	call amovki (1, Memi[y1], nimages)
	call amovki (nl, Memi[y2], nimages)
	do i = 1, nimages {
	    if (ins[i] == NULL)
	        next
	    if (instrume != DECAM && section[1] != EOS) {
	        if (section[1] == '!') {
		    ifnoerr (call imgstr (ins[i], section[2],
		        Memc[str], SZ_FNAME))
			call ccd_section (Memc[str], Memi[x1+i-1], Memi[x2+i-1],
			    j, Memi[y1+i-1], Memi[y2+i-1], k)
		} else
		    call ccd_section (section, Memi[x1+i-1], Memi[x2+i-1],
			j, Memi[y1+i-1], Memi[y2+i-1], k)
	    }
	    atm = 1.
	    ifnoerr (rval = imgetr (ins[i], "atm1_1"))
	        atm = rval
	    if (atm < 0.) {
	        j = Memi[x1+i-1]
		Memi[x1+i-1] = Memi[x2+i-1]
		Memi[x2+i-1] = j
	    }
	    atm = 1.
	    ifnoerr (rval = imgetr (ins[i], "atm2_2"))
	        atm = rval
	    if (atm < 0.) {
	        j = Memi[y1+i-1]
		Memi[y1+i-1] = Memi[y2+i-1]
		Memi[y2+i-1] = j
	    }
	}

	# If all dependent images have the same flip then don't flip.
	doxflip = false
	doyflip = false
	for (sym1 = sthead (stp); sym1 != NULL; sym1 = stnext (stp, sym1)) {
	    i = Memi[sym1]
	    do j = 1, nimages {
		if (Memr[P2R(sym1+j)] == 0.)
		    next
		if (Memi[x2+i-1]-Memi[x1+i-1] != Memi[x2+j-1]-Memi[x1+j-1])
		    doxflip = true
		if (Memi[y2+i-1]-Memi[y1+i-1] != Memi[y2+j-1]-Memi[y1+j-1])
		    doyflip = true
	    }
	}
	if (!doxflip) {
	    i = min (Memi[x1], Memi[x2])
	    j = max (Memi[x1], Memi[x2])
	    call amovki (i, Memi[x1], nimages)
	    call amovki (j, Memi[x2], nimages)
	}
	if (!doyflip) {
	    i = min (Memi[y1], Memi[y2])
	    j = max (Memi[y1], Memi[y2])
	    call amovki (i, Memi[y1], nimages)
	    call amovki (j, Memi[y2], nimages)
	}

	# Update the output headers.
	for (sym1 = sthead (stp); sym1 != NULL; sym1 = stnext (stp, sym1)) {
	    i = Memi[sym1]
	    call cnvdate (clktime(0), Memc[str], 10000)
	    fd = stropen (Memc[str], 10000, APPEND)
	    k = 0
	    for (sym2 = sthead (stp); sym2 != NULL; sym2 = stnext (stp, sym2)) {
		j = Memi[sym2]
		if (j == i || Memr[P2R(sym1+j)] == 0.)
		    next
		k = k + 1
		if (k == 1)
		    call fprintf (fd, " Crosstalk is ")
		if (k > 1 && Memr[P2R(sym1+j)] > 0.)
		    call fprintf (fd, "+")
		call fprintf (fd, "%.3g*%s")
		    call pargr (Memr[P2R(sym1+j)])
		    call pargstr (Memc[stname(stp,sym2)])
	    }
	    if (k == 0)
		call fprintf (fd, " No crosstalk correction required")
	    call close (fd)
	    if (logfd != NULL) {
		call fprintf (logfd, "%s[%s]: %s\n")
		    call pargstr (infile)
		    call pargstr (Memc[stname(stp,sym1)])
		    call pargstr (Memc[str])
		call flush (logfd)
	    }
	    if (verbose == YES) {
		call printf ("%s[%s]: %s\n")
		    call pargstr (infile)
		    call pargstr (Memc[stname(stp,sym1)])
		    call pargstr (Memc[str])
		call flush (STDOUT)
	    }
	    if (outs[i] != NULL) {
		call imastr (outs[i], "XTALKCOR", Memc[str])
		call imastr (outs[i], "XTALKFILE", xtfile)
		if (bpms[i] != NULL) {
		    call imstats (bpms[i], IM_IMAGENAME, Memc[str], 10000)
		    call imastr (outs[i], "XTALKBPM", Memc[str])
		}
		call xtalkhdr (ins[i], outs[i], instrume,
		    Memc[stname(stp,sym1)])
	    }
	}

	# Do the corrections.
	switch (pixtype) {
	case TY_SHORT:
	    if (doout && dobpm)
		call ctobs (stp, ins, outs, bpms, Memi[x1], Memi[x2],
		    Memi[y1], Memi[y2], Memi[inbufs], Memi[bufs],
		    Memr[coeffs], bpmthresh, nimages, nc, nl)
	    else if (doout)
		call ctalks (stp, ins, outs, Memi[x1], Memi[x2],
		    Memi[y1], Memi[y2], Memi[inbufs], Memi[bufs],
		    Memr[coeffs], nimages, nc, nl)
	    else if (dobpm)
		call ctbpms (stp, ins, bpms, Memi[x1], Memi[x2],
		    Memi[y1], Memi[y2], Memi[inbufs], Memi[bufs],
		    Memr[coeffs], bpmthresh, nimages, nc, nl)
	default:
	    if (doout && dobpm)
		call ctobr (stp, ins, outs, bpms, Memi[x1], Memi[x2],
		    Memi[y1], Memi[y2], Memi[inbufs], Memi[bufs],
		    Memr[coeffs], bpmthresh, nimages, nc, nl)
	    else if (doout)
		call ctalkr (stp, ins, outs, Memi[x1], Memi[x2],
		    Memi[y1], Memi[y2], Memi[inbufs], Memi[bufs],
		    Memr[coeffs], nimages, nc, nl)
	    else if (dobpm)
		call ctbpmr (stp, ins, bpms, Memi[x1], Memi[x2],
		    Memi[y1], Memi[y2], Memi[inbufs], Memi[bufs],
		    Memr[coeffs], bpmthresh, nimages, nc, nl)
	}

	call sfree (sp)
end


# CTIMMAP -- Map an input image.  This is used to encapsulate mapping
# of multiple amp regions in an image; e.g. DECam.


pointer procedure ctimmap (input, instrume, extname, output, szoutput)

char	input[ARB]			#I Input MEF file
int	instrume			#I Input instrument
char	extname[ARB]			#I Input extension name
char	output[szoutput]		#U Output image section
int	szoutput			#I Max size of output name
pointer	im				#U Output image pointer

int	i, ampid
int	x1, x2, x3, y1, y2, y3, x1b, x2b, y1b, y2b
int	strlen()
pointer	sp, extnam, datasec, biassec, ampsec, immap()
errchk	immap, imgstr, ccd_section

begin
	switch (instrume) {
	case DECAM:
	    call smark (sp)
	    call salloc (extnam, SZ_FNAME, TY_CHAR)
	    call salloc (datasec, SZ_FNAME, TY_CHAR)
	    call salloc (biassec, SZ_FNAME, TY_CHAR)
	    call salloc (ampsec, SZ_FNAME, TY_CHAR)

	    i = strlen (extname)
	    call strcpy (extname, Memc[extnam], i-1)
	    ampid = extname[i]
	    # The following is not general but it avoids lots of image maps.
	    switch (extname[1]) {
	    case 'N':
		switch (ampid) {
		case 'A':
		    call strcpy ("[57:1080,1:4096]", Memc[datasec], SZ_FNAME)
		    call strcpy ("[7:56,1:4096]", Memc[biassec], SZ_FNAME)
		    call strcpy ("[1:1024,1:4096]", Memc[ampsec], SZ_FNAME)
		case 'B':
		    call strcpy ("[1081:2104,1:4096]", Memc[datasec], SZ_FNAME)
		    call strcpy ("[2105:2154,1:4096]", Memc[biassec], SZ_FNAME)
		    call strcpy ("[2048:1025,1:4096]", Memc[ampsec], SZ_FNAME)
		}
	    case 'S':
	        switch (ampid) {
		case 'A':
		    call strcpy ("[1081:2104,51:4146]", Memc[datasec], SZ_FNAME)
		    call strcpy ("[2105:2154,51:4146]", Memc[biassec], SZ_FNAME)
		    call strcpy ("[2048:1025,4096:1]", Memc[ampsec], SZ_FNAME)
		case 'B':
		    call strcpy ("[57:1080,51:4146]", Memc[datasec], SZ_FNAME)
		    call strcpy ("[7:56,51:4146]", Memc[biassec], SZ_FNAME)
		    call strcpy ("[1:1024,4096:1]", Memc[ampsec], SZ_FNAME)
		}
	    }

	    call ccd_section (Memc[datasec], x1, x2, x3, y1, y2, y3)
	    call ccd_section (Memc[biassec], x1b, x2b, x3, y1b, y2b, y3)
	    x1 = min (x1, x1b); x2 = max (x2, x2b)
	    y1 = min (y1, y1b); y2 = max (y2, y2b)
	    call sprintf (output, szoutput, "%s[%s][%d:%d,%d:%d]")
		call pargstr (input)
		call pargstr (Memc[extnam])
		call pargi (x1)
		call pargi (x2)
		call pargi (y1)
		call pargi (y2)
	    im = immap (output, READ_ONLY, 0)

	    call ccd_section (Memc[ampsec], x1, x2, x3, y1, y2, y3)
	    if (x1 < x2)
		call imaddr (im, "ATM1_1", 1.)
	    else
		call imaddr (im, "ATM1_1", -1.)
	    if (y1 < y2)
		call imaddr (im, "ATM2_2", 1.)
	    else
		call imaddr (im, "ATM2_2", -1.)

	    call sfree (sp)
	default:
	    call sprintf (output, szoutput, "%s[%s]")
		call pargstr (input)
		call pargstr (extname)
	    im = immap (output, READ_ONLY, 0)
	}

	return (im)
end


# CTJOIN -- Join the separate temporary images into the output MEF file.
# The input file is used to maintain the order of the extensions and to
# supply data when the extension does not have a crosstalk correction.

procedure ctjoin (infile, instrume, outfile, tempfile, bufsize, xtfile)

char	infile[ARB]			#I Input MEF file
int	instrume			#I Input instrument
char	outfile[ARB]			#I Output MEF file
char	tempfile[ARB]			#I Temporary file rootname
int	bufsize				#I I/O buffer size
char	xtfile[ARB]			#I Crosstalk file for header

int	i, j, k, nc, err, errget()
pointer	sp, inname, outname, extname, extnout, str
pointer	in, out, tmp, bufin, bufout, ctimmap(), immap(), imgl2r(), impl2r()
long	clktime()
errchk	ctimmap, immap, imgl2r, impl2r

begin
	call smark (sp)
	call salloc (inname, SZ_FNAME, TY_CHAR)
	call salloc (outname, SZ_FNAME, TY_CHAR)
	call salloc (extname, SZ_FNAME, TY_CHAR)
	call salloc (extnout, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    do i = 0, ARB {
		in = NULL; out = NULL
		call sprintf (Memc[inname], SZ_FNAME, "%s[%d]")
		    call pargstr (infile)
		    call pargi (i)
		iferr (in = immap (Memc[inname], READ_ONLY, 0))
		    break
		if (i == 0) {
		    # Copy the global header.
		    tmp = immap (outfile, NEW_COPY, in)
		    out = tmp
		    call imunmap (out)
		    call imunmap (in)
		    next
		}

		call imgstr (in, "EXTNAME", Memc[extname], SZ_FNAME)
		switch (instrume) {
		case DECAM:
		    if (IM_LEN(in,2) != 4146) {
			call imunmap (in)
		        next
		    }

		    call imunmap (in)
		    do k = 'A', 'B' {
		        switch (k) {
			case 'A':
			    call sprintf (Memc[extnout], SZ_FNAME, "%sA")
				call pargstr (Memc[extname])
				call pargstr (Memc[extnout])
			    call sprintf (Memc[inname], SZ_FNAME, "%s_%s")
				call pargstr (tempfile)
				call pargstr (Memc[extnout])
			    iferr (tmp = immap (Memc[inname], READ_ONLY, 0)) {
				tmp = ctimmap (infile, instrume,
				    Memc[extnout], Memc[inname], SZ_FNAME)
				Memc[inname] = EOS
			    }
			case 'B':
			    call sprintf (Memc[extnout], SZ_FNAME, "%sB")
				call pargstr (Memc[extname])
			    call sprintf (Memc[inname], SZ_FNAME, "%s_%s")
				call pargstr (tempfile)
				call pargstr (Memc[extnout])
			    iferr (tmp = immap (Memc[inname], READ_ONLY, 0)) {
				tmp = ctimmap (infile, instrume,
				    Memc[extnout], Memc[inname], SZ_FNAME)
				Memc[inname] = EOS
			    }
			}
			in = tmp

			# Open the output image.
			call sprintf (Memc[outname], SZ_FNAME,
			    "%s[%s,append,inherit]")
			    call pargstr (outfile)
			    call pargstr (Memc[extnout])
			tmp = immap (Memc[outname], NEW_COPY, in)
			out = tmp

			# Add keywords and fix the header.
			if (xtfile[1] != EOS) {
			    if (Memc[inname] == EOS) {
				call cnvdate (clktime(0), Memc[str], SZ_LINE)
				call strcat (" No crosstalk correction required",
				    Memc[str], SZ_LINE)
				call imastr (out, "XTALKCOR", Memc[str])
				call xtalkhdr (in, out, instrume, Memc[extnout])
			    }
			    call imastr (out, "XTALKFILE", xtfile)
			}

			# Copy data.
			call imseti (in, IM_BUFSIZE, bufsize)
			call imseti (out, IM_BUFSIZE, bufsize)
			nc = IM_LEN(in,1)
			do j = 1, IM_LEN(in,2) {
			    bufin = imgl2r(in,j)
			    bufout = impl2r(out,j)
			    call amovr (Memr[bufin], Memr[bufout], nc)
			}
			call imunmap (out)
			call imunmap (in)
			if (Memc[inname] != EOS)
			    call imdelete (Memc[inname])
		    }

		default:
		    # Check if a crosstalk corrected image exists.
		    call sprintf (Memc[inname], SZ_FNAME, "%s_%s")
			call pargstr (tempfile)
			call pargstr (Memc[extname])
		    iferr (tmp = immap (Memc[inname], READ_ONLY, 0)) {
			tmp = in
		        Memc[inname] = EOS
		    } else
			call imunmap (in)
		    in = tmp

		    # Open output and copy header.
		    call sprintf (Memc[outname], SZ_FNAME,
		        "%s[%s,append,inherit]")
			call pargstr (outfile)
			call pargstr (Memc[extname])
		    tmp = immap (Memc[outname], NEW_COPY, in)
		    out = tmp

		    # Add keywords.
		    if (xtfile[1] != EOS) {
			if (Memc[inname] == EOS) {
			    call cnvdate (clktime(0), Memc[str], SZ_LINE)
			    call strcat (" No crosstalk correction required",
				Memc[str], SZ_LINE)
			    call imastr (out, "XTALKCOR", Memc[str])
			}
			call imastr (out, "XTALKFILE", xtfile)
		    }

		    # Copy data.
		    call imseti (in, IM_BUFSIZE, bufsize)
		    call imseti (out, IM_BUFSIZE, bufsize)
		    nc = IM_LEN(in,1)
		    do j = 1, IM_LEN(in,2) {
			bufin = imgl2r(in,j)
			bufout = impl2r(out,j)
			call amovr (Memr[bufin], Memr[bufout], nc)
		    }
		    call imunmap (out)
		    call imunmap (in)
		    if (Memc[inname] != EOS)
		        call imdelete (Memc[inname])
		}
	    }
	} then {
	    err = errget (Memc[extname], SZ_FNAME)
	    if (out != NULL) {
		call imunmap (out)
		iferr (call imdelete (outfile))
		    ;
	    }
	    if (in != NULL)
		call imunmap (in)
	    call error (err, Memc[extname])
	}

	call sfree (sp)
end


# CTSPLIT -- Split the images which did not require correction.

procedure ctsplit (input, instrume, output, tempfile, bufsize, xtfile)

char	input[ARB]			#I Input MEF file
int	instrume			#I Input instrument
char	output[ARB]			#I Output file root name
char	tempfile[ARB]			#I Temporary file rootname
int	bufsize				#I I/O buffer size
char	xtfile[ARB]			#I Crosstalk file for header

int	i, j, k, nc, err, imaccess(), errget()
pointer	sp, inname, outname, extname, extnout, str
pointer	in, out, tmp, bufin, bufout, ctimmap(), immap(), imgl2r(), impl2r()
real	imgetr()
long	clktime()
errchk	ctimmap, immap, imgl2r, impl2r

begin
call eprintf ("ctsplit (%s)\n")
call pargstr (input)
	call smark (sp)
	call salloc (inname, SZ_FNAME, TY_CHAR)
	call salloc (outname, SZ_FNAME, TY_CHAR)
	call salloc (extname, SZ_FNAME, TY_CHAR)
	call salloc (extnout, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    do i = 0, ARB {
		in = NULL; out = NULL
		call sprintf (Memc[inname], SZ_FNAME, "%s[%d]")
		    call pargstr (input)
		    call pargi (i)
		iferr (in = immap (Memc[inname], READ_ONLY, 0))
		    break
		if (i == 0) {
		    call imunmap (in)
		    next
		}

		call imgstr (in, "EXTNAME", Memc[extname], SZ_FNAME)
	    	switch (instrume) {
		case DECAM:
		    if (IM_LEN(in,2) != 4146) {
			call imunmap (in)
		        next
		    }

		    call imunmap (in)
		    do k = 'A', 'B' {
		        switch (k) {
			case 'A':
			    call sprintf (Memc[extnout], SZ_FNAME, "%sA")
				call pargstr (Memc[extname])
			    call sprintf (Memc[outname], SZ_FNAME, "%s_%s")
				call pargstr (tempfile)
				call pargstr (Memc[extnout])
			case 'B':
			    call sprintf (Memc[extnout], SZ_FNAME, "%sB")
				call pargstr (Memc[extname])
			    call sprintf (Memc[outname], SZ_FNAME, "%s_%s")
				call pargstr (tempfile)
				call pargstr (Memc[extnout])
			}

			# Check if a crosstalk corrected image exists.
			if (imaccess (Memc[outname], 0) == YES)
			    next

call eprintf ("ctimmap (%s, %s)\n")
call pargstr (input)
call pargstr (Memc[extnout])
			# Open the image.
			tmp = ctimmap (input, instrume, Memc[extnout],
			    Memc[inname], SZ_FNAME)
			in = tmp

			# Open the output image.
			iferr (tmp = immap (Memc[outname], NEW_COPY, in)) {
			    call imunmap (in)
			    next
			}
			out = tmp

			# Add keywords.
			if (xtfile[1] != EOS) {
			    call cnvdate (clktime(0), Memc[str], SZ_LINE)
			    call strcat (" No crosstalk correction required",
				Memc[str], SZ_LINE)
			    call imastr (out, "XTALKCOR", Memc[str])
			    call imastr (out, "XTALKFILE", xtfile)
			}

			# Fix the header.
			call xtalkhdr (in, out, instrume, Memc[extnout])

			# Copy data.
			call imseti (in, IM_BUFSIZE, bufsize)
			call imseti (out, IM_BUFSIZE, bufsize)
			nc = IM_LEN(in,1)
			do j = 1, IM_LEN(in,2) {
			    bufin = imgl2r(in,j)
			    bufout = impl2r(out,j)
			    call amovr (Memr[bufin], Memr[bufout], nc)
			}
			call imunmap (out)
			call imunmap (in)
		    }
		
		default:
		    # Check if a crosstalk corrected image exists.
		    call sprintf (Memc[outname], SZ_FNAME, "%s_%s")
			call pargstr (tempfile)
			call pargstr (Memc[extname])
		    if (imaccess (Memc[outname], 0) == YES) {
			call imunmap (in)
			next
		    }

		    # Open the output image.
		    iferr (tmp = immap (Memc[outname], NEW_COPY, in)) {
			call imunmap (in)
			next
		    }
		    out = tmp

		    # Add keywords.
		    if (xtfile[1] != EOS) {
			call cnvdate (clktime(0), Memc[str], SZ_LINE)
			call strcat (" No crosstalk correction required",
			    Memc[str], SZ_LINE)
			call imastr (out, "XTALKCOR", Memc[str])
			call imastr (out, "XTALKFILE", xtfile)
		    }

		    # Fix the header.
		    call imastr (out, "AMPID", Memc[extname])
		    call xtalkhdr (in, out, instrume, Memc[extname])

		    # Copy data.
		    call imseti (in, IM_BUFSIZE, bufsize)
		    call imseti (out, IM_BUFSIZE, bufsize)
		    nc = IM_LEN(in,1)
		    do j = 1, IM_LEN(in,2) {
			bufin = imgl2r(in,j)
			bufout = impl2r(out,j)
			call amovr (Memr[bufin], Memr[bufout], nc)
		    }
		    call imunmap (out)
		    call imunmap (in)
		}
	    }
	} then {
	    err = errget (Memc[extname], SZ_FNAME)
	    if (out != NULL) {
		call imunmap (out)
		iferr (call imdelete (output))
		    ;
	    }
	    if (in != NULL)
		call imunmap (in)
	    call error (err, Memc[extname])
	}

	call sfree (sp)
end


# XTALKHDR -- Update the output header.

procedure xtalkhdr (in, out, instrume, extname)

pointer	in			#I Input image pointer
pointer	out			#I Output image pointer
int	instrume		#I Instrument ID
char	extname[ARB]		#I Extension name

int	ampid, xoffset, yoffset, x1, x2, x3, y1, y2, y3, x1b, x2b, y1b, y2b
int	trim
int	strlen()
real	rval, imgetr()
pointer	sp, str, detsec, ccdsec, ampsec, datasec, trimsec, biassec
pointer	gain, rdnoise, saturate

errchk	ccd_section

begin
	switch (instrume) {
	case DECAM:
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
	    call salloc (detsec, 8, TY_CHAR)
	    call salloc (ccdsec, 8, TY_CHAR)
	    call salloc (ampsec, 8, TY_CHAR)
	    call salloc (datasec, 8, TY_CHAR)
	    call salloc (trimsec, 8, TY_CHAR)
	    call salloc (biassec, 8, TY_CHAR)
	    call salloc (gain, 8, TY_CHAR)
	    call salloc (rdnoise, 8, TY_CHAR)
	    call salloc (saturate, 8, TY_CHAR)

	    ampid = extname[strlen(extname)]
	    switch (ampid) {
	    case 'A':
		call strcpy ("GAINA", Memc[gain], 8)
		call strcpy ("RDNOISEA", Memc[rdnoise], 8)
		call strcpy ("SATURATA", Memc[saturate], 8)
		call strcpy ("DETSECA", Memc[detsec], 8)
		call strcpy ("CCDSECA", Memc[ccdsec], 8)
		call strcpy ("AMPSECA", Memc[ampsec], 8)
		call strcpy ("DATASECA", Memc[datasec], 8)
		call strcpy ("TRIMSECA", Memc[trimsec], 8)
		call strcpy ("BIASSECA", Memc[biassec], 8)
	    case 'B':
		call strcpy ("GAINB", Memc[gain], 8)
		call strcpy ("RDNOISEB", Memc[rdnoise], 8)
		call strcpy ("SATURATB", Memc[saturate], 8)
		call strcpy ("DETSECB", Memc[detsec], 8)
		call strcpy ("CCDSECB", Memc[ccdsec], 8)
		call strcpy ("AMPSECB", Memc[ampsec], 8)
		call strcpy ("DATASECB", Memc[datasec], 8)
		call strcpy ("TRIMSECB", Memc[trimsec], 8)
		call strcpy ("BIASSECB", Memc[biassec], 8)
	    }

	    call imgstr (in, "DETSEC", Memc[str], SZ_FNAME)
	    call ccd_section (Memc[str], x1, x2, x3, y1, y2, y3)
	    rval = x1 - 1; call imaddr (out, "DTV1", rval)
	    rval = y1 - 1; call imaddr (out, "DTV2", rval)
	    call imaddr (out, "DTM1_1", 1.); call imaddr (out, "DTM2_2", 1.)
	    call imgstr (in, Memc[detsec], Memc[str], SZ_FNAME)
	    call imastr (out, "DETSEC", Memc[str])
	    call imgstr (in, Memc[ccdsec], Memc[str], SZ_FNAME)
	    call imastr (out, "CCDSEC", Memc[str])
	    call imgstr (in, Memc[ampsec], Memc[str], SZ_FNAME)
	    call imastr (out, "AMPSEC", Memc[str])
	    call imgstr (in, Memc[datasec], Memc[str], SZ_FNAME)
	    call ccd_section (Memc[str], x1, x2, x3, y1, y2, y3)
	    call imgstr (in, Memc[biassec], Memc[str], SZ_FNAME)
	    call ccd_section (Memc[str], x1b, x2b, x3, y1b, y2b, y3)
	    xoffset = min (x1, x1b) - 1; yoffset = min (y1, y1b) - 1
	    x1 = x1 - xoffset; x2 = x2 - xoffset
	    y1 = y1 - yoffset; y2 = y2 - yoffset
	    call sprintf (Memc[str], SZ_FNAME, "[%d:%d,%d:%d]")
		 call pargi (x1); call pargi (x2)
		 call pargi (y1); call pargi (y2)
	    call imastr (out, "DATASEC", Memc[str])
	    call imgstr (in, Memc[trimsec], Memc[str], SZ_FNAME)
	    call ccd_section (Memc[str], x1, x2, x3, y1, y2, y3)
	    x1 = x1 - xoffset; x2 = x2 - xoffset
	    y1 = y1 - yoffset; y2 = y2 - yoffset
	    trim = 8
	    switch (extname[1]) {
	    case 'N':
		switch (ampid) {
		case 'A':
		    x1 = x1 + trim; y1 = y1 + trim; y2 = y2 - trim
		case 'B':
		    x2 = x2 - trim; y1 = y1 + trim; y2 = y2 - trim
		}
	    case 'S':
		switch (ampid) {
		case 'A':
		    x2 = x2 - trim; y1 = y1 + trim; y2 = y2 - trim
		case 'B':
		    x1 = x1 + trim; y1 = y1 + trim; y2 = y2 - trim
		}
	    }
	    call sprintf (Memc[str], SZ_FNAME, "[%d:%d,%d:%d]")
		 call pargi (x1); call pargi (x2)
		 call pargi (y1); call pargi (y2)
	    call imastr (out, "TRIMSEC", Memc[str])
	    x1 = x1b - xoffset; x2 = x2b - xoffset
	    y1 = y1b - yoffset; y2 = y2b - yoffset
	    call sprintf (Memc[str], SZ_FNAME, "[%d:%d,%d:%d]")
		 call pargi (x1); call pargi (x2)
		 call pargi (y1); call pargi (y2)
	    call imastr (out, "BIASSEC", Memc[str])
	    rval = imgetr (in, Memc[gain])
	    call imaddr (out, "GAIN", rval)
	    rval = imgetr (in, Memc[rdnoise])
	    call imaddr (out, "RDNOISE", rval)
	    rval = imgetr (in, Memc[saturate])
	    call imaddr (out, "SATURATE", rval)
	    rval = imgetr (in, "CRPIX1")
	    rval = rval - xoffset 
	    call imaddr (out, "CRPIX1", rval)
	    rval = imgetr (in, "CRPIX2")
	    rval = rval - yoffset
	    call imaddr (out, "CRPIX2", rval)
	    call imgstr (in, "DETECTOR", Memc[str], SZ_FNAME)
	    call imastr (out, "CCDNAME", Memc[str])

	    call imdelf (out, "DETSECA")
	    call imdelf (out, "CCDSECA")
	    call imdelf (out, "AMPSECA")
	    call imdelf (out, "DATASECA")
	    call imdelf (out, "TRIMSECA")
	    call imdelf (out, "BIASSECA")
	    call imdelf (out, "PRESECA")
	    call imdelf (out, "POSTSECA")
	    call imdelf (out, "GAINA")
	    call imdelf (out, "RDNOISEA")
	    call imdelf (out, "SATURATA")
	    call imdelf (out, "DETSECB")
	    call imdelf (out, "CCDSECB")
	    call imdelf (out, "AMPSECB")
	    call imdelf (out, "DATASECB")
	    call imdelf (out, "TRIMSECB")
	    call imdelf (out, "BIASSECB")
	    call imdelf (out, "PRESECB")
	    call imdelf (out, "POSTSECB")
	    call imdelf (out, "GAINB")
	    call imdelf (out, "RDNOISEB")
	    call imdelf (out, "SATURATB")
	    call imdelf (out, "DETSIZE")
	    iferr (call imdelf (out, "ATM1_1"))
	        ;
	    iferr (call imdelf (out, "ATM2_2"))
	        ;

	    call sfree (sp)
	}
end
