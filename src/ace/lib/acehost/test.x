

procedure test (fd)

int	fd

int	stropen()
pointer	xqzrkc
errchk	malloc

begin
	if (fd == NULL) {
	    call malloc (xqzrkc, 152, TY_CHAR)
	    fd = stropen (Memc[xqzrkc], 152, NEW_FILE)
	    call fprintf (fd, "Now is the time for all good people\n")
	    call fprintf (fd, "to come\n")
	    call fprintf (fd, "\n")
	    call fprintf (fd, "to the aid of their\n")
	    call fprintf (fd, "				party\n")
	    call fprintf (fd, "\n")
	    call close (fd)
	    fd = stropen (Memc[xqzrkc], 152, READ_ONLY)
	} else {
	    call close (fd); fd = NULL
	    call mfree (xqzrkc, TY_CHAR)
	}
end
