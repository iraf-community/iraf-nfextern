include	<acecat.h>
include	"catdemo.h"

define	STRUCTDEF	"catdemo.h"

procedure t_catwdemo ()

char	output[SZ_FNAME]
char	catdef[SZ_FNAME]
int	i
pointer	cat, hdr, rec

errchk	catopen, catcreate, catwojs catclose

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
	    call calloc (Memi[CAT_RECS(cat)+i-1], CAT_RECLEN(cat), TY_STRUCT)

	# Set the catalog records using the generic reference.
	do i = 1, CAT_NRECS(cat) {
	    rec = Memi[CAT_RECS(cat)+i-1]
	    RECR(rec,ID_RA) = 13. + i / 3600.
	    RECR(rec,ID_DEC) = 32. + i / 3600.
	    RECR(rec,ID_MAG) = 20 + i / 10.
	}

	# Create the catalog file, write the records, and close the catalog.
	call catcreate (cat)
	call catwrecs (cat)
	call catclose (cat)
end


procedure t_catrdemo ()

char	input[SZ_FNAME], str[SZ_LINE]
char	catdef[SZ_FNAME]
int	i
pointer	cat, hdr, recs, obj

#int	catgid()
pointer	cathead(), catnext()

errchk	catopen, catrhdr, catrrecs, catclose

begin
	call clgstr ("input", input, SZ_FNAME)
	call clgstr ("catdef", catdef, SZ_FNAME)

	# Define the catalog.
	#call catopen (cat, input, "", catdef, STRUCTDEF, NULL)
	#call catopen (cat, input, "", "#ra C1\nDEC c2\nMag C3", STRUCTDEF, NULL)
	#call catopen (cat, input, "", "", STRUCTDEF, NULL)
	call catopen (cat, input, "", "", "", NULL)

	# Do some stuff with the header.
	hdr = CAT_HDR(cat)
	#call imgstr (hdr, "KEY1", str, SZ_LINE)
	#call printf ("KEY1 = %s\n")
	#    call pargstr (str)

	# Read the records.
	call catrrecs (cat, "", -1)
	#call catrrecs (cat, "", ID_N)
	#call catrrecs (cat, "", catgid (cat, "N"))

	# Print values
	for (rec=cathead(cat); obj!=NULL; obj=catnext(cat,obj)) {
	    call printf ("%g %g %g\n")
	        #call pargr (REC_RA(rec))
	        #call pargr (REC_DEC(rec))
	        #call pargr (REC_MAG(rec))
	        call pargd (RECR(rec,0))
	        call pargd (RECR(rec,2))
	        call pargd (RECR(rec,4))
	}

#	recs = CAT_RECS(cat)
#	do i = 1, CAT_NRECS(cat) {
#	    call printf ("%2d: ")
#		call pargi (i)
#	    rec = Memi[objs+i-1]
#	    if (rec == NULL)
#	        call printf ("---\n")
#	    else {
#	        call printf ("%d %g\n")
#		    call pargi (REC_N(rec))
#		    call pargr (REC_X(rec))
#	    }
#	}

	# Finish up.
	call catclose (cat)
end
