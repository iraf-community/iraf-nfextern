include	<imhdr.h>
include	<acecat.h>
include	<acecat1.h>


procedure catputs (cat, param, value)

pointer	cat			#I Catalog pointer
char	param[ARB]		#I Parameter to get
char	value[ARB]		#I Value 

int	i, strdic()
pointer	hdr

begin
	if (cat == NULL)
	    return

	i = strdic (param, CAT_STR(cat), CAT_SZSTR, CATPARAMS)
	switch (i) {
	case 0:
	    call sprintf (CAT_STR(cat), CAT_SZSTR,
		"catgets: unknown catalog parameter `%s'")
		call pargstr (param)
	    call error (1, CAT_STR(cat))
	case 1:
	    hdr = CAT_IHDR(cat)
	    if (hdr != NULL)
	       call strcpy (value, IM_HDRFILE(hdr), SZ_IMHDRFILE)
	case 2:
	    hdr = CAT_OHDR(cat)
	    if (hdr != NULL)
	       call strcpy (value, IM_HDRFILE(hdr), SZ_IMHDRFILE)
	case 3:
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    call imastr (hdr, "IMAGE", value)
	case 4:
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    call imastr (hdr, "OBJMASK", value)
	case 5:
	    call strcpy (value, CAT_RECID(cat), CAT_SZSTR)
	case 6:
	    call strcpy (value, CAT_CATALOG(cat), CAT_SZSTR)
	default:
#	    call sprintf (CAT_STR(cat), CAT_SZSTR,
#		"catgets: unknown catalog parameter `%s'")
#		call pargstr (param)
#	    call error (1, CAT_STR(cat))
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    if (hdr != NULL)
		call imastr (hdr, param, value)
	}
end


procedure catputr (cat, param, value)

pointer	cat			#I Catalog pointer
char	param[ARB]		#I Parameter to get
real	value			#I Value

int	i, strdic()
pointer	hdr

begin
	if (cat == NULL)
	    return

	i = strdic (param, CAT_STR(cat), CAT_SZSTR, CATPARAMS)
	switch (i) {
	case 8:
	    CAT_MAGZERO(cat) = value
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    call imaddr (hdr, "MAGZERO", value)
	default:
#	    call sprintf (CAT_STR(cat), CAT_SZSTR,
#		"catgetr: unknown catalog parameter `%s'")
#		call pargstr (param)
#	    call error (1, CAT_STR(cat))
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    if (hdr != NULL)
		call imaddr (hdr, param, value)
	}
end
