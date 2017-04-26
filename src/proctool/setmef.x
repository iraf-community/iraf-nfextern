include	<error.h>
include	<syserr.h>
include	<imhdr.h>
include	<imio.h>
include	"par.h"
include	"prc.h"
include	"pi.h"


# SETMEF -- Set information for an image or MEF.

procedure setmef (prc, input, list, listtype, sortval, pis, npi)

pointer	prc				#I Processing pointer
char	input[ARB]			#U Input to set
int	list				#I LIst
int	listtype			#I List type
double	sortval				#I Default sort value
pointer	pis				#U Processing image array
int	npi				#O Number of PI structures

int	i, j, err
bool	mef
pointer	par, in, im, stp, sym
pointer	sp, name, entry, image, extn

bool	streq()
int	errget(), stridxs()
pointer	immap(), stfind(), stenter(), sthead(), stnext()
errchk	immap, setimage, proc

begin
	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (entry, SZ_FNAME, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (extn, SZ_FNAME, TY_CHAR)

	stp = PRC_STP(prc)

	iferr {
	    # Initialize.
	    call malloc (pis, 16, TY_POINTER)
	    npi = 0

	    # Remove image extension.
	    call xt_imext (input, Memc[extn], SZ_FNAME)
	    if (Memc[extn] != EOS) {
	        call gstrmatch (input, Memc[extn], i, j)
		call strcpy (input, Memc[name], i-1)
		call strcat (input[j+1], Memc[name], SZ_FNAME)
		call strcpy (Memc[name], input, ARB)
	    } else
	        call strcpy (input, Memc[name], SZ_FNAME)

	    # Loop through input image or MEF extensions.
	    par = PRC_PAR(prc)
	    do i = 0, 1000 {
		in = NULL
		if (i == 0) {
		    call sprintf (Memc[image], SZ_FNAME, "%s")
			call pargstr (Memc[name])
		    Memc[extn] = EOS
		    mef = false
		} else {
		    if (stridxs ("[", Memc[name]) > 0)
		        break
		    call sprintf (Memc[extn], SZ_FNAME, "%d")
			call pargi (i)
		    call sprintf (Memc[image], SZ_FNAME, "%s[%s]")
			call pargstr (Memc[name])
			call pargstr (Memc[extn])
		    call sprintf (Memc[extn], SZ_FNAME, "im%d")
			call pargi (i)
		    mef = true
		}

		# We need to make the entry name different than the
		# image name to allow the same image to be in more than
		# one processing type list.
		call sprintf (Memc[entry], SZ_FNAME, "%s %d")
		    call pargstr (Memc[image])
		    call pargi (listtype)

		# Find previous entry.  If called with an extension
		# then we need to search.
		if (!mef && stridxs ("[", Memc[name]) > 0) {
		    for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
		        if (Memi[sym] != NULL) {
			    if (streq (PI_NAME(Memi[sym]), Memc[name]) &&
			        PI_LISTTYPE(Memi[sym]) == listtype)
			         break
			}
		    }
		} else
		    sym = stfind (stp, Memc[entry])

		if (sym == NULL) {
		    iferr (im = immap (Memc[image], READ_ONLY, 0)) {
			err = errget (PRC_STR(prc), SZ_LINE)
			switch (err) {
			case SYS_IKIOPEN:
			    if (i == 0)
				call error (err, PRC_STR(prc))
			    break
			case SYS_FXFRFEOF:
			    break
			case SYS_IKIEXTN:
			    next
			case SYS_FXFOPNOEXTNV:
			    call sprintf (Memc[image], SZ_FNAME, "%s[%d]")
				call pargstr (Memc[name])
				call pargi (i)
			    mef = true
			    im = immap (Memc[image], READ_ONLY, 0)
			default:
			    call error (err, PRC_STR(prc))
			}
		    }
		    in = im

		    sym = stenter (stp, Memc[entry], 1)
		    Memi[sym] = NULL

		    # Skip dataless primary image extensions.
		    if (IM_NDIM(in) == 0) {
			call imunmap (in)
			next
		    }

		    # Convert to an extension name.
		    if (i > 0) {
			ifnoerr (call imgstr (in, "extname", Memc[extn],
			    SZ_FNAME)) {
			    call sprintf (Memc[image], SZ_FNAME, "%s[%s]")
				call pargstr (Memc[name])
				call pargstr (Memc[extn])
			    call strcpy (Memc[image], IM_NAME(in), SZ_IMNAME)
			}
		    }

		    # Set image.
		    if (listtype == PRC_INPUT) {
		        if (PAR_TSEC(par) != EOS)
			    call imunmap (in)
			call setimage (prc, Memc[image], i,  Memc[extn],
			    PAR_TSEC(par), list, listtype, sortval, in,
			    Memi[sym])
		    } else
			call setimage (prc, Memc[image], i, Memc[extn],
			    "", list, listtype, sortval, in, Memi[sym])
		    call pi_unmap (Memi[sym])
		    if (Memi[sym] == NULL) {
		        if (mef)
			    next
			else
			    break
		    }
		} else if (Memi[sym] == NULL) {
		    if (i == 0)
		        next
		    else
		        break
		}

		# Increase the PI list if needed.
		if (npi > 0 && mod(npi,16) == 0)
		    call realloc (pis, npi+16, TY_POINTER)
		Memi[pis+npi] = Memi[sym]
		npi = npi + 1

		# Finish up.
		if (!mef)
		    break
	    }
	} then {
	    err = errget (PRC_STR(prc), SZ_LINE)
	    do j = 1, npi
	        call pi_free (Memi[pis])
	    call mfree (pis, TY_POINTER)
	    call sfree (sp)
	    call error (err, PRC_STR(prc))
	}

	call sfree (sp)
end
