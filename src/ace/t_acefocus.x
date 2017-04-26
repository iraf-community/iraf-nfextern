include	<mach.h>
include	<acecat.h>
include	"acefocus.h"
include	"stf/starfocus.h"

define	HELP	"acesrc$acefocus.key"


# ACEFOCUS -- Focusing routine using ACE catalogs.
#
# This derived from the STARFOCUS/PSFMEASURE tasks with input derived from
# catalogs and the profile measuring not used.

procedure t_acefocus ()

int	list		# List of images or catalogs
pointer	fvals		# Focus values
int	logfd		# List of log file descriptors
real	match		# Matching distance (arcsec)
bool	interactive	# Interactive graphics?

real	f
int	i, ncat, list1, ltype
int	nsfd, ncats, nstars, ngraph, nmark
real	xmin, xmax, ymin, ymax, crmin1, crmax1, crmin2, crmax2, crpix1, crpix2
pointer	sp, sf, catname, catdef, filter, structdef, str
pointer	cat, rec, sfds, sfd, rg, mark

bool	clgetb()
int	xt_extns(), imtopenp(), imtgetim(), imtlen(), clpopnu(), clgfil()
int	nowhite(), open(), rng_index(), locpr()
real	clgetr(), imgetr()
pointer	rng_open(), immap()
errchk	open, xt_extns, immap
errchk	stf_find, stf_bkgd, stf_profile, stf_widths, stf_fwhms, stf_radius
errchk	stf_organize, stf_graph, stf_display
extern	f_acefocus()

