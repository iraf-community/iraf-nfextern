include	<mach.h>
include	"starfocus.h"

define	HELP		"nmisc$src/starfocus.key"
define	PROMPT		"Options"


# STFFOCUS -- Stellar focusing and PSF measuring main routine.
#
# This version takes text input and does not show profiles.

procedure t_stffocus ()

int	list		# List of images
pointer	fvals		# Focus values
int	logfd		# Log file descriptor

real	wx, wy, f, w, m, e, p
int	i, id, fd
int	nsfd, nimages, nstars, ngraph, nmark
pointer	sp, sf, image, rg, mark
pointer	sfds, sfd

int	clpopnu(), clgfil()
int	nowhite(), open(), fscan(), nscan() rng_index()
pointer	rng_open()
errchk	open
errchk	stf_find, stf_bkgd, stf_profile, stf_widths, stf_fwhms, stf_radius
errchk	stf_organize, stf_graph, stf_display

begin
	call smark (sp)
	call salloc (sf, SF, TY_STRUCT)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (fvals, SZ_LINE, TY_CHAR)

	call aclri (Memi[sf], SF)

	# Set task parameters.
	list = clpopnu ("input")
	call clgstr ("focus", Memc[fvals], SZ_LINE)

	call strcpy ("RR", SF_WTYPE(sf), SF_SZWTYPE)
	SF_OVRPLT(sf) = NO
#	SF_NCOLS(sf) = INDEFI
#	SF_NLINES(sf) = INDEFI
SF_NCOLS(sf) = 1000
SF_NLINES(sf) = 1000

	if (nowhite (Memc[fvals], Memc[fvals], SZ_LINE) != 0) {
	    iferr (rg = rng_open (Memc[fvals], -MAX_REAL, MAX_REAL, 1.))
		rg = NULL
	} else
	    rg = NULL

	# Accumulate the psf/focus data.
	mark = NULL
	nstars = 0
	nmark = 0
	ngraph = 0
	nimages = 0
	nsfd = 0
	while (clgfil (list, Memc[image], SZ_FNAME) != EOF) {
	    fd = open (Memc[image], READ_ONLY, TEXT_FILE)
	    nimages = nimages + 1

	    if (Memc[fvals] == EOS)
	        f = INDEF
	    else if (rg != NULL) {
	        if (rng_index (rg, nimages, f) == EOF)
		    call error (1, "Focus list ended prematurely")
	    } else
	        f = INDEF

	    # Accumulate objects.
	    while (fscan (fd) != EOF) {
	        call gargi (id)
	        call gargi (id)
		call gargr (wx)
		call gargr (wy)
		call gargr (w)
		call gargr (m)
		call gargr (e)
		call gargr (p)
		if (nscan() != 8)
		    next
		if (IS_INDEFI(id)||IS_INDEFR(wx)||IS_INDEFR(wy)||IS_INDEFR(w)||
		    IS_INDEFR(m)||IS_INDEFR(e)||IS_INDEFR(p))
		    next

		# Allocate space for new SFD structure.
		if (nsfd == 0)
		    call malloc (sfds, 10, TY_POINTER)
		else if (mod (nsfd, 10) == 0)
		    call realloc (sfds, nsfd+10, TY_POINTER)
		call calloc (sfd, SFD, TY_STRUCT)
		Memi[sfds+nsfd] = sfd
		nsfd = nsfd + 1

		# Set measurement values.
		call strcpy (Memc[image], SFD_IMAGE(sfd), SF_SZFNAME)
		SFD_F(sfd) = f
		SFD_ID(sfd) = id
		SFD_X(sfd) = wx
		SFD_Y(sfd) = wy
		SFD_W(sfd) = w
		SFD_M(sfd) = m
		SFD_E(sfd) = e
		SFD_PA(sfd) = p
	    }
	    call close (fd)
	}

	# Check for no data.
	if (nsfd == 0)
	    call error (1, "No input data")

	# Organize the objects, graph the data, and log the results.
	if (nsfd > 1) {
	    call stf_organize (sf, sfds, nsfd)
	    call stf_graph (sf)
	}
	call stf_log (sf, STDOUT)
	call clgstr ("logfile", Memc[image], SZ_FNAME)
	ifnoerr (logfd = open (Memc[image], APPEND, TEXT_FILE)) {
	    call stf_log (sf, logfd)
	    call close (logfd)
	}

	# Finish up
	call rng_close (rg)
	call clpcls (list)
	call stf_free (sf)
	do i = 1, SF_NSFD(sf) {
	    sfd = SF_SFD(sf,i)
	    if (SFD_ASI1(sfd) != NULL)
		call asifree (SFD_ASI1(sfd))
	    if (SFD_ASI2(sfd) != NULL)
		call asifree (SFD_ASI2(sfd))
	    call mfree (sfd, TY_STRUCT)
	}
	call mfree (SF_SFDS(sf), TY_POINTER)
	call mfree (mark, TY_REAL)
	call sfree (sp)
end
