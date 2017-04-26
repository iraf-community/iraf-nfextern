include	<ctotok.h>


define	SZ_PARAM 32

# XT_PARSET -- Enter a par file into the CL cache only if not defined.

procedure xt_parset (parfile)

char	parfile[ARB]			#I Parameter file

char	dummy[1]
char	line[SZ_LINE], param[SZ_PARAM], value[SZ_LINE]
int	i, ip, fd

bool	streq()
int	getline(), ctotok()
pointer	clc_find()
errchk	xt_txtopen

begin
	# Open parameter file.
	fd = NULL
	call xt_txtopen (fname, fd)

	# Scan parameter file lines and parse them.
	while (fscan (fd) != EOF) {
	    call gargstr (line, SZ_LINE)

	    ip = 1
	    if (ctotok (line, ip, param, SZ_PARAM) != TOK_IDENTIFIER)
	        next
	    if (streq (param, "mode"))
	        next
	    for (i=0; i<3 && ctotok(line,ip,value,SZ_LINE)!=TOK_EOS;) {
		if (value[1] == ',')
		    i = i + 1
	    }
	    switch (ctotok (line, ip, value, SZ_LINE)) {
	    case TOK_NUMBER, TOK_STRING:
	        ;
	    default:
	        value[1] = EOS
	    }

	    # Enter in clcache if not already defined.
	    if (clc_find (param, line, 1) == NULL)
	        call clc_enter (param, value)
	}

	# Close parameter file.
	call xt_txtopen (fname, fd)
end
