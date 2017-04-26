# Copyright restrictions apply - see tables$copyright.tables 
# 
include <tbset.h>
include "tbtables.h"

# tbfrsi -- read size info
# This routine reads NAXIS2 (number of rows) and TFIELDS (number of columns)
# from a FITS file and saves the values in the table descriptor.
#
# Phil Hodge,  6-Jul-1995  Subroutine created
# Phil Hodge,  2-Feb-1996  Check whether current HDU is a table.
# Phil Hodge,  7-Jun-1999  Use TB_SUBTYPE instead of TB_HDUTYPE.

procedure tbfrsi (tp)

pointer tp		# i: pointer to table descriptor
#--
pointer sp
pointer comment		# comment from FITS file
int	status		# used for fitsio
int	keysexist	# number of header keywords
int	keysadd		# space available for new header keywords
errchk	tbferr

begin
	status = 0

	call smark (sp)
	call salloc (comment, SZ_LINE, TY_CHAR)

	if (TB_SUBTYPE(tp) == TBL_SUBTYPE_BINTABLE || 
	    TB_SUBTYPE(tp) == TBL_SUBTYPE_ASCII) {

	    call fsgkyj (TB_FILE(tp), "NAXIS2",
		    TB_NROWS(tp), Memc[comment], status)
	    if (status != 0)
		call tbferr (status)

	    call fsgkyj (TB_FILE(tp), "TFIELDS",
		    TB_NCOLS(tp), Memc[comment], status)
	    if (status != 0)
		call tbferr (status)

	} else {

	    # The current extension (or primary HDU) is not a table.
	    TB_NROWS(tp) = 0
	    TB_NCOLS(tp) = 0
	}

	call fsghsp (TB_FILE(tp), keysexist, keysadd, status)
	if (status != 0)
	    call tbferr (status)

	TB_MAXCOLS(tp) = TB_NCOLS(tp)
	TB_COLUSED(tp) = 0			# meaningless
	TB_NPAR(tp) = keysexist
	TB_MAXPAR(tp) = keysexist + keysadd
	TB_BOD(tp) = 0

	call sfree (sp)
end