begin
	call smark (sp)
	call salloc (sf, SF, TY_STRUCT)
	call salloc (catname, SZ_FNAME, TY_CHAR)
	call salloc (catdef, SZ_LINE, TY_CHAR)
	call salloc (filter, SZ_LINE, TY_CHAR)
	call salloc (fvals, SZ_LINE, TY_CHAR)
	call salloc (structdef, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	call aclri (Memi[sf], SF)
	call strcpy (HELP, SF_HELP(sf), SF_SZFNAME)

	# Set task parameters.
	list = imtopenp ("input")
	call clgstr ("catdef", Memc[catdef], SZ_LINE)
	call clgstr ("filter", Memc[filter], SZ_LINE)
	call clgstr ("focus", Memc[fvals], SZ_LINE)
	match = clgetr ("match")
	SF_RSIG(sf) = clgetr ("rsig")
	SF_FSIG(sf) = clgetr ("fsig")
	interactive = clgetb ("interactive")

	i = nowhite (Memc[catdef], Memc[str], SZ_LINE)
	if (Memc[str] == '!')
	     call strcpy (Memc[str], Memc[catdef], SZ_LINE)

	SF_WTYPE(sf) = EOS
	SF_OVRPLT(sf) = NO
	SF_SCALE(sf) = 1.

	rg = NULL
	if (nowhite (Memc[fvals], Memc[fvals], SZ_LINE) != 0) {
	    if (Memc[fvals] != '!') {
		iferr (rg = rng_open (Memc[fvals], -MAX_REAL, MAX_REAL, 1.))
		    ;
	    }
	}

	# Set structure definition.
	call sprintf (Memc[structdef], SZ_FNAME, "proc:%d")
	    call pargi (locpr(f_acefocus))

	# Accumulate the psf/focus data.
	xmin = MAX_REAL; xmax = -MAX_REAL
	ymin = MAX_REAL; ymax = -MAX_REAL
	mark = NULL
	nstars = 0
	nmark = 0
	ngraph = 0
	ncats = 0
	nsfd = 0
	for (ncats=1; imtgetim(list,Memc[str],SZ_LINE)!=EOF; ncat=ncat+1) {
	    list1 = xt_extns (Memc[str], "IMAGE", "", "", "", NO, YES, YES,
	        NO, "", NO, i)
	    ltype = 1
	    if (imtlen(list1) == 0) {
	        call imtclose (list1)
		list1 = xt_extns (Memc[str], "", "", "", "", NO, YES, YES,
		    NO, "", NO, i)
		ltype = 2
	    }
	    while (imtgetim (list1, Memc[catname], SZ_FNAME)  != EOF) {
		if (ltype == 1) {
	    	    cat = immap (Memc[catname], READ_ONLY, 0)
		    call imgstr (cat, "CATALOG", Memc[catname], SZ_FNAME)
		    call imunmap (cat)
		}
		cat = NULL
		if (Memc[catdef] != '!')
		    call catopen (cat, Memc[catname], "", Memc[catdef],
			Memc[structdef], NULL, 1)
		else
		    call catopen (cat, Memc[catname], "", "",
			Memc[structdef], NULL, 1)

		iferr (crpix1 = imgetr (CAT_IHDR(cat), "CRPIX1"))
		    crpix1 = 0.
		iferr (crpix2 = imgetr (CAT_IHDR(cat), "CRPIX2"))
		    crpix2 = 0.
		crmin1 = imgetr (CAT_IHDR(cat), "CRMIN1")
		crmin2 = imgetr (CAT_IHDR(cat), "CRMIN2")
		crmax1 = imgetr (CAT_IHDR(cat), "CRMAX1")
		crmax2 = imgetr (CAT_IHDR(cat), "CRMAX2")
		xmin = min (xmin, crmin1-crpix1)
		xmax = max (xmax, crmax1-crpix1)
		ymin = min (ymin, crmin1-crpix1)
		ymax = max (ymax, crmax1-crpix1)

		if (Memc[fvals] == EOS)
		    f = ncat
		else if (Memc[fvals] == '!')
		    f = imgetr (CAT_IHDR(cat), Memc[fvals+1]) 
		else if (rg != NULL) {
		    if (rng_index (rg, ncats, f) == EOF)
			call error (1, "Focus list ended prematurely")
		} else
		    f = imgetr (CAT_IHDR(cat), Memc[fvals]) 

		if (Memc[catdef] != '!') {
		    call catrrecs (cat, Memc[filter], -1)

		    # Set label for size quantity.
		    if (SF_WTYPE(sf) == EOS)
			call strcpy (CAT_CNAME(cat,ID_SIZE), SF_WTYPE(sf),
			    SF_SZWTYPE)

		    # Accumulate objects.
		    do i = 1, CAT_NRECS(cat) {
			rec = CAT_REC(cat,i)
			if (rec == NULL)
			    next
			if (IS_INDEFR(RECR(rec,ID_SIZE)))
			    next
			if (IS_INDEFI(RECI(rec,ID_STARID)))
			    RECI(rec,ID_STARID) = 1
			if (IS_INDEFD(RECD(rec,ID_X)))
			    RECD(rec,ID_X) = 0.
			if (IS_INDEFD(RECD(rec,ID_Y)))
			    RECD(rec,ID_Y) = 0.
			if (IS_INDEFR(RECR(rec,ID_FLUX)))
			    RECR(rec,ID_FLUX) = 0.
			if (IS_INDEFR(RECR(rec,ID_ELLIP)))
			    RECR(rec,ID_ELLIP) = 0.
			if (IS_INDEFR(RECR(rec,ID_PA)))
			    RECR(rec,ID_PA) = 0.

			# Allocate space for new SFD structure.
			if (nsfd == 0)
			    call malloc (sfds, 10, TY_POINTER)
			else if (mod (nsfd, 10) == 0)
			    call realloc (sfds, nsfd+10, TY_POINTER)
			call calloc (sfd, SFD, TY_STRUCT)
			Memi[sfds+nsfd] = sfd
			nsfd = nsfd + 1

			# Set measurement values.
			iferr (call imgstr (CAT_IHDR(cat), "IMAGE",
			    SFD_IMAGE(sfd), SF_SZFNAME))
			    call strcpy (Memc[catname], SFD_IMAGE(sfd),
			        SF_SZFNAME)
			SFD_F(sfd) = f
			SFD_W(sfd) = RECR(rec,ID_SIZE)
			SFD_ID(sfd) = RECI(rec,ID_STARID)
			SFD_RA(sfd) = RECD(rec,ID_RA)
			SFD_DEC(sfd) = RECD(rec,ID_DEC)
			SFD_X(sfd) = RECD(rec,ID_X) - crpix1
			SFD_Y(sfd) = RECD(rec,ID_Y) - crpix2
			SFD_M(sfd) = RECR(rec,ID_FLUX)
			SFD_E(sfd) = RECR(rec,ID_ELLIP)
			SFD_PA(sfd) = RECR(rec,ID_PA)
		    }
		} else {
		    # Set label for size quantity.
		    if (SF_WTYPE(sf) == EOS)
			call strcpy (Memc[catdef+1], SF_WTYPE(sf), SF_SZWTYPE)

		    # Allocate space for new SFD structure.
		    if (nsfd == 0)
			call malloc (sfds, 10, TY_POINTER)
		    else if (mod (nsfd, 10) == 0)
			call realloc (sfds, nsfd+10, TY_POINTER)
		    call calloc (sfd, SFD, TY_STRUCT)
		    Memi[sfds+nsfd] = sfd
		    nsfd = nsfd + 1

		    # Set measurement values.
		    iferr (call imgstr (CAT_IHDR(cat), "IMAGE",
			SFD_IMAGE(sfd), SF_SZFNAME))
			call strcpy (Memc[catname], SFD_IMAGE(sfd),
			    SF_SZFNAME)
		    SFD_F(sfd) = f
		    SFD_W(sfd) = imgetr (CAT_IHDR(cat), SF_WTYPE(sf))
		    SFD_ID(sfd) = nsfd
		    SFD_RA(sfd) = INDEFD
		    SFD_DEC(sfd) = INDEFD
		    SFD_X(sfd) = (crmax1 + crmin1) / 2 - crpix1
		    SFD_Y(sfd) = (crmax2 + crmin2) / 2 - crpix2
		    SFD_M(sfd) = 1.
		    SFD_E(sfd) = 0.
		    SFD_PA(sfd) = 0.
		}
		call catclose (cat, NO)
	    }
	    call imtclose (list1)
	}
	call imtclose (list)

	# Check for no data.
	if (nsfd == 0)
	    call error (1, "No input data")

	# Adjust the X and Y values.
	xmin = xmin - 1; ymin = ymin - 1
	do i = 0, nsfd-1 {
	    sfd = Memi[sfds+i]
	    SFD_X(sfd) = SFD_X(sfd) - xmin
	    SFD_Y(sfd) = SFD_Y(sfd) - ymin
	}
	SF_NCOLS(sf) = xmax - xmin + 0.99
	SF_NLINES(sf) = ymax - ymin + 0.99
	SF_XF(sf) = (SF_NCOLS(sf) + 1) / 2.
	SF_YF(sf) = (SF_NLINES(sf) + 1) / 2.

	# Organize the objects, graph the data, and log the results.
	if (nsfd > 1) {
	    call stf_match (sfds, nsfd, match)
	    call stf_organize (sf, sfds, nsfd)
	    SF_RSIG(sf) = 0.; SF_FSIG(sf) = 0.
	    if (SF_NFOCUS(sf) > 1)
		call stf_graph (sf, interactive)
	}

	if (SF_NFOCUS(sf) > 1) {
	    # Log results.
	    list = clpopnu ("logfiles")
	    while (clgfil (list, Memc[str], SZ_LINE) != EOF) {
		ifnoerr (logfd = open (Memc[str], APPEND, TEXT_FILE)) {
		    call stf_log (sf, logfd)
		    call close (logfd)
		}
	    }
	    call clpcls (list)

	    # Update parameters.
	    call clputr ("bestfocus", SF_F(sf))
	    call clputr ("bestsize", SF_W(sf))
	} else {
	    sfd = Memi[sfds]
	    call clputr ("bestfocus", SFD_F(sfd))
	    call clputr ("bestsize", SF_W(sf))
	    call eprintf ("WARNING: All focus values the same (%.6g)\n")
	        call pargr (SFD_F(sfd))
	}

	# Finish up
	call rng_close (rg)
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
