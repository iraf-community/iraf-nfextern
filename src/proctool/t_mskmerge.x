include	<error.h>
include	"par.h"
include	"prc.h"
include	"ost.h"

define	MSK_METHODS	"|map|min|max|add|or|"


# T_MSKMERGE -- Merge masks.
#
# This expression evaluator is a layer on proctool.

procedure t_mskmerge ()

pointer	par			# Parameters

int	i, masks, mapto
char	key[1]
pointer	stp, ost
pointer	sp, mapval, expr, ost1, str

bool	streq
int	clgwrd(), locpr(), errget(), strdic()
pointer	imtopen(), clpopnu(), clgfil(), stenter(), stfind()
extern	ost_iopen, ost_iclose
errchk	stenter

begin
	call smark (sp)
	call salloc (mapval, SZ_LINE, TY_CHAR)
	call salloc (expr, SZ_LINE, TY_CHAR)
	call salloc (ost1, OST_ILEN, TY_STRUCT)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Allocate parameter structure.
	call par_alloc (par)
	stp = PAR_OST(par)

	# Set error action.
	PAR_ERRACT(par) = clgwrd ("erraction", Memc[str], SZ_LINE, PAR_EA)

	iferr {
	    # Defaults common to all operands
	    call aclri (Memi[ost1], OST_ILEN)
	    OST_PRCTYPE(ost1) = PRC_OBJECT
	    OST_OPEN(ost1) = locpr (ost_iopen)
	    OST_CLOSE(ost1) = locpr (ost_iclose)
	    OST_SRT(ost1) = SRT_NEAREST
	    call setexpr ("!imageid", OST_IMAGEID(ost1), OST_LENSTR)

	    # Define expression.
	    key[1] = 'i'
	    ost = stenter (stp, key, OST_ILEN)
	    call amovi (Memi[ost1], Memi[ost], OST_ILEN)
	    call strcpy ("Expression", OST_NAME(ost), OST_LENSTR)
	    OST_FLAG(ost) = YES
	    call strcpy (key[1], OST_ORDER(ost,1), OST_LENOSTR)

	    # Input image.
	    OST_PRCTYPE(ost) = PRC_INPUT
	    call clgstr ("image", OST_IEXPR(ost), OST_LENSTR)
	    OST_LIST(ost) = imtopen (OST_IEXPR(ost))

	    # Output image.
	    call clgstr ("key", PAR_MASKKEY(par), 8)
	    key[1] = 'o'
	    ost = stenter (stp, key, OST_ILEN)
	    call amovi (Memi[ost1], Memi[ost], OST_ILEN)
	    OST_PRCTYPE(ost) = PRC_OUTPUT
	    call setexpr ("output", OST_IEXPR(ost), OST_LENSTR)
	    if (OST_IEXPR(ost) == EOS) {
	        PAR_OUTTYPE(par) = PAR_OUTLST
		call strcpy ("+LIST+", OST_IEXPR(ost), OST_LENSTR)
	    } else
	        PAR_OUTTYPE(par) = PAR_OUTMSK
	    if (OST_IEXPR(ost) != '(')
		OST_LIST(ost) = imtopen (OST_IEXPR(ost))

	    # Set expression and operands.
	    call strcpy ("msk", Memc[expr], SZ_LINE)
	    call clgstr ("method", Memc[expr+3], SZ_LINE-3)
	    if (strdic (Memc[expr+3],Memc[expr+3],SZ_LINE-3,MSK_METHODS) == 0)
	        call error (1, "Unknown or ambiguous merging method")
	    masks = clpopnu ("masks")
	    OST_PRCTYPE(ost1) = PRC_MASK
	    if (streq (Memc[expr], "mskmap")) {
	        call strcpy ("1", Memc[mapval], 8)
	        mapto = clpopnu ("mapto")
		for (key[1]='A'; key[1]<='Z' &&
		    clgfil(masks,PAR_STR(par),PAR_SZSTR)!=EOF;
		    key[1]=key[1]+1) { 
		    if (clgfil(mapto,Memc[mapval],8)==EOF)
		        ;
		    ost = stenter (stp, key, OST_ILEN)
		    call amovi (Memi[ost1], Memi[ost], OST_ILEN)
		    call strcpy (PAR_STR(par), OST_IEXPR(ost), OST_LENSTR)
		    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
			OST_LIST(ost) = imtopen (OST_IEXPR(ost))
		    if (key[1] == 'A')
			call strcat ("($", Memc[expr], SZ_LINE)
		    else
			call strcat (",$", Memc[expr], SZ_LINE)
		    call strcat (key, Memc[expr], SZ_LINE)
		    call strcat (",", Memc[expr], SZ_LINE)
		    if (Memc[mapval] == '$') {
			call strcat ("$", Memc[expr], SZ_LINE)
			call strcat (key, Memc[expr], SZ_LINE)
		    } else
			call strcat (Memc[mapval], Memc[expr], SZ_LINE)
		}
		call strcat (")", Memc[expr], SZ_LINE)
		call clpcls (mapto)
	    } else {
		for (key[1]='A'; key[1]<='Z' &&
		    clgfil(masks,PAR_STR(par),PAR_SZSTR)!=EOF;
		    key[1]=key[1]+1) { 
		    ost = stenter (stp, key, OST_ILEN)
		    call amovi (Memi[ost1], Memi[ost], OST_ILEN)
		    call strcpy (PAR_STR(par), OST_IEXPR(ost), OST_LENSTR)
		    if (OST_IEXPR(ost) != EOS && OST_IEXPR(ost) != '(')
			OST_LIST(ost) = imtopen (OST_IEXPR(ost))
		    if (key[1] == 'A')
			call strcat ("($", Memc[expr], SZ_LINE)
		    else
			call strcat (",$", Memc[expr], SZ_LINE)
		    call strcat (key, Memc[expr], SZ_LINE)
		}
		call strcat (")", Memc[expr], SZ_LINE)
	    }
	    call clpcls (masks)
	    if (key[1] > 'Z')
	        call error (1, "Too many masks to merge")
	    ost = stfind (stp, "i")
	    call strcpy (Memc[expr], OST_EXPR(ost), OST_LENEXPR)

	    # Other parameters.
	    PAR_OLLIST(par) = clpopnu ("logfiles")
	    PAR_OVERRIDE(par) = YES
	    PAR_COPY(par) = YES
	    PAR_LISTIM(par) = NO

	    # Sort by list order and by imageid.  Note that the list
	    # order is set by the absence of a sort value expression.
	    call strcpy ("SI", Memc[PAR_SRTORDER(par)], 9)

	    # Call processing tool.
	    call proctool (par, "MSKMERGE")
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
