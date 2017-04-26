include	<error.h>
include	<fset.h>
include	<mach.h>
include	<math.h>
include	<imhdr.h>
include	<acecat.h>
include	"acematch.h"

define	STRUCTDEF	"acesrc$acematch.h"
define	DEBUG		0
define	SZ_CMD		(4*SZ_LINE)

procedure t_acegeomap ()

pointer	icats			# List of input catalogs
pointer	ocats			# List of output catalogs
pointer	iwcs			# List of input WCS
pointer	catdef			# Catalog definitions
pointer	filter			# Catalog filter
bool	all			# Do all as one WCS?
pointer	fitgeom			# Fit geometry
real	reject			# Rejection sigma
real	rms			# RMS to accept (arcsec)
bool	interactive		# Interactive?
int	ngrid			# Number of constraining grid points
pointer	logs			# Logfiles
bool	verbose			# Verbose output?

int	i, nalloc, ncats, nfit, stat
double	scale, ra, dec
pointer	sp, icat, ocat, wcs, wcs1, fitfile, logfd, str
pointer	icats1, ocats1, iwcs1, cat, mw, mwa, mwg, im, ptr

bool	clgetb(), streq()
int	clgeti()
int	afn_cl(), afn_opn(), afn_opno(), afn_len(), afn_gfn()
int	xt_extns(), open(), catacc()
double	clgetd()
pointer	immap()
errchk	afn_cl, afn_opn, afn_opno, xtextns, catopen, open, immap
errchk	acm_mw, acm_gcat1, acm_geomap, acm_ccmap_cat

