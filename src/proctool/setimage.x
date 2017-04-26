include	<error.h>
include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"

define	DEBUG	false


# SETIMAGE -- Set information for an image.

procedure setimage (prc, image, exti, extn, tsec, list, listtype, sortval,
	in, pi)

pointer	prc				#I Processing pointer
char	image[ARB]			#I Image to set
int	exti				#I Extension index
char	extn[ARB]			#I Extension name
char	tsec[ARB]			#I Trim section
int	list				#I List
int	listtype			#I List type
double	sortval				#I Default sort value
pointer	in				#I IMIO pointer
pointer	pi				#O Processing image

int	i
pointer	par, stp, ost, sym

bool	prc_exprb()
real	prc_exprr()
double	prc_exprd()
pointer	ost_find(), sthead(), stnext()
errchk	pi_map, prc_error, prc_exprb, prc_exprr, prc_exprd, prc_exprs

define	done_	10

begin
	if (image[1] == EOS)
	    call error (1, "No image specified")

	iferr {
	    # Set parameter structure.
	    par = PRC_PAR(prc)
	    stp = PAR_OST(par)

	    # Check if processing type is defined.
	    ost = ost_find (stp, listtype)
	    if (ost == NULL)
		call prc_error (prc, 1, "Unknown processing type", "", "")

	    # Allocate a new image object.
	    call pi_alloc (prc, pi, image, exti, extn, tsec, INDEFI, in)

	    # Map the image if needed.
	    call pi_map (pi)

	    # Set the line to force updates of the operand cache.
	    PRC_LINE(prc) = 1

	    # Set the list.
	    PI_LIST(pi) = list
	    PI_LISTTYPE(pi) = listtype
	    i = 0
	    if (listtype == PRC_INPUT) {
	    	if (OST_INTYPE(ost) != NULL) {
		    if (!prc_exprb (prc, pi, OST_INTYPE(ost))) {
		        call pi_free (pi)
			goto done_
		    }
		}
		PI_PRCTYPE(pi) = PRC_OBJECT
	        for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
		    if (OST_PRCTYPE(sym) == PRC_INPUT)
		        next
		    if (OST_EXPRDB(sym) == NO)
		        next
		    #if (OST_LIST(sym) != NULL)
		    #    next
		    if (OST_INTYPE(sym) == NULL)
		        next

		    if (prc_exprb (prc, pi, OST_INTYPE(sym))) {
			PI_PRCTYPE(pi) = OST_PRCTYPE(sym)
			i = i + 1
		    }
		}
		if (i > 1)
		    call prc_error (prc, 1,
		        "Input matches more than one type (%s)", image, "")

	    # There is only one flat list which we want to separate into
	    # lamp on and lamp off flats.
	    } else if (listtype == PRC_FFLAT || listtype == PRC_GFLAT) {
		PI_PRCTYPE(pi) = PRC_FFLAT
		if (OST_INTYPE(ost) == EOS)
		    i = i + 1
		else if (prc_exprb (prc, pi, OST_INTYPE(ost)))
		    i = i + 1
		if (listtype == PRC_FFLAT)
		    sym = ost_find (stp, PRC_GFLAT)
		else
		    sym = ost_find (stp, PRC_FFLAT)
		if (sym != NULL) {
		    if (OST_INTYPE(sym) == EOS)
			i = i + 1
		    else if (prc_exprb (prc, pi, OST_INTYPE(sym))) {
			PI_PRCTYPE(pi) = OST_PRCTYPE(sym)
			i = i + 1
		    }
		}
		if (i > 1)
		    call prc_error (prc, 1,
		        "Flat matches more than one type (%s)", image, "")
	        
	    } else
		PI_PRCTYPE(pi) = listtype
	    ost = ost_find (stp, PI_PRCTYPE(pi))

	    if (DEBUG) {
		call eprintf ("setimage: %s %d %d\n")
		call pargstr (PI_NAME(pi))
		call pargi (PI_PRCTYPE(pi))
		call pargi (PI_LISTTYPE(pi))
	    }

	    # Get the filter string.
	    if (OST_FILTER(ost) != EOS)
	        call prc_exprs (prc, pi, OST_FILTER(ost), PI_FILTER(pi),
		    PRC_LENSTR)
	    else
		PI_FILTER(pi) = EOS

	    # Get the image ID string.
	    if (OST_IMAGEID(ost) != NULL)
	        call prc_exprs (prc, pi, OST_IMAGEID(ost), PI_IMAGEID(pi),
		    PRC_LENSTR)
	    else
		PI_IMAGEID(pi) = EOS

	    # Get the exposure time.
	    if (OST_EXPTIME(ost) != NULL)
		PI_EXPTIME(pi) = prc_exprr (prc, pi, OST_EXPTIME(ost))
	    else
		PI_EXPTIME(pi) = INDEFR

	    # Get the sort value.
	    if (OST_SORTVAL(ost) != NULL)
		PI_SORTVAL(pi) = prc_exprd (prc, pi, OST_SORTVAL(ost))
	    else
		PI_SORTVAL(pi) = sortval

done_	   if (pi == NULL)
		;

	} then {
	    call pi_free (pi)
	    call erract (EA_ERROR)
	}
end
