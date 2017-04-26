include	<evvexpr.h>
include	<acecat.h>
include	<acecat1.h>

include	<error.h>


procedure catwrecs (cat, filt, maxrecs)

pointer	cat			#I Catalog pointer
char	filt[ARB]		#I Filter string
int	maxrecs			#I Maximum number of records to write

int	i, j, n
pointer	recs, rec

bool	filter()

begin
	if (cat == NULL)
	    return
	if (CAT_OUTTBL(cat) == NULL)
	    return
	if (CAT_RECS(cat) == NULL)
	    return

	recs = CAT_RECS(cat)
	if (IS_INDEFI(maxrecs))
	    n = CAT_NRECS(cat)
	else
	    n = maxrecs

	j = 0
	do i = 1, CAT_NRECS(cat) {
	    rec = Memi[recs+i-1]
	    if (rec == NULL)
		next
	    if (!filter (cat, rec, filt))
		next
	    j = j + 1
	    if (j > n)
	        break
	    call catwrec (cat, rec, j)
	}
end


procedure catwrec (cat, rec, row)

pointer	cat			#I Catalog pointer
pointer	rec			#I Record pointer
int	row			#I Table row

char	expr[SZ_LINE]
pointer	tbl, tp, stp, sym, cdef, o

pointer	sthead(), stnext(), stname(), catexpr()
errchk	catexpr

begin
	if (cat == NULL || rec == NULL)
	    return

	tbl = CAT_OUTTBL(cat)
	if (tbl == NULL)
	    return
	tp = TBL_TP(tbl)
	stp = TBL_STP(tbl)

	for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
	    if (ENTRY_WRITE(sym) == NO)
	        next
	    cdef = ENTRY_CDEF(sym)
	    if (cdef == NULL)
	        next

	    # Evaluate the expression.
	    call strcpy (Memc[stname(stp,sym)], expr, SZ_LINE)
	    ifnoerr (o = catexpr (expr, cat, rec)) {
		switch (O_TYPE(o)) {
		case TY_INT:
		    call tbepti (tp, cdef, row, O_VALI(o))
		case TY_REAL:
		    call tbeptr (tp, cdef, row, O_VALR(o))
		case TY_DOUBLE:
		    call tbeptd (tp, cdef, row, O_VALD(o))
		default:
		    call tbeptt (tp, cdef, row, O_VALC(o))
		}
		call evvfree (o)
	    } else {
		switch (ENTRY_CTYPE(sym)) {
		case TY_INT:
		    call tbepti (tp, cdef, row, INDEFI)
		case TY_REAL:
		    call tbeptr (tp, cdef, row, INDEFR)
		case TY_DOUBLE:
		    call tbeptd (tp, cdef, row, INDEFD)
		default:
		    call tbeptt (tp, cdef, row, "")
		}
	    }
	}
end