begin
	call smark (sp)
	call salloc (icat, SZ_FNAME, TY_CHAR)
	call salloc (ocat, SZ_FNAME, TY_CHAR)
	call salloc (wcs, SZ_FNAME, TY_CHAR)
	call salloc (wcs1, SZ_FNAME, TY_CHAR)
	call salloc (catdef, SZ_FNAME, TY_CHAR)
	call salloc (filter, SZ_LINE, TY_CHAR)
	call salloc (fitgeom, SZ_FNAME, TY_CHAR)
	call salloc (fitfile, SZ_FNAME, TY_CHAR)
	call salloc (logfd, 2, TY_INT)
	call salloc (str, SZ_LINE, TY_CHAR)

	call mktemp ("tmp$iraf", Memc[fitfile], SZ_FNAME)

	# Get task parameters.
	icats = afn_cl ("input", "catalog", NULL)
	ocats = afn_cl ("output", "catalog", icats)
	iwcs = afn_cl ("wcs", "image", icats)
	call clgstr ("catdef", Memc[catdef], SZ_LINE)
	call clgstr ("filter", Memc[filter], SZ_LINE)
	all = clgetb ("all")
	call clgstr ("fitgeometry", Memc[fitgeom], SZ_FNAME)
	interactive = clgetb ("interactive")
	reject = clgetd ("reject")
	rms = clgetd ("rms")
	ngrid = clgeti ("ngrid")
	logs = afn_cl ("logfiles", "file", NULL)
	verbose = clgetb ("verbose")

	# Set logfiles.
	call aclri (Memi[logfd], 2)
	if (verbose || interactive) {
	    Memi[logfd] = open ("STDOUT", APPEND, TEXT_FILE)
	    call fseti (Memi[logfd], F_FLUSHNL, YES)
	    call sysid (Memc[str], SZ_LINE)
	    call fprintf (Memi[logfd], "ACEGEOMAP: %s\n")
	        call pargstr (Memc[str])
	}

	# Check lists.
	ncats = afn_len (icats)
	i = afn_len (ocats)
	if (i > 0 && i != ncats)
	    call error (1, "Input and output catalog lists don't match")
	i = afn_len (iwcs)
	if (i > 1 && i != ncats)
	    call error (1, "WCS images don't match input catalogs")

	# Process catalogs.
	while (afn_gfn (icats, Memc[icat], SZ_FNAME) != EOF) {
	    if (afn_gfn (ocats, Memc[ocat], SZ_FNAME) == EOF)
	        Memc[ocat] = EOS
	    stat = afn_gfn (iwcs, Memc[wcs], SZ_FNAME)

	    iferr {
		cat = NULL; mw = NULL; mwa = NULL

		# Loop through catalogs to be done together.
		# All extensions in an input catalog are done together.
		# With the all flag the icat list is also done here.

		ncats = 0; nalloc = 0
		repeat {
		    if (ncats > 1) {
		        stat = afn_gfn (icats, Memc[icat], SZ_FNAME)
		        stat = afn_gfn (ocats, Memc[ocat], SZ_FNAME)
		        stat = afn_gfn (iwcs, Memc[wcs], SZ_FNAME)
		    }

		    # Set associated files.
		    if (afn_gfn (logs, Memc[str], SZ_LINE) != EOF) {
			if (Memi[logfd+1] != NULL)
			    call close (Memi[logfd+1])
			Memi[logfd+1] = open (Memc[str], APPEND, TEXT_FILE)
			call sysid (Memc[str], SZ_LINE)
			call fprintf (Memi[logfd+1], "ACEGEOMAP: %s\n")
			    call pargstr (Memc[str])
		    }

		    # Expand MEF catalogs.
		    ptr = xt_extns (Memc[icat], "", "", "", "",
		        NO, YES, NO, NO, "", NO, stat)
		    icats1 = afn_opno (ptr, "catalog")
		    ocats1 = afn_opn (Memc[ocat], "catalog", icats1)
		    iwcs1 = afn_opn (Memc[wcs], "image", icats1)

		    # Loop through MEF extensions.
		    while (afn_gfn (icats1, Memc[icat], SZ_FNAME) != EOF) {
		        stat = afn_gfn (ocats1, Memc[ocat], SZ_FNAME)
		        stat = afn_gfn (iwcs1, Memc[wcs1], SZ_FNAME)

			# Check output catalog.
			if (Memc[ocat] != EOS && catacc (Memc[ocat]) == YES) {
			    call sprintf (Memc[str], SZ_LINE,
			        "Output catalog exists (%s)")
				call pargstr (Memc[ocat])
			    call error (1, Memc[str])
			}

			# Allocate or reallocate memory.
			if (nalloc == 0) {
			    if (all)
				nalloc = afn_len (icats) * afn_len (icats1)
			    else
				nalloc = afn_len (icats1)
			    call calloc (cat, nalloc, TY_POINTER)
			    call calloc (mw, nalloc, TY_POINTER)
			    call calloc (mwa, nalloc, TY_POINTER)
			} else if (ncats == nalloc) {
			    i = nalloc
			    nalloc = nalloc + afn_len (icats1)
			    call realloc (cat, nalloc, TY_POINTER)
			    call realloc (mw, nalloc, TY_POINTER)
			    call realloc (mwa, nalloc, TY_POINTER)
			    call aclri (Memi[cat+i], nalloc-i)
			    call aclri (Memi[mw+i], nalloc-i)
			    call aclri (Memi[mwa+i], nalloc-i)
			}

			# Accumulate the catalog.
			call catopen (Memi[cat+ncats], Memc[icat], Memc[ocat],
			    Memc[catdef], STRUCTDEF, NULL, 1)
			if (Memc[wcs] == EOS || streq (Memc[wcs], Memc[icat])) {
			    im = CAT_IHDR(Memi[cat+ncats])
			    call acm_mw (im, Memi[mw+ncats], Memi[mwa+ncats],
			        scale)
			} else {
			    iferr (im = immap (Memc[wcs1], READ_ONLY, 0))
			        im = immap (Memc[wcs], READ_ONLY, 0)
			    call acm_mw (im, Memi[mw+ncats], Memi[mwa+ncats],
			        scale)
			    ptr = CAT_IHDR(cat)
			    if (IM_NDIM(im) == 2) {
				call imputi (ptr, "crmin1", 1)
				call imputi (ptr, "crmax1", IM_LEN(im,1))
				call imputi (ptr, "crmin2", 1)
				call imputi (ptr, "crmax2", IM_LEN(im,2))
			    }
			    call imunmap (im)
			}
			call acm_gcat1 (Memi[cat+ncats], Memi[mw+ncats],
			    Memc[filter], Memi[logfd])
			call acm_geomap_data (Memi[cat+ncats], Memi[mw+ncats],
			    Memi[mwa+ncats], Memc[fitfile], nfit)
			ncats = ncats + 1
		    }

		    call afn_cls (iwcs1)
		    call afn_cls (ocats1)
		    call afn_cls (icats1)

		    # If not doing all input together we break this loop.
		    if (!all)
		        break
		}

		# Do the GEOMAP fitting.
		call acm_geomap (mwg, Memi[mw], Memc[fitfile], nfit,
		    "general", interactive, reject, rms, ra, dec, Memi[logfd])

		# Add grid of constraining points based on global adjustment.
		do i = 0, ncats-1
		    call acm_ccmap_cat (Memi[cat+i], Memi[mw+i],
			Memi[mwa+i], mwg, ngrid, Memc[filter],
			ra, dec, Memi[logfd])

		# Write the revised tangent point.
		call clputd ("ra", ra)
		call clputd ("dec", dec)
	    } then
	        call erract (EA_WARN)

	    # Free catalogs and MWCS pointers.
	    if (mwg != NULL)
		call mw_close (mwg)
	    do i = 0, ncats-1 {
		call catclose (Memi[cat+i], NO)
		call mw_close (Memi[mw+i])
		call mw_close (Memi[mwa+i])
	    }
	    call mfree (cat, TY_POINTER)
	    call mfree (mw, TY_POINTER)
	    call mfree (mwa, TY_POINTER)
	}

	# Finish up.
	do i = 1, 2 {
	    if (Memi[logfd+i-1] != NULL)
	        call close (Memi[logfd+i-1])
	}
	call afn_cls(logs)
	call afn_cls (iwcs)
	call afn_cls (ocats)
	call afn_cls (icats)
	call sfree (sp)
