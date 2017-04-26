include	<error.h>
include	<acecat.h>
include	<acecat1.h>


procedure catcreate (cat)

pointer	cat			#I Catalog structure

pointer	tbl, tp

begin
	if (cat == NULL)
	    return
	tbl = CAT_OUTTBL(cat)
	if (tbl == NULL)
	    return
	tp = TBL_TP(tbl)
	if (tp == NULL)
	    return
	if (CAT_INTBL(cat) != NULL) {
	    if (tp == TBL_TP(CAT_INTBL(cat)))
		return
	}

	iferr (call tbtcre (tp)) {
	    # Need to clean up such that catclose will not crash.
	    if (CAT_IHDR(cat) != CAT_OHDR(cat))
		call mfree (CAT_OHDR(cat), TY_STRUCT)
	    TBL_TP(tbl) = NULL
	    call erract (EA_ERROR)
	}
end
