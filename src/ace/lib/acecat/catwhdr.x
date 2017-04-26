include	<acecat.h>
include	<acecat1.h>
include <tbset.h>


# CATWHDR -- Write header to catalog.
# This is called by CATCLOSE with the header defined in the CAT structure.
#
# Note that this currently add keywords and doesn't check for
# keywords already in the table header which are not in the IMIO header.

procedure catwhdr (tbl, hdr, del)

pointer	tbl			#I Table pointer
pointer	hdr			#I Header
int	del			#I Delete existing keywords first?

int	i, npar, tbpsta()
pointer	tp
errchk	im2tb

begin
	if (hdr == NULL || tbl == NULL)
	    return

	tp = TBL_TP(tbl)
	if (tp == NULL)
	    return

	if (del == YES) {
	    npar = tbpsta (tp, TBL_NPAR)
	    do i = npar, 1, -1
	        call tbhdel (tp, i)
	}

	call im2tb (hdr, tp)
end