end


procedure acm_gcat1 (cat, mw, filter, logfd)

pointer	cat				#I Catalog pointer
pointer	mw				#I MWCS
char	filter[ARB]			#I Catalog filter
int	logfd[2]			#I Log file descriptors

int	i
pointer	ctlw, ctwl, rec

pointer	mw_sctran()
errchk	mw_sctran, catrrecs

begin
	# Read catalogs and set fields using the WCS.
	call catrrecs (cat, filter, -1)
	ctlw = mw_sctran (mw, "logical", "world", 3)
	ctwl = mw_sctran (mw, "world", "logical", 3)
	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    if (rec == NULL)
	        next
	    if ((IS_INDEFD(ACM_X(rec))||IS_INDEFD(ACM_Y(rec))) &&
		(IS_INDEFD(ACM_RA(rec))||IS_INDEFD(ACM_DEC(rec))))
		next
	    if (IS_INDEFD(ACM_X(rec))||IS_INDEFD(ACM_Y(rec))) {
		call mw_c2trand (ctwl, ACM_RA(rec)*15D0, ACM_DEC(rec),
		    ACM_X(rec), ACM_Y(rec))
	    } else if (IS_INDEFD(ACM_RA(rec))||IS_INDEFD(ACM_DEC(rec))) {
		call mw_c2trand (ctlw, ACM_X(rec), ACM_Y(rec),
		    ACM_RA(rec), ACM_DEC(rec))
		ACM_RA(rec) = ACM_RA(rec) / 15D0
	    }
	    ACM_PTR(rec) = NULL
	}
	call mw_ctfree (ctlw)
	call mw_ctfree (ctwl)
end


procedure acm_geomap_data (cat, mw, mwa, fitfile, nfit)

pointer	cat			#I Reference catalogs
pointer	mw			#I WCS
pointer	mwa			#I WCS for world <-> astrometry
char	fitfile[ARB]		#O Filename for fitting data
int	nfit			#U Number of objects in fitting data

int	i, fd
double	dra1, ddec1, dra2, ddec2, dra3, ddec3
pointer	rec, ctlw, ctwa

int	open()
pointer	mw_sctran()
errchk	open

