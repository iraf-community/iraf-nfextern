# AFN -- Procedures to set ACE file name lists.
#
# The purpose of this is to support the '+' substitution pattern.
# It has the side-effect of hiding the list type (file or image).
#
#	 afn = afn_cl (param, type, afnref)
#	 afn = afn_opn (pat, type, afnref)
#	 afn = afn_opno (list, type)
#	stat = afn_gfn (afn, fname, len)
#	stat = afn_rfn (afn, index, fname, len)
#	 len = afn_len (afn)
#	       afn_rew (afn)
#	       afn_cls (afn)
#
# This has some knowledge of image types.  If an extension matching imtype
# or ".fits" is given then any cluster extension is put at the end.
# For catalog types it also checks the default catalog extension.
# Otherwise the special characters are removed and added to the end
# of the reference name.

define	AFN_LEN		2		# Length of AFN structure
define	AFN_LIST	Memi[$1]	# List
define	AFN_TYPE	Memc[P2C($1+1)]	# List type

define	SZ_LIST		16384		# Maximum expanded list


# AFN_CL -- Open file name list past on CL parameter.
# type is either "image", "file", or "catalog" (only the first char matters).

pointer procedure afn_cl (param, type, afnref)

char	param[ARB]		#I CL parameter
char	type[ARB]		#I List type (i|f|c)
pointer	afnref			#I AFN list for expansion
pointer	afn			#R Return list

pointer	sp, str

int	afn_opn(), stridxs()
pointer	imtopen(), fntopnb()
errchk	salloc, afn_opn, imtopen, fntopnb

begin
	call smark (sp)
	call salloc (str, SZ_LIST, TY_CHAR)

	# Set pattern or list from CL parameter.
	if (param[1] != EOS)
	    call clgstr (param, Memc[str], SZ_LINE)
	else
	    Memc[str] = EOS

	# Only use the pattern expansion if there is a list and a "+".
	if (afnref != NULL && AFN_LIST(afnref) != NULL &&
	    stridxs ("+", Memc[str]) > 0)
	    afn = afn_opn (Memc[str], type, afnref)
	
	else {
	    call malloc (afn, AFN_LEN, TY_STRUCT)
	    AFN_TYPE(afn) = type[1]
	    AFN_LIST(afn) = NULL

	    # An empty string produces a NULL list pointer.
	    if (Memc[str] != EOS) {
		switch (AFN_TYPE(afn)) {
		case 'f':
		    AFN_LIST(afn) = fntopnb (Memc[str], NO)
		default:
		    AFN_LIST(afn) = imtopen (Memc[str])
		}
	    }
	}

	call sfree (sp)
	return (afn)
end


# AFN_OPN -- Open file name list.
# type is either "image", "file" or "catalog" (only the first char matters).
# Unlike AFN_CL the pattern need not have a "+".  This is useful when
# there are extensions to generate a list with extensions from the
# the input list but only a rootname for the pattern.

pointer procedure afn_opn (pat, type, afnref)

char	pat[ARB]		#I Pattern
char	type[ARB]		#I List type (i|f|c)
pointer	afnref			#I AFN list for expansion
pointer	afn			#R Return AFN list

int	i, j, k, l

bool	mef
pointer	sp, str, str1, fname, fextn, extn

bool	streq()
int	afn_gfn(), envgets(),  stridxs(), strlen()
pointer	imtopen(), fntopnb()
errchk	salloc, malloc, imtopen, fntopnb, cat_extn

