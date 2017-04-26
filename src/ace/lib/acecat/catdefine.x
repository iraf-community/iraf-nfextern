include	<ctype.h>
include	<acecat.h>
include	<acecat1.h>


# CATDEF -- Read catalog definition file and create symbol table.
#
# Note there is a special feature that requires the basic field names
# to not end with a number.  Instead the number will be interpreted as
# an array index.

procedure catdefine (cat, tbl, mode, catdef, structdef, nim)

pointer	cat			#I Catalog pointer
pointer	tbl			#I Table pointer
int	mode			#I Table access mode
char	catdef[ARB]		#I Catalog definition file
char	structdef[ARB]		#I Application structure definition file
int	nim			#I Number of images

int	i, j, k, l, m, n, ni, fd, func, ncols, reclen, fnt
real	rap
pointer	sp, fname, name, name1, label, label1, pat, str, str2, str3
pointer	entry, sym, sym1, sym2, sym3
pointer	stp1, stp2, tp

bool	streq()
int	xt_txtopen(), stropen(), fscan(), nscan(), fntopn(), fntgfn()
int	stridxs(), strlen(), patmake(), gpatmatch(), strncmp()
pointer	stopen(), stenter(), stfind(), sthead(), stnext(), stname()
errchk	catdefine1, catdefine2,  xt_txtopen, stropen, stopen, tbcdef1, tbcfnd1

