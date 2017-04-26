include	<error.h>
include	<imhdr.h>
include	<imio.h>
include	<evvexpr.h>
include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"


# PROCTOOL -- The detector processing tool.
#
# At this highest level we sequence the input list and processing steps
# resulting in calls to process individual mefs or images.

procedure proctool (par, taskname)

pointer	par				#I Parameters
char	taskname[ARB]			#I Parent task name

bool	ckprctype
int	i, j, k, prctypes[6], nblk, err
pointer	prc, in, out, bp, ob, ost, ipi, opi, sym, ord, stps
pointer	sp, entry, order, steps

bool	strne()
int	imtlen(), fntgfn(), errget(), stridxs(), imtgetim(), imaccess()
long	clktime()
pointer	stfind(), stenter(), ost_find(), fntopn()

errchk	proc1, prclog_flush, ost_iopen

data	prctypes/PRC_ZERO,PRC_DARK,PRC_FFLAT,PRC_GFLAT,PRC_SKY,PRC_OBJECT/

begin
	call smark (sp)
	call salloc (entry, SZ_FNAME, TY_CHAR)
	call salloc (order, SZ_FNAME, TY_CHAR)
	call salloc (steps, SZ_FNAME, TY_CHAR)

	# Initialize processing object.
	call prc_alloc (prc, par)

	iferr {
	    # Check image lists.
	    in = ost_find (PAR_OST(par), PRC_INPUT)
	    out = ost_find (PAR_OST(par), PRC_OUTPUT)
	    bp = ost_find (PAR_OST(par), PRC_BPM)
	    ob = ost_find (PAR_OST(par), PRC_OBM)

	    i = imtlen (OST_LIST(in))
	    if (bp != NULL) {
		if (OST_LIST(bp) != NULL) {
		    j = imtlen (OST_LIST(bp))
		    if (i != j) {
			switch (j) {
			case 0, 1:
			    ;
			default:
			    call error (1,
				"Bad pixel mask list doesn't match input list")
			}
		    }
		}
	    }

	    if (ob != NULL) {
		if (OST_LIST(ob) != NULL) {
		    j = imtlen (OST_LIST(ob))
		    if (i != j) {
			switch (j) {
			case 0, 1:
			    ;
			default:
			    call error (1,
				"Object mask list doesn't match input list")
			}
		    }
		}
	    }

	    if (OST_LIST(out) != NULL) {
		j = imtlen (OST_LIST(out))
		if (i != j) {
		    switch (j) {
		    case 0:
			call error (1, "No output specified")
		    case 1:
			k = imtgetim (OST_LIST(out), PRC_STR(prc), PRC_LENSTR)
			if (stridxs ("+", PRC_STR(prc)) == 0 &&
			    strne (PRC_STR(prc), PRC_NOPROC))
			    call error (1,
			   "Output list doesn't match input list (need '+'?)")
		    default:
			call error (1, "Output list doesn't match input list")
		    }
		}
	    }


	    # Initialize.
	    call prclog_open (10*SZ_LINE+OST_LENEXPR)
	    call cnvdate (clktime(0), PRC_STR(prc), PRC_LENSTR)
	    call strcat (" ", PRC_STR(prc), PRC_LENSTR)
	    call strcat (taskname, PRC_STR(prc), PRC_LENSTR)
	    call prclog (PRC_STR(prc), NULL, NO)
	    call prclog_flush (PAR_OLLIST(par), NULL)
	    PRC_LINE(prc) = 1
	    PRC_GNMEAN(prc) = INDEFI

	    # Sort the input list.
	    OST_SRT(in) = SRT_LIST
	    call ost_iopen (prc, in, NULL)
	    PRC_PIS(prc) = OST_PI(in)
	    OST_PI(in) = NULL

	    # Loop through the input images.
	    # Loop by processing type if desired.
	    ckprctype = (stridxs ("P", Memc[PAR_SRTORDER(par)]) > 0)
	    do j = 1, 6 {
	        if (!ckprctype && prctypes[j] != PRC_OBJECT)
		    next
	    	ost = ost_find (PAR_OST(par), prctypes[j])
		if (ost == NULL)
		    next
		
	    iferr {
		# If the steps are defined by header keywords check if they
		# are all the same.  If this is the case then do all images
		# for each set of block of steps.
		if (OST_ORDER(ost,1) == '(') {
		    Memc[order] = EOS
		    do i = 1, Memi[PRC_PIS(prc)] {
			ipi = Memi[PRC_PIS(prc)+i]
			if (ckprctype && PI_PRCTYPE(ipi) != prctypes[j])
			    next
			call pi_map (ipi)
			call prc_exprs (prc, ipi, OST_ORDER(ost,1),
			    Memc[steps], SZ_FNAME)
			call pi_unmap (ipi)
			if (Memc[order] == EOS)
			    call strcpy (Memc[steps], Memc[order], SZ_FNAME)
			else if (strne (Memc[steps], Memc[order])) {
			    call strcpy (OST_ORDER(ost,1),Memc[order],SZ_FNAME)
			    break
			}
		    }
		} else
		    call strcpy (OST_ORDER(ost,1), Memc[order], SZ_FNAME)

		# For a particular processing type loop by block of steps.
		ord = fntopn (Memc[order])
		for (nblk=1; fntgfn(ord,Memc[order],SZ_FNAME)!=EOF; nblk=nblk+1) {

		    # Loop over each image for a particular block of steps.
		    do i = 1, Memi[PRC_PIS(prc)] {
			ipi = Memi[PRC_PIS(prc)+i]
			if (ckprctype && PI_PRCTYPE(ipi) != prctypes[j])
			    next

			opi = PI_OPI(ipi)

			# If the steps are defined by a keyword reference that
			# was different for different images then we
			# loop over all blocks of steps for the individual
			# image.
			if (Memc[order] == '(') {
			    call pi_map (ipi)
			    call prc_exprs (prc, ipi, Memc[order],
				Memc[steps], SZ_FNAME)
			} else
			    call strcpy (Memc[order], Memc[steps], SZ_FNAME)

			stps = fntopn (Memc[steps])
			while (fntgfn (stps, Memc[steps], SZ_FNAME) != EOF) {

			    # Process a particular image for a particular
			    # set of steps.
			    iferr (call proc1(prc, PI_NAME(ipi), PI_NAME(opi),
				Memc[steps], nblk)) {
				PRC_LINE(prc) = 1
				err = errget (PRC_STR(prc), SZ_LINE)
				if (err != 2) {
				    call prclog_clear ()
				    switch (PAR_ERRACT(par)) {
				    case PAR_EAWARN:
					call erract (EA_WARN)
				    default:
					call error (err, PRC_STR(prc))
				    }
				}
			    } else if (imaccess(PI_NAME(opi),0)==YES &&
			        strne (PI_NAME(opi), PI_NAME(ipi)) &&
			    	strne (PI_NAME(opi), PRC_NOPROC) &&
				PAR_OUTTYPE(par) != PAR_OUTMSK &&
				stridxs("S",Memc[steps])==0) {
				# Add output as an input.
				if (PI_EXTN(ipi) == EOS)
				    call strcpy (PI_NAME(ipi), PRC_STR(prc),
				        PRC_LENSTR)
				else {
				    k = stridxs ("[", PI_NAME(ipi)) - 1
				    call strcpy (PI_NAME(ipi), PRC_STR(prc), k)
				    call sprintf (PRC_STR(prc), PRC_LENSTR,
				        "%s[%d]")
					call pargstr (PRC_STR(prc))
					call pargi (PI_EXTI(ipi))
				}

				call sprintf (Memc[entry], SZ_FNAME, "%s %d")
				    call pargstr (PRC_STR(prc))
				    call pargi (PI_LISTTYPE(ipi))
				sym = stfind (PRC_STP(prc), Memc[entry])
				if (sym == NULL)
				    call error (1, "Symbol table error")
				if (ipi == Memi[sym])
				    Memi[sym] = NULL
				if (PI_EXTN(opi) == EOS)
				    call strcpy (PI_NAME(opi), PRC_STR(prc),
				        PRC_LENSTR)
				else {
				    k = stridxs ("[", PI_NAME(opi)) - 1
				    call strcpy (PI_NAME(opi), PRC_STR(prc), k)
				    call sprintf (PRC_STR(prc), PRC_LENSTR,
				        "%s[%d]")
					call pargstr (PRC_STR(prc))
					call pargi (PI_EXTI(opi))
				}
				sym = stenter (PRC_STP(prc), PRC_STR(prc), 1)
				Memi[sym] = ipi
				k = stridxs ("[", PI_NAME(opi)) - 1
				if (k < 0)
				    k = PI_LENSTR
				call strcpy (PI_NAME(opi), PRC_STR(prc), k)
				call sprintf (PI_NAME(opi), PRC_LENSTR,
				    "%s[%s]")
				    call pargstr (PRC_STR(prc))
				    call pargstr (PI_EXTN(opi))
				call strcpy (PI_NAME(opi), PI_NAME(ipi),
				    PI_LENSTR)
				PI_OPI(ipi) = opi
				PI_EXTI(ipi) = PI_EXTI(opi)
				call strcpy (PI_EXTN(opi), PI_EXTN(ipi),
				    PI_LENSTR)
				call strcpy (PI_TSEC(opi), PI_TSEC(ipi),
				    PI_LENSTR)
			    }
			    call prclog_flush (PAR_OLLIST(par), NULL)
			}
			call fntcls (stps)
		    }
		}
		call fntcls (ord)
	    } then {
	        err = errget (PRC_STR(prc), SZ_LINE)
		call prclog_clear ()
		switch (PAR_ERRACT(par)) {
		case PAR_EAWARN:
		    call erract (EA_WARN)
		default:
		    call error (err, PRC_STR(prc))
		}
	    }
	    }

	    call prclog_flush (PAR_OLLIST(par), NULL)
	    call prclog_close ()
	} then {
	    err = errget (PRC_STR(prc), SZ_LINE)
	    switch (PAR_ERRACT(par)) {
	    case PAR_EAWARN:
		call erract (EA_WARN)
	    default:
		call error (err, PRC_STR(prc))
	    }
	}

	call prc_free (prc)
	call sfree (sp)
