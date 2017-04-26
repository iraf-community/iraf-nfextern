

procedure foo (xqzrkc)

pointer	xqzrkc

int	fd, stropen()
errchk	malloc

begin
	call malloc (xqzrkc, 64, TY_CHAR)
	fd = stropen (Memc[xqzrkc], ARB, NEW_FILE)
	call fprintf (fd, "msg,s,h,""Hello World"",,,Message\n")
	call close (fd)
end
