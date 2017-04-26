include	<imhdr.h>
include	<error.h>
include	<mach.h>
include <pkg/gtools.h>
include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"
include	"sky.h"
include	"per.h"

define	DEBUG	false


# OST_IOPEN -- Open method for images.

procedure ost_iopen (prc, ost, ipi)

pointer	prc				#I Processing object
pointer	ost				#I Expression object
pointer	ipi				#I Input processing image

bool	noproc, debug
int	i, j, k, l, list, npi, exti, srt, prctype, listtype, err
int	listbpm, listobm, listo
real	ed, ecd
double	d, cd
pointer	cpi, stp, sym, ostbpm, ostobm, osto, pi, pis, bpm, obm, output, oname

bool	streq(), strne(), prc_exprb(), fp_equalr()
int	imtrgetim(), imtlen(), pi_compare(), stridxs(), errget()
pointer	ost_find(), sthead(), stnext()
errchk	prc_exprs, setmef, pi_map, prc_error, prc_exprb
extern	pi_compare

define	err_	10

begin
	# Check for images associated with the input.
	switch (OST_PRCTYPE(ost)) {
	case PRC_BPM:
	    cpi = PI_BPMPI(ipi)
	    if (cpi == NULL)
		call prc_error (prc, PRCERR_CALNF,
		    "Calibration not found for %s", PI_NAME(ipi), "")
	    PI_IPI(cpi) = ipi
	    OST_PI(ost) = cpi
	    call pi_map (cpi)
	    return
	case PRC_OBM:
	    cpi = PI_OBMPI(ipi)
	    if (cpi == NULL)
		call prc_error (prc, PRCERR_CALNF,
		    "Calibration not found for %s", PI_NAME(ipi), "")
	    PI_IPI(cpi) = ipi
	    OST_PI(ost) = cpi
	    call pi_map (cpi)
	    return
	}

	# Check indirect reference.
	if (OST_IEXPR(ost) == '(') {
	    call prc_exprs (prc, ipi, OST_IEXPR(ost), OST_STR(ost), OST_LENSTR)
	    call setmef (prc, OST_STR(ost), OST_LIST(ost), OST_PRCTYPE(ost),
	        INDEFD, pis, npi)
	    cpi = Memi[pis]
	    call mfree (pis, TY_STRUCT)
	    if (cpi == NULL)
		call prc_error (prc, PRCERR_CALNF,
		    "Calibration not found for %s", PI_NAME(ipi), "")
	    PI_IPI(cpi) = ipi
	    OST_PI(ost) = cpi
	    call pi_map (cpi)
	    return
	}

	# Initialize.
	noproc = false

	# Set list.
	listtype = OST_PRCTYPE(ost)
	list = OST_LIST(ost)
	if (list != NULL) {
	    if (imtlen(list) == 0)
		list = NULL
	}
	if (list == NULL) {
	    listtype = PRC_INPUT
	    sym = ost_find (PAR_OST(PRC_PAR(prc)), PRC_INPUT)
	    list = OST_LIST(sym)
	} else
	    sym = NULL

	# Read list if necessary.
	call malloc (oname, SZ_FNAME, TY_CHAR)
	if (OST_READ(ost) == NO) {
	    # Only set output for input list.
	    osto = NULL; listo = NULL
	    if (listtype == PRC_INPUT) {
	        osto = ost_find (PAR_OST(PRC_PAR(prc)), PRC_OUTPUT)
		if (osto != NULL) {
		    listo = OST_LIST(osto)
		    call malloc (output, SZ_FNAME, TY_CHAR)
		}
	    }

	    # Set BPM for all images unless BPM are specified as
	    # a list which must then apply only to the input.
	    ostbpm = NULL; listbpm = NULL
	    ostbpm = ost_find (PAR_OST(PRC_PAR(prc)), PRC_BPM)
	    if (ostbpm != NULL) {
		listbpm = OST_LIST(ostbpm)
		if (listbpm != NULL && listtype != PRC_INPUT) {
		    ostbpm = NULL
		    listbpm = NULL
		}
		if (ostbpm != NULL)
		    call malloc (bpm, SZ_FNAME, TY_CHAR)
	    }

	    # Set OBM for all images unless OBM are specified as
	    # a list which must then apply only to the input.
	    ostobm = NULL; listobm = NULL
	    ostobm = ost_find (PAR_OST(PRC_PAR(prc)), PRC_OBM)
	    if (ostobm != NULL) {
		listobm = OST_LIST(ostobm)
		if (listobm != NULL && listtype != PRC_INPUT) {
		    ostobm = NULL
		    listobm = NULL
		}
		if (ostobm != NULL)
		    call malloc (obm, SZ_FNAME, TY_CHAR)
	    }

	    # Enter images from the list(s).
	    for (i=1; imtrgetim(list,i,OST_STR(ost),OST_LENSTR)!=EOF; i=i+1) {
		iferr (call setmef (prc, OST_STR(ost), OST_LIST(ost), listtype,
		    double(i), pis, npi)) {
		    err = errget (PRC_STR(prc), SZ_LINE)
		    switch (PAR_ERRACT(PRC_PAR(prc))) {
		    case PAR_EAWARN:
			call erract (EA_WARN)
		    default:
		        call error (err, PRC_STR(prc))
		    }
		}
		if (pis == NULL)
		    next
		if (listbpm != NULL)
		    j = imtrgetim (listbpm, min(imtlen(listbpm),i), Memc[bpm],
			SZ_FNAME)
		if (listobm != NULL)
		    j = imtrgetim (listobm, min(imtlen(listobm),i), Memc[obm],
			SZ_FNAME)
	        if (listo != NULL) {
		    j = imtrgetim (listo, min(imtlen(listo),i), Memc[output],
		        SZ_FNAME)
		    noproc = streq (Memc[output], PRC_NOPROC)
		    if (!noproc) {
			j = stridxs ("+", Memc[output])
			if (j > 0) {
			    call strcpy (OST_STR(ost), Memc[oname], SZ_FNAME)
			    k = stridxs ("[", Memc[oname])
			    if (k > 0)
			        Memc[oname+k-1] = EOS
			    PRC_STR(prc) = EOS
			    call zfnbrk (Memc[oname], k, l)
			    call strcat (Memc[output], PRC_STR(prc), j-1)
			    call strcat (Memc[oname+k-1], PRC_STR(prc),
			        PRC_LENSTR)
			    call strcat (Memc[output+j],PRC_STR(prc),PRC_LENSTR)
			    call strcpy (PRC_STR(prc), Memc[output], SZ_FNAME)
			}
		    }
		}
		exti = 0
		do j = 0, npi-1 {
		    pi = Memi[pis+j]
		    if (ostbpm != NULL) {
			if (listbpm == NULL) {
			    iferr (call prc_exprs (prc,pi,OST_IEXPR(ostbpm),
				Memc[oname], OST_LENSTR)) {
				err = errget (PRC_STR(prc), SZ_LINE)
				switch (err) {
				case PRCERR_IMKEYNF:
				    Memc[oname] = EOS
				default:
				    call error (err, PRC_STR(prc))
				}
			    }
			} else {
			    if (Memc[bpm] != NULL && PI_EXTN(pi)!=EOS) {
				call sprintf (Memc[oname], SZ_FNAME,
				    "%s[%s]")
				    call pargstr (Memc[bpm])
				    call pargstr (PI_EXTN(pi))
			    } else
				call strcpy (Memc[bpm], Memc[oname],
				        SZ_FNAME)
			}
			if (Memc[oname] != EOS && !noproc) {
			    call pi_alloc (prc, PI_BPMPI(pi), Memc[oname], 0,
				PI_EXTN(pi), "", PRC_BPM, NULL)
			    PI_IPI(PI_BPMPI(pi)) = pi
			}
		    }
		    if (ostobm != NULL) {
			if (listobm == NULL) {
			    iferr (call prc_exprs (prc,pi,OST_IEXPR(ostobm),
				Memc[oname], OST_LENSTR)) {
				err = errget (PRC_STR(prc), SZ_LINE)
				switch (err) {
				case PRCERR_IMKEYNF:
				    Memc[oname] = EOS
				default:
				    call error (err, PRC_STR(prc))
				}
			    }
			} else {
			    if (PI_EXTN(pi)!=EOS) {
				call sprintf (Memc[oname], SZ_FNAME,
				    "%s[%s]")
				    call pargstr (Memc[obm])
				    call pargstr (PI_EXTN(pi))
			    } else
				call strcpy (Memc[obm], Memc[oname],
				SZ_FNAME)
			}
			call pi_alloc (prc, PI_OBMPI(pi), Memc[oname], 0,
			    PI_EXTN(pi), "", PRC_OBM, NULL)
			PI_IPI(PI_OBMPI(pi)) = pi
		    }
		    if (osto != NULL) {
			if (noproc)
			    call strcpy (Memc[output],Memc[oname],SZ_FNAME)
			else {
			    if (listo == NULL)
				call prc_exprs (prc, pi, OST_IEXPR(osto),
				    Memc[oname], OST_LENSTR)
			    else {
				if (PI_EXTN(pi)!=EOS) {
				    switch (PAR_OUTTYPE(PRC_PAR(prc))) {
				    case PAR_OUTMSK:
					call sprintf (Memc[oname], SZ_FNAME,
					    "%s[%s,type=mask,append,inherit]")
					call pargstr (Memc[output])
					call pargstr (PI_EXTN(pi))
				    case PAR_OUTIMG:
					call sprintf (Memc[oname], SZ_FNAME,
					    "%s[%s,append,inherit]")
					call pargstr (Memc[output])
					call pargstr (PI_EXTN(pi))
				    }
				    exti = exti + 1
				} else {
				    switch (PAR_OUTTYPE(PRC_PAR(prc))) {
				    case PAR_OUTMSK:
					call sprintf (Memc[oname], SZ_FNAME,
					    "%s[pl,type=mask]")
					call pargstr (Memc[output])
				    case PAR_OUTIMG:
					call strcpy (Memc[output], Memc[oname],
					    SZ_FNAME)
				    }
				}
			    }
			}
			
			call pi_alloc (prc, PI_OPI(pi), Memc[oname], exti,
			    PI_EXTN(pi), "", PRC_OUTPUT, NULL)
		    }
		    if (pi != ipi)
			call pi_unmap (pi)
		}
		call mfree (pis, TY_POINTER)
	    }
	    if (ostbpm != NULL)
	        call mfree (bpm, TY_CHAR)
	    if (ostobm != NULL)
	        call mfree (obm, TY_CHAR)
	    if (listo != NULL)
	        call mfree (output, TY_CHAR)
	    call mfree (oname, TY_CHAR)
	    OST_READ(ost) = YES
	    if (sym != NULL)
		OST_READ(sym) = YES
	}

	# Search for calibration.
	prctype = OST_PRCTYPE(ost)
	listtype = OST_PRCTYPE(ost)

	# If nothing identifies sky or persistence then use objects.
	if ((prctype==PRC_SKY || prctype==PRC_PER) &&
	    OST_LIST(ost)==NULL && OST_INTYPE(ost)==EOS)
	    prctype = PRC_OBJECT

	# If no separate calibration list use the input list or flat list.
	if (OST_LIST(ost) == NULL) {
	    if (listtype == PRC_GFLAT)
	        listtype = PRC_FFLAT
	    else
		listtype = PRC_INPUT
	}

	if (DEBUG && ipi != NULL) {
	    call eprintf ("%s: Looking for prctype = %d -> %d\n")
	    call pargstr (PI_NAME(ipi))
	    call pargi (OST_PRCTYPE(ost))
	    call pargi (prctype)
	}

	cpi = NULL
	stp = PRC_STP(prc)
	for (sym = sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
	    pi = Memi[sym]
	    if (pi == NULL)
		next

	    if (DEBUG && ipi != NULL) {
		debug = (OST_IMAGEID(ost)==EOS ||
		    streq(PI_IMAGEID(pi),PI_IMAGEID(ipi)))
		debug = (debug && (OST_FILTER(ost)==NULL || 
		    streq(PI_FILTER(pi),PI_FILTER(ipi))))
		if (debug) {
		    call eprintf ("  %s: %d\n")
		    call pargstr (PI_NAME(pi))
		    call pargi (PI_PRCTYPE(pi))
		    if (PI_PRCTYPE(pi) == prctype) {
			call eprintf ("    A %s: %d\n")
			call pargstr (PI_NAME(pi))
			call pargi (PI_PRCTYPE(pi))
		    }
		}
	    } else
		debug = false

	    if (OST_PRCTYPE(ost)!=PRC_INPUT) {
	        if (PI_PRCTYPE(pi) != prctype || PI_LISTTYPE(pi) != listtype)
		    next
	        if (OST_LIST(ost) != NULL && OST_LIST(ost) != PI_LIST(pi))
		    next
	    }

	    if (debug) {
		call eprintf ("    B %s: %d\n")
		call pargstr (PI_NAME(pi))
		call pargi (PI_PRCTYPE(pi))
	    }
	    if (ipi != NULL) {
		if (OST_IMAGEID(ost)!=EOS &&
		    strne(PI_IMAGEID(pi),PI_IMAGEID(ipi)))
		    next
		if (OST_FILTER(ost)!=NULL &&
		    strne(PI_FILTER(pi),PI_FILTER(ipi)))
		    next
		if (OST_MATCH(ost)!=EOS && OST_SRT(ost)!=SRT_LIST) {
		    PRC_PIAKEY(prc) = pi
		    PRC_PIBKEY(prc) = ipi
		    if (!prc_exprb (prc, ipi, OST_MATCH(ost)))
		        next
		}
	    }
	    if (debug) {
		call eprintf ("    C %s: %d\n")
		call pargstr (PI_NAME(pi))
		call pargi (PI_PRCTYPE(pi))
	    }

	    # Sort by exposure time if desired.
	    srt = OST_SRT(ost) / 10
	    switch (srt) {
	    case SRT_NEAREST, SRT_BEFORE, SRT_AFTER:
		if (streq (PI_NAME(pi), PI_NAME(ipi)))
		    next
		if (IS_INDEFR(PI_EXPTIME(ipi)))
		    break
		if (IS_INDEFR(PI_EXPTIME(pi)))
		    next
		ed = PI_EXPTIME(pi) - PI_EXPTIME(ipi)
		if (IS_INDEFD(PI_SORTVAL(ipi)) ||
		    IS_INDEFD(PI_SORTVAL(pi)))
		    d = MAX_DOUBLE
		else
		    d = PI_SORTVAL(pi) - PI_SORTVAL(ipi)
		if (cpi == NULL) {
		    cpi = pi
		    ecd = ed
		    cd = d
		    next
		} else {
		    switch (srt) {
		    case SRT_BEFORE:
			if ((ecd > 0 && ed < ecd) ||
			    (ecd < 0 && ed < 0 && ed > ecd)) {
			    cpi = pi
			    ecd = ed
			    cd = d
			    next
			}
		    case SRT_AFTER:
			if ((ecd < 0 && ed > ecd) ||
			    (ecd > 0 && ed > 0 && ed < ecd)) {
			    cpi = pi
			    ecd = ed
			    cd = d
			    next
			}
		    case SRT_NEAREST:
			if (abs(ed) < abs(ecd)) {
			    cpi = pi
			    ecd = ed
			    cd = d
			    next
			}
		    }
		    if (!fp_equalr (abs(ed), abs(ecd)))
		        next
		}
	    }

	    # Sort by sort value.
	    srt = mod (OST_SRT(ost), 10)
	    switch (srt) {
	    case SRT_NEAREST, SRT_BEFORE, SRT_AFTER:
		if (streq (PI_NAME(pi), PI_NAME(ipi)))
		    next
		if (IS_INDEFD(PI_SORTVAL(ipi)) ||
		    IS_INDEFD(PI_SORTVAL(pi)))
		    d = MAX_DOUBLE
		else
		    d = PI_SORTVAL(pi) - PI_SORTVAL(ipi)
		if (cpi == NULL) {
		    cpi = pi
		    cd = d
		} else {
		    switch (srt) {
		    case SRT_BEFORE:
			if ((cd > 0 && d < cd) ||
			    (cd < 0 && d < 0 && d > cd)) {
			    cpi = pi
			    cd = d
			}
		    case SRT_AFTER:
			if ((cd < 0 && d > cd) ||
			    (cd > 0 && d > 0 && d < cd)) {
			    cpi = pi
			    cd = d
			}
		    case SRT_NEAREST:
			if (abs(d) < abs(cd)) {
			    cpi = pi
			    cd = d
			}
		    }
		}
	    case SRT_LIST:
	        if (cpi == NULL)
		    call calloc (cpi, 101, TY_POINTER)
		else if (mod (Memi[cpi], 100) == 0)
		    call realloc (cpi, Memi[cpi]+101, TY_POINTER)
		Memi[cpi] = Memi[cpi] + 1
		Memi[cpi+Memi[cpi]] = pi
	    }
	}

	if (cpi == NULL) {
	    if (ipi == NULL)
		call prc_error (prc, 1, "No suitable input data found %s",
		    "(check input list and parameters)", "")
	    else
		call prc_error (prc, PRCERR_CALNF, "%s not found for %s",
		    OST_NAME(ost), PI_NAME(ipi))
	}

	if (srt == SRT_LIST)
	    call gqsort (Memi[cpi+1], Memi[cpi], pi_compare, prc)
	else
	    PI_IPI(cpi) = ipi

	OST_PI(ost) = cpi
