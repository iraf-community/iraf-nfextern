include	<acecat.h>
include	"example1.h"

define	STRUCTDEF	"example1.h"

procedure t_example1 ()

char	output[SZ_FNAME]
char	catdef[SZ_FNAME]
int	i
pointer	cat, hdr, rec

errchk	catopen, catcreate, catwrecs catclose

begin
	call clgstr ("output", output, SZ_FNAME)
	call clgstr ("catdef", catdef, SZ_FNAME)

	# Define the catalog.
	call catopen (cat, "", output, catdef, STRUCTDEF, NULL)

	# Do some stuff with the header.
	hdr = CAT_HDR(cat)
	call imastr (hdr, "KEY1", "This is a header keyword")

	# Allocate the entry records.
	CAT_NRECS(cat) = 10
	call calloc (CAT_RECS(cat), CAT_NRECS(cat), TY_POINTER)
	do i = 1, CAT_NRECS(cat)
	    call calloc (CAT_REC(cat,i), CAT_RECLEN(cat), TY_STRUCT)

	# Set the catalog records using the generic reference.
	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    RECR(rec,ID_RA) = 13. + i / 3600.
	    RECR(rec,ID_DEC) = 32. + i / 3600.
	    RECR(rec,ID_MAG) = 20 + i / 10.
	}

	# Alternatively use the application macros.
	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    OBJ_RA(rec) = 13. + i / 3600.
	    OBJ_DEC(rec) = 32. + i / 3600.
	    OBJ_MAG(rec) = 20 + i / 10.
	}

	# Create the catalog file, write the records, and close the catalog.
	call catcreate (cat)
	call catwrecs (cat)
	call catclose (cat)
end
