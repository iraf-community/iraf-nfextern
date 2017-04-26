task	test = t_test

procedure t_test ()

char	fname[SZ_FNAME]
char	line[SZ_LINE]
int	fd, locpr(), getline()
extern	test
errchk	xt_txtopen

begin
	call sprintf (fname, SZ_FNAME, "proc:%d")
	    call pargi (locpr (test))
	fd = NULL
	call xt_txtopen (fname, fd)
	while (getline (fd, line) != EOF)
	     call putline (STDOUT, line)
	call xt_txtopen ("", fd)
end