end


# OST_ICLOSE -- Close method for images.

procedure ost_iclose (ost)

pointer	ost				#I Expression object

begin
	if (OST_LIST(ost) != NULL)
	    call imtclose (OST_LIST(ost))
end


# OST_BOPEN -- Open method for bias.

procedure ost_bopen (prc, ost, ipi)

pointer	prc				#I Processing object
pointer	ost				#I Expression object
pointer	ipi				#I Input processing image

char	imsteps[1]
int	i, j, nc, nl
real	junk, d, dmin, dmax
pointer	imdone, pi, im, buf

int	locpr(), strdic(), stridxs()
real	amedr()
pointer	imgl2r()
extern	pi_bopen, pi_bgline, pi_bclose
errchk	prc_exprs, prc_error, zcall1

begin
	# Check if bias has already been subtracted.
	if (PAR_OVERRIDE(PRC_PAR(prc)) == NO) {
	    call malloc (imdone, SZ_LINE, TY_CHAR)
	    call prc_steps (prc, ipi, "", imsteps, Memc[imdone], SZ_LINE)
	    i = stridxs ("BD", Memc[imdone])
	    call mfree (imdone, TY_CHAR)
	    if (i != 0) {
		call pi_alloc (prc, pi, "0", 0, PI_EXTN(ipi),
		    "", PRC_BIAS, NULL)

		PI_LEN(pi,1) = 1
		PI_LEN(pi,2) = PI_LEN(ipi,2)
		call calloc (PI_DATA(pi), PI_LEN(pi,2), TY_REAL)

		PI_MAPPED(pi) = NO
		PI_OPEN(pi) = locpr (pi_bopen)
		PI_GLINE(pi) = locpr (pi_bgline)
		PI_CLOSE(pi) = locpr (pi_bclose)

		PI_IPI(pi) = ipi
		OST_PI(ost) = pi

		return
	    }
	}

	call prc_exprs (prc, ipi, OST_BIASSEC(ost), OST_STR(ost), OST_LENSTR)
	call pi_alloc (prc, pi, PI_NAME(ipi), 0, PI_EXTN(ipi), OST_STR(ost),
	    PRC_BIAS, NULL)
	iferr (call pi_map (pi)) {
	    call strcpy (PI_NAME(pi), OST_STR(ost), OST_LENSTR)
	    call pi_free (pi)
	    call prc_error (prc, 1, "Bias section error (%s)", OST_STR(ost), "")
	}
	im = PI_IM(pi)
	nc = IM_LEN(im,1)
	nl = IM_LEN(im,2)
	if (IM_NDIM(im) == 1) {
	    nl = nc
	    nc = 1
	}
	PI_LEN(pi,1) = 1
	PI_LEN(pi,2) = nl
	if (nl < PI_LEN(ipi,2)) {
	    call strcpy (PI_NAME(pi), OST_STR(ost), OST_LENSTR)
	    call pi_free (pi)
	    call prc_error (prc, 1, "Bias section error (%s)", OST_STR(ost), "")
	}
	call malloc (PI_DATA(pi), nl, TY_REAL)
	if (IM_NDIM(im) == 1) {
	    call amovr (Memr[imgl2r(im,1)], Memr[PI_DATA(pi)], nl)
	    call prc_exprs (prc, ipi, OST_BTYPE(ost), OST_STR(ost), OST_LENSTR)
	    switch (strdic (OST_STR(ost), OST_STR(ost), OST_LENSTR, BTYPES)) {
	    case BTYPE_FIT:
		call ost_bfit (prc, ost, pi, Memr[PI_DATA(pi)], nl, NO)
	    case BTYPE_IFIT:
		call ost_bfit (prc, ost, pi, Memr[PI_DATA(pi)], nl, YES)
	    case BTYPE_MEAN, BTYPE_MEDIAN, BTYPE_MINMAX:
	        ;
	    default:
		call prc_error (prc, 1, "Bias type error (%s)", OST_STR(ost),"")
	    }
	} else {
	    call prc_exprs (prc, ipi, OST_BTYPE(ost), OST_STR(ost), OST_LENSTR)
	    switch (strdic (OST_STR(ost), OST_STR(ost), OST_LENSTR, BTYPES)) {
	    case BTYPE_FIT:
		do i = 1, nl
		    call aavgr (Memr[imgl2r(im,i)], nc, Memr[PI_DATA(pi)+i-1],
		        junk)
		call ost_bfit (prc, ost, pi, Memr[PI_DATA(pi)], nl, NO)
	    case BTYPE_IFIT:
		do i = 1, nl
		    call aavgr (Memr[imgl2r(im,i)], nc, Memr[PI_DATA(pi)+i-1],
		        junk)
		call ost_bfit (prc, ost, pi, Memr[PI_DATA(pi)], nl, YES)
	    case BTYPE_MEAN:
		do i = 1, nl
		    call aavgr (Memr[imgl2r(im,i)], nc, Memr[PI_DATA(pi)+i-1],
		        junk)
	    case BTYPE_MEDIAN:
		do i = 1, nl
		    Memr[PI_DATA(pi)+i-1] = amedr (Memr[imgl2r(im,i)], nc)
	    case BTYPE_MINMAX:
		if (nc < 3) {
		    do i = 1, nl
			call aavgr (Memr[imgl2r(im,i)], nc,
			    Memr[PI_DATA(pi)+i-1], junk)
		} else {
		    do i = 1, nl {
			buf = imgl2r (im, i)
			dmin = Memr[buf] 
			dmax = Memr[buf] 
			junk = 0.
			do j = 1, nc {
			    d = Memr[buf+j-1]
			    dmin = min (d, dmin)
			    dmax = max (d, dmax)
			    junk = junk + d
			}
			Memr[PI_DATA(pi)+i-1] = (junk - dmin - dmax) / (nc - 2)
		    }
		}
	    default:
		call prc_error (prc, 1, "Bias type error (%s)", OST_STR(ost),"")
	    }
	}
	        
	call imunmap (PI_IM(pi))

	PI_MAPPED(pi) = NO
	PI_OPEN(pi) = locpr (pi_bopen)
	PI_GLINE(pi) = locpr (pi_bgline)
	PI_CLOSE(pi) = locpr (pi_bclose)

	PI_IPI(pi) = ipi
	OST_PI(ost) = pi
