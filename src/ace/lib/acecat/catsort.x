include	<acecat.h>


# CATSORT -- Sort records by a specified field and in a specified direction.
#
# NULL records and INDEF values are always sorted last.
# A NULL catalog pointer or undefined field leave the records unsorted.
# To allow sorting subsets of the records, the records and number of records
# are passed as arguments rather than doing all the records.  To sort
# all the records the call would be somethingl like:
#    call catsort (cat, CAT_REC(cat,1), CAT_NRECS(cat), id, dir)

procedure catsort (cat, rec, nrec, id, dir)

pointer	cat			#I Catalog pointer
pointer	rec[ARB]		#I Array of records
int	nrec			#I Number of records
int	id			#I Field id for sort
int	dir			#I Sort direction (1=increasing, -1 decreasing)

pointer	sorted
int	catcmp()
extern	catcmp()

int	id1, dir1
common	/catcmpcom/ id1, dir1

begin
	if (cat == NULL)
	    return
	if (id < 0 || id > CAT_RECLEN(cat))
	    return
	if (CAT_DEF(cat,id) == NULL)
	    return

	call malloc (sorted, nrec, TY_POINTER)
	call amovi (rec, Memi[sorted], nrec)

	id1 = id; dir1 = dir
	call gqsort (Memi[sorted], nrec, catcmp, cat)
	call amovi (Memi[sorted], rec, nrec)
	call mfree (sorted, TY_POINTER)
end


# CATCMP -- Compare two records.
#
# The field and direction are passed in a common.

int procedure catcmp (cat, rec1, rec2)

pointer	cat				#I Catalog pointer
pointer	rec1, rec2			#I Records to be compared

int	i1, i2, strcmp()
real	r1, r2
double	d1, d2

int	id, dir
common	/catcmpcom/ id, dir

begin
	if (rec1 == NULL && rec2 == NULL)
	    return (0)
	else if (rec1 == NULL)
	    return (1)
	else if (rec2 == NULL)
	    return (-1)

	switch (CAT_TYPE(cat,id)) {
	case TY_INT:
	    i1 = RECI(rec1,id)
	    i2 = RECI(rec2,id)
	    if (i1 == i2)
	        return (0)
	    else if (IS_INDEFI(i1))
	        return (1)
	    else if (IS_INDEFI(i2))
	        return (-1)
	    else if (i1 < i2)
	        return (-dir)
	    else
	        return (dir)
	case TY_REAL:
	    r1 = RECR(rec1,id)
	    r2 = RECR(rec2,id)
	    if (r1 == r2)
	        return (0)
	    else if (IS_INDEFR(r1))
	        return (1)
	    else if (IS_INDEFR(r2))
	        return (-1)
	    else if (r1 < r2)
	        return (-dir)
	    else
	        return (dir)
	case TY_DOUBLE:
	    d1 = RECD(rec1,id)
	    d2 = RECD(rec2,id)
	    if (d1 == d2)
	        return (0)
	    else if (IS_INDEFD(d1))
	        return (1)
	    else if (IS_INDEFD(d2))
	        return (-1)
	    else if (d1 < d2)
	        return (-dir)
	    else
	        return (dir)
	default:
	    return (dir*strcmp (RECT(rec1,id), RECT(rec2,id)))
	}
end
