include	<acecat.h>
include	<acecat1.h>


# These currently work on the record number but eventually there will be
# an array of indices to allow traversing the records in some sorted order.

pointer procedure cathead (cat)

pointer	cat			#I Catalog pointer
pointer	rec			#O First record pointer

int	i

begin
	if (cat == NULL)
	    return (NULL)

	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    if (rec != NULL) {
	        CAT_CUR(cat) = i
		return (rec)
	    }
	}
	return (NULL)
end