begin
	fd = open (fitfile, APPEND, TEXT_FILE)

	ctlw = mw_sctran (mw, "logical", "world", 3)
	ctwa = mw_sctran (mwa, "world", "physical", 3)
	do i = 1, CAT_NRECS(cat) {
	    rec = CAT_REC(cat,i)
	    call mw_c2trand (ctlw, ACM_X(rec), ACM_Y(rec), dra3, ddec3)
#call eprintf ("x,y->ra,dec: %g %g %.2H %.1h\n")
#call pargd (ACM_X(rec))
#call pargd (ACM_Y(rec))
#call pargd (dra1)
#call pargd (ddec1)
	    call mw_c2trand (ctwa, dra3, ddec3, dra1, ddec1)
#call eprintf ("ra,dec->xi,eta: %.2H %.1h %g %g\n")
#call pargd (dra3)
#call pargd (ddec3)
#call pargd (dra1)
#call pargd (ddec1)
	    call mw_c2trand (ctwa, ACM_RA(rec)*15D0, ACM_DEC(rec), dra2, ddec2)
#call eprintf ("ra,dec->xi,eta: %.2H %.1h %g %g\n")
#call pargd (ACM_RA(rec))
#call pargd (ACM_DEC(rec))
#call pargd (dra1)
#call pargd (ddec1)
	    call fprintf (fd, "%g %g %g %g\n")
		call pargd (3600. * dra1)
		call pargd (3600. * ddec1)
		call pargd (3600. * dra2)
		call pargd (3600. * ddec2)
	    nfit = nfit + 1
	}
	call mw_ctfree (ctlw)
	call mw_ctfree (ctwa)

	call close (fd)
end


procedure acm_geomap (mw, mwref, fitfile, nfit, fitgeom, interactive,
	reject, rms, ra, dec, logfd)

pointer	mw			#O MWCS mapping
pointer	mwref			#I Reference MWCS for tangent point
char	fitfile[ARB]		#I File containing fitting data
int	nfit			#I Number of objects in fitting data
char	fitgeom[ARB]		#I Fit geometry
bool	interactive		#I Interactive?
real	reject 			#I sigma rejection
real	rms			#I RMS to accept (arcsec)
double	ra, dec			#O Revised tangent point
int	logfd[2]		#I Log file descriptors

int	i, fd
double	results[8], r[2], w[2], cd[2,2]
pointer	sp, db, graphics, cursor, cmd

int	open(), stropen(), strdic(), fscan(), nscan()
pointer	mw_open()
errchk	open

