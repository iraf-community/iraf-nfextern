include	<fset.h>
include	<imset.h>
include	<acecat.h>
include	"acedetect.h"
include	"filter.h"


# ACE_OMULTICAT -- Open multiple catalog.

procedure ace_omulticat (outcat, cat, catdef, acestruct, nim)

char	outcat[ARB]		#I Output catalog name
pointer	cat			#O Catalog
char	catdef[ARB]		#I Catalog definition file
char	acestruct[ARB]		#I ACE structure definition file
int	nim			#I Number of images

errchk	catopen, catdefine

begin
	if (outcat[1] == EOS)
	    return

	call catopen (cat, "", "", "", "", NULL, 1)
	if (catdef[1] == EOS)
	    call catdefine (cat, NULL, NULL, "acelib$catdef.dat", acestruct,
	        nim)
	else
	    call catdefine (cat, NULL, NULL, catdef, acestruct, nim)
end


# ACE_AMULTICAT -- Add a single catalog to a multicatalog.
#
# Currently this requires explicit knowledge of the object data structures.

procedure ace_amulticat (cat1, ncat, cat)

pointer	cat1			#I Input single catalog
pointer	ncat			#I Catalog index
pointer	cat			#I Output multicatalog

int	i, reclen, reclen1
pointer	im, rec, rec1
pointer	sp, key, image, objmask

pointer	immap()
errchk	calloc, malloc, immap, im2im, catwcs, catrec

begin
	if (cat == NULL)
	    return

	call smark (sp)
	call salloc (key, 8, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (objmask, SZ_FNAME, TY_CHAR)

	iferr (call catgets (cat1, "image", Memc[image], SZ_FNAME))
	    Memc[image] = EOS
	iferr (call catgets (cat1, "objmask", Memc[objmask], SZ_FNAME))
	    Memc[objmask] = EOS

	if (ncat == 0) {
	    if (Memc[image] != EOS) {
		im = immap (Memc[image], READ_ONLY, 0)
		call im2im (im, CAT_OHDR(cat))
		call catwcs (cat, im)
		call imunmap (im)
		call catputs (cat, "image", Memc[image])
	    }
	    if (Memc[objmask] != EOS)
		call catputs (cat, "objmask", Memc[objmask])
	} else {
	    call sprintf (Memc[key], 8, "IMAGE%d")
	        call pargi (ncat)
	    if (Memc[image] != EOS)
		call imastr (CAT_OHDR(cat), Memc[key], Memc[image])
	}

	reclen = CAT_RECLEN(cat)
	reclen1 = CAT_RECLEN(cat1)

	# Allocate records.
	if (CAT_NRECS(cat) == 0) {
	    rec = NULL; call catrec (cat, rec)
	    CAT_NRECS(cat) = CAT_NRECS(cat1)
	    call calloc (CAT_RECS(cat), CAT_NRECS(cat), TY_POINTER)
	    do i = 1, CAT_NRECS(cat) {
		rec1 = CAT_REC(cat1,i)
		if (rec1 == NULL)
		    next
		call malloc (CAT_REC(cat,i), reclen, TY_STRUCT)
		call amovi (Memi[rec], Memi[CAT_REC(cat,i)], reclen)
	    }
	}
	
	# Copy fields.
	#
	# A future extension is to convert pixel coordinates from one
	# image to another so that the single WCS is valid.  This
	# needs to be done if the registration of the object mask is
	# allowed.

	do i = 1, CAT_NRECS(cat) {
	    rec1 = CAT_REC(cat1,i)
	    if (rec1 == NULL)
	        next
	    rec = CAT_REC(cat,i)
	    call amovi (Memi[rec1], Memi[rec+ncat*reclen1], reclen1)
	}

	call sfree (sp)
end


# ACE_CMULTICAT -- Write out and close multiple catalog.

procedure ace_cmulticat (par, cat, nim, outcat, catdef, acestruct, logfile)

pointer	par			#I Parameters
pointer	cat			#I Catalog
int	nim			#I Number of images
char	outcat[ARB]		#I Output catalog name
char	catdef[ARB]		#I Output catalog definitions
char	acestruct[ARB]		#I ACE structure definition file
char	logfile[ARB]		#I Output log file

int	logfd, locpr(), open()
extern	acefunc()

errchk	catopen, catcreate, open

begin
	if (cat == NULL)
	    return

	call catopen (cat, "", outcat, catdef, acestruct, locpr(acefunc), nim)
	call catputs (cat, "catalog", outcat)

	# Log file.
	if (logfile[1] != EOS) {
	    logfd = open (logfile, APPEND, TEXT_FILE)
	    call fseti (logfd, F_FLUSHNL, YES)
	    call fprintf (logfd,
		"  Write catalog: catalog = %s\n")
		call pargstr (outcat)
	    call close (logfd)
	}

	call catcreate (cat)
	if (PAR_FLT(par) == NULL)
	    call catwrecs (cat, "", PAR_NMAXREC(par))
	else
	    call catwrecs (cat, FLT_FILTER(PAR_FLT(par)), PAR_NMAXREC(par))

	call catclose (cat, NO)
end