define	err_	10

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (name1, SZ_FNAME, TY_CHAR)
	call salloc (label, SZ_LINE, TY_CHAR)
	call salloc (label1, SZ_LINE, TY_CHAR)
	call salloc (pat, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (str2, SZ_LINE, TY_CHAR)
	call salloc (sym2, ENTRY_LEN, TY_STRUCT)
	call salloc (entry, ENTRY_LEN, TY_STRUCT)
	call aclri (Memi[sym2], ENTRY_LEN)
	call aclri (Memi[entry], ENTRY_LEN)
	ENTRY_WRITE(entry) = YES

	if (tbl != NULL)
	    tp = TBL_TP(tbl)

	# Set the application entry structure.
	if (structdef[1] != EOS)
	    call catdefine1 (cat, structdef, stp1, reclen, nim)
	else if (CAT_INTBL(cat) != NULL)
	    call catdefine2 (cat, TBL_TP(CAT_INTBL(cat)), stp1, reclen)
	else if (tp != NULL && mode != NEW_FILE)
	    call catdefine2 (cat, tp, stp1, reclen)
	else
	    call error (1, "catdefine: no catalog structure definition")

#call stpdump (stp1, "STRUCTURE DEFINITION 1", NO)

	# Read the catalog definitions.
	fd = NULL
	fnt = NULL
	if (catdef[1] == '=')
	    fnt = fntopn (catdef[2])
	else if (catdef[1] == '#') {
	    i = strlen (catdef)
	    call salloc (str3, i, TY_CHAR)
	    call sprintf (Memc[str3], i, catdef[2])
	    fd = stropen (Memc[str3], i, READ_ONLY)
	} else if (catdef[1] == '@')
	    fd = xt_txtopen (catdef[2], READ_ONLY, TEXT_FILE)
	else if (catdef[1] != EOS)
	    fd = xt_txtopen (catdef, READ_ONLY, TEXT_FILE)
	else
	    if (streq (structdef, "acelib$aceobjs.h"))
		fd = xt_txtopen ("acelib$catdef.dat", READ_ONLY, TEXT_FILE)

	stp2 = stopen ("catdefine", 100, ENTRY_LEN, SZ_LINE)
	ncols = 0
	func = 0
	rap = INDEFR
	n = 1
	repeat {
	    # Parse catalog field translation.
	    if (fd == NULL && fnt == NULL) {
		if (ncols == 0)
		    sym1 = sthead(stp1)
		else
		    sym1 = stnext(stp1,sym1)
		if (sym1 == NULL)
		    break
		call strcpy (Memc[stname(stp1,sym1)], Memc[name], SZ_FNAME)
		call strcpy (Memc[name], Memc[label], SZ_FNAME)
		if (catdef[1] != EOS && !streq (catdef, structdef)) {
		    if (ncols == 0)
		        call sscan (catdef)
		    if (ENTRY_READ(sym1) == YES || ENTRY_WRITE(sym1) == YES) {
			call gargwrd (Memc[str], SZ_LINE)
			if (Memc[str] != EOS) {
			   call strcpy (Memc[str], Memc[name], SZ_FNAME)
			   call strcpy (Memc[name], Memc[label], SZ_LINE)
			}
		    }
		}

		if (sym1 == NULL) {
		    call stclose (stp1)
		    call stclose (stp2)
		    call xt_txtclose (fd)
		    call sprintf (Memc[str], SZ_LINE,
	    "Unknown or ambiguous catalog quantity `%s' in definition `%s'")
			call pargstr (Memc[name])
			call pargstr (catdef)
		    call error (1, Memc[str])
		}
		call strcpy (Memc[label], CAT_CNAME(cat,ENTRY_ID(sym1)),
		    CAT_SLEN)
		if (tbl == NULL) {
		    ncols = ncols + 1
		    next
		}

		if ((mode!=NEW_FILE&&mode!=NEW_COPY) &&
		    ENTRY_READ(sym1) == YES)
		    call tbcfnd1 (tp, Memc[label], ENTRY_CDEF(sym1))

		ENTRY_EVAL(sym1) = YES
		sym2 = stenter (stp2, Memc[name], ENTRY_LEN)
		call amovi (Memi[sym1], Memi[sym2], ENTRY_LEN)
		call strcpy (Memc[stname(stp1,sym1)], ENTRY_NAME(sym2),
		    ENTRY_DLEN)

		if ((mode==NEW_FILE||mode==NEW_COPY) &&
		    ENTRY_WRITE(sym2) == YES)
		    call tbcdef1 (tp, ENTRY_CDEF(sym2), Memc[label],
			ENTRY_UNITS(sym2), ENTRY_FORMAT(sym2),
			ENTRY_CTYPE(sym2), 1)

		ncols = ncols + 1

	    } else {
		if (fd != NULL) {
		    if (fscan(fd) == EOF)
			break

		    call gargwrd (Memc[name], SZ_FNAME)
		    call gargwrd (Memc[label], SZ_LINE)
		    n = nscan()
		    if (n == 0)
			next
		    if (Memc[name] == '#')
			next
		} else {
		    # If the end of the list is reached before the end
		    # of the structure definitions loop back to
		    # initialize the reset as if reading the
		    # structure.
		    if (fntgfn (fnt, Memc[label], SZ_FNAME) == EOF) {
			call fntcls (fnt)
			sym1 = sym3
			next
		    }
		    if (ncols == 0)
			sym3 = sthead(stp1)
		    else
			sym3 = stnext(stp1,sym3)
		    if (sym3 == NULL)
			break
		    call strcpy (Memc[stname(stp1,sym3)], Memc[name], SZ_FNAME)
		    n = 2
		}

		if (n == 1)
		   call strcpy (Memc[name], Memc[label], SZ_LINE)

		call strcpy (Memc[name], Memc[name1], SZ_FNAME)
		call strcpy (Memc[label], Memc[label1], SZ_FNAME)
		do ni = 0, nim-1 {
		    j = 0
		    for (i=name1; Memc[i]!=EOS; i=i+1) {
		        if (Memc[i] == '%') {
			    if (ni > 0) {
				call sprintf (Memc[name+j], SZ_FNAME, "%d")
				    call pargi (ni)
				j = strlen (Memc[name])
			    }
			} else {
			    Memc[name+j] = Memc[i]
			    j = j + 1
			}
		    }
		    Memc[name+j] = EOS

		    j = 0
		    for (i=label1; Memc[i]!=EOS; i=i+1) {
			if (Memc[i] == '%') {
			    if (ni > 0) {
				call sprintf (Memc[label+j], SZ_FNAME, "%d")
				    call pargi (ni)
				j = strlen (Memc[label])
			    }
			} else {
			    Memc[label+j] = Memc[i]
			    j = j + 1
			}
		    }
		    Memc[label+j] = EOS

		    # Parse the name.
		    #call strupr (Memc[name])
		    sym1 = stfind (stp1, Memc[name])
		    i = stridxs ("([", Memc[name])
		    if (sym1 == NULL && i == 0) {
			call strcpy (Memc[name], Memc[str], SZ_LINE)
			i = stridxs ("0123456789", Memc[str])
			if (i > 0) {
			    Memc[str+i-1] = EOS
			    sym1 = stfind (stp1, Memc[str])
			}
		    }

		    # Extract arguments.
		    call strcpy (Memc[name], Memc[str2], SZ_LINE)
		    l = stridxs ("[", Memc[str2])
		    for (sym=sthead(stp1);l>0&&sym!=NULL;sym=stnext(stp1,sym)) {
			call strcpy (Memc[stname(stp1,sym)],Memc[str],SZ_LINE)
			j = stridxs ("_", Memc[str])
			if (j > 0)
			    Memc[str+j-1] = EOS
			m = stridxs ("0123456789", Memc[str])
			if (m > 0)
			    call strcat ("\[", Memc[str], SZ_LINE)
			else
			    call strcat ("[0-9]*\[", Memc[str], SZ_LINE)
			i = patmake (Memc[str], Memc[pat], SZ_LINE)
			while (gpatmatch(Memc[str2],Memc[pat],i,j)>0) {
			    if (IS_ALNUM(Memc[str2+i-2]))
				break
			    k = stridxs ("]", Memc[str2+j]) - 1
			    if (k < 0)
				goto err_
			    if (ENTRY_ARGS(sym) == EOS) {
				call strcpy (Memc[str2+i-1], ENTRY_NAME(sym),
				   j+k-i+2)
				call strcpy (Memc[str2+j], ENTRY_ARGS(sym), k)
				ENTRY_EVAL(sym) = YES
			    } else if (strncmp(ENTRY_ARGS(sym),Memc[str2+j],k)!=0)
				break
			    sym1 = sym
			    call strcpy (Memc[str2+j+k+1],Memc[str2+j-1],SZ_LINE)
			    l = stridxs ("[", Memc[str2])
			    if (l == 0)
				break 
			}
		    }
		    if (l != 0)
			goto err_

		    # Check for function.
		    k = stridxs ("(", Memc[str2])
		    if (k > 0) {
			# Search arguments for catalog quantities.
			for (sym1=sthead(stp1);sym1!=NULL;sym1=stnext(stp1,sym1)) {
			    call strcpy (Memc[stname(stp1,sym1)],Memc[str],SZ_LINE)
			    j = stridxs ("_", Memc[str])
			    if (j > 0)
			        next
			    m = stridxs ("0123456789", Memc[str])
			    if (m == 0)
				call strcat ("[0-9]*", Memc[str], SZ_LINE)
			    i = patmake (Memc[str], Memc[pat], SZ_FNAME)
			    if (gpatmatch(Memc[str2+k],Memc[pat],i,j)>0) {
				if (!IS_ALNUM(Memc[str2+k+i-2])&&
				    !IS_ALNUM(Memc[str2+k+j])) {
				    ENTRY_EVAL(sym1) = YES
				}
			    }
			}
			sym1 = entry
			call catfuncs (Memc[str2], Memc[str], func,
			    ENTRY_CTYPE(sym1),ENTRY_UNITS(sym1),ENTRY_FORMAT(sym1))
			if (func == 0)
			    sym1 = NULL
		    }

		    if (sym1 == NULL) {
	err_
			call stclose (stp1)
			call stclose (stp2)
			call xt_txtclose (fd)
			call sprintf (Memc[str], SZ_LINE,
		"Unknown or ambiguous catalog quantity `%s' in definition `%s'")
			    call pargstr (Memc[name])
			    call pargstr (catdef)
			call error (1, Memc[str])
		    }

		    if (sym1 != entry && ENTRY_ID(sym1) <= 10000)
			call strcpy (Memc[label], CAT_CNAME(cat,ENTRY_ID(sym1)),
			    CAT_SLEN)

		    if (tbl != NULL) {
			if ((mode!=NEW_FILE&&mode!=NEW_COPY) &&
			    ENTRY_READ(sym1) == YES)
			    call tbcfnd1 (tp, Memc[label], ENTRY_CDEF(sym1))

			ENTRY_EVAL(sym1) = YES
			sym2 = stenter (stp2, Memc[name], ENTRY_LEN)
			call amovi (Memi[sym1], Memi[sym2], ENTRY_LEN)
			if (sym1 != entry)
			    call strcpy (Memc[stname(stp1,sym1)],
			        ENTRY_NAME(sym2), ENTRY_DLEN)

			if ((mode==NEW_FILE||mode==NEW_COPY) &&
			    ENTRY_WRITE(sym2) == YES)
			    call tbcdef1 (tp, ENTRY_CDEF(sym2), Memc[label],
				ENTRY_UNITS(sym2), ENTRY_FORMAT(sym2),
				ENTRY_CTYPE(sym2), 1)
		    }

		    ncols = ncols + 1
		    if (streq (Memc[name], Memc[name1]) ||
		        streq (Memc[label], Memc[label1]))
			break
		}
	    }
	}

	if (fd != NULL)
	    call xt_txtclose (fd)
	if (fnt != NULL)
	    call fntcls (fnt)

	if (cat == NULL)
	    call stclose (stp1)
	else {
	    if (CAT_STP(cat) != NULL)
	        call stclose (CAT_STP(cat))
	    CAT_RECLEN(cat) = reclen
	    CAT_STP(cat) = stp1
	}

	if (tbl == NULL) {
	    call stclose (stp2)
	    return
	}

	if (ncols == 0) {
	    call stclose (stp2)
	    call sprintf (Memc[str], SZ_LINE,
		"No catalog quantity definitions in file `%s'")
		call pargstr (Memc[fname])
	    call error (1, Memc[str])
	}

	# Reverse order of symbol table.
	stp1 = stopen ("catdef", ncols, ENTRY_LEN, SZ_LINE)
	for (sym1=sthead(stp2); sym1!=NULL; sym1=stnext(stp2,sym1)) {
	    sym2 = stenter (stp1, Memc[stname(stp2,sym1)], ENTRY_LEN)
	    call amovi (Memi[sym1], Memi[sym2], ENTRY_LEN)
	}
	call stclose (stp2)

	TBL_STP(tbl) = stp1

#call stpdump (CAT_STP(cat), "STRUCTURE DEFINITION", YES)
#call stpdump (TBL_STP(tbl), "OUTPUT CATALOG", YES)

	call sfree (sp)
end


# CATDEF1 -- Create record symbol table from a structure definition.

procedure catdefine1 (cat, structdef, stp, reclen, nim)

pointer	cat			#I Catalog pointer
char	structdef[ARB]		#I Application structure definition file
pointer	stp			#O Symbol table
int	reclen			#O Record length
int	nim			#I Number of images

int	i, j, n, lenindexid, nalloc, id, fd
pointer	sp, indexid, fname, name, label, entry
pointer	stp1, sym

bool	streq()
int	xt_txtopen(), fscan(), nscan(), strlen(), strncmp(), ctoi(), stridxs()
pointer	stopen(), stenter(), sthead(), stnext(), stname()
errchk	xt_txtopen, stopen

begin
	stp = NULL
	reclen = 0

	if (cat != NULL) {
	    if (CAT_DEFS(cat) != NULL) {
		do i = 0, CAT_NF(cat)-1
		    call mfree (CAT_DEF(cat,i), TY_STRUCT)
		call mfree (CAT_DEFS(cat), TY_POINTER)
	    }
	    CAT_NF(cat) = 0
	}

	call smark (sp)
	call salloc (indexid, SZ_FNAME, TY_CHAR)
	call salloc (fname, SZ_FNAME, TY_CHAR)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (label, SZ_LINE, TY_CHAR)
	call salloc (entry, ENTRY_LEN, TY_STRUCT)

	call strcpy ("ID_", Memc[indexid], SZ_FNAME)
	lenindexid = strlen (Memc[indexid])
	call aclri (Memi[entry], ENTRY_LEN)
	ENTRY_EVAL(entry) = NO

	# Read the application structure definitions.
	fd = xt_txtopen (structdef, READ_ONLY, TEXT_FILE)

	stp1 = stopen ("catdefine", 100, ENTRY_LEN, SZ_LINE)
	n = 0
	nalloc = 0
	while (fscan(fd) != EOF) {
	    Memc[fname] = EOS
	    call gargwrd (Memc[fname], SZ_FNAME)
	    if (!streq (Memc[fname], "define"))
		next
	    call gargwrd (Memc[name], SZ_FNAME)
	    #call strupr (Memc[name])
	    if (streq (Memc[name], "INDEXID")) {
		call gargwrd (Memc[indexid], SZ_FNAME)
		lenindexid = strlen (Memc[indexid])
		next
	    }
	    if (strncmp (Memc[name], Memc[indexid], lenindexid) != 0)
		next

	    call gargi (ENTRY_ID(entry))
	    id = ENTRY_ID(entry)
	    call gargwrd (Memc[label], SZ_LINE)
	    if (Memc[label] != '#')
		next
	    call gargwrd (Memc[label], SZ_LINE)
	    call gargwrd (ENTRY_UNITS(entry), ENTRY_ULEN)
	    call gargwrd (ENTRY_FORMAT(entry), ENTRY_FLEN)
	    call gargwrd (Memc[fname], SZ_FNAME)

	    if (ENTRY_UNITS(entry) == '/')
	        j = 5
	    else if (ENTRY_FORMAT(entry) == '/')
	        j = 6
	    else
		j = nscan()

	    switch (j) {
	    case 5:
	        ENTRY_UNITS(entry) = EOS
	        ENTRY_FORMAT(entry) = EOS
	    case 6:
	        ENTRY_FORMAT(entry) = EOS
	    }

	    # Decode type string.
	    i = 1
	    switch (Memc[label+i-1]) {
	    case 'i':
		ENTRY_TYPE(entry) = TY_INT
		i = i + 1
	    case 'r':
		ENTRY_TYPE(entry) = TY_REAL
		i = i + 1
	    case 'd':
		ENTRY_TYPE(entry) = TY_DOUBLE
		i = i + 1
	    case 't':
                if (ctoi (Memc[label], i, ENTRY_TYPE(entry)) == 0)
		    next
		ENTRY_TYPE(entry) = -ENTRY_TYPE(entry)
		i = i + 1
	    default:
                if (ctoi (Memc[label], i, ENTRY_TYPE(entry)) == 0)
		    next
		ENTRY_TYPE(entry) = -ENTRY_TYPE(entry)
	    }
	    ENTRY_CTYPE(entry) = ENTRY_TYPE(entry)

	    switch (Memc[label+i-1]) {
	    case 'i':
		ENTRY_READ(entry) = NO
		ENTRY_WRITE(entry) = NO
	    case 'r':
		ENTRY_READ(entry) = YES
		ENTRY_WRITE(entry) = NO
	    case 'w':
		ENTRY_READ(entry) = NO
		ENTRY_WRITE(entry) = YES
	    default:
		ENTRY_READ(entry) = YES
		ENTRY_WRITE(entry) = YES
	    }

	    sym = stenter (stp1, Memc[name+lenindexid], ENTRY_LEN)
	    call amovi (Memi[entry], Memi[sym], ENTRY_LEN)
	    call strcpy (Memc[name+lenindexid], ENTRY_NAME(sym), ENTRY_DLEN)

	    if (id > 10000)
		next

	    switch (ENTRY_TYPE(entry)) {
	    case TY_INT, TY_REAL:
		n = max (n, id+1)
	    case TY_DOUBLE:
		n = max (n, id+2)
	    default:
		n = max (n, id+(-ENTRY_TYPE(entry))/2+1)
	    }

	    if (cat != NULL) {
		if (nalloc == 0) {
		    nalloc = 100
		    call calloc (CAT_DEFS(cat), nalloc, TY_POINTER)
		} else if (id+1 >= nalloc) {
		    call realloc (CAT_DEFS(cat), id+100, TY_POINTER)
		    call aclri (CAT_DEF(cat,nalloc), id+100-nalloc)
		    nalloc = id + 100
		}
		if (CAT_DEF(cat,id) == NULL)
		    call calloc (CAT_DEF(cat,id), CAT_DEFLEN, TY_STRUCT)
		CAT_TYPE(cat,id) = ENTRY_TYPE(entry)
		CAT_READ(cat,id) = ENTRY_READ(entry)
		CAT_WRITE(cat,id) = ENTRY_WRITE(entry)
		call strcpy (Memc[name+lenindexid], CAT_NAME(cat,id), CAT_SLEN)
		call strcpy (ENTRY_UNITS(entry), CAT_FORMAT(cat,id), CAT_SLEN)
		call strcpy (ENTRY_FORMAT(entry), CAT_FORMAT(cat,id), CAT_SLEN)
	    }
	}
	call xt_txtclose (fd)

	if (n == 0) {
	    call stclose (stp1)
	    stp = NULL
	    call error (1, "catdefine1: No field definitions found")
	}

	# Reverse order of symbol table and add repetitions.
	if (nim == 1) {
	    stp = stopen ("catdef", n, ENTRY_LEN, SZ_LINE)
	    for (sym=sthead(stp1); sym!=NULL; sym=stnext(stp1,sym)) {
		entry = stenter (stp, Memc[stname(stp1,sym)], ENTRY_LEN)
		call amovi (Memi[sym], Memi[entry], ENTRY_LEN)
	    }
	    call stclose (stp1)
	} else {
	    stp = stopen ("catdef", nim*n, ENTRY_LEN, SZ_LINE)
	    do i = nim-1, 0, -1 {
		for (sym=sthead(stp1); sym!=NULL; sym=stnext(stp1,sym)) {
		    if (i > 0) {
			call strcpy (Memc[stname(stp1,sym)], Memc[fname],
			    SZ_FNAME)
			j = stridxs ("_", Memc[fname])
			if (j > 0) {
			    Memc[fname+j-1] = EOS
			    call sprintf (Memc[name], SZ_FNAME, "%s%d_%s")
				call pargstr (Memc[fname])
				call pargi (i)
				call pargstr (Memc[fname+i])
			} else {
			    call sprintf (Memc[name], SZ_FNAME, "%s%d")
				call pargstr (Memc[fname])
				call pargi (i)
			}
		    } else
			call strcpy (Memc[stname(stp1,sym)], Memc[name],
			    SZ_FNAME)
		    entry = stenter (stp, Memc[name], ENTRY_LEN)
		    call amovi (Memi[sym], Memi[entry], ENTRY_LEN)
		    call strcpy (Memc[name], ENTRY_NAME(entry), ENTRY_DLEN)
		    ENTRY_ID(entry) = ENTRY_ID(sym) + i * n
		}
	    }
	    call stclose (stp1)
	}

	reclen = n * nim
	if (cat != NULL) {
	    CAT_RECLEN(cat) = reclen
	    CAT_NF(cat) = CAT_RECLEN(cat)
	    call realloc (CAT_DEFS(cat), CAT_NF(cat), TY_POINTER)
	    CAT_NIM(cat) = nim
	}

	call sfree (sp)
end


# CATDEF2 -- Create catalog definition symbol table from a table.

procedure catdefine2 (cat, tp, stp, reclen)

pointer	cat			#I Catalog pointer
pointer	tp			#I Table pointer
pointer	stp			#O Symbol table
int	reclen			#O Record length

int	i, n, nalloc, id, colnum, nelem, lenfmt
pointer	sp, name, entry
pointer	cdef, stp1, sym

pointer	tbcnum()
pointer	stopen(), stenter(), sthead(), stnext(), stname()
errchk	stopen, tbcnum, tbcinf

begin
	stp = NULL
	reclen = 0

	if (cat != NULL) {
	    if (CAT_DEFS(cat) != NULL) {
		do i = 0, CAT_NF(cat)-1
		    call mfree (CAT_DEF(cat,i), TY_STRUCT)
		call mfree (CAT_DEFS(cat), TY_POINTER)
	    }
	    CAT_NF(cat) = 0
	}

	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (entry, ENTRY_LEN, TY_STRUCT)
	call aclri (Memi[entry], ENTRY_LEN)

	stp1 = stopen ("catdefine", 100, ENTRY_LEN, SZ_LINE)
	n = 0
	nalloc = 0
	do i = 1, ARB {
	    cdef = tbcnum (tp, i)
	    if (cdef == NULL)
	        break

	    call tbcinf (cdef, colnum, Memc[name], ENTRY_UNITS(entry),
	        ENTRY_FORMAT(entry), ENTRY_TYPE(entry), nelem, lenfmt)
	    if (nelem > 1)
	        next

	    id = n
	    switch (ENTRY_TYPE(entry)) {
	    case TY_INT, TY_REAL:
		n = id + 1
	    case TY_DOUBLE:
	        id = (id + 1) / 2 * 2
		n = id + 2
	    default:
		n = id + (-ENTRY_TYPE(entry)) / 2 + 1
	    }

	    ENTRY_ID(entry) = id
	    ENTRY_CTYPE(entry) = ENTRY_TYPE(entry)
	    ENTRY_READ(entry) = YES
	    ENTRY_WRITE(entry) = YES

	    #call strupr (Memc[name])
	    sym = stenter (stp1, Memc[name], ENTRY_LEN)
	    call amovi (Memi[entry], Memi[sym], ENTRY_LEN)
	    call strcpy (Memc[name], ENTRY_NAME(sym), ENTRY_DLEN)

	    if (cat != NULL) {
		if (nalloc == 0) {
		    nalloc = 100
		    call calloc (CAT_DEFS(cat), nalloc, TY_POINTER)
		} else if (id+1 >= nalloc) {
		    call realloc (CAT_DEFS(cat), id+100, TY_POINTER)
		    call aclri (CAT_DEF(cat,nalloc), id+100-nalloc)
		    nalloc = id + 100
		}
		if (CAT_DEF(cat,id) == NULL)
		    call calloc (CAT_DEF(cat,id), CAT_DEFLEN, TY_STRUCT)
		CAT_TYPE(cat,id) = ENTRY_TYPE(entry)
		CAT_READ(cat,id) = ENTRY_READ(entry)
		CAT_WRITE(cat,id) = ENTRY_WRITE(entry)
		call strcpy (Memc[name], CAT_NAME(cat,id), CAT_SLEN)
		call strcpy (ENTRY_UNITS(entry), CAT_FORMAT(cat,id), CAT_SLEN)
		call strcpy (ENTRY_FORMAT(entry), CAT_FORMAT(cat,id), CAT_SLEN)
	    }
	}

	if (n == 0) {
	    call stclose (stp1)
	    stp = NULL
	    call error (1, "catdefine2: No table field definitions found")
	}

	# Reverse order of symbol table.
	stp = stopen ("catdef", n, ENTRY_LEN, SZ_LINE)
	for (sym=sthead(stp1); sym!=NULL; sym=stnext(stp1,sym)) {
	    entry = stenter (stp, Memc[stname(stp1,sym)], ENTRY_LEN)
	    call amovi (Memi[sym], Memi[entry], ENTRY_LEN)
	}
	call stclose (stp1)

	reclen = n
	if (cat != NULL) {
	    CAT_RECLEN(cat) = reclen
	    CAT_NF(cat) = CAT_RECLEN(cat)
	    call realloc (CAT_DEFS(cat), CAT_NF(cat), TY_POINTER)
	}

	call sfree (sp)
end


# STPDUMP -- Debugging utility to dump the symbol tables.

procedure stpdump (stp, label, eval)

pointer	stp			#I Symbol table
char	label			#I Label
int	eval			#I Evaluate only?

int	colnum, datatype, lendata, lenfmt
pointer	sym, sthead(), stnext(), stname()
pointer	sp, colname, colunits, colfmt

begin
	call smark (sp)
	call salloc (colname, SZ_LINE, TY_CHAR)
	call salloc (colunits, SZ_LINE, TY_CHAR)
	call salloc (colfmt, SZ_LINE, TY_CHAR)

	call printf ("%s\n")
	    call pargstr (label)
	for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
	    if (eval == YES && ENTRY_EVAL(sym) == NO)
	        next
	    call printf ("%s:\n")
	        call pargstr (Memc[stname(stp,sym)])
	    call printf ("  NAME = %s\n")
	        call pargstr (ENTRY_NAME(sym))
	    if (ENTRY_ARGS(sym) != EOF) {
		call printf ("  ARGS = %s\n")
		    call pargstr (ENTRY_ARGS(sym))
	    }
	    call printf ("  ID = %d\n  EVAL = %b\n  READ = %b\n  WRITE = %b\n")
	        call pargi (ENTRY_ID(sym))
	        call pargi (ENTRY_EVAL(sym))
	        call pargi (ENTRY_READ(sym))
	        call pargi (ENTRY_WRITE(sym))
	    call printf ("  TYPE = %d\n  CTYPE = %b\n")
	        call pargi (ENTRY_TYPE(sym))
	        call pargi (ENTRY_CTYPE(sym))
	    call printf ("  UNITS = '%s'\n  FORMAT='%s'\n  DESC = '%s'\n")
	        call pargstr (ENTRY_UNITS(sym))
	        call pargstr (ENTRY_FORMAT(sym))
	        call pargstr (ENTRY_DESC(sym))
	    call printf ("  CDEF = %d\n")
	        call pargi (ENTRY_CDEF(sym))
	    if (ENTRY_CDEF(sym) != NULL) {
	        call tbcinf (ENTRY_CDEF(sym), colnum, Memc[colname],
		    Memc[colunits], Memc[colfmt], datatype, lendata, lenfmt)
		call eprintf ("    COLNUM = %d\n    COLNAME = '%s'\n")
		    call pargi (colnum)
		    call pargstr (Memc[colname])
		call eprintf ("    COLUNITS = %d\n    COLFMT = '%s'\n")
		    call pargstr (Memc[colunits])
		    call pargstr (Memc[colfmt])
		call eprintf ("    DATATYPE = %d\n    LENDATA = %d\n")
		    call pargi (datatype)
		    call pargi (lendata)
		call eprintf ("    LENFMT = %d\n")
		    call pargi (lenfmt)
	    }
	}
	call printf ("\n")
end
