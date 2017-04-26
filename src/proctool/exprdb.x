include	<ctype.h>
include	"prc.h"
include	"ost.h"


# EXPRDB -- Read expression database and update OST symbol table.

procedure exprdb (ostp, fname)

pointer	ostp				#I Operand symbol table
char	fname[ARB]			#I Expression database

int	fd
pointer	sp, key, name, expr, ost

int	open(), fscan(), nscan(), nowhite()
pointer	stfind(), stenter()
errchk	open

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (expr, SZ_LINE, TY_CHAR)

	# Open database if specified.
	if (nowhite (fname, Memc[name], SZ_LINE) == 0) {
	    call sfree (sp)
	    return
	}
	fd = open (fname, READ_ONLY, TEXT_FILE)

	# Read through file extracting non-comment lines.
	while (fscan (fd) != EOF) {
	    call gargwrd (Memc[key], SZ_FNAME)
	    if (Memc[key] == '#' || Memc[key+1] != EOS)
	        next
	    call gargwrd (Memc[name], SZ_FNAME)
	    call gargwrd (Memc[expr], SZ_LINE) 
	    if (nscan() < 3)
		next

	    call strupr (Memc[key])
	    ost = stfind (ostp, Memc[key])
	    if (ost == NULL) {
		ost = stenter (ostp, Memc[key], OST_ILEN)
		call aclri (Memi[ost], OST_ILEN)
		OST_FLAG(ost) = YES
		OST_EXPRDB(ost) = YES
	    } else if (OST_EXPRDB(ost) == NO) {
		call eprintf (
		"Cannot modify operation '%s' in expression database (%s)\n")
			call pargstr (Memc[key])
			call pargstr (fname)
		    next
	    }

	    call setexpr ("", Memc[expr], SZ_LINE)
	    if (Memc[expr] != EOS)
		call strcpy (Memc[expr], OST_EXPR(ost), OST_LENSTR)
	    if (nowhite (Memc[name], Memc[expr], SZ_FNAME) > 0)
		call strcpy (Memc[name], OST_NAME(ost), OST_LENSTR)
	}
	call close (fd)
	call sfree (sp)
end
