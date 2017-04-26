include	<imhdr.h>
include	<acecat.h>
include	<acecat1.h>

# CATOPEN -- Open a catalog.
# This may be used just to allocate the structure or to actually open
# a catalog file.  It does not read the objects.  Use catrobjs.

procedure catopen (cat, input, output, catdef, structdef, ufunc, nim)

pointer	cat			#U Catalog structure
char	input[ARB]		#I Input catalog name
char	output[ARB]		#I Output catalog name
char	catdef[ARB]		#I Catalog definition file
char	structdef[ARB]		#I Application structure definition file
pointer	ufunc			#I User evaluation function
int	nim			#I Number of images

pointer	tbl, ptr

bool	streq()
int	tbtacc()
pointer	mkimhdr(), catopen1()
errchk	catopen1, catdefine

begin
	if (cat == NULL) {
	    call calloc (cat, CAT_LEN, TY_STRUCT)
	    CAT_IHDR(cat) = mkimhdr (2, 0)
	    CAT_OHDR(cat) = mkimhdr (2, 0)
	    CAT_UFUNC(cat) = ufunc
	    if (input[1] != EOS)
	       call strcpy (input, IM_HDRFILE(CAT_IHDR(cat)), SZ_IMHDRFILE)
	    if (output[1] != EOS)
	       call strcpy (output, IM_HDRFILE(CAT_OHDR(cat)), SZ_IMHDRFILE)
	} else if (ufunc != NULL)
	    CAT_UFUNC(cat) = ufunc

	if (input[1] == EOS && output[1] == EOS)
	    return

	if (streq (input, output)) {		# READ_WRITE
	    call calloc (tbl, TBL_LEN, TY_STRUCT)
	    CAT_INTBL(cat) = tbl
	    CAT_OUTTBL(cat) = tbl
	    call mfree (CAT_OHDR(cat), TY_STRUCT)
	    CAT_OHDR(cat) = CAT_IHDR(cat)

	    ptr = catopen1 (input, READ_WRITE, 0); TBL_TP(tbl) = ptr
	    call catdefine (cat, tbl, READ_ONLY, catdef, structdef, nim)
	    call catrhdr (CAT_INTBL(cat), CAT_IHDR(cat))
	} else if (output[1] == EOS) {		# READ_ONLY
	    call calloc (tbl, TBL_LEN, TY_STRUCT)
	    CAT_INTBL(cat) = tbl
	    CAT_OUTTBL(cat) = NULL
	    call mfree (CAT_OHDR(cat), TY_STRUCT)

	    ptr = catopen1 (input, READ_ONLY, 0); TBL_TP(tbl) = ptr
	    call catdefine (cat, tbl, READ_ONLY, catdef, structdef, nim)
	    call catrhdr (CAT_INTBL(cat), CAT_IHDR(cat))
	} else if (input[1] == EOS) {		# NEW_FILE
	    call calloc (tbl, TBL_LEN, TY_STRUCT)
	    if (structdef[1] == EOS) {
		CAT_INTBL(cat) = ufunc
		CAT_UFUNC(cat) = NULL
	    } else
		CAT_INTBL(cat) = NULL
	    CAT_OUTTBL(cat) = tbl
	    call mfree (CAT_IHDR(cat), TY_STRUCT)

	    ptr = catopen1 (output, NEW_FILE, 0); TBL_TP(tbl) = ptr
	    call catdefine (cat, tbl, NEW_FILE, catdef, structdef, nim)
	    CAT_INTBL(cat) = NULL
	} else {				# NEW_COPY or READ_WRITE
	    call calloc (tbl, TBL_LEN, TY_STRUCT)
	    CAT_INTBL(cat) = tbl

	    ptr = catopen1 (input, READ_ONLY, 0); TBL_TP(tbl) = ptr
	    call catdefine (cat, tbl, READ_ONLY, catdef, structdef, nim)
	    call catrhdr (CAT_INTBL(cat), CAT_IHDR(cat))

	    call calloc (tbl, TBL_LEN, TY_STRUCT)
	    CAT_OUTTBL(cat) = tbl
	    if (tbtacc (output) == NO) {
		ptr = catopen1 (output, NEW_FILE, 0); TBL_TP(tbl) = ptr
		call catdefine (cat, tbl, NEW_COPY, catdef, structdef, nim)
		#call catcreate (cat)
		call catrhdr (CAT_INTBL(cat), CAT_OHDR(cat))
	    } else {
		ptr = catopen1 (output, READ_WRITE, 0)
		TBL_TP(tbl) = ptr
		call catdefine (cat, tbl, READ_WRITE, catdef, structdef, nim)
		call catrhdr (CAT_OUTTBL(cat), CAT_OHDR(cat))
	    }
	}
end


# CATOPEN1 -- Interface procedure to handle an error.

pointer procedure catopen1 (fname, mode, template)

char	fname[ARB]			#I Filename
pointer	mode				#I Mode
pointer	template			#I Pointer to template

pointer	tp, err, tbtopn()
pointer	sp, catname
errchk	catextn

begin
	call smark (sp)
	call salloc (catname, SZ_FNAME, TY_CHAR)

	call catextn (fname, Memc[catname], SZ_FNAME)
	iferr (tp = tbtopn (Memc[catname], mode, template)) {
	    call salloc (err, SZ_FNAME, TY_CHAR)
	    call sprintf (Memc[err], SZ_FNAME, "Cannot open catalog (%s)")
	        call pargstr (Memc[catname])
	    call error (1, Memc[err])
	}

	call sfree (sp)
	return (tp)
end