end


# OST_BCLOSE -- Close method for bias.

procedure ost_bclose (ost)

pointer	ost				#I Expression object

begin
	return
end


# OST_BFIT -- Fit a function to smooth the overscan vector.
#   The fitting uses the ICFIT procedures which may be interactive.

procedure ost_bfit (prc, ost, pi, overscan, npts, interactive)

pointer	prc			#I Processing pointer
pointer	ost			#I Operand pointer
pointer	pi			#I Processing image pointer
real	overscan[npts]		#U Input overscan and output fitted overscan
int	npts			#I Number of data points
int	interactive		#I Interactive?

int	i, fd
real	rval
pointer	par
pointer	sp, x, w, ic, cv, gp, gt

int	open()
real	prc_exprr()
pointer	gopen(), gt_init()
errchk	gopen, open, prc_exprs, prc_exprr

begin
	call smark (sp)
	call salloc (x, npts, TY_REAL)
	call salloc (w, npts, TY_REAL)
	do i = 1, npts
	    Memr[x+i-1] = i
	call amovkr (1., Memr[w], npts)

	par = PRC_PAR(prc)

	# Open the ICFIT procedures.
	call ic_open (ic)
	call prc_exprs (prc, pi, OST_BFUNC(ost), OST_STR(ost), OST_LENSTR)
	call ic_pstr (ic, "function", OST_STR(ost))
	rval = prc_exprr (prc, pi, OST_BORDER(ost))
	call ic_puti (ic, "order", nint(rval))
	call prc_exprs (prc, pi, OST_BSAMP(ost), OST_STR(ost), OST_LENSTR)
	call ic_pstr (ic, "sample", OST_STR(ost))
	rval = prc_exprr (prc, pi, OST_BNAV(ost))
	call ic_puti (ic, "naverage", nint(rval))
	rval = prc_exprr (prc, pi, OST_BNIT(ost))
	call ic_puti (ic, "niterate", nint(rval))
	rval = prc_exprr (prc, pi, OST_BLREJ(ost))
	call ic_putr (ic, "low", rval)
	rval = prc_exprr (prc, pi, OST_BHREJ(ost))
	call ic_putr (ic, "high", rval)
	rval = prc_exprr (prc, pi, OST_BGROW(ost))
	call ic_putr (ic, "grow", rval)
	call ic_putr (ic, "xmin", 1.)
	call ic_putr (ic, "xmax", real(npts))
	call ic_pstr (ic, "xlabel", "Pixel")
	call ic_pstr (ic, "ylabel", "Overscan")

	# If the fitting is done interactively set the GTOOLS and GIO
	# pointers.  TODO: "learn" the fitting parameters since they may
	# be changed when fitting interactively.

	if (interactive == YES) {
	    gt = gt_init ()
	    call gt_sets (gt, GTTITLE, PI_NAME(pi))
	    call gt_sets (gt, GTTYPE, "line")
	    call gt_setr (gt, GTXMIN, 1.)
	    call gt_setr (gt, GTXMAX, real(npts))
	    gp = gopen (PAR_GDEV(par), NEW_FILE, STDGRAPH)

	    call icg_fit (ic, gp, PAR_GCUR(par), gt, cv, Memr[x], overscan,
	        Memr[w], npts)

	    call gclose (gp)
	    call gt_free (gt)
	} else
	    call ic_fit (ic, cv, Memr[x], overscan, Memr[w], npts,
	        YES, YES, YES, YES)

	# Make a log of the fit in the plot file if given.
	if (PAR_GPFILE(par) != EOS) {
	    fd = open (PAR_GPFILE(par), APPEND, BINARY_FILE)
	    gp = gopen ("stdvdm", NEW_FILE, fd)
	    gt = gt_init ()
	    call gt_sets (gt, GTTITLE, PI_NAME(pi))
	    call gt_sets (gt, GTTYPE, "line")
	    call gt_setr (gt, GTXMIN, 1.)
	    call gt_setr (gt, GTXMAX, real (npts))
	    call icg_graphr (ic, gp, gt, cv, Memr[x], overscan, Memr[w], npts)
	    call gclose (gp)
	    call close (fd)
	    call gt_free (gt)
	}

	# Replace the raw overscan vector with the smooth fit.
	call cvvector (cv, Memr[x], overscan, npts)

	# Finish up.
	call ic_closer (ic)
	call cvfree (cv)
	call sfree (sp)
