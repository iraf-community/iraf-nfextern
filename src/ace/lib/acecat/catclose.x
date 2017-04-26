include	<error.h>
include	<acecat.h>
include	<acecat1.h>


# CATCLOSE -- Close a catalog.

procedure catclose (cat, err)

pointer	cat			#I Catalog pointer
int	err			#I Error?

int	i
pointer	tbl

begin
	if (cat == NULL)
	    return

	if (err == NO)
	    call catwhdr (CAT_OUTTBL(cat), CAT_OHDR(cat), YES)

	call catwcs_close (cat)

	tbl = CAT_INTBL(cat)
	if (tbl != NULL) {
	    if (TBL_STP(tbl) != NULL)
		call stclose (TBL_STP(tbl))
	    if (tbl == CAT_OUTTBL(cat))
		CAT_OUTTBL(cat) = NULL
	    if (TBL_TP(tbl) != NULL)
		iferr (call tbtclo (TBL_TP(tbl)))
		    ;
	}
	tbl = CAT_OUTTBL(cat)
	if (tbl != NULL) {
	    if (TBL_STP(tbl) != NULL)
		call stclose (TBL_STP(tbl))
	    if (TBL_TP(tbl) != NULL && err == NO)
		iferr (call tbtclo (TBL_TP(tbl)))
		    call erract (EA_WARN)
	}

	call catrecs_free (cat)

	if (CAT_DEFS(cat) != NULL) {
	    do i = 0, CAT_NF(cat)-1
		call mfree (CAT_DEF(cat,i), TY_STRUCT)
	    call mfree (CAT_DEFS(cat), TY_POINTER)
	}
	if (CAT_STP(cat) != NULL)
	    call stclose (CAT_STP(cat))
	call mfree (CAT_APFLUX(cat), TY_REAL)
	call mfree (CAT_INTBL(cat), TY_STRUCT)
	call mfree (CAT_OUTTBL(cat), TY_STRUCT)
	if (CAT_IHDR(cat) == CAT_OHDR(cat))
	    call mfree (CAT_IHDR(cat), TY_STRUCT)
	else {
	    call mfree (CAT_IHDR(cat), TY_STRUCT)
	    call mfree (CAT_OHDR(cat), TY_STRUCT)
	}

	call mfree (cat, TY_STRUCT)
end


procedure catrecs_free (cat)

pointer	cat			#I Catalog

int	i
pointer	recs

begin
	if (cat == NULL)
	    return
	if (CAT_RECS(cat) == NULL)
	    return

	recs = CAT_RECS(cat)
	do i = 0, CAT_NRECS(cat)-1
	    call mfree (Memi[recs+i], TY_STRUCT)
	call mfree (CAT_RECS(cat), TY_POINTER)
	CAT_NRECS(cat) = 0
end