begin
	call smark (sp)
	call salloc (db, SZ_FNAME, TY_CHAR)
	call salloc (graphics, SZ_FNAME, TY_CHAR)
	call salloc (cursor, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_CMD, TY_CHAR)

	# Get interactive graphics parameters.
	call clgstr ("graphics", Memc[graphics], SZ_LINE)
	call clgstr ("cursor", Memc[cursor], SZ_LINE)

	# Temporary database.
	call mktemp ("tmp$iraf", Memc[db], SZ_FNAME)

	# Generate command.
	fd = stropen (Memc[cmd], SZ_CMD, NEW_FILE)
	call fprintf (fd,
	    "geomap input=%s database=%s transforms='' results=''")
	    call pargstr (fitfile)
	    call pargstr (Memc[db])
	call fprintf (fd, " xmin=INDEF xmax=INDEF ymin=INDEF ymax=INDEF")
	call fprintf (fd, " fitgeom=%s func=polynomial")
	    if (nfit > 1)
		call pargstr (fitgeom)
	    else
		call pargstr ("shift")
	call fprintf (fd, " xxo=2 xyo=2 xxt=half yxo=2 yyo=2 yxt=half")
	call fprintf (fd, " reject=%g maxiter=%d calc=double verb-")
	    call pargr (reject)	
	    if (reject > 0.1)
		call pargi (3)	
	    else
		call pargi (0)	
	call fprintf (fd, " inter=%b graphics=%s cursor=\"%s\"")
	    call pargb (interactive)
	    call pargstr (Memc[graphics])
	    call pargstr (Memc[cursor])
	if (Memc[cursor] != EOS)
	    call fprintf (fd, " > dev$null")
	call close (fd)

	# Run GEOMAP.
	call clcmdw (Memc[cmd])

	# Remove fit file.
	call delete (fitfile)

	# Extract linear transformations terms.
	fd = open (Memc[db], READ_ONLY, TEXT_FILE)
	while (fscan (fd) != EOF) {
	    call gargwrd (Memc[cmd], SZ_CMD)
	    if (nscan() != 1)
		next
	    i = strdic (Memc[cmd], Memc[cmd], SZ_CMD,
		"|xshift|yshift|xmag|ymag|xrotation|yrotation|xrms|yrms|")
	    if (i == 0)
		next
	    call gargd (results[i])
	    if (i == 5 || i == 6)
		if (results[i] > 180.)
		    results[i] = results[i] - 360.
	}
	call close (fd)
	call delete (Memc[db])

	# Compute new tangent point.
	call mw_gwtermd (mwref, r, w, cd, 2)
	call sldtps (DEGTORAD(results[1]/3600.), DEGTORAD(results[2]/3600.),
	    DEGTORAD(w[1]), DEGTORAD(w[2]), r[1], r[2])
	r[1] = RADTODEG(r[1])
	r[2] = RADTODEG(r[2])

	# Provide output.
	ra = r[1] / 15D0
	dec = r[2]
	do i = 1, 2 {
	    if (logfd[i] == NULL)
		next
	    call fprintf (logfd[i], "      input number of coordinates = %d\n")
		call pargi (nfit)
	    call fprintf (logfd[i], "      old tangent point = (%.2H, %.1h)\n")
		call pargd (w[1])
		call pargd (w[2])
	    call fprintf (logfd[i], "      new tangent point = (%.2H, %.1h)\n")
		call pargd (r[1])
		call pargd (r[2])
	    call fprintf (logfd[i],
	        "      tangent point shift = (%.2f, %.2f) arcsec\n")
		call pargd (results[1])
		call pargd (results[2])
	    call fprintf (logfd[i],
	        "      fractional scale change = (%.3f, %.3f)\n")
		call pargd (results[3])
		call pargd (results[4])
	    call fprintf (logfd[i],
	        "      axis rotation = (%.3f, %.3f) degrees\n")
		call pargd (results[5])
		call pargd (results[6])
	    call fprintf (logfd[i], "      rms = (%.3f, %.3f) arcsec\n")
		call pargd (results[7])
		call pargd (results[8])
	}

	# Set transformation: uncorrected astrometric -> corrected astrometric.
	r[1] = 0.; r[2] = 0.
	w[1] = results[1] / 3600.; w[2] = results[2] / 3600.
	cd[1,1] = results[3] * cos (DEGTORAD(results[5]))
	cd[2,1] = results[4] * sin (DEGTORAD(results[6]))
	cd[1,2] = -results[3] * sin (DEGTORAD(results[5]))
	cd[2,2] = results[4] * cos (DEGTORAD(results[6]))

	mw = mw_open (NULL, 2)
	call mw_newsystem (mw, "world", 2)
	call mw_swtype (mw, 1, 1, "linear", "")
	call mw_swtype (mw, 2, 1, "linear", "")
	call mw_swtermd (mw, r, w, cd, 2)

	# If the result doesn't satisfy RMS requirement return with an error.
	if (!interactive && rms < max (results[7], results[8])) {
	    call sprintf (Memc[cmd], SZ_CMD,
		"RMS of fit is too large: %.3f > %.3f")
		call pargd (max (results[7], results[8]))
		call pargr (rms)
	    call error (1, Memc[cmd])
	}

	call sfree (sp)
end


procedure acm_ccmap_cat (cat, mw, mwa, mwg, ngrid, filter, ra, dec, logfd)

pointer	cat			#I Catalogs
pointer	mw			#I Full uncorrected WCS
pointer	mwa			#I World <-> Astrometry transformation
pointer	mwg			#I Geomap transformation
int	ngrid			#I Number of constraining grid points
char	filter[ARB]		#I Catalog filter
double	ra, dec			#I Revised tangent point for output catalog
int	logfd[2]		#I Log file descriptors

