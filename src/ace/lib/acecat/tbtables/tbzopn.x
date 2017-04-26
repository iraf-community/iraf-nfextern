# Copyright restrictions apply - see tables$copyright.tables 
# 
include <tbset.h>
include "tbtables.h"
include "tbltext.h"

# tbzopn -- read an existing text file into memory
#
# Phil Hodge, 14-Jan-1992  Subroutine created.
# Phil Hodge,  6-Dec-1992  Pass line to tbzmem for possible error message.
# Phil hodge,  7-Jun-1994  Pass Memc[fmt_code] to tbzmem.
# Phil Hodge, 10-Aug-1994  Update COL_LEN.
# Phil Hodge,  3-Apr-1995  Use tbcfpt instead of tbcfmt.
# Phil Hodge, 26-Dec-1995  Errchk tbtwer.
# Phil Hodge, 30-Apr-1996  Remove call to tbtwer.
# Phil Hodge, 14-Apr-1998  Use strcpy instead of tbcftp for print format.
# Phil Hodge, 21-Apr-1999  Increase the maximum line length from 1024 to 4096.
# Phil Hodge,  7-Jun-1999  Rewrite, checking for text table subtype.

procedure tbzopn (tp)

pointer tp		# i: pointer to table descriptor
#--
pointer sp
pointer buf		# buffer for input line
int	line		# counter for line number in input file
int	line_type	# type of line read by tbzlin
int	subtype		# text table subtype
errchk	tbzsub, tbzrds, tbzrdx

begin
	call smark (sp)
	call salloc (buf, SZ_TEXTBUF, TY_CHAR)

	line = 0	# incremented later

	# Allocate space for the list of keywords.
	if (TB_MAXPAR(tp) <= 0)
	    TB_MAXPAR(tp) = INCR_N_KEYWORDS
	call calloc (TB_KEYLIST_PTR(tp), TB_MAXPAR(tp), TY_POINTER)

	# Allocate space for the comment buffer.
	call malloc (TB_COMMENT(tp), SZ_TEXTBUF, TY_CHAR)
	TB_SZ_COMMENT(tp) = SZ_TEXTBUF
	Memc[TB_COMMENT(tp)] = EOS

	# Determine the subtype of this text table.
	call tbzsub (tp, Memc[buf], SZ_TEXTBUF, line, line_type, subtype)
	TB_SUBTYPE(tp) = subtype

	# Read the file into memory.
	if (TB_SUBTYPE(tp) == TBL_SUBTYPE_SIMPLE)
	    call tbzrds (tp, Memc[buf], line, line_type)
	else if (TB_SUBTYPE(tp) == TBL_SUBTYPE_EXPLICIT)
	    call tbzrdx (tp, Memc[buf], line, line_type)

	call sfree (sp)
end