end


# OST_SOPEN -- Open method for sky subtraction.
# This returns a PI data structure in OST_PI(ost).
#
# This is called when a sky subtraction reference ($S) is made.  There are
# different types of sky subtraction.  If it is a single image then the
# image methods are used.  Otherwise sky subtraction specific methods
# are defined.

procedure ost_sopen (prc, ost, ipi)

pointer	prc				#I Processing object
pointer	ost				#I Expression object
pointer	ipi				#I Input processing image

bool	reinit
int	ival, mode, window, navg
real	rval, nclip
pointer	sky, pi

bool	strne()
int	nscan(), strdic(), locpr()
errchk	ost_iopen, pi_alloc, sky_alloc
extern	pi_sopen, pi_sgline, pi_sclose

begin
	# Check for indirect reference.  This is always an image method.
	if (OST_IEXPR(ost) == '(') {
	    call ost_iopen (prc, ost, ipi)
	    return
	}

	# Determine type of sky subtraction.
	call prc_exprs (prc, ipi, OST_SKYMODE(ost), OST_STR(ost), OST_LENSTR)
	call sscan (OST_STR(ost))
	call gargwrd (OST_STR(ost), OST_LENSTR)
	mode = strdic (OST_STR(ost), OST_STR(ost), OST_LENSTR, SKYMODES)

	# Set up the desired type of sky subtraction.  The single image
	# types use the image methods.

	switch (mode) {
	case SKY_NEAREST, SKY_BEFORE, SKY_AFTER:
	    OST_SRT(ost) = mode
	    call ost_iopen (prc, ost, ipi)
	    return
	case SKY_MEDIAN:
	    window = 5
	    navg = 1
	    nclip = 2.
	    call gargi (ival)
	    if (nscan() == 2)
	        window = ival
	    call gargi (ival)
	    if (nscan() == 3)
	        navg = ival
	    call gargr (rval)
	    if (nscan() == 4)
	        nclip = rval
	default:
	    call error (1, "Unknown sky mode")
	}

	# Check if we need to reinitialize for a new filter/imageid, etc.
	sky = OST_SKY(ost)
	if (sky != NULL) {
	    reinit = false
	    pi = SKY_PI(sky,1)
	    if (OST_IMAGEID(ost)!=EOS &&
		strne(PI_IMAGEID(pi),PI_IMAGEID(ipi)))
		reinit = true
	    if (OST_FILTER(ost)!=NULL &&
		strne(PI_FILTER(pi),PI_FILTER(ipi)))
		reinit = true
	    if (reinit)
	        call ost_sclose (ost)
	}

	# Read sky list and initialize the data structures.
	sky = OST_SKY(ost)
	if (sky == NULL) {
	    OST_SRT(ost) = SRT_LIST
	    call ost_iopen (prc, ost, ipi)
	    call sky_alloc (sky, window, Memi[OST_PI(ost)+1], Memi[OST_PI(ost)])
	    call mfree (OST_PI(ost), TY_POINTER)
	    
	    SKY_MODE(sky) = mode
	    SKY_NAVG(sky) = navg
	    SKY_NCLIP(sky) = nclip
	    OST_SKY(ost) = sky
	}

	# Set return structure.
	call pi_free (OST_PI(ost))
	call pi_alloc (prc, pi, OST_SKYMODE(ost), PI_EXTI(ipi), PI_EXTN(ipi),
	    "", PRC_SKY, NULL)
	PI_OPEN(pi) = locpr (pi_sopen)
	PI_GLINE(pi) = locpr (pi_sgline)
	PI_CLOSE(pi) = locpr (pi_sclose)

	PI_IPI(pi) = ipi
	OST_PI(ost) = pi

	if (PAR_OUTTYPE(PRC_PAR(prc)) == PAR_OUTLST ||
	    PAR_OUTTYPE(PRC_PAR(prc)) == PAR_OUTVLST) {
	    PI_IM(pi) = NULL
	    call amovki (1, PI_LEN(pi,1), 3)
	} else {
	    PI_IM(pi) = sky
	    call amovi (PI_LEN(ipi,1), PI_LEN(pi,1), 3)
	}
