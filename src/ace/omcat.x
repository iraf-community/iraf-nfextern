include	<imhdr.h>
include	<pmset.h>
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>
include	"ace.h"


# OMCAT -- Create a minimal catalog from an object mask.

procedure omcat (om, im, cat, logfd, verbose)

pointer	om			#I Object mask pointer
pointer	im			#I Image pointer
pointer	cat			#U Catalog
int	logfd			#I Logfile
int	verbose			#I Verbose level

int	i, l, nc, nl, nobj, nummax, nalloc, val, num, c1, c2
pointer	sp, v, rl
pointer	objs
pointer	rlptr, obj

int	andi()
bool	pm_linenotempty()
errchk	calloc, malloc, realloc

begin
	call smark (sp)
	call salloc (v, PM_MAXDIM, TY_LONG)
	call salloc (rl, 3+3*IM_LEN(im,1), TY_INT)

	if (logfd != NULL)
	    call fprintf (logfd, "  Create catalog from object mask\n")
	if (verbose > 1)
	    call printf ("  Create catalog from object mask\n")

	# Initialize.
	nc = IM_LEN(im,1)
	nl = IM_LEN(im,2)
	nobj = 0
	nummax = 0
	nalloc = 1000
	call calloc (objs, nalloc, TY_POINTER)

	# Loop through the mask.
	Memi[v] = 1
	do l = 1, nl {
	    Memi[v+1] = l
	    if (!pm_linenotempty (om, Memi[v]))
	        next
	    call pmglri (om, Memi[v], Memi[rl], 0, nc, 0)

	    rlptr = rl
	    do i = 2, Memi[rl] {
	        rlptr = rlptr + 3
		c1 = Memi[rlptr]
		c2 = c1 + Memi[rlptr+1] - 1
		val = Memi[rlptr+2]
		num = MNUM(val)
		if (num < NUMSTART)
		    next
		if (MSPLIT(val) || MDARK(val))
		    next
		if (num > nalloc) {
		    call realloc (objs, num+1000, TY_POINTER)
		    call aclri (Memi[objs+nalloc], num+1000-nalloc)
		    nalloc = num + 1000
		}
		obj = Memi[objs+num-1]
		if (obj != NULL) {
		    OBJ_XMIN(obj) = min (OBJ_XMIN(obj), c1)
		    OBJ_XMAX(obj) = max (OBJ_XMAX(obj), c2)
		    OBJ_YMAX(obj) = l
		    next
		}
		call calloc (obj, CAT_RECLEN(cat), TY_STRUCT)
		Memi[objs+num-1] = obj
		OBJ_XMIN(obj) = c1
		OBJ_XMAX(obj) = c2
		OBJ_YMIN(obj) = l
		OBJ_YMAX(obj) = l
		OBJ_NUM(obj) = num
		OBJ_PEAK(obj) = INDEFR
		OBJ_GWFLUX(obj) = INDEFR
		OBJ_XPEAK(obj) = INDEFR
		OBJ_YPEAK(obj) = INDEFR
		OBJ_XAP(obj) = INDEFR
		OBJ_YAP(obj) = INDEFR
		OBJ_X(obj) = INDEFR
		OBJ_Y(obj) = INDEFR
		OBJ_XX(obj) = INDEFR
		OBJ_YY(obj) = INDEFR
		OBJ_XY(obj) = INDEFR
		OBJ_EAELLIP(obj) = INDEFR
		OBJ_EATHETA(obj) = INDEFR
		call strcpy ("S----", OBJ_FLAGS(obj), ARB)
		if (MGRW(val))
		    OBJ_FLAG(obj,GROW) = 'G'
		if (MSPLIT(val))
		    OBJ_FLAG(obj,SPLIT) = 'M'
		if (MDARK(val))
		    OBJ_FLAG(obj,DARK) = 'D'
		if (MBPFLAG(val))
		    OBJ_FLAG(obj,BP) = 'B'
		nobj = nobj + 1
		nummax = max (nummax, num)
	    }
	}

	call realloc (objs, nummax, TY_POINTER)
	CAT_RECS(cat) = objs
	CAT_NRECS(cat) = nummax
	CAT_NUMMAX(cat) = nummax
end
