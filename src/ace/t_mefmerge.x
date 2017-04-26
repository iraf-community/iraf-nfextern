include	<error.h>
include	<acecat.h>


# T_MEFMERGE -- Merge mosaic catalogs from the same CCD.
#
# This is a version of ACECOPY that updates the CRMIN/CRMAX keywords.

procedure t_mefmerge ()

int	inlist			# List of input catalogs
int	outlist			# List of output catalogs
pointer	catdef			# Catalog definitions
pointer	filt			# Catalog filter
bool	append			# Append to existing catalog?
bool	verbose			# Verbose?

int	i, j, k, nrecs
real	x1, x2
pointer	cat, recs, rec, ptr
pointer	ihdr, ohdr, imw, omw, ict, oct
pointer	sp, input, output, str

bool	clgetb()
int	imtopenp(), imtlen(), imtgetim(), nowhite(), catacc()
real	imgetr(), mw_c1tranr()
pointer	mw_openim(), mw_sctran()
errchk	catopen(), mw_openim()

begin
	call smark (sp)
	call salloc (input, SZ_FNAME, TY_CHAR)
	call salloc (output, SZ_FNAME, TY_CHAR)
	call salloc (catdef, SZ_FNAME, TY_CHAR)
	call salloc (filt, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get task parameters.
	inlist = imtopenp ("input")
	outlist = imtopenp ("output")
	call clgstr ("catdef", Memc[catdef], SZ_LINE)
	call clgstr ("filter", Memc[filt], SZ_LINE)
	append = clgetb ("append")
	verbose = clgetb ("verbose")

	i = nowhite (Memc[catdef], Memc[catdef], SZ_LINE)

	# Check lists.
	i = imtlen (inlist)
	j = imtlen (outlist)
	if (j != i) {
	    if (j != 1)
		call error (1, "Input and output lists don't match")
	    else if (!append)
		call error (1, "Append must be set for this operation")
	}

	# Copy catalogs.
	while (imtgetim (inlist, Memc[input], SZ_FNAME) != EOF) {
	    if (imtgetim (outlist, Memc[str], SZ_LINE) != EOF) {
	        call strcpy (Memc[str], Memc[output], SZ_FNAME)
		k = 0
	    }
	    k = k + 1

	    iferr {
		cat = NULL; rec = NULL

		# Check if for output if not appending.
		if (!append && catacc (Memc[output]) == YES) {
		    call sprintf (Memc[str], SZ_LINE,
		        "Output catalog exists (%s)")
			call pargstr (Memc[output])
		    call error (1, Memc[output])
		}

		# Open the catalogs.
		ptr = NULL
		call catopen (ptr, Memc[input], Memc[output], Memc[catdef],
		    "", NULL, 1)
		cat = ptr

		if (verbose) {
		    call printf ("%s -> %s\n")
			call pargstr (Memc[input])
			call pargstr (Memc[output])
		    call flush (STDOUT)
		}

		# Copy the entries.
		call catrrecs (cat, Memc[filt], -1)
		recs = CAT_RECS(cat)
		nrecs = CAT_NRECS(cat)
		call catgeti (cat, "orows", j)
		do i = 0, nrecs-1 {
		    rec = Memi[recs+i]
		    j = j + 1
		    call catwrec (cat, rec, j)
		}

		# Update the CRMIN/CRMAX keywords.
		ihdr = CAT_IHDR(cat)
		ohdr = CAT_OHDR(cat)
		imw = mw_openim (CAT_IHDR(cat))
		omw = mw_openim (CAT_OHDR(cat))
		ict = mw_sctran (imw, "logical", "physical", 1)
		#oct = mw_sctran (omw, "physical", "logical", 1)
		oct = mw_sctran (omw, "physical", "physical", 1)
		x1 = mw_c1tranr (oct, mw_c1tranr (ict, imgetr(ihdr,"crmin1")))
		x2 = mw_c1tranr (oct, mw_c1tranr (ict, imgetr(ihdr,"crmax1")))
		call imputr (ohdr, "crmin1", min(imgetr(ohdr,"crmin1"), x1, x2))
		call imputr (ohdr, "crmax1", max(imgetr(ohdr,"crmax1"), x1, x2))
		call mw_ctfree (oct)
		call mw_ctfree (ict)
		ict = mw_sctran (imw, "logical", "physical", 2)
		oct = mw_sctran (imw, "physical", "logical", 2)
		x1 = mw_c1tranr (oct, mw_c1tranr (ict, imgetr(ihdr,"crmin2")))
		x2 = mw_c1tranr (oct, mw_c1tranr (ict, imgetr(ihdr,"crmax2")))
		call imputr (ohdr, "crmin2", min(imgetr(ohdr,"crmin2"), x1, x2))
		call imputr (ohdr, "crmax2", max(imgetr(ohdr,"crmax2"), x1, x2))
		call mw_close (omw)
		call mw_close (imw)

	    } then
	        call erract (EA_WARN)

	    if (cat != NULL)
		call catclose (cat, NO)
	}

	call imtclose (outlist)
	call imtclose (inlist)
	call sfree (sp)
end
