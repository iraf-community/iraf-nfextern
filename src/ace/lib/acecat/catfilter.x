include	<ctype.h>
include	<evvexpr.h>
include <acecat.h>

bool procedure filter (cat, rec, filt)

pointer	cat			#I Catalog pointer
pointer	rec			#I Record structure
char	filt[ARB]		#I Filter string
bool	match			#O Filter return value

int	i, id, strncmp()
pointer	o, catexpr()
errchk	catexpr, xvv_error1

begin
	if (cat == NULL || rec == NULL)
	    return (false)

	# Check for NOINDEF request.
	i = 1
	if (strncmp (filt, "NOINDEF", 7) == 0) {
	   do id = 0, CAT_NF(cat)-1 {
	       if (CAT_DEF(cat,id) == NULL)
	           next
	       switch (CAT_TYPE(cat,id)) {
	       case TY_INT:
	           if (IS_INDEFI(RECI(rec,id)))
		       return (false)
	       case TY_REAL:
	           if (IS_INDEFR(RECR(rec,id)))
		       return (false)
	       case TY_DOUBLE:
	           if (IS_INDEFD(RECD(rec,id)))
		       return (false)
		}
	    }
	    for (i=8; IS_WHITE(filt[i]); i = i + 1)
	        ;
	}

	if (filt[i] == EOS)
	    return (true)

	# Evaluate filter.
	iferr (o = catexpr (filt[i], cat, rec)) {
	    #call evvfree(o)
	    match = false
	    return (match)
	}

	if (O_TYPE(o) != TY_BOOL) {
	    call evvfree(o)
	    call xvv_error1 ("Filter expression is not boolean", filt)
	}

	match = (O_VALI(o) == YES)
	call evvfree(o)

	return (match)
end
