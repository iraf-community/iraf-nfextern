task	zztest

procedure zztest ()

char	files[SZ_FNAME]
int	err, imext, list, xt_extns(), imtgetim()
errchk	xt_extns

begin
	call clgstr ("files", files, SZ_FNAME)

	list = xt_extns (files, "", "", "", "", NO, YES, NO, NO, "",
	    err, imext)

	while (imtgetim (list, files, SZ_FNAME) != EOF) {
	    call printf ("%s\n")
	        call pargstr (files)
	}

	call imtclose (list)
end