begin
	call malloc (afn, AFN_LEN, TY_STRUCT)
	AFN_TYPE(afn) = type[1]
	AFN_LIST(afn) = NULL

	# An empty pattern results in a NULL list.
	if (pat[1] == EOS)
	    return (afn)

	call smark (sp)
	call salloc (str, SZ_LIST, TY_CHAR)

	# For catalogs add the catalog extension if needed.
	if (type[1] == 'c')
	    call cat_extn (pat, Memc[str], SZ_LIST)
	else
	    call strcpy (pat, Memc[str], SZ_LIST)

	# Only expand if a list is given.
	if (afnref != NULL && AFN_LIST(afnref) != NULL) {
	    call salloc (fname, SZ_FNAME, TY_CHAR)
	    call salloc (fextn, SZ_FNAME, TY_CHAR)
	    call salloc (extn, SZ_FNAME, TY_CHAR)
	    call salloc (str1, strlen(Memc[str]), TY_CHAR)
	    call strcpy (Memc[str], Memc[str1], ARB)

	    # Check if the pattern includes an explicit extension.
	    call zfnbrk (Memc[str1], i, k)
	    call strcpy (Memc[str1+k-1], Memc[fextn], SZ_FNAME)
	    Memc[str1+k-1] = EOS

	    # Check the extension for an image or catalog MEF type.
	    mef = false
	    if (Memc[fextn] != EOS) {
		if (type[1] == 'c')
		    mef = (Memc[fextn+1] == 'f')
		else if (type[1] == 'i') {
		    if (envgets ("imtype", Memc[fname], SZ_FNAME) == 0)
		       call strcpy ("fits", Memc[fname], SZ_FNAME)
		    mef = (streq (Memc[fextn+1], Memc[fname]))
		}
	    }

	    # Create new list with substitutions.
	    j = 0
	    call afn_rew (afnref)
	    while (j<SZ_LIST && afn_gfn (afnref, Memc[fname], SZ_FNAME)!=EOF) {

		# Extract cluster extension.
		Memc[extn] = EOS
		l = stridxs ("[", Memc[fname])
		if (l > 0) {
		    call strcpy (Memc[fname+l-1], Memc[extn], SZ_FNAME)
		    Memc[fname+l-1] = EOS
		    if (!mef) {
			k = extn
		        for (i=extn; Memc[i]!=EOS; i=i+1) {
			    switch (Memc[i]) {
			    case ',', ']', '=', ':':
			        next
			    case '[':
				Memc[k] = '_'
			    default:
				Memc[k] = Memc[i]
			    }
			    k = k + 1
			}
			Memc[k] = EOS
		    }
		}

		# Remove extension.
		call zfnbrk (Memc[fname], i, k)
		Memc[fname+k-1] = EOS

		# Strip path.
		call strcpy (Memc[fname+i-1], Memc[fname], SZ_FNAME)

		# Do + substitution.
		if (j != str) {
		    Memc[str+j] = ','
		    j = j + 1
		}
		for (i=str1; Memc[i]!=EOS&&j<SZ_LIST; i=i+1) {
		    if (Memc[i] == '+') {
		        for (k=fname; Memc[k]!=EOS; k=k+1) {
			    Memc[str+j] = Memc[k]
			    j = j + 1
			    if (j == SZ_LIST)
			        break
			}
		    } else {
		        Memc[str+j] = Memc[i]
			j = j + 1
		    }
		}

		# Add any final extensions.
		if (mef) {
		    call strcpy (Memc[fextn], Memc[str+j], SZ_LIST)
		    j = j + strlen (Memc[fextn])
		    call strcpy (Memc[extn], Memc[str+j], SZ_LIST)
		    j = j + strlen (Memc[extn])
		} else {
		    call strcpy (Memc[extn], Memc[str+j], SZ_FNAME)
		    j = j + strlen (Memc[extn])
		    call strcpy (Memc[fextn], Memc[str+j], SZ_LIST)
		    j = j + strlen (Memc[fextn])
		}
	    }
	    call afn_rew (afnref)
	    Memc[str+j] = EOS
	    if (j == SZ_LIST) {
		call sprintf (Memc[str], SZ_LIST, "Expanded list too long (%s)")
		    call pargstr (pat)
		call error (1, Memc[str])
	    }
	}

	# An empty lists produces a NULL list pointer.
	if (Memc[str] != EOS) {
	    switch (AFN_TYPE(afn)) {
	    case 'f':
		AFN_LIST(afn) = fntopnb (Memc[str], NO)
	    default:
		AFN_LIST(afn) = imtopen (Memc[str])
	    }
	}

	call sfree (sp)
	return (afn)
end


# AFN_OPNO -- Open existing list as an AFN list.
# The input list should not be closed separately.  Once the existing list
# is entered as an AFN list it will be closed by afn_cls.
# type is either "image", "file", or "catalog" (only the first char matters).

pointer procedure afn_opno (list, type)

pointer	list			#I IMT or FNT list
char	type[ARB]		#I List type (i|f|c)
pointer	afn			#R Return list

errchk	malloc

begin
	call malloc (afn, AFN_LEN, TY_STRUCT)
	AFN_LIST(afn) = list
	AFN_TYPE(afn) = type[1]
	return (afn)
end


# AFN_CLS -- Close list.

procedure afn_cls (afn)

pointer	afn			#U List
errchk	fntclsb, imtclose

begin
	if (afn == NULL)
	    return

	if (AFN_LIST(afn) != NULL) {
	    switch (AFN_TYPE(afn)) {
	    case 'f':
		call fntclsb (AFN_LIST(afn))
	    default:
		call imtclose (AFN_LIST(afn))
	    }
	}

	call mfree (afn, TY_STRUCT)
end


# AFN_LEN -- Length of list.

int procedure afn_len (afn)

pointer	afn			#I List

int	imtlen(), fntlenb()

begin
	if (afn == NULL)
	    return (0)
	if (AFN_LIST(afn) == NULL)
	    return (0)

	switch (AFN_TYPE(afn)) {
	case 'f':
	    return (fntlenb (AFN_LIST(afn)))
	default:
	    return (imtlen (AFN_LIST(afn)))
	}
end


# AFN_REW -- Length of list.

procedure afn_rew (afn)

pointer	afn			#I List

begin
	if (afn == NULL)
	    return
	if (AFN_LIST(afn) == NULL)
	    return

	switch (AFN_TYPE(afn)) {
	case 'f':
	    call fntrewb (AFN_LIST(afn))
	default:
	    call imtrew (AFN_LIST(afn))
	}
end


# AFN_GFN -- Get next file.

int procedure afn_gfn (afn, fname, len)

pointer	afn			#I List
char	fname[len]		#O File name
int	len			#I Maximum file name length

int	imtgetim(), fntgfnb()

begin
	if (afn == NULL) {
	    fname[1] = EOS
	    return (EOF)
	}
	if (AFN_LIST(afn) == NULL) {
	    fname[1] = EOS
	    return (EOF)
	}

	switch (AFN_TYPE(afn)) {
	case 'f':
	    return (fntgfnb (AFN_LIST(afn), fname, len))
	default:
	    return (imtgetim (AFN_LIST(afn), fname, len))
	}
end


# AFN_RFN -- Get next indexed (random) file.

int procedure afn_rfn (afn, index, fname, len)

pointer	afn			#I List
int	index			#I Index
char	fname[len]		#O File name
int	len			#I Maximum file name length

int	imtrgetim(), fntrfnb()

begin
	if (afn == NULL) {
	    fname[1] = EOS
	    return (EOF)
	}
	if (AFN_LIST(afn) == NULL) {
	    fname[1] = EOS
	    return (EOF)
	}

	switch (AFN_TYPE(afn)) {
	case 'f':
	    return (fntrfnb (AFN_LIST(afn), index, fname, len))
	default:
	    return (imtrgetim (AFN_LIST(afn), index, fname, len))
	}
end
