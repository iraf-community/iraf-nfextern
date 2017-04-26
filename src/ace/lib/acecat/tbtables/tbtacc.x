# Copyright restrictions apply - see tables$copyright.tables 
# 
# tbtacc -- test for existence of table
# This function returns YES if the table exists, NO if not.
# We attempt to open the specified file read-only as a table using tbtopn.
# If that fails, either the file does not exist or it is not a table (or
# we don't have read access to it), and the value NO is returned as the
# function value.  If the open is successful, the table is closed, and YES
# is returned.
# (Until 4-Dec-90 we called tbtext and access.  The problem with that was
# that it would report YES for any file that existed regardless of whether
# it really was a table.)
#
# Phil Hodge, 25-Aug-1987  Function created.
# Phil Hodge,  4-Dec-1990  Use tbtopn instead of access.

int procedure tbtacc (tablename)

char	tablename[ARB]		# i: the table name
#--
pointer tp
pointer tbtopn()

begin
	iferr {
	    tp = tbtopn (tablename, READ_ONLY, NULL)
	} then {
	    return (NO)
	} else {
	    call tbtclo (tp)
	    return (YES)
	}
end
