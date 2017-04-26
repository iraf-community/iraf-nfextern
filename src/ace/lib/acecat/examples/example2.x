include	<acecat.h>
include	"example2.h"

procedure t_example2 ()

char	input[SZ_FNAME], str[SZ_LINE]
char	catdef[SZ_FNAME], structdef[SZ_FNAME], recindex[SZ_FNAME]
char	filter[SZ_LINE]
int	i, j, id
pointer	cat, hdr, rec

int	catgid()
pointer	cathead(), catnext()

errchk	catopen, catrhdr, catrrecs, catclose

begin
	call clgstr ("input", input, SZ_FNAME)
	call clgstr ("catdef", catdef, SZ_FNAME)
	call clgstr ("structdef", structdef, SZ_FNAME)
	call clgstr ("recindex", recindex, SZ_FNAME)
	call clgstr ("filter", filter, SZ_LINE)

	# Open the input catalog.
	call catopen (cat, input, "", catdef, structdef, NULL)

	# Do some stuff with the header.
	hdr = CAT_HDR(cat)
	ifnoerr (call imgstr (hdr, "KEY1", str, SZ_LINE)) {
	    call printf ("KEY1 = %s\n")
		call pargstr (str)
	}

	# Read the records ordered by specified ID.
	id = catgid (cat, recindex)
	call catrrecs (cat, filter, id)

	call catsort (cat, 1, 1)

	# Print values using CATHEAD/CATNEXT.
	# Use the field definitions to define the type.

	i = 1
	for (rec=cathead(cat); rec!=NULL; rec=catnext(cat,rec)) {
	    call printf ("%2d: ")
		call pargi (i)
	    i = i + 1
	    do j = 0, CAT_RECLEN(cat)-1 {
		if (CAT_DEF(cat,j) == NULL)
		    next
	        switch (CAT_TYPE(cat,j)) {
		case TY_INT:
		    call printf ("%3d ")
		        call pargi (RECI(rec,j))
		case TY_REAL:
		    call printf ("%g ")
		        call pargr (RECR(rec,j))
		case TY_DOUBLE:
		    call printf ("%g ")
		        call pargd (RECD(rec,j))
		default:
		    call printf ("%s ")
		        call pargstr (RECC(rec,j))
		}
	    }
	    call printf ("\n")
	}
	call printf ("\n")


	# Print in index order and use application definitions.
	do i = 1, CAT_NRECS(cat) {
	    call printf ("%2d: ")
		call pargi (i)
	    rec = CAT_REC(cat,i)
	    if (rec == NULL)
	        call printf ("---\n")
	    else {
	        call printf ("%3d %3d \n")
		    call pargi (REC_N(rec))
		    call pargi (REC_X(rec))
	    }
	}

	# Finish up.
	call catclose (cat)
end
