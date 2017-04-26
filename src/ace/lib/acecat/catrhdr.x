include	<acecat.h>
include	<acecat1.h>


procedure catrhdr (tbl, hdr)

pointer	tbl			#I Table pointer
pointer	hdr			#I Header

errchk	tb2im()

begin
	if (tbl == NULL || hdr == NULL)
	    return
	if (TBL_TP(tbl) == NULL)
	    return

	call tb2im (TBL_TP(tbl), hdr)
end
