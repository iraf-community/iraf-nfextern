include	<imset.h>


define	OFFTYPES	"|none|wcs|world|physical|"
define	FILE		0
define	NONE		1
define	WCS		2
define	WORLD		3
define	PHYSICAL	4

# GET_OFFSETS -- Get offsets.

procedure get_offsets (in, nimages, param, offsets)

pointer	in[nimages]		#I Input image pointers
int	nimages			#I Number of images
char	param[ARB]		#I Offset parameter string
int	offsets[2,nimages]	#O Offsets

int	i, j, fd, offtype, off
real	val
bool	flip, streq(), fp_equald()
pointer	sp, str, fname
pointer	pref, lref, wref, cd, ltm, coord, section
pointer	mw, ct, mw_openim(), mw_sctran(), immap()
int	open(), fscan(), nscan(), strlen(), strdic()
errchk	mw_openim, mw_gwtermd, mw_gltermd, mw_gaxmap
errchk	mw_sctran, mw_ctrand, open, immap

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (fname, SZ_LINE, TY_CHAR)
	call salloc (lref, 2, TY_DOUBLE)
	call salloc (wref, 2, TY_DOUBLE)
	call salloc (cd, 2*2, TY_DOUBLE)
	call salloc (coord, 2, TY_DOUBLE)

	call aclri (offsets, 2*nimages)

	# Parse the user offset string.  If "none" then there are no offsets.
	# If "world" or "wcs" then set the offsets based on the world WCS.
	# If "physical" then set the offsets based on the physical WCS.
	# If a file scan the offsets.

	call sscan (param)
	call gargwrd (Memc[str], SZ_LINE)
	if (nscan() == 0)
	    offtype = NONE
	else {
	    offtype = strdic (Memc[str], Memc[fname], SZ_LINE, OFFTYPES)
	    if (offtype > 0 && !streq (Memc[str], Memc[fname]))
		offtype = 0
	}
	if (offtype == 0)
	    offtype = FILE

	switch (offtype) {
	case NONE:
	    ;
	case WORLD, WCS:
	    mw = mw_openim (in[1])
	    call mw_gwtermd (mw, Memd[lref], Memd[wref], Memd[cd], 2)
	    ct = mw_sctran (mw, "world", "logical", 0)
	    call mw_ctrand (ct, Memd[wref], Memd[lref], 2)
	    call mw_close (mw)

	    do i = 2, nimages {
		mw = mw_openim (in[i])
		ct = mw_sctran (mw, "world", "logical", 0)
		call mw_ctrand (ct, Memd[wref], Memd[coord], 2)
		do j = 1, 2
		    offsets[j,i] = nint (Memd[lref+j-1] - Memd[coord+j-1])
		call mw_close (mw)
	    }
	case PHYSICAL:
	    call salloc (pref, 2, TY_DOUBLE)
	    call salloc (ltm, 4, TY_DOUBLE)
	    call salloc (section, SZ_FNAME, TY_CHAR)

	    mw = mw_openim (in[1])
	    call mw_gltermd (mw, Memd[ltm], Memd[coord], 2)
	    call mw_close (mw)
	    do i = 2, nimages {
		mw = mw_openim (in[i])
		call mw_gltermd (mw, Memd[cd], Memd[coord], 2)
		call strcpy ("[", Memc[section], SZ_FNAME)
		flip = false
		do j = 0, 3, 3 {
		    if (Memd[ltm+j] * Memd[cd+j] >= 0.)
			call strcat ("*,", Memc[section], SZ_FNAME)
		    else {
			call strcat ("-*,", Memc[section], SZ_FNAME)
			flip = true
		    }
		}
		Memc[section+strlen(Memc[section])-1] = ']'
		if (flip) {
		    call imstats (in[i], IM_IMAGENAME, Memc[fname], SZ_LINE)
		    call strcat (Memc[section], Memc[fname], SZ_LINE)
		    call imunmap (in[i])
		    in[i] = immap (Memc[fname], READ_ONLY, TY_CHAR) 
		    call mw_close (mw)
		    mw = mw_openim (in[i])
		    call mw_gltermd (mw, Memd[cd], Memd[coord], 2)
		    do j = 0, 3
			if (!fp_equald (Memd[ltm+j], Memd[cd+j]))
			    call error (1,
				"Cannot match physical coordinates")
		}
		call mw_close (mw)
	    }

	    mw = mw_openim (in[1])
	    ct = mw_sctran (mw, "logical", "physical", 0)
	    call mw_ctrand (ct, Memd[lref], Memd[pref], 2)
	    call mw_close (mw)
	    do i = 2, nimages {
		mw = mw_openim (in[i])
		ct = mw_sctran (mw, "physical", "logical", 0)
		call mw_ctrand (ct, Memd[pref], Memd[coord], 2)
		do j = 1, 2
		    offsets[j,i] = nint (Memd[lref+j-1] - Memd[coord+j-1])
		call mw_close (mw)
	    }
	case FILE:
	    fd = open (Memc[str], READ_ONLY, TEXT_FILE)
	    i = 1
	    while (fscan (fd) != EOF) {
		do j = 1, 2 {
		    call gargr (val)
		    offsets[j,i] = nint (val)
		}
		if (nscan() == 2)
		    i = i + 1
	    }
	    call close (fd)
	    if (i <= nimages)
		call error (1, "offset file incomplete")
	}

	# Adjust offsets to be positive.
	do j = 1, 2 {
	    off =  offsets[j,1]
	    do i = 2, nimages
		off = min (off, offsets[j,i])
	    do i = 1, nimages
		offsets[j,i] = offsets[j,i] - off
	}

	call sfree (sp)
end
