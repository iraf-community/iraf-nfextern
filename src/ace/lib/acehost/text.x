

procedure abcdefg (fname, fd)

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
		call close (fd); fd = NULL
	    }
	    return
	}

	if (fd == NULL) {
	    call malloc (strbuf, 152, TY_CHAR)
	    fd = stropen (Memc[strbuf], 152, NEW_FILE)
	    call fprintf (fd, "Now is the time for all good people\n")
	    call fprintf (fd, "to come\n")
	    call fprintf (fd, "\n")
	    call fprintf (fd, "to the aid of their\n")
	    call fprintf (fd, "				party\n")
	    call fprintf (fd, "\n")
	    call close (fd)
	    fd = stropen (Memc[strbuf], 152, READ_ONLY)
	} else {
	    call close (fd); fd = NULL
	    call mfree (strbuf, TY_CHAR)
	}
end
