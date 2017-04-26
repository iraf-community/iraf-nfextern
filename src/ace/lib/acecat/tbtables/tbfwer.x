# Copyright restrictions apply - see tables$copyright.tables 
# 
include <tbset.h>
include "tbtables.h"
include "tblfits.h"		# defines FITS_TNULL_NOT_SET

# tbfwer -- write empty rows to end of FITS table
#
# Phil Hodge,  6-Jul-1995  Subroutine created
# Phil Hodge,  3-Jun-1996  Remove call to fsirow.
# Phil Hodge, 23-Apr-1997  Add TNULL to header for FITS ASCII table.
# Phil Hodge, 29-Jul-1997  Call fsirow to create new rows.
# Phil Hodge,  7-Jun-1999  Use TB_SUBTYPE instead of TB_HDUTYPE.

procedure tbfwer (tp, nrows, new_nrows)

pointer tp		# i: pointer to table descriptor
int	nrows		# i: number of rows on entry to this routine
int	new_nrows	# i: number of rows after calling this routine
#--
pointer sp
pointer keyword		# for TNULL keyword
pointer cp		# pointer to one column descriptor
int	row, col	# row and column numbers
int	nelem		# number of elements, if column is array type
int	dtype		# data type of column (needed to set TNULL)
int	ival		# undefined value
int	status		# zero is OK
pointer tbcnum()
int	tbcigi()
errchk	tbferr

begin
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)

	status = 0

	# Create new rows and update NAXIS2.
	if (new_nrows - nrows > 0) {
	    call fsirow (TB_FILE(tp), nrows, new_nrows-nrows, status)
	    if (status > 0)
		call tbferr (status)
	}

	# Set all elements in new rows to INDEF.
	do row = nrows+1, new_nrows {

	    # Loop over columns
	    do col = 1, TB_NCOLS(tp) {

		cp = tbcnum (tp, col)
		nelem = tbcigi (cp, TBL_COL_LENDATA)

		call fspclu (TB_FILE(tp), col, row, 1, nelem, status)

		if (status == FITS_TNULL_NOT_SET) {

		    status = 0
		    call ftcmsg()

		    # Create TNULL string, and add to header.

		    call sprintf (Memc[keyword], SZ_FNAME, "TNULL%d")
			call pargi (col)

		    if (TB_SUBTYPE(tp) == TBL_SUBTYPE_ASCII) {

			# TNULL = "*"
			call fspkys (TB_FILE(tp), Memc[keyword],
				"*", "undefined value for column", status)

		    } else if (TB_SUBTYPE(tp) == TBL_SUBTYPE_BINTABLE) {

			dtype = tbcigi (cp, TBL_COL_DATATYPE)
			if (dtype == TY_INT || dtype == TY_SHORT) {
			    if (dtype == TY_INT)
				ival = FITS_INDEFI
			    else if (dtype == TY_SHORT)
				ival = FITS_INDEFS
			    call fspkyj (TB_FILE(tp), Memc[keyword],
				ival, "undefined value for column", status)
			}		# else don't do anything
		    }
		    # try again
		    call fsrdef (TB_FILE(tp), status)
		    call fspclu (TB_FILE(tp), col, row, 1, nelem, status)
		}
		if (status != 0)
		    call tbferr (status)
	    }
	}

	call sfree (sp)
end
