include	<error.h>
include	<imhdr.h>
include	<imset.h>
include	<pmset.h>
include	"ace.h"


pointer procedure overlay (ovrly, im)

char	ovrly[ARB]		#I Overlay name
pointer	im			#I Reference image
pointer	ovr			#O Overlay pointer

int	i, j, nc, nl, val, flags
long	v[2]
pointer	sp, fname, pm, buf

int	nowhite(), andi()
bool	pm_linenotempty()
pointer	ods_pmmap(), imstati()

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	if (nowhite (ovrly, Memc[fname], SZ_FNAME) == 0) {
	    call sfree (sp)
	    return (NULL)
	}

	if (Memc[fname] == '!') {
	    iferr (call imgstr (im, Memc[fname+1], Memc[fname], SZ_FNAME)) {
		call sfree (sp)
		return (NULL)
	    }
	}

	iferr (ovr = ods_pmmap (Memc[fname], im)) {
	    call sfree (sp)
	    call erract (EA_WARN)
	    return (NULL)
	}

	nc = IM_LEN(ovr,1)
	nl = IM_LEN(ovr,2)
	pm = imstati (ovr, IM_PMDES)

	call salloc (buf, nc, TY_INT)

	v[1] = 1
	do i = 1, nl {
	    v[2] = i
	    if (!pm_linenotempty(pm, v))
		next
	    call pmglpi (pm, v, Memi[buf], 0, nc, 0)
	    do j = 0, nc-1 {
		val = Memi[buf+j]
		if (val == 0)
		    next
		flags = 0
		if (MBNDRY(val))
		    flags = flags + 4
		if (MBPFLAG(val))
		    flags = flags + 8
		if (MBP(val))
		    flags = flags + 16
		if (MSPLIT(val))
		    flags = flags + 32
		if (MDARK(val))
		    flags = flags + 64

		if (val < NUMSTART)
		    val = 1
		else if (MSPLIT(val)) {
		    if (MBP(val))
			val = 6
		    else
		        val = 7
		} else if (MBP(val))
		    val = 3
		else if (MBNDRY(val)) {
		    if (MBPFLAG(val))
			val = 4
		    else
			val = 5
		} else if (MDARK(val))
		    val = 8
		else
		    val = 2

		Memi[buf+j] = val
	    }
	    call pmplpi (pm, v, Memi[buf], 0, nc, PIX_SRC)
	}

	call sfree (sp)

	return (ovr)
end
