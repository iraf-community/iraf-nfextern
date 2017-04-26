include	<evvexpr.h>

# CATEXPR -- Evaluate expression.
#
# This is a simple wrapper for evvexpr to encapsulate this function
# within the acecat library.  This returns an error which the calling
# function can trap and set the value to a desired default.

pointer procedure catexpr (expr, cat, rec)

char	expr[ARB]		#I Expression
pointer	cat			#I Catalog pointer
pointer	rec			#I Record pointer

int	locpr()
pointer	evvexpr()
errchk	evvexpr
extern	catop, catfunc

pointer	catptr
common	/catexprcom/ catptr

begin
	if (cat == NULL || rec == NULL)
	    call error (1, "Can't evaluate expression with NULL arguments")

	catptr = cat
	return (evvexpr (expr,locpr(catop),rec,locpr(catfunc),cat,O_FREEOP))
end
