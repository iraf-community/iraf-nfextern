procedure txtfile (fname, fd)

char	fname[ARB]
int	fd

int	open(), stropen()
pointer	strbuf
errchk	malloc

begin
	if (fname[1] != EOS) {
	    if (fd == NULL)
		fd = open (fname, READ_ONLY, TEXT_FILE)
	    else {
	        call close (fd)
		fd = NULL
	    }
	    return
	}

	if (fd == NULL) {
	    call malloc (strbuf, XXXX, TY_CHAR)
	    fd = stropen (Memc[strbuf], XXXX, NEW_FILE)
	    call fprintf (fd, "abc\n")
	    ...
	    call close (fd)
	    fd = stropen (Memc[strbuf], XXXX, READ_ONLY)
	} else {
	    call close (fd)
	    call mfree (strbuf, TY_CHAR)
	    fd = NULL
	}
end