end


# OST_SCLOSE -- Close method for sky subtraction.

procedure ost_sclose (ost)

pointer	ost				#I Expression object

begin
	if (OST_SKY(ost) != NULL)
	    call sky_free (OST_SKY(ost))
	call ost_iclose (ost)
end


# SKY_ALLOC -- Allocate sky subtraction structure.
# This is used when not using simple image sky subtraction.

procedure sky_alloc (sky, window, pi, npi)

pointer	sky				#O Sky pointer
int	window				#I Median window size
pointer	pi[npi]				#I Array of sky PIs
int	npi				#I Number of input skys

int	i, nc, nl, win
pointer	rms

pointer	yrm_open()
errchk	calloc, yrm_open

begin
	nc = PI_LEN(pi[1],1)
	nl = PI_LEN(pi[1],2)
	win = min (window, npi)
	call calloc (rms, nc, TY_STRUCT)
	do i = 0, nc-1
	    Memi[rms+i] = yrm_open (win, "median", nc, TY_REAL)

	call calloc (sky, SKY_LEN(npi), TY_STRUCT)
	SKY_WINDOW(sky) = win
	call amovi (pi, SKY_PI(sky,1), npi)
	SKY_NPI(sky) = npi
	SKY_NC(sky) = nc
	SKY_NL(sky) = nl
	SKY_NAVG(sky) = 1
	SKY_NCLIP(sky) = 2.
	SKY_RMS(sky) = rms
