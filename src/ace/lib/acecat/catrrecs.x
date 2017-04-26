include	<acecat.h>
include	<acecat1.h>
include	<tbset.h>


procedure catrrecs (cat, filt, id)

pointer	cat			#I Catalog pointer
char	filt[ARB]		#I Filter string
int	id			#I Entry ID for indexing (or -1 for row)

int	i, n, index, nrows, nrecs, nalloc, tbpsta(), catrrec()
pointer	tbl, tp, recs, rec
bool	filter()

begin
	# Check for a catalog data structure.
	if (cat == NULL)
	    return

	# Free any existing records.
	call catrecs_free (cat)

	# Check for a catalog to read.
	tbl = CAT_INTBL(cat)
	if (tbl == NULL)
	    return
	tp = TBL_TP(tbl)

	# Check the index request for errors.
	if (id != -1) {
	    if (id < -1 || id > CAT_RECLEN(cat))
		call error (1, "Catalog index field not defined.")
	    else if (CAT_DEF(cat,id) == NULL)
		call error (1, "Catalog index field not defined.")
	    else if (CAT_TYPE(cat,id) != TY_INT)
		call error (1, "Catalog index field not integer.")
	}

	# Initially allocate a record array for the full catalog.
	nrows = tbpsta (tp, TBL_NROWS)
	nalloc = nrows
	call calloc (recs, nalloc, TY_POINTER)

	nrecs = 0
	rec = NULL
	do i = 1, nrows {
	    n = catrrec (cat, rec, i)
	    if (!filter (cat, rec, filt))
		next

	    if (id >= 0) {
		index = RECI(rec,id)
		if (index < 1 || IS_INDEFI(index))
		    next
	    } else
	        index = nrecs + 1

	    if (index > nalloc) {
		nalloc = nalloc + 1000
		call realloc (recs, nalloc, TY_POINTER)
		call aclri (Memi[recs+nalloc-1000], 1000)
	    }

	    if (Memi[recs+index-1] == NULL) {
		if (id >= 0)
		    nrecs = max (index, nrecs)
		else
		    nrecs = nrecs + 1
	    }

	    Memi[recs+index-1] = rec
	    rec = NULL
	}

	call realloc (recs, nrecs, TY_POINTER)

	CAT_RECS(cat) = recs
	CAT_NRECS(cat) = nrecs
end


# CATRREC -- Read record and fill in application structure.
# The number of fields read from the catalog is returned.
# Note that it is not an error for a field to be absent in which case the
# structure value is set to INDEF.

int procedure catrrec (cat, rec, row)

pointer	cat			#I Catalog pointer
pointer	rec			#U Record pointer
int	row			#I Table row
int	nread			#R Number of fields actually read

int	id, type
pointer	tbl, tp, stp, sym, cdef, sthead(), stnext()

begin
	if (cat == NULL)
	    return

	tbl = CAT_INTBL(cat)
	if (tbl == NULL)
	    return
	tp = TBL_TP(tbl)
	stp = TBL_STP(tbl)

	if (rec == NULL) {
	    call calloc (rec, CAT_RECLEN(cat), TY_STRUCT)
	    do id = 0, CAT_NF(cat)-1 {
	        if (CAT_DEF(cat,id) == NULL)
		    next
		switch (CAT_TYPE(cat,id)) {
		case TY_INT:
		    RECI(rec,id) = INDEFI
		case TY_REAL:
		    RECR(rec,id) = INDEFR
		case TY_DOUBLE:
		    RECD(rec,id) = INDEFD
		}
	    }
	}

	nread = 0
	for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
	    id = ENTRY_ID(sym)
	    type = ENTRY_TYPE(sym)
	    cdef = ENTRY_CDEF(sym)

	    if (id < 0 || id > 10000)
		next

	    switch (type) {
	    case TY_INT:
		if (cdef == NULL)
		    RECI(rec,id) = INDEFI
		else iferr (call tbegti (tp, cdef, row, RECI(rec,id)))
		    RECI(rec,id) = INDEFI
	    case TY_REAL:
		if (cdef == NULL)
		    RECR(rec,id) = INDEFR
		else iferr (call tbegtr (tp, cdef, row, RECR(rec,id)))
		    RECR(rec,id) = INDEFR
	    case TY_DOUBLE:
		if (cdef == NULL)
		    RECD(rec,id) = INDEFD
		else iferr (call tbegtd (tp, cdef, row, RECD(rec,id)))
		    RECD(rec,id) = INDEFD
	    default:
		if (cdef == NULL)
		    RECT(rec,id) = EOS
		else iferr (call tbegtt (tp, cdef, row, RECT(rec,id), -type))
		    RECT(rec,id) = EOS
	    }
	    if (cdef != NULL)
	        nread = nread + 1
	}

	return (nread)
end


# CATREC -- Allocate and initialize a record.

procedure catrec (cat, rec)

pointer	cat			#I Catalog pointer
pointer	rec			#U Record pointer

int	id
pointer	stp, sym, sthead(), stnext()

begin
	if (cat == NULL)
	    return

	if (rec == NULL)
	    call calloc (rec, CAT_RECLEN(cat), TY_STRUCT)

	stp = CAT_STP(cat)
	for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
	    id = ENTRY_ID(sym)
	    if (id < 0 || id > CAT_RECLEN(cat))
		next

	    switch (ENTRY_TYPE(sym)) {
	    case TY_INT:
		RECI(rec,id) = INDEFI
	    case TY_REAL:
		RECR(rec,id) = INDEFR
	    case TY_DOUBLE:
		RECD(rec,id) = INDEFD
	    default:
		RECT(rec,id) = EOS
	    }
	}
end