int	i, j, row, nxgrid, nygrid
double	crmin1, crmax1, crmin2, crmax2, x, y, r, d
pointer	hdr, ctlw, ctwa, ctaw, ctaa, recs, rec
pointer	sp, str

double	imgetd()
pointer	mw_sctran()
errchk	imgetd, mw_sctran, catcreate

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get output catalog name.  Use this to determine in an output
	# catalog will be created.

	call catgets (cat, "outcatalog", Memc[str], SZ_LINE)
	if (Memc[str] == EOS) {
	    call sfree (sp)
	    return
	}

	# Create the output catalog.
	do i = 1, 2 {
	    if (logfd[i] == NULL)
		next
	    call fprintf (logfd[i], "    writing catalog %s\n")
	        call pargstr (Memc[str])
	}
	call catcreate (cat)

	# Set catalog to point to input catalog.
	call catgets (cat, "incatalog", Memc[str], SZ_LINE)
	call imastr (CAT_OHDR(cat), "catalog", Memc[str])

	# Update the RA and DEC in the output header.
	call sprintf (Memc[str], SZ_LINE, "%.2h")
	    call pargd (ra)
	call impstr (CAT_OHDR(cat), "RA", Memc[str])
	call sprintf (Memc[str], SZ_LINE, "%.2h")
	    call pargd (dec)
	call impstr (CAT_OHDR(cat), "DEC", Memc[str])

	# Copy the records if desired.
	if (ngrid >= 0) {
	    call catrrecs (cat, filter, -1)
	    recs = CAT_RECS(cat)
	    do row = 0, CAT_NRECS(cat)-1
		call catwrec (cat, Memi[recs+row], row+1)
	} else
	    row = 0

	# Return if there are no grid points.
	if (ngrid == 0) {
	    call sfree (sp)
	    return
	}

	hdr = CAT_IHDR(cat)
	iferr {
	    crmin1 = imgetd (hdr, "crmin1")
	    crmax1 = imgetd (hdr, "crmax1")
	    crmin2 = imgetd (hdr, "crmin2")
	    crmax2 = imgetd (hdr, "crmax2")
	} then
	    call error (1, "Undefined range for grid")

	r = (crmax2 - crmin2) / (crmax1 - crmin1)
	nxgrid = max (3, nint (sqrt (abs(ngrid) / r)))
	nygrid = max (3, nint (sqrt (abs(ngrid) * r)))

	# Set WCS to apply GEOMAP transformation.
	ctlw = mw_sctran (mw, "logical", "world", 3)
	ctwa = mw_sctran (mwa, "world", "physical", 3)
	ctaw = mw_sctran (mwa, "physical", "world", 3)
	ctaa = mw_sctran (mwg, "physical", "world", 3)
	
	# Create output record structure.
	call malloc (rec, CAT_RECLEN(cat), TY_STRUCT)

	# Create grid entries.
	do j = 1, nygrid {
	    y = nint (crmin2 + (j - 1) * (crmax2 - crmin2) / (nygrid - 1.))
	    do i = 1, nxgrid {
	        x = nint (crmin1 + (i - 1) * (crmax1 - crmin1) / (nxgrid - 1.))

		call mw_c2trand (ctlw, x, y, r, d)
		call mw_c2trand (ctwa, r, d, r, d)
		call mw_c2trand (ctaa, r, d, r, d)
		call mw_c2trand (ctaw, r, d, r, d)

		ACM_X(rec) = x
		ACM_Y(rec) = y
		ACM_RA(rec) = r / 15.
		ACM_DEC(rec) = d
		ACM_MREF(rec) = INDEFR
		ACM_MAG(rec) = INDEFR
		ACM_A(rec) = INDEFR
		ACM_B(rec) = INDEFR
		call strcpy ("-", ACM_FLAGS(rec), ARB)
		row = row + 1
		call catwrec (cat, rec, row)
	    }
	}

	call mfree (rec, TY_STRUCT)
	call mw_ctfree (ctaa)
	call mw_ctfree (ctaw)
	call mw_ctfree (ctwa)
	call mw_ctfree (ctlw)
	call sfree (sp)
end