end


# SKY_FREE -- Free sky subtraction memory allocation.

procedure sky_free (sky)

pointer	sky				#U Sky pointer

int	i
pointer	rms

begin
	if (sky == NULL)
	    return

	rms = SKY_RMS(sky)
	do i = 0, SKY_NC(sky)-1
	    call yrm_close (Memi[rms+i])
	call mfree (SKY_RMS(sky), TY_STRUCT)
	call mfree (sky, TY_STRUCT)
end


# OST_POPEN -- Open method for making persistence mask.
# This returns a PI data structure in OST_PI(ost).
#
# This is called when a persistence mask reference ($P) is made.

procedure ost_popen (prc, ost, ipi)

pointer	prc				#I Processing object
pointer	ost				#I Expression object
pointer	ipi				#I Input processing image

bool	reinit
int	window
pointer	per, pi

bool	strne()
int	locpr()
real	prc_exprr()
errchk	ost_iopen, pi_alloc, per_alloc, prc_exprr
extern	pi_popen, pi_pgline, pi_pclose

begin
	# Check for indirect reference.  This is always an image method.
	if (OST_IEXPR(ost) == '(') {
	    call ost_iopen (prc, ost, ipi)
	    return
	}

	# Determine persistence window.
	window = nint (prc_exprr (prc, ipi, OST_PERWIN(ost))) + 1

	# Check if we need to reinitialize for a new filter/imageid, etc.
	per = OST_PER(ost)
	if (per != NULL) {
	    reinit = false
	    pi = PER_PI(per,1)
	    if (OST_IMAGEID(ost)!=EOS &&
		strne(PI_IMAGEID(pi),PI_IMAGEID(ipi)))
		reinit = true
	    if (reinit)
	        call ost_pclose (ost)
	}

	# Read peristence list and initialize the data structures.
	per = OST_PER(ost)
	if (per == NULL) {
	    OST_SRT(ost) = SRT_LIST
	    call ost_iopen (prc, ost, ipi)
	    call per_alloc (per, window, Memi[OST_PI(ost)+1], Memi[OST_PI(ost)])
	    call mfree (OST_PI(ost), TY_POINTER)
	    
	    PER_WINDOW(per) = window
	    OST_PER(ost) = per
	}

	# Set return structure.
	call pi_free (OST_PI(ost))
	call pi_alloc (prc, pi, OST_NAME(ost), PI_EXTI(ipi), PI_EXTN(ipi),
	    "", PRC_PER, NULL)
	PI_OPEN(pi) = locpr (pi_popen)
	PI_GLINE(pi) = locpr (pi_pgline)
	PI_CLOSE(pi) = locpr (pi_pclose)

	PI_IPI(pi) = ipi
	OST_PI(ost) = pi

	if (PAR_OUTTYPE(PRC_PAR(prc)) == PAR_OUTLST ||
	    PAR_OUTTYPE(PRC_PAR(prc)) == PAR_OUTVLST) {
	    PI_IM(pi) = NULL
	    call amovki (1, PI_LEN(pi,1), 3)
	} else {
	    PI_IM(pi) = per
	    call amovi (PI_LEN(ipi,1), PI_LEN(pi,1), 3)
	}
