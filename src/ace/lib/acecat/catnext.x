include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>


pointer	procedure catnext (cat, rec)

pointer	cat			#I Catalog pointer
pointer	rec			#I Input object pointer
pointer	recnext			#O Next record pointer

int	i

begin
	if (cat == NULL)
	    return (NULL)

	do i = CAT_CUR(cat)+1, CAT_NRECS(cat) {
	    recnext = CAT_REC(cat,i)
	    if (recnext != NULL) {
	        CAT_CUR(cat) = i
		return (recnext)
	    }
	}
	return (NULL)
end
