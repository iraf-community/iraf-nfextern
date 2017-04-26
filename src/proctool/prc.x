include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"


# PRC_ALLOC -- Allocate processing data structure.

procedure prc_alloc (prc, par)

pointer	prc				#O Allocated processing structure.
pointer	par				#I Parameter structure.

int	locpr()
pointer	stopen()
extern	pe_getop(), pe_func()
errchk	stopen

begin
	call calloc (prc, PRC_LEN, TY_STRUCT)

	PRC_PAR(prc) = par
	PRC_STP(prc) = stopen ("PROC", 100, 100, 1024)
	PRC_GETOP(prc) = locpr(pe_getop)
	PRC_FUNC(prc) = locpr(pe_func)
end


# PRC_FREE -- Free processing data structure.

procedure prc_free (prc)

pointer	prc				#U Allocated processing structure.

pointer	stp, sym
pointer	sthead(), stnext()

begin
	if (prc == NULL)
	    return

	stp = PRC_STP(prc)
	if (stp != NULL) {
	    for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym))
	        call pi_free (Memi[sym])
	    call stclose (stp)
	}
	call mfree (PRC_PIS(prc), TY_POINTER)
	call mfree (prc, TY_STRUCT)
end


# PRC_PIUNMAP -- Unmap all images in the operand symbol table.

procedure prc_piunmap (prc)

pointer	prc				#U Allocated processing structure.

pointer	stp, sym
pointer	sthead(), stnext()

begin
	if (prc == NULL)
	    return

	stp = PAR_OST(PRC_PAR(prc))
	if (stp != NULL)
	    for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym))
		call pi_unmap (OST_PI(sym))
end


# PRC_ERROR -- Format error with up to two string arguments.

procedure prc_error (prc, errnum, fmt, arg1, arg2)

pointer	prc				#I PRC structure
int	errnum				#I Error number
char	fmt[ARB]			#I Format string
char	arg1[ARB]			#I String argument
char	arg2[ARB]			#I String argument

begin
	call sprintf (PRC_STR(prc), PRC_LENSTR, fmt)
	    if (arg1[1] != EOS)
		call pargstr (arg1)
	    if (arg2[1] != EOS)
		call pargstr (arg2)
	call error (errnum, PRC_STR(prc))
end