end


# OST_PCLOSE -- Close method for persistence mask.

procedure ost_pclose (ost)

pointer	ost				#I Expression object

begin
	if (OST_PER(ost) != NULL)
	    call per_free (OST_PER(ost))
	call ost_iclose (ost)
end


# PER_ALLOC -- Allocate persistence mask structure.

procedure per_alloc (per, window, pi, npi)

pointer	per				#O Persistence pointer
int	window				#I Median window size
pointer	pi[npi]				#I Array of PIs
int	npi				#I Number of input images

int	i, nc, nl
pointer	rms

pointer	yrm_open()
errchk	calloc, yrm_open

begin
	nc = PI_LEN(pi[1],1)
	nl = PI_LEN(pi[1],2)
	call calloc (rms, nc, TY_STRUCT)
	do i = 0, nc-1
	    Memi[rms+i] = yrm_open (window, "maximum", nc, TY_REAL)

	call calloc (per, PER_LEN(npi), TY_STRUCT)
	PER_WINDOW(per) = min (window, npi)
	call amovi (pi, PER_PI(per,1), npi)
	PER_NPI(per) = npi
	PER_NC(per) = nc
	PER_NL(per) = nl
	PER_RMS(per) = rms
end


# PER_FREE -- Free persistence memory allocation.

procedure per_free (per)

pointer	per				#U Persistence pointer

int	i
pointer	rms

begin
	if (per == NULL)
	    return

	rms = PER_RMS(per)
	do i = 0, PER_NC(per)-1
	    call yrm_close (Memi[rms+i])
	call mfree (PER_RMS(per), TY_STRUCT)
	call mfree (per, TY_STRUCT)
end


# OST_FIND -- Find the OST entry for the desired processing type.

pointer procedure ost_find (ostp, prctype)

pointer	ostp				#I Operand symbol table pointer
int	prctype				#I Desired processing type
pointer	ost				#R Return pointer

int	i

pointer	sthead(), stnext()

begin
	i = prctype
	if (i == PRC_OBJECT)
	    i = PRC_INPUT

	for (ost=sthead(ostp); ost!=NULL; ost=stnext(ostp,ost))
	    if (OST_PRCTYPE(ost) == i)
	        break
	return (ost)
end
