include	<evvexpr.h>
include	"ace.h"
include	<aceobjs.h>
include	<aceobjs1.h>


procedure t_filter ()

pointer	incat			# Input catalog name
pointer	outcat			# Output catalog name
pointer	filt			#I Filter

pointer	sp, cat, obj, cathead(), catnext()
errchk	catopen

begin
	call smark (sp)
	call salloc (icat, SZ_FNAME, TY_CHAR)
	call salloc (ocat, SZ_FNAME, TY_CHAR)
	call salloc (filt, SZ_LINE, TY_CHAR)

	call clgstr ("icatalog", Memc[icat], SZ_FNAME)
	call clgstr ("ocatalog", Memc[ocat], SZ_FNAME)
	call clgstr ("filter", Memc[filt], SZ_FNAME)

	# Open catalogs.
	call catopen (cat, Memc[icat], Memc[ocat], "", "", NULL, 1)
	call catwrecs (cat, Memc[filt], INDEFI)

	# Loop through records.
	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    if (!filter (cat, rec, filt))
	        next
	    if (rec == NULL)
	        next
	for (rec=cathead(icat); rec!=NULL; rec=catnext(icat,obj)) {
#	    call printf ("%d\n")
#		call pargi (OBJ_ROW(obj))
	}

	call catclose (cat, NO)

	call sfree (sp)
end