end


# PROC1 -- Process a single input which may be an MEF file.

procedure proc1 (prc, input, output, steps, nblk)

pointer	prc					#I Processing object
char	input[ARB]				#I Input image
char	output[ARB]				#I Output image
char	steps[ARB]				#I Processing steps
int	nblk					#I Step block


bool	select, new
int	i, j, npi, exti, nextend, nstat, err
real	mean, procmean
pointer	par, in, ost, ipi, mpi, opi, pis, im, ptr
pointer	sp, iroot, iextn, oroot, oextn, image, imsteps, str

bool	streq(), prc_exprb()
int	imaccess(), errget(), stridxs(), imgeti()
real	imgetr()
pointer	immap(), ost_find()
errchk	prc_exprb, immap, setmef, proc, prc_error, ost_find, imgeti, imgetr

begin
	call smark (sp)
	call salloc (iroot, SZ_FNAME, TY_CHAR)
	call salloc (iextn, SZ_FNAME, TY_CHAR)
	call salloc (oroot, SZ_FNAME, TY_CHAR)
	call salloc (oextn, SZ_FNAME, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (imsteps, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    opi = NULL; im = NULL

	    par = PRC_PAR(prc)

	    # Open input image or MEF extensions.
	    call setmef (prc, input, NULL, PRC_INPUT, INDEFD, pis, npi)

	    # Loop through image or MEF extensions.
	    exti = 0
	    in = ost_find (PAR_OST(par), PRC_INPUT)
	    do i = 0, npi-1 {
		ipi = Memi[pis+i]
		call pi_map(ipi)
	        OST_PI(in) = ipi

		# Check selection criteria.
		ost = ost_find (PAR_OST(par), PI_PRCTYPE(ipi))
		if (OST_INTYPE(ost) != EOS)
		    select = prc_exprb (prc, ipi, OST_INTYPE(ost))
		else
		    select = true

		if (!select) {
		    call pi_unmap (ipi)
		    next
		}

		# Set the processing steps.
		call prc_steps (prc, ipi, steps, Memc[imsteps],
		    PI_IMDONE(ipi), SZ_FNAME)
		if (Memc[imsteps] == EOS && (streq (input, output) ||
		    (streq (output, PRC_NOPROC) && nblk > 1) ||
		    PAR_OUTTYPE(par) == PAR_OUTMSK)) {
		    call pi_unmap (ipi)
		    call prc_piunmap (prc)
		    next
		}

		# Apply trim now so output can inherit the trimmed size.
		if (stridxs("T",Memc[imsteps]) > 0 && PI_TRIM(ipi) != YES) {
		    if (streq (input, output) && PAR_TSEC(par) != EOS)
		       call error (1, "Can only apply trim on first pass")
		    call pi_unmap (ipi)
		    PI_TRIM(ipi) = YES
		    call pi_iopen (ipi)
		}

		# Set output name.
		if (!streq (output, PRC_NOPROC)) {
		    new = (!streq (input, output))
		    if (new) {
			# Parse root and extension names.
			j = stridxs ("[", input)
			if (j == 0) {
			    call strcpy (input, Memc[iroot], SZ_FNAME)
			    Memc[iextn] = EOS
			} else {
			    call strcpy (input, Memc[iroot], j-1)
			    call strcpy (input[j], Memc[iextn], SZ_FNAME)
			}
			j = stridxs ("[", output)
			if (j == 0) {
			    call strcpy (output, Memc[oroot], SZ_FNAME)
			    if (PI_EXTN(ipi) != EOS) {
				switch (PAR_OUTTYPE(par)) {
				case PAR_OUTMSK:
				    call strcpy (Memc[iextn], Memc[oextn],
				        SZ_FNAME)
				case PAR_OUTIMG:
				    call sprintf (Memc[oextn], SZ_FNAME,
					"[%s,append,inherit]")
					call pargstr (PI_EXTN(ipi))
				}
			    } else
				Memc[oextn] = EOS
			} else {
			    switch (PAR_OUTTYPE(par)) {
			    case PAR_OUTMSK:
				call strcpy (output, Memc[oroot], j-1)
				call strcpy (output[j], Memc[oextn], SZ_FNAME)
			    case PAR_OUTIMG:
				call strcpy (output, Memc[oroot], j-1)
				call strcpy (output[j], Memc[oextn], SZ_FNAME)
			    }
			}

			# Make output name.
			call sprintf (Memc[image], SZ_FNAME, "%s%s")
			    call pargstr (Memc[oroot])
			    call pargstr (Memc[oextn])

			if (imaccess (Memc[image], 0) == YES)
			    call prc_error (prc, 1,
			        "Output already exists (%s)", Memc[image], "")
		    
			# Make global header if needed.
			if (Memc[iextn] != EOS && Memc[oextn] != EOS) {
			    call sprintf (Memc[str],SZ_LINE,"%s[0]")
				call pargstr (Memc[oroot])
			    if (imaccess (Memc[str], 0) == NO) {
				call sprintf (Memc[str],SZ_LINE,"%s[0]")
				    call pargstr (Memc[iroot])
				ptr = immap (Memc[str], READ_ONLY, 0)
				im = immap (Memc[oroot], NEW_COPY, ptr)
				nextend = 0
				procmean = 0
				call imaddi (im, "NEXTEND", nextend)
				call imunmap (im)
				call imunmap (ptr)
			    } else {
				im = immap (Memc[str], READ_ONLY, 0)
				nextend = imgeti (im, "NEXTEND")
				iferr (procmean = imgetr (im, "PROCMEAN"))
				    procmean = 0
				call imunmap (im)
			    }
			    exti = nextend + 1
			}

			# Map the output.
			ptr = immap (Memc[image], NEW_COPY, PI_IM(ipi))
			im = ptr
			IM_PIXTYPE(im) = TY_REAL
		    } else {
			call strcpy (output, Memc[image], SZ_FNAME)
			ptr = immap (Memc[image], READ_WRITE, 0)
			im = ptr
			exti = PI_EXTI(ipi)
		    }

		    # Allocate output image structure.
		    call pi_alloc (prc, opi, Memc[image], exti, PI_EXTN(ipi),
			"", PRC_OUTPUT, im)
		    im = PI_IM(opi)
		} else
		    PI_FLAG(ipi) = PIFLAG_LIST

		# Set input mask.
		mpi = PI_BPMPI(ipi)
		if (mpi != NULL) {
		    ost = ost_find (PAR_OST(par), PRC_BPM)
		    if (ost != NULL) {
			call pi_iopen (mpi)
			if (PI_IM(mpi) == NULL)
			    mpi = NULL
			OST_PI(ost) = PI_BPMPI(ipi)
		    } else
		        mpi = NULL
		}

		# Process.
		call proc (prc, ipi, mpi, opi, Memc[imsteps], nblk)

		# Set the output header.
		call prclog_flush (PAR_OLLIST(par), im)
		if (PI_IMDONE(ipi) != EOS)
		    call strcat (",", PI_IMDONE(ipi), SZ_FNAME)
		call strcat (Memc[imsteps], PI_IMDONE(ipi), SZ_FNAME)
		if (!streq (output, PRC_NOPROC)) {
		    #if (mpi != NULL)
		    #    call imastr (PI_IM(opi), "BPM", PI_NAME(mpi))
		    call imastr (PI_IM(opi), "PROCDONE", PI_IMDONE(ipi))
		    if (new && PI_NSTAT(opi) > 0) {
			call imaddr (PI_IM(opi), "PROCAVG", PI_MEAN(opi))
			call imaddr (PI_IM(opi), "PROCSIG", PI_SIGMA(opi))
			if (Memc[oextn] == EOS)
			    call imaddr (PI_IM(opi), "PROCMEAN", PI_MEAN(opi))
		    }
		    if (PI_TSEC(ipi) != EOS) {
			iferr (call imdelf (PI_IM(opi), "DATASEC"))
			    ;
			iferr (call imdelf (PI_IM(opi), "TRIMSEC"))
			    ;
			iferr (call imdelf (PI_IM(opi), "BIASSEC"))
			    ;
		    }
		    if (!IS_INDEFR(PI_SKYMODE(ipi))) {
		        PI_SKYMODE(opi) = PI_SKYMODE(ipi)
			call imaddr (PI_IM(opi), "SKYMODE", PI_SKYMODE(opi))
		    }

		    # Update the global header.
		    if (Memc[oextn] != EOS) {
			nstat = PI_NSTAT(opi)
			mean = PI_MEAN(opi)
			call pi_unmap (opi)
			call sprintf (Memc[str],SZ_LINE,"%s[0]")
			    call pargstr (Memc[oroot])
			if (new) {
			    im = immap (Memc[str], READ_WRITE, 0)
			    nextend = nextend + 1
			    if (nstat > 0) {
				procmean = ((nextend-1) * procmean + mean) /
				    nextend
				call imaddr (im, "PROCMEAN", procmean)
				if (IS_INDEFI(PRC_GNMEAN(prc))) {
				    PRC_GNMEAN(prc) = 1
				    PRC_GMEAN(prc) = 0.
				} else
				    PRC_GNMEAN(prc) = PRC_GNMEAN(prc) + 1
				PRC_GMEAN(prc) = ((PRC_GNMEAN(prc)-1) *
				    PRC_GMEAN(prc) + mean) / PRC_GNMEAN(prc)
			    }
			    call imaddi (im, "NEXTEND", nextend)
			    call imunmap (im)
			}
		    }
		}

		# Finish up.
		call pi_unmap (opi)
		call pi_unmap (ipi)
		call pi_free (opi)
		call prc_piunmap (prc)

		# Add to input if needed.
		if (PAR_OUTTYPE(par)==PAR_OUTMSK &&
		    PAR_MASKKEY(par) != EOS) {
		    if (Memc[oextn] != EOS) {
			call sprintf (Memc[image], SZ_FNAME, "%s[%s]")
			    call pargstr (Memc[oroot])
			    call pargstr (PI_EXTN(ipi))
		    }
		    ifnoerr (im = immap (PI_NAME(ipi), READ_WRITE, 0)) {
		        call imastr (im, PAR_MASKKEY(par), Memc[image])
			call imastr (im, "PROCDONE", PI_IMDONE(ipi))
			call imunmap (im)
		    }
		}
	    }
	    call mfree (pis, TY_STRUCT)

	} then {
	    err = errget (Memc[str], SZ_LINE)
	    if (opi != NULL) {
		call pi_unmap (opi)
		call pi_free (opi)
		if (!streq (input, output) && imaccess (output, 0) == YES)
		    i = stridxs ("[", output)
		    if (i > 0) {
		        call strcpy (output, Memc[image], i-1)
			call imdelete (Memc[image])
		    } else
			call imdelete (output)
	    }
	    call prc_piunmap (prc)
	    call mfree (pis, TY_STRUCT)
	    call error (err, Memc[str])
	}

	call sfree (sp)
end


# PROC -- Process a single image.

procedure proc (prc, ipi, mpi, opi, steps, nblk)

pointer	prc				#I Processing object
pointer	ipi				#I Input processing image
pointer	mpi				#I Input mask processing image
pointer	opi				#I Output processing image
char	steps[ARB]			#I Processing steps
int	nblk				#I Step block

int	i, nc, nl
pointer	iop, ost
pointer	sp, str

int	errget(), stridxs()
pointer	stfind(), ost_find()
errchk	procline, zcall3, set_fp

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	PRC_PI(prc) = ipi
	PI_IPI(ipi) = ipi
	if (steps[1] == EOS) {
	    if (PAR_COPY(PRC_PAR(prc)) == NO && PI_FLAG(ipi) != PIFLAG_LIST)
		call error (2, "No steps to perform")
	    ost = ost_find (PAR_OST(PRC_PAR(prc)), PI_PRCTYPE(ipi))
	    call prc_steps (prc, ipi, OST_ORDER(ost,1), Memc[str], OST_STR(ost),
	        OST_LENSTR)
	    if (Memc[str] != EOS)
		call error (2, "No steps to perform")
	}

	# Set input pixel interpolation if needed.
	if (stridxs("X",steps) > 0 && mpi != NULL) {
	    if (PAR_OUTTYPE(PRC_PAR(prc)) == PAR_OUTIMG)
		call set_fp (PI_IM(mpi), PI_FP(ipi))
	    else
	        PI_FP(ipi) = -1
	}

	# Set dimensions.
	nc = IM_LEN(PI_IM(ipi),1)
	nl = IM_LEN(PI_IM(ipi),2)

	# Initialize input image operand.  We need to allocate a line
	# buffer instead of using the IMIO buffer because sky subtraction
	# will read the input image and invalidate the buffer.

	iop = PI_OP(ipi)
	if (iop == NULL) {
	    call calloc (PI_OP(ipi), LEN_OPERAND, TY_STRUCT)
	    iop = PI_OP(ipi)
	}
	O_TYPE(iop) = TY_REAL
	O_LEN(iop) = nc
	O_FLAGS(iop) = 0

	# Error checking of the expression is done only on the first line.
	# Rather than get the potential calibrations first we
	# will let the expression evaluation determine what is needed.
	# Note it would be nice to just get the calibrations when the
	# operand is requested but, since some of the metadata is
	# defined through expressions, this would result in recursion
	# which is not allowed in SPP.

	repeat {
	    ifnoerr (call procline (prc, ipi, mpi, opi, steps, 1))
		break
	    i = errget (Memc[str], SZ_LINE)
	    if (Memc[str] == '$') {
	        ost = stfind (PAR_OST(PRC_PAR(prc)), Memc[str+1])
		if (ost == NULL)
		    call error (i, Memc[str])
		if (OST_OPEN(ost) == NULL)
		    call error (i, Memc[str])
		call zcall3 (OST_OPEN(ost), prc, ost, ipi) 
	    } else
	        call error (i, Memc[str])
	}

	if (opi != NULL) {
	    do i = 2, nl
		call procline (prc, ipi, mpi, opi, steps, i)

	    PI_MEAN(opi) = PI_MEAN(opi) / max(1,PI_NSTAT(opi))
	    PI_SIGMA(opi) = sqrt (max (0., (PI_SIGMA(opi) -
		PI_MEAN(opi) * PI_MEAN(opi) * max(1,PI_NSTAT(opi))) /
		max(1,(PI_NSTAT(opi) - 1))))
	} else
	    call procline (prc, ipi, mpi, opi, steps, 2)

	# Reset line for operand caching.
	PRC_LINE(prc) = 1

	call sfree (sp)
end


# PROCLINE -- Process a line of single image.

procedure procline (prc, ipi, mpi, opi, steps, line)

pointer	prc				#I Processing object
pointer	ipi				#I Input image processing structure
pointer	mpi				#I Mask image processing structure
pointer	opi				#I Output image processing structure
char	steps[ARB]			#I Processing steps
int	line				#I Image line

char	step[1]
int	i, j
real	mean, sigma
pointer	im, ibuf, obuf, ost, iop, o

bool	strne()
int	awvgr(), mwvgr()
#int	aravr(), mravr()
pointer	prc_exprp(), xt_fpr(), imgl2r(), impl2r(), stfind()
errchk	prc_exprs, prc_exprp, malloc, pi_iopen, xt_fpr

data	step/EOS,EOS/

begin
	PRC_LINE(prc) = line
	PI_LINE(ipi) = line
	iop = PI_OP(ipi)

	# Get line of input.
	if (PI_FP(ipi) != NULL && PI_FP(ipi) != -1)
	    O_VALP(iop) = xt_fpr (PI_FP(ipi), PI_IM(ipi), line, NULL)
	else
	    O_VALP(iop) = imgl2r (PI_IM(ipi), line)
	if (line == 1)
	    call ieemapr (NO, NO)

	# Set output buffer.
	if (opi != NULL) {
	    im = PI_IM(opi)
	    obuf = impl2r (PI_IM(opi), line)
	} else {
	    im = NULL
	    call malloc (obuf, IM_LEN(PI_IM(ipi),1), TY_REAL)
	}

	# Loop over the steps which have an expression.
	j = 0
	for (i=1; steps[i]!=EOS; i=i+1) {
	    step[1] = steps[i]
	    ost = stfind (PAR_OST(PRC_PAR(prc)), step)
	    if (ost == NULL)
	        next
	    if (OST_EXPR(ost) == EOS)
	        next
	    j = j + 1

	    if (line == 2) {
		if (j == 1) {
		    if (PAR_LISTIM(PRC_PAR(prc)) == YES) {
			call sprintf (PRC_STR(prc), PRC_LENSTR,
			    "$I = %s[%d][%s][%s][%.1f][%s]")
			    call pargstr (PI_NAME(ipi))
			    switch (PI_PRCTYPE(ipi)) {
			    case PRC_BIAS:
				call pargstr ("bias")
			    case PRC_ZERO:
				call pargstr ("zero")
			    case PRC_DARK:
				call pargstr ("dark")
			    case PRC_FFLAT:
				call pargstr ("fflat")
			    case PRC_GFLAT:
				call pargstr ("gflat")
			    case PRC_SKY:
				call pargstr ("sky")
			    case PRC_OBJECT:
				call pargstr ("object")
			    default:
				call pargstr ("unknown")
			    }
			    call pargstr (PI_IMAGEID(ipi))
			    call pargstr (PI_FILTER(ipi))
			    call pargr (PI_EXPTIME(ipi))
			    call pargstr (PI_IMDONE(ipi))
			call prclog (PRC_STR(prc), NULL, NO)
			if (PI_OPI(ipi) != NULL) {
			    if (strne (PI_NAME(PI_OPI(ipi)), "+LIST+")) {
				call sprintf (PRC_STR(prc), PRC_LENSTR,
				    "$O = %s")
				    call pargstr (PI_NAME(PI_OPI(ipi)))
				call prclog (PRC_STR(prc), NULL, NO)
			    }
			}
		    }
		    if (PI_TSEC(ipi) != EOS) {
			call prclog ("Trim $I", ipi, NO)
			call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s")
			    call pargstr ("trimsec")
			    call pargstr (PI_TSEC(ipi))
			call prclog (PRC_STR(prc), NULL, YES)
		    }
		    if (PI_FP(ipi) != NULL) {
			call prclog ("Fixpix $I", ipi, NO)
			call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s")
			    call pargstr ("$M")
			    call pargstr (PI_NAME(PI_BPMPI(ipi)))
			call prclog (PRC_STR(prc), NULL, YES)
		    }
		}
		call sprintf (PRC_STR(ost), PRC_LENSTR, "%s = %s")
		    call pargstr (OST_NAME(ost))
		    call pargstr (OST_EXPR(ost))
	    	call prclog (PRC_STR(ost), ipi, YES)
		if (strne (OST_EXPR(ost), OST_EXPR1(ost)) &&
		    PAR_OUTTYPE(PRC_PAR(prc)) == PAR_OUTVLST)
		    call prclog (OST_EXPR1(ost), NULL, NO)
	    }

	    # Because the sky initialization step, done on the first line,
	    # may read the the input image we have to be careful about
	    # using the IMIO buffer.
	    if (line == 1) {
	        iferr (call setexpr1 (prc, ipi, OST_EXPR(ost), OST_EXPR1(ost),
		    OST_LENEXPR, 10, NO)) {
		    if (opi == NULL)
			call mfree (obuf, TY_REAL)
		    else
			call aclrr (Memr[obuf], IM_LEN(PI_IM(ipi),1))
		    call erract (EA_ERROR)
		}
	        call malloc (ibuf, O_LEN(iop), TY_REAL)
		call amovr (Memr[O_VALP(iop)], Memr[ibuf], O_LEN(iop))
		O_VALP(iop) = ibuf
		iferr (o = prc_exprp (prc, ipi, OST_EXPR1(ost))) {
		    call mfree (ibuf, TY_REAL)
		    if (opi == NULL)
			call mfree (obuf, TY_REAL)
		    else
			call aclrr (Memr[obuf], IM_LEN(PI_IM(ipi),1))
		    call erract (EA_ERROR)
		}
		call mfree (ibuf, TY_REAL)
	    } else
		o = prc_exprp (prc, ipi, OST_EXPR1(ost))

	    if (O_LEN(o) == 0) {
		switch (O_TYPE(iop)) {
		case TY_REAL:
		    switch (O_TYPE(o)) {
		    case TY_SHORT:
		        call amovkr (real(O_VALS(o)), Memr[obuf], O_LEN(iop))
		    case TY_INT:
		        call amovkr (real(O_VALI(o)), Memr[obuf], O_LEN(iop))
		    case TY_REAL:
		        call amovkr (O_VALR(o), Memr[obuf], O_LEN(iop))
		    case TY_DOUBLE:
		        call amovkr (real(O_VALD(o)), Memr[obuf], O_LEN(iop))
		    default:
			call error (1, "Expression type mismatch")
		    }
		default:
		    call error (1, "Expression type mismatch")
		}
	    } else {
		if (O_LEN(o) != O_LEN(iop))
		    call error (1, "Image length mismatch")
		switch (O_TYPE(iop)) {
		case TY_REAL:
		    switch (O_TYPE(o)) {
		    case TY_SHORT:
			call achtsr (Mems[O_VALP(o)], Memr[obuf], O_LEN(iop))
		    case TY_INT:
			call achtir (Memi[O_VALP(o)], Memr[obuf], O_LEN(iop))
		    case TY_REAL:
			call amovr (Memr[O_VALP(o)], Memr[obuf], O_LEN(iop))
		    case TY_DOUBLE:
			call achtdr (Memd[O_VALP(o)], Memr[obuf], O_LEN(iop))
		    default:
			call error (1, "Expression type mismatch")
		    }
		default:
		    call error (1, "Expression type mismatch")
		}
	    }
	    O_VALP(iop) = obuf
	    call evvfree (o)
	}

	# If no expression steps copy the input to the output.
	if (j == 0 && PI_IM(ipi) != im) {
	    if (line == 1) {
		if (PAR_LISTIM(PRC_PAR(prc)) == YES) {
		    call sprintf (PRC_STR(prc), PRC_LENSTR,
			"%s[%d][%s][%s][%.1f][%s]")
			call pargstr (PI_NAME(ipi))
			switch (PI_PRCTYPE(ipi)) {
			case PRC_BIAS:
			    call pargstr ("bias")
			case PRC_ZERO:
			    call pargstr ("zero")
			case PRC_DARK:
			    call pargstr ("dark")
			case PRC_FFLAT:
			    call pargstr ("fflat")
			case PRC_GFLAT:
			    call pargstr ("gflat")
			case PRC_SKY:
			    call pargstr ("sky")
			case PRC_OBJECT:
			    call pargstr ("object")
			default:
			    call pargstr ("unknown")
			}
			call pargstr (PI_IMAGEID(ipi))
			call pargstr (PI_FILTER(ipi))
			call pargr (PI_EXPTIME(ipi))
			call pargstr (PI_IMDONE(ipi))
		    call prclog (PRC_STR(prc), NULL, NO)
		}
		if (PI_FP(ipi) != NULL && PI_TSEC(ipi) != EOS) {
		    call prclog ("Trim $I", ipi, NO)
		    call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s")
			call pargstr ("trimsec")
			call pargstr (PI_TSEC(ipi))
		    call prclog (PRC_STR(prc), NULL, YES)
		    call prclog ("Fixpix $I", ipi, NO)
		    call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s")
			call pargstr ("$M")
			call pargstr (PI_NAME(PI_BPMPI(ipi)))
		    call prclog (PRC_STR(prc), NULL, YES)
		} else if (PI_TSEC(ipi) != EOS) {
		    call prclog ("Trim $I", ipi, NO)
		    call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s")
			call pargstr ("trimsec")
			call pargstr (PI_TSEC(ipi))
		    call prclog (PRC_STR(prc), NULL, YES)
		} else if (PI_FP(ipi) != NULL) {
		    call prclog ("Fixpix $I", ipi, NO)
		    call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s")
			call pargstr ("$M")
			call pargstr (PI_NAME(PI_BPMPI(ipi)))
		    call prclog (PRC_STR(prc), NULL, YES)
		} else if (PAR_COPY(PRC_PAR(prc)) == YES)
		    call prclog ("Copy $I", ipi, NO)
	    }
	    call amovr (Memr[O_VALP(iop)], Memr[obuf], O_LEN(iop))
	}

	# Update statistics.
	if (opi != NULL) {
	    if (PI_PRCTYPE(ipi) == PRC_FFLAT || PI_PRCTYPE(ipi) == PRC_GFLAT) {
		if (mpi != NULL) {
		    call pi_igline (mpi, line)
		    i = mwvgr (Memr[obuf], Mems[PI_DATA(mpi)], O_LEN(iop),
			mean, sigma, 0., 0.)
		    #i = mravr (Memr[obuf], Mems[PI_DATA(mpi)], O_LEN(iop),
		    #    mean, sigma, 3.)
		    ##i = mravr (Memr[obuf], Mems[PI_DATA(PI_BPMPI(ipi))],
		    ##	O_LEN(iop), mean, sigma, 3.)
		} else
		    #i = aravr (Memr[obuf], O_LEN(iop), mean, sigma, 3.)
		    i = awvgr (Memr[obuf], O_LEN(iop), mean, sigma, 0., 0.)
		if (i > 0) {
		    PI_MEAN(opi) = PI_MEAN(opi) + mean * i
		    PI_SIGMA(opi) = PI_SIGMA(opi) +
		        sigma*sigma*(i-1)+mean*mean*i
		    PI_NSTAT(opi) = PI_NSTAT(opi) + i
		}
	    }
	} else
	    call mfree (obuf, TY_REAL)
end
