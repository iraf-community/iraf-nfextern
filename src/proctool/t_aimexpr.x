include	<error.h>
include	"par.h"
include	"prc.h"
include	"ost.h"


# T_AIMEXPR -- Another image expression evaluator
#
# This expression evaluator is a layer on proctool.

procedure t_aimexpr ()

pointer	par			# Parameters

int	i
char	key[1]
pointer	stp, ost
pointer	sp, ost1, str

int	clgwrd(), locpr(), errget(), nowhite(), strdic()
pointer	imtopen(), clpopnu(), stenter()
extern	ost_iopen, ost_iclose
errchk	stenter

begin
	call smark (sp)
	call salloc (ost1, OST_ILEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Allocate parameter structure.
	call par_alloc (par)
	stp = PAR_OST(par)

	# Set error action.
	PAR_ERRACT(par) = clgwrd ("erraction", Memc[str], SZ_LINE, PAR_EA)

	iferr {
	    # Open expression database if defined.
	    call clgstr ("exprdb", Memc[str], SZ_LINE)
	    if (nowhite (Memc[str], Memc[str], SZ_LINE) > 0)
		call setexpr ("open", Memc[str], SZ_LINE)

	    # Operation symbol table.
	    
	    # Defaults common to all operands
	    call aclri (Memi[ost1], OST_ILEN)
	    OST_PRCTYPE(ost1) = PRC_OBJECT
	    OST_OPEN(ost1) = locpr (ost_iopen)
	    OST_CLOSE(ost1) = locpr (ost_iclose)
	    OST_SRT(ost1) = SRT_NEAREST
	    call setexpr ("imageid", OST_IMAGEID(ost1), OST_LENSTR)

	    # Define expression.
	    key[1] = 'i'
	    ost = stenter (stp, key, OST_ILEN)
	    call amovi (Memi[ost1], Memi[ost], OST_ILEN)
	    call strcpy ("Expression", OST_NAME(ost), OST_LENSTR)
	    OST_FLAG(ost) = YES
	    call setexpr ("expr", OST_EXPR(ost), OST_LENEXPR)
	    call strcpy (key[1], OST_ORDER(ost,1), OST_LENOSTR)

	    # Input images.
	    OST_PRCTYPE(ost) = PRC_INPUT
	    call setexpr ("i", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))

	    # Output images.
	    call clgstr ("outtype", Memc[str], SZ_LINE)
	    call sscan (Memc[str])
	    call gargwrd (Memc[str], SZ_LINE)
	    call gargwrd (PAR_MASKKEY(par), 8)
	    if (Memc[str] != EOS) {
		PAR_OUTTYPE(par) = strdic (Memc[str], Memc[str], SZ_LINE,
		    PAR_OUTTYPES)
		if (PAR_OUTTYPE(par) == 0)
		    call error (1, "Bad output type parameter")
	    } else
	        PAR_OUTTYPE(par) = PAR_OUTIMG
	    key[1] = 'o'
	    ost = stenter (stp, key, OST_ILEN)
	    call amovi (Memi[ost1], Memi[ost], OST_ILEN)
	    OST_PRCTYPE(ost) = PRC_OUTPUT
	    if (PAR_OUTTYPE(par)==PAR_OUTLST || PAR_OUTTYPE(par)==PAR_OUTVLST)
	        call strcpy ("+LIST+", OST_IEXPR(ost), OST_LENSTR)
	    else
		call setexpr (key, OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))

	    # Set image operands.
	    for (key[1] = 'a'; key[1] <= 'h'; key[1] = key[1] + 1) { 
		ost = stenter (stp, key, OST_ILEN)
		call amovi (Memi[ost1], Memi[ost], OST_ILEN)
		call setexpr (key, OST_IEXPR(ost), OST_LENSTR)
		if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		    OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    }

	    # Set mask operands.  These are different from the other
	    # image operands in that they are masks which are matched
	    # to the input images.

	    OST_PRCTYPE(ost1) = PRC_MASK
	    for (key[1] = 'A'; key[1] <= 'H'; key[1] = key[1] + 1) { 
		ost = stenter (stp, key, OST_ILEN)
		call amovi (Memi[ost1], Memi[ost], OST_ILEN)
		call setexpr (key, OST_IEXPR(ost), OST_LENSTR)
		if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
		    OST_LIST(ost) = imtopen (OST_IEXPR(ost))
	    }

	    # Other parameters.
	    PAR_OLLIST(par) = clpopnu ("logfiles")
	    PAR_OVERRIDE(par) = YES
	    PAR_COPY(par) = YES
	    PAR_LISTIM(par) = NO

	    # Sort by list order and by imageid.  Note that the list
	    # order is set by the absence of a sort value expression.
	    call strcpy ("SI", Memc[PAR_SRTORDER(par)], 9)

	    # Call processing tool.
	    call proctool (par, "AIMEXPR")
	} then {
	    switch (PAR_ERRACT(par)) {
	    case PAR_EAWARN:
		call erract (EA_WARN)
	    case PAR_EAERROR:
		call erract (EA_ERROR)
	    case PAR_EAQUIT:
		i = errget (Memc[str], SZ_LINE)
	        call eprintf ("QUIT: %s\n")
		    call pargstr (Memc[str])
	    }
	}

	# Finish up.
	call setexpr ("close", Memc[str], SZ_LINE)
	call par_free (par)
	call sfree (sp)
end
