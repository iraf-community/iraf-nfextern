include	<imhdr.h>
include	<acecat.h>
include	<acecat1.h>
include	<tbset.h>


# CATGETS -- Get a string parameter from the catalog header.

procedure catgets (cat, param, value, maxchar)

pointer	cat			#I Catalog pointer
char	param[ARB]		#I Parameter to get
char	value[ARB]		#O Returned value 
int	maxchar			#I Maximum characters in value

int	i, strdic()
pointer	hdr

begin
	value[1] = EOS

	if (cat == NULL)
	    return

	i = strdic (param, CAT_STR(cat), CAT_SZSTR, CATPARAMS)
	switch (i) {
	case 1:
	    hdr = CAT_IHDR(cat)
	    if (hdr != NULL)
	       call strcpy (IM_HDRFILE(hdr), value, maxchar)
	    else
	        value[1] = EOS
	case 2:
	    hdr = CAT_OHDR(cat)
	    if (hdr != NULL)
	       call strcpy (IM_HDRFILE(hdr), value, maxchar)
	    else
	        value[1] = EOS
	case 3:
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    iferr (call imgstr (hdr, "image", value, maxchar))
		i = 0
	case 4:
	    hdr = CAT_OHDR(cat)
	    if (hdr == NULL)
		hdr = CAT_IHDR(cat)
	    iferr (call imgstr (hdr, "objmask", value, maxchar))
		i = 0
	case 5:
	    call strcpy (CAT_RECID(cat), value, maxchar)
	case 6:
	    call strcpy (CAT_CATALOG(cat), value, maxchar)
	default:
	    call sprintf (CAT_STR(cat), CAT_SZSTR,
		"catgets: unknown catalog parameter `%s'")
		call pargstr (param)
	    call error (1, CAT_STR(cat))
	}

	if (i == 0) {
	    call sprintf (CAT_STR(cat), CAT_SZSTR,
		"catgets: parameter `%s' not found")
		call pargstr (param)
	    call error (1, CAT_STR(cat))
	}
end


procedure catgeti (cat, param, value)

pointer	cat			#I Catalog pointer
char	param[ARB]		#I Parameter to get
int	value			#O Returned value 

int	i, strdic(), tbpsta()

begin
	value = INDEFI

	if (cat == NULL)
	    return

	i = strdic (param, CAT_STR(cat), CAT_SZSTR, CATPARAMS)
	switch (i) {
	case 7:
	    value = CAT_NRECS(cat)
	case 9:
	    if (CAT_INTBL(cat) != NULL)
	        value = tbpsta (TBL_TP(CAT_INTBL(cat)), TBL_NROWS)
	case 10:
	    if (CAT_OUTTBL(cat) != NULL)
	        value = tbpsta (TBL_TP(CAT_OUTTBL(cat)), TBL_NROWS)
	default:
	    call sprintf (CAT_STR(cat), CAT_SZSTR,
		"catgeti: unknown catalog parameter `%s'")
		call pargstr (param)
	    call error (1, CAT_STR(cat))
	}
end


procedure catgetr (cat, param, value)

pointer	cat			#I Catalog pointer
char	param[ARB]		#I Parameter to get
real	value			#O Returned value 

int	i, strdic()

begin
	value = INDEFR

	if (cat == NULL)
	    return

	i = strdic (param, CAT_STR(cat), CAT_SZSTR, CATPARAMS)
	switch (i) {
	case 8:
	    value = CAT_MAGZERO(cat)
	default:
	    call sprintf (CAT_STR(cat), CAT_SZSTR,
		"catgetr: unknown catalog parameter `%s'")
		call pargstr (param)
	    call error (1, CAT_STR(cat))
	}
end
