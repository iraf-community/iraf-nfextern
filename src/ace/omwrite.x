include	<imhdr.h>
include	<pmset.h>
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>
include	"ace.h"
include	"filter.h"


procedure omwrite (pm, fname, flt, omtype, refim, cat, catalog, objid,
	update, logfd, verbose)

pointer	pm		#I Pixel mask pointer to save
char	fname[ARB]	#I Filename
pointer	flt		#I Filter parameters
int	omtype		#I Type of mask values
pointer	refim		#I Reference image pointer
pointer	cat		#I Catalog pointer
char	catalog[ARB]	#I Catalog filename
char	objid[ARB]	#I Object ID string
int	update		#I Update image header
int	logfd		#I Logfile
int	verbose		#I Verbose level

int	i, j, k, nc, nl, id, nummax
long	v[2]
pointer	sp, str, im, buf, recs, rec, nums, sym

bool	filter()
int	stridxs(), andi()
pointer	immap(), impl2i(), stfind()

errchk	immap, filter

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Remove output only fields.
	call strcpy (fname, Memc[str], SZ_LINE)
	i = stridxs (",", fname)
	if (i > 0) {
	    Memc[str+i-1] = ']'
	    Memc[str+i] = EOS
	}
	
	if (update == YES)
	    call imastr (refim, "OBJMASK", Memc[str])
	if (pm == NULL)
	    return

	# Check catalog for mask number field.
	id = INDEFI
	if (cat != NULL && flt != NULL) {
	    sym = stfind (CAT_STP(cat), FLT_NUM(flt))
	    if (sym == NULL) {
	        call sprintf (Memc[str], SZ_LINE,
		    "Mask number catalog field not found (%s)")
		    call pargstr (FLT_NUM(flt))
	        call error (1, Memc[str])
	    }
	    if (ENTRY_TYPE(sym) != TY_INT) {
	        call sprintf (Memc[str], SZ_LINE,
		    "Mask number catalog field not integer (%s)")
		    call pargstr (FLT_NUM(flt))
	        call error (1, Memc[str])
	    }
	    id = ENTRY_ID(sym)
	}

	if (logfd != NULL) {
	    call fprintf (logfd, "  Write object mask: %s\n")
		call pargstr (Memc[str])
	}
	if (verbose > 1) {
	    call printf ("  Write object mask: %s\n")
		call pargstr (Memc[str])
	}

	im = immap (fname, NEW_COPY, refim)
	IM_PIXTYPE(im) = TY_INT

	nc = IM_LEN(refim,1)
	nl = IM_LEN(refim,2)

	v[1] = 1
	if (IS_INDEFI(id)) {
	    switch (omtype) {
	    case OM_BOOL, OM_BBOOL:
		do i = 1, nl {
		    v[2] = i
		    buf = impl2i (im, i)
		    call pmglpi (pm, v, Memi[buf], 0, nc, PIX_SRC)
		    if (omtype == OM_BBOOL) {
			do j = buf, buf+nc-1 {
			    if (Memi[j] >= NUMSTART && MNOTBNDRY(Memi[j]))
				Memi[j] = 0
			}
		    }
		    call aminki (Memi[buf], 1, Memi[buf], nc)
		}
	    case OM_ONUM, OM_BONUM:
		do i = 1, nl {
		    v[2] = i
		    buf = impl2i (im, i)
		    call pmglpi (pm, v, Memi[buf], 0, nc, PIX_SRC)
		    if (omtype == OM_BONUM) {
			do j = buf, buf+nc-1 {
			    if (Memi[j] >= NUMSTART && MNOTBNDRY(Memi[j]))
				Memi[j] = 0
			}
		    }
		    do j = buf, buf+nc-1
			Memi[j] = MNUM(Memi[j])
		}
	    default:
		do i = 1, nl {
		    v[2] = i
		    call pmglpi (pm, v, Memi[impl2i(im,i)], 0, nc, PIX_SRC)
		}
	    }
	} else {
	    nummax = CAT_NUMMAX(cat)
	    recs = CAT_RECS(cat)
	    do i = 0, CAT_NRECS(cat)-1 {
		rec = Memi[recs+i]
		if (rec == NULL)
		    next
		if (!filter (cat, rec, FLT_FILTER(flt)))
		    next
		nummax = max (nummax, RECI(rec,id))
	    }

	    call salloc (nums, nummax+1, TY_SHORT)
	    call aclrs (Mems[nums], nummax+1)
	    do i = 0, CAT_NRECS(cat)-1 {
		rec = Memi[recs+i]
		if (rec == NULL)
		    next
		if (!filter (cat, rec, FLT_FILTER(flt)))
		    next
		k = RECI(rec,id)
		if (k < 1 || k > nummax)
		    next
		Mems[nums+k] = 1
	    }
	    
	    do i = 1, nl {
		v[2] = i
		buf = impl2i (im, i)
		call pmglpi (pm, v, Memi[buf], 0, nc, PIX_SRC)
		do j = buf, buf+nc-1 {
		    k = MNUM(Memi[j])
		    if (k > NUMSTART && (k > nummax || Mems[nums+k] == 0))
			Memi[j] = 0
		}
		switch (omtype) {
		case OM_BOOL, OM_BBOOL:
		    if (omtype == OM_BBOOL) {
			do j = buf, buf+nc-1 {
			    if (Memi[j] >= NUMSTART && MNOTBNDRY(Memi[j]))
				Memi[j] = 0
			}
		    }
		    call aminki (Memi[buf], 1, Memi[buf], nc)
		case OM_ONUM, OM_BONUM:
		    if (omtype == OM_BONUM) {
			do j = buf, buf+nc-1 {
			    if (Memi[j] >= NUMSTART && MNOTBNDRY(Memi[j]))
				Memi[j] = 0
			}
		    }
		    do j = buf, buf+nc-1
			Memi[j] = MNUM(Memi[j])
		}
	    }
	}

	iferr (call imdelf (im, "DATASEC"))
	    ;
	iferr (call imdelf (im, "TRIMSEC"))
	    ;
	iferr (call imdelf (im, "OBJMASK"))
	    ;
	if (catalog[1] != EOS)
	    call imastr (im, "CATALOG", catalog)
	if (objid[1] != EOS)
	    call imastr (im, "OBJID", objid)

	# Add the mask type for other programs to use.
	switch (omtype) {
	case OM_BOOL:
	    call imastr (im, "OMTYPE", "boolean")
	case OM_ONUM:
	    call imastr (im, "OMTYPE", "numbers")
	case OM_ALL:
	    call imastr (im, "OMTYPE", "all")
	case OM_BBOOL:
	    call imastr (im, "OMTYPE", "bboolean")
	case OM_BONUM:
	    call imastr (im, "OMTYPE", "bonum")
	}


	call imunmap (im)
end
