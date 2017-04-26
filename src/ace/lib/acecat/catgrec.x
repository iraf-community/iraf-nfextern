include	<acecat.h>
include	<acecat1.h>


# CATGREC -- Get record given the record number.
#
# Currently this relies on the record pointer array being indexed by
# record number.

pointer procedure catgrec (cat, num)

pointer	cat			#I Catalog
int	num			#I Record number

begin
	return (Memi[CAT_RECS(cat)+num-1])
end
