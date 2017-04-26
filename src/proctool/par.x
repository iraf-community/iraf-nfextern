include "par.h"
include	"ost.h"


# PAR_ALLOC -- Allocate parameter structure.

procedure par_alloc (par)

pointer	par				#O Parameter structure

pointer	stopen()

begin
	call calloc (par, PAR_LEN, TY_STRUCT)

	PAR_OST(par) = stopen ("OST", 26, 26, 1024)
	PAR_OPERAND(par) = stopen ("OPERAND", 26, 26, 1024)
end


# PAR_FREE -- Free parameter structure.

procedure par_free (par)

pointer	par				#O Parameter structure

pointer	stp, ost
pointer	sthead(), stnext()

begin
	if (par == NULL)
	    return

	stp = PAR_OST(par)
	for (ost=sthead(stp); ost!=NULL; ost=stnext(stp,ost)) {
	    if (OST_CLOSE(ost) != NULL)
		call zcall1 (OST_CLOSE(ost), ost)
	}
	call stclose (stp)

	if (PAR_OLLIST(par) != NULL)
	    call clpcls (PAR_OLLIST(par))

	call mfree (par, TY_STRUCT)
end
