include	<acecat.h>


# CATACC -- Is the catalog accessible?  Currently this is a wrapper for tbtacc.

int procedure catacc (fname, mode)

char	fname[ARB]		#I Filename
int	mode			#I Mode

int	stat
pointer	catname
int	tbtacc()

begin
	call malloc (catname, SZ_FNAME, TY_CHAR)
	call catextn (fname, Memc[catname], SZ_FNAME)
	stat = tbtacc (Memc[catname])
	call mfree (catname, TY_CHAR)
	return (stat)
end
