include	<error.h>
include	<acecat.h>
include	<acecat1.h>


# T_ACECOPY -- Copy catalogs.
#
# This task does more than just copy catalogs.  It allows changing formats
# and filtering.

procedure t_acecopy ()

pointer	inlist			# List of input catalogs
pointer	outlist			# List of output catalogs
pointer	catdef			# Catalog definitions
pointer	filt			# Catalog filter
bool	verbose			# Verbose?

int	i
pointer	inlist1, outlist1, icat, ocat, recs, ptr
pointer	sp, input, output, str

bool	clgetb()
int	afn_cl(), afn_opn(),  afn_opno(), afn_len(), afn_gfn()
int	xt_extns(), catacc()
errchk	afn_cl, afn_opn, afn_opno, xt_extns, catopen, catcreate

begin
	call smark (sp)
	call salloc (input, SZ_FNAME, TY_CHAR)
	call salloc (output, SZ_FNAME, TY_CHAR)
	call salloc (catdef, SZ_FNAME, TY_CHAR)
	call salloc (filt, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get task parameters.
	inlist = afn_cl ("input", "catalog", NULL)
	outlist = afn_cl ("output", "catalog", inlist)
	call clgstr ("catdef", Memc[catdef], SZ_LINE)
	call clgstr ("filter", Memc[filt], SZ_LINE)
	verbose = clgetb ("verbose")

	# Check lists.
	if (afn_len(outlist) != afn_len(inlist))
	    call error (1, "Input and output lists don't match")

	# Copy catalogs.
	while (afn_gfn (inlist, Memc[input], SZ_FNAME) != EOF) {
	    i = afn_gfn (outlist, Memc[output], SZ_FNAME)

	    iferr {
		# Expand MEF catalogs.
		ptr = xt_extns (Memc[input], "", "", "", "",
		    NO, YES, NO, NO, "", NO, i)
		inlist1 = afn_opno (ptr, "catalog")
		outlist1 = afn_opn (Memc[output], "catalog", inlist1)

		while (afn_gfn (inlist1, Memc[input], SZ_FNAME) != EOF) {
		    i = afn_gfn (outlist1, Memc[output], SZ_FNAME)

		    iferr {
			# Check for existing output.
			if (catacc (Memc[output]) == YES) {
			    call sprintf (Memc[str], SZ_LINE,
				"Output catalog exists (%s)")
				call pargstr (Memc[output])
			    call error (1, Memc[str])
			}
			    
			# Open the catalogs.
			ptr = NULL
			call catopen (ptr, Memc[input], "", "", "", NULL, 1)
			icat = ptr

			ptr = NULL
			call catopen (ptr, "", Memc[output], Memc[catdef],
			    "", CAT_INTBL(icat), 1)
			ocat = ptr

			# Output operation.
			if (verbose) {
			    call printf ("%s -> %s\n")
				call pargstr (Memc[input])
				call pargstr (Memc[output])
			    call flush (STDOUT)
			}

			# Create the output catalog.
			call catcreate (ocat)

			# Copy the catalog header.
			call im2im (CAT_IHDR(icat), CAT_OHDR(ocat))

			# Copy the entries.
			call catrrecs (icat, Memc[filt], -1)
			recs = CAT_RECS(icat)
			do i = 1, CAT_NRECS(icat)
			    call catwrec (ocat, Memi[recs+i-1], i)
			CAT_NRECS(ocat) = CAT_NRECS(icat)

			# Finish up.
			call catclose (icat, NO)
			call catclose (ocat, NO)
		    } then
			call erract (EA_WARN)
		}

		call afn_cls (outlist1)
		call afn_cls (inlist1)

	    } then
	        call erract (EA_WARN)

	}

	call afn_cls (outlist)
	call afn_cls (inlist)
	call sfree (sp)
end
