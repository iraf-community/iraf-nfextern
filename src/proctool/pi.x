include	<error.h>
include	<imhdr.h>
include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"
include	"sky.h"
include	"per.h"


# PI_IOPEN -- Open method for regular images and masks.
#
# This is called for both the input image being processed and the
# calibration images.  In the latter case there will be a pointer
# to the input images.  It is here were we need to deal with matching
# the calibration images to the input image.  In this version we
# assume that the calibration images are matched except possibly for
# the input mask.  This means that if a trim is applied to the input
# no trim is applied to the calibration which is assumed to have been
# previously trimmed in the same way.

procedure pi_iopen (pi)

pointer	pi				#I Processing image pointer

int	i, strlen()
pointer	im, refim, immap(), yt_pmmap()
errchk	immap, yt_pmmap

begin
	if (PI_IM(pi) != NULL)
	    return

	if (PI_PRCTYPE(pi) == PRC_BPM || PI_PRCTYPE(pi) == PRC_OBM ||
	    PI_PRCTYPE(pi) == PRC_MASK) {
	    refim = PI_IPI(pi)
	    if (refim != NULL)
		refim = PI_IM(refim)
	} else
	    refim = NULL

	if (refim != NULL) {
	    call pi_iclose (pi)
	    im = yt_pmmap (PI_NAME(pi), refim, PI_NAME(pi), PI_LENSTR)
	    if (im == NULL) {
		call strcpy ("EMPTY", PI_NAME(pi), PI_LENSTR)
	        PI_IM(pi) = -1
		call calloc (PI_DATA(pi), 1, TY_SHORT)
		call amovki (1, PI_LEN(pi,1), 3)
	    } else {
		PI_IM(pi) = im
		PI_DATA(pi) = NULL
		call amovi (IM_LEN(im,1), PI_LEN(pi,1), 3)
	    }
	} else {
	    call pi_iclose (pi)
	    if (PI_TRIM(pi) == NO && PI_PRCTYPE(pi) != PRC_BIAS)
		im = immap (PI_NAME(pi), READ_ONLY, 0)
	    else if (PI_TSEC(pi) == EOS)
		im = immap (PI_NAME(pi), READ_ONLY, 0)
	    else {
		i = strlen (PI_NAME(pi))
		call strcat (PI_TSEC(pi), PI_NAME(pi), PI_LENSTR)
		im = immap (PI_NAME(pi), READ_ONLY, 0)
		call strcpy (PI_NAME(pi), PI_NAME(pi), i)
	    }
	    if (PI_BPMPI(pi) != NULL) {
		PI_IM(PI_BPMPI(pi)) = NULL
		PI_DATA(PI_BPMPI(pi)) = NULL
	    }
	    if (PI_OBMPI(pi) != NULL) {
		PI_IM(PI_OBMPI(pi)) = NULL
		PI_DATA(PI_OBMPI(pi)) = NULL
	    }
	    PI_IM(pi) = im
	    PI_DATA(pi) = NULL
	    call amovi (IM_LEN(im,1), PI_LEN(pi,1), 3)
	}
	PI_LINE(pi) = 0
	PI_MAPPED(pi) = YES
end


# PI_IGLINE -- Get line method for regular images.

procedure pi_igline (pi, line)

pointer	pi				#I Processing image pointer
int	line				#I Line to get

pointer	im, imgs3r(), imgs3s()
errchk	imgs3r, imgs3s

begin
	im = PI_IM(pi)
	switch (PI_PRCTYPE(pi)) {
	case PRC_BPM, PRC_OBM, PRC_MASK:
	    if (im != -1)
		PI_DATA(pi) = imgs3s (im, 1, IM_LEN(im,1), line, line, 1,
		    IM_LEN(im,3))
	default:
	    PI_DATA(pi) = imgs3r (im, 1, IM_LEN(im,1), line, line, 1,
	        IM_LEN(im,3))
	}
	PI_LINE(pi) = line
	if (line == 1)
	    call ieemapr (NO, NO)
end


# PI_IBPGLINE -- Get mask line method for regular images.
# This can be used with either the bad pixel mask or the object mask.

procedure pi_mgline (pi, mpi, line)

pointer	pi				#I Processing image pointer
pointer	mpi				#I Mask processing image pointer
int	line				#I Line to get

pointer	bp, im, yt_pmmap(), imgs3s()
errchk	yt_pmmap, imgs3s

begin
	if (mpi == NULL)
	    return

	bp = PI_IM(mpi)
	if (bp == NULL) {
	    im = PI_IM(pi)
	    bp = yt_pmmap (PI_NAME(mpi), im, PI_NAME(mpi), PI_LENSTR)
	    if (bp == NULL) {
		bp = -1
		PI_DATA(mpi) = NULL
		#call calloc (PI_DATA(mpi), IM_LEN(im,1)*IM_LEN(im,3), TY_SHORT)
	    }
	    PI_IM(mpi) = bp
	}

	if (bp == -1)
	    return

	PI_DATA(mpi) = imgs3s (bp, 1, IM_LEN(bp,1), line, line, 1, IM_LEN(bp,3))
	if (line == 1)
	    call ieemapr (NO, NO)
end


# PI_ICLOSE -- Close method for regular images and masks.

procedure pi_iclose (pi)

pointer	pi				#I Processing image pointer

pointer	mpi
errchk	imunmap

begin
	if (PI_PRCTYPE(pi) != PRC_BPM) {
	    mpi = PI_BPMPI(pi)
	    if (mpi != NULL) {
		if (PI_IM(mpi) != NULL) {
		    if (PI_IM(mpi) == -1) {
			#call mfree (PI_DATA(mpi), TY_SHORT)
		    } else {
			call imunmap (PI_IM(mpi))
		    }
		}
		PI_IM(mpi) = NULL
		PI_DATA(mpi) = NULL
	    }
	}
	if (PI_PRCTYPE(pi) != PRC_OBM) {
	    mpi = PI_OBMPI(pi)
	    if (mpi != NULL) {
		if (PI_IM(mpi) != NULL) {
		    if (PI_IM(mpi) == -1) {
			#call mfree (PI_DATA(mpi), TY_SHORT)
		    } else {
			call imunmap (PI_IM(mpi))
		    }
		}
		PI_IM(mpi) = NULL
		PI_DATA(mpi) = NULL
	    }
	}

	if (PI_FP(pi) != NULL) {
	    if (PI_FP(pi) != -1)
		call xt_fpfree (PI_FP(pi))
	    else
	        PI_FP(pi) = NULL
	}
	if (PI_IM(pi) != NULL) {
	    switch (PI_PRCTYPE(pi)) {
	    case PRC_BPM, PRC_OBM, PRC_MASK:
		if (PI_IM(pi) == -1) {
		    call mfree (PI_DATA(pi), TY_SHORT)
		} else {
		    call yt_pmunmap (PI_IM(pi))
		}
	    default:
		call imunmap (PI_IM(pi))
	    }
	}
	PI_IM(pi) = NULL
	PI_DATA(pi) = NULL
	PI_LINE(pi) = 0
	PI_MAPPED(pi) = NO
end


# PI_BOPEN -- Open method for bias.

procedure pi_bopen (pi)

pointer	pi				#I Processing image pointer

begin
	PI_IM(pi) = PI_DATA(pi)
	PI_LINE(pi) = 0
	PI_MAPPED(pi) = YES
end


# PI_BGLINE -- Get line method for bias.

procedure pi_bgline (pi, line)

pointer	pi				# Processing image pointer
int	line				# Line to get

begin
	PI_DATA(pi) = PI_IM(pi)+line-1
	PI_LINE(pi) = line
end


# PI_BCLOSE -- Close method for bias.

procedure pi_bclose (pi)

pointer	pi				# Processing image pointer

begin
	call mfree (PI_IM(pi), TY_REAL)
	PI_LINE(pi) = 0
	PI_MAPPED(pi) = NO
end


# PI_SOPEN -- Open method for median sky subtraction.
# This method loads the running median buffers, if needed, for the
# input image.

procedure pi_sopen (pi)

pointer	pi				#I PI pointer

int	i, j, k, npi, window, nc, nl, index1, index2, navg, nsample, nlstep
short	nused
real	blank, val, mode, nclip
pointer	sky, ipi, spi, mpi, rms, rm, idata, mdata, mdata1, sample

real	yrm_med(), pi_smode()
errchk	malloc, pi_smode, pi_mgline

begin
	sky = PI_IM(pi)
	if (sky == NULL) {
	    call calloc (PI_DATA(pi), 1, TY_REAL)
	    PI_MAPPED(pi) = YES
	    return
	}
	ipi = PI_IPI(pi)
	npi = SKY_NPI(sky)
	window = SKY_WINDOW(sky)
	nc = SKY_NC(sky)
	nl = SKY_NL(sky)
	navg = SKY_NAVG(sky)
	nclip = SKY_NCLIP(sky)
	blank = SKY_BLANK(sky)
	rms = SKY_RMS(sky)

	call calloc (mdata1, nc, TY_SHORT)

	# Set statistics sampling information.
	nsample = min (nl, max (5, nint (100000. / nc)))
	nlstep = max (1, nl / nsample)
	nsample = 0
	do j = 1 + nlstep/2, nl, nlstep
	    nsample = nsample + nc
	sample = NULL

	# Set index of input image in list.
	# This assumes the sky list has been sorted.
	# Also check if the input image is also in the sky list.
	SKY_EINDEX(sky) = 0
	do i = 1, npi {
	    spi = SKY_PI(sky,i)
	    if (PI_SORTVAL(spi) >= PI_SORTVAL(ipi))
	        break
	}
	i = min (i, npi)
	if (PI_SORTVAL(spi) == PI_SORTVAL(ipi))
	    SKY_EINDEX(sky) = i

#	# Compute mode if target image is not in the sky list.
#	if (SKY_EINDEX(sky) == 0) {
#	    mpi = PI_OBMPI(ipi)
#
#	    # Compute mode.
#	    if (sample == NULL)
#		call malloc (sample, nsample, TY_REAL)
#	    PI_SKYMODE(ipi) =  pi_smode (ipi, mpi, mdata1, sample, nc, nl,
#	        nlstep)
#	}

	# Set the sky images to be used.
	index1 = max (1, i - window / 2)
	index2 = min (npi, index1 + window - 1)
	index1 = max (1, index2 - window + 1)

	# Now initialize the median if needed.  This is most efficient if
	# the input images are processed in sorted order.
	do k = index1, index2 {
	    if (k >= SKY_INDEX1(sky) && k <= SKY_INDEX2(sky))
	        next
	    spi = SKY_PI(sky,k)
	    call pi_map (spi)
	    mpi = PI_OBMPI(spi)

	    # Compute mode.
	    if (sample == NULL)
		call malloc (sample, nsample, TY_REAL)
	    PI_SKYMODE(spi) =  pi_smode (spi, mpi, mdata1, sample, nc, nl,
	        nlstep)
	    mode = PI_SKYMODE(spi)

	    do j = 1, nl {
		rm = Memi[rms+j-1]
		call pi_igline (spi, j)
		idata = PI_DATA(spi)
		if (mpi != NULL) {
		    call pi_mgline (spi, mpi, j)
		    mdata = PI_DATA(mpi)
		    if (mdata == NULL)
		        mdata = mdata1
		} else
		    mdata = mdata1
		do i = 1, nc {
		    call yrm_unpack (rm, i)
		    val = yrm_med (rm, nclip, navg, blank, 0, k,
		        Memr[idata+i-1]-mode, Mems[mdata+i-1], nused)
		    call yrm_pack (rm, i)
		}
	    }
	    if (spi != ipi)
		call pi_unmap (spi)
	}

	if (mpi != NULL)
	    call pi_iclose (mpi)

	call mfree (sample, TY_REAL)
	call mfree (mdata1, TY_SHORT)

	SKY_INDEX1(sky) = index1
	SKY_INDEX2(sky) = index2
	call malloc (PI_DATA(pi), nc, TY_REAL)
	PI_MAPPED(pi) = YES
end


# PI_SGLINE -- Get line method for sky subtraction.

procedure pi_sgline (pi, line)

pointer	pi				# PI pointer
int	line				# Line to get

int	i, n, eindex, navg
short	omdata
real	blank, nclip, mode
pointer	sky, odata, rm

real	yrm_gmed()

begin
	sky = PI_IM(pi)
	if (sky == NULL)
	    return
	rm = Memi[SKY_RMS(sky)+line-1]
	navg = SKY_NAVG(sky)
	nclip = SKY_NCLIP(sky)
	blank = SKY_BLANK(sky)
	eindex = SKY_EINDEX(sky)

	# Set input mode to the image mode if part of the sky list
	# or the average of the sky modesl if not.
	if (line == 1) {
	    if (eindex != 0)
	        mode = PI_SKYMODE(SKY_PI(sky,eindex))
	    else {
		mode = 0.; n = 0
		do i = SKY_INDEX1(sky), SKY_INDEX2(sky) {
		    if (i == eindex)
		        next
		    mode = mode + PI_SKYMODE(SKY_PI(sky,i))
		    n = n + 1
		}
		mode = mode / n
		PI_SKYMODE(PI_IPI(pi)) = mode
	    }
	}

	# Get the line of running median data shifted to the input mode.
	odata = PI_DATA(pi)
	do i = 1, SKY_NC(sky) {
	    call yrm_unpack (rm, i)
	    Memr[odata+i-1] =
	        yrm_gmed (rm, nclip, navg, blank, eindex, omdata) + mode
	    call yrm_pack (rm, i)
	}
end


# PI_SCLOSE -- Close method for sky subtraction.
# This currently does nothing since we want to keep the running median
# data structures from image to image.

procedure pi_sclose (pi)

pointer	pi				# Processing image pointer

begin
	call mfree (PI_DATA(pi), TY_REAL)
	PI_MAPPED(pi) = NO
end


# PI_SMODE -- Compute sampled mode for an image.

real procedure pi_smode (pi, mpi, mdata1, sample, nc, nl, nlstep)

pointer	pi			#I Image pointer
pointer	mpi			#I Mask pointer
pointer	mdata1			#I Default mask data pointer
int	nc, nl			#I Image size
int	nlstep			#I Sample line step
pointer	sample			#I Sample working buffer
real	mode			#R Returned mode

int	i, j
pointer	ptr, idata, mdata

real	pi_moder()
errchk pi_igline, pi_mgline, pi_moder

begin
	# Initialize.
	mode = 0

	# Collect masked sample data.
	ptr = sample
	do j = 1 + nlstep/2, nl, nlstep {
	    call pi_igline (pi, j)
	    idata = PI_DATA(pi)
	    if (mpi != NULL) {
		call pi_mgline (pi, mpi, j)
		mdata = PI_DATA(mpi)
		if (mdata == NULL)
		    mdata = mdata1
	    } else
		mdata = mdata1
	    do i = 0, nc-1 {
		if (Mems[mdata+i] != 0)
		    next
		Memr[ptr] = Memr[idata+i]
		ptr = ptr + 1
	    }
	}

	# Sort and compute mode.
	i = ptr - sample
	if (i > 0) {
	    call asrtr (Memr[sample], Memr[sample], i)
	    mode = pi_moder (Memr[sample], i)
	}

	return (mode)
end


# PI_POPEN -- Open method for persistence mask.
# This method loads the running maximum buffers, if needed, for the
# input image.

procedure pi_popen (pi)

pointer	pi				#I PI pointer

int	i, j, k, npi, window, nc, nl, index1, index2
short	nused
real	blank, val
pointer	per, ipi, ppi, mpi, rms, rm, idata, mdata, mdata1

real	yrm_med()
errchk	malloc, pi_mgline

begin
	per = PI_IM(pi)
	if (per == NULL) {
	    call calloc (PI_DATA(pi), 1, TY_REAL)
	    PI_MAPPED(pi) = YES
	    return
	}
	ipi = PI_IPI(pi)
	npi = PER_NPI(per)
	window = PER_WINDOW(per)
	nc = PER_NC(per)
	nl = PER_NL(per)
	blank = PER_BLANK(per)
	rms = PER_RMS(per)

	call calloc (mdata1, nc, TY_SHORT)

	# Set index of input image in list.
	# This assumes the list has been sorted.
	# Also check if the input image is also in the list.
	PER_EINDEX(per) = 0
	do i = 1, npi {
	    ppi = PER_PI(per,i)
	    if (PI_SORTVAL(ppi) >= PI_SORTVAL(ipi))
	        break
	}
	i = min (i, npi)
	if (PI_SORTVAL(ppi) == PI_SORTVAL(ipi))
	    PER_EINDEX(per) = i

	# Set the images to be used.
	#index1 = max (1, i - window / 2)
	#index2 = min (npi, index1 + window - 1)
	#index1 = max (1, index2 - window + 1)
	index1 = max (1, i - window)
	index2 = i

	# Now initialize the running maximum if needed.  This is most
	# efficient if the input images are processed in sorted order.
	do k = index1, index2 {
	    if (k >= PER_INDEX1(per) && k <= PER_INDEX2(per))
	        next
	    ppi = PER_PI(per,k)
	    call pi_map (ppi)
	    mpi = PI_OBMPI(ppi)

	    do j = 1, nl {
		rm = Memi[rms+j-1]
		call pi_igline (ppi, j)
		idata = PI_DATA(ppi)
		if (mpi != NULL) {
		    call pi_mgline (ppi, mpi, j)
		    mdata = PI_DATA(mpi)
		    if (mdata == NULL)
		        mdata = mdata1
		} else
		    mdata = mdata1
		do i = 1, nc {
		    call yrm_unpack (rm, i)
		    val = yrm_med (rm, 0., 1, blank, 0, k,
		        Memr[idata+i-1], Mems[mdata+i-1], nused)
		    call yrm_pack (rm, i)
		}
	    }
	    if (ppi != ipi)
		call pi_unmap (ppi)
	}

	call mfree (mdata1, TY_SHORT)

	PER_INDEX1(per) = index1
	PER_INDEX2(per) = index2
	call malloc (PI_DATA(pi), nc, TY_REAL)
	PI_MAPPED(pi) = YES
end


# PI_PGLINE -- Get line method for persistence mask.

procedure pi_pgline (pi, line)

pointer	pi				# PI pointer
int	line				# Line to get

int	i, eindex
short	omdata
real	blank
pointer	per, odata, rm

real	yrm_gmed()

begin
	per = PI_IM(pi)
	if (per == NULL)
	    return
	rm = Memi[PER_RMS(per)+line-1]
	blank = PER_BLANK(per)
	eindex = PER_EINDEX(per)

	odata = PI_DATA(pi)
	do i = 1, PER_NC(per) {
	    call yrm_unpack (rm, i)
	    Memr[odata+i-1] = yrm_gmed (rm, 0., 1, blank, eindex, omdata)
	    call yrm_pack (rm, i)
	}
end


# PI_PCLOSE -- Close method for persistence mask.
# This currently does nothing since we want to keep the running median
# data structures from image to image.

procedure pi_pclose (pi)

pointer	pi				# Processing image pointer

begin
	call mfree (PI_DATA(pi), TY_REAL)
	PI_MAPPED(pi) = NO
end


define	NMIN	10	# Minimum number of pixels for mode calculation
define	ZRANGE	0.7	# Fraction of pixels about median to use
define	ZSTEP	0.01	# Step size for search for mode
define	ZBIN	0.1	# Bin size for mode.

# PI_MODE -- Compute mode of an array.  The mode is found by binning
# with a bin size based on the data range over a fraction of the
# pixels about the median and a bin step which may be smaller than the
# bin size.  If there are too few points the median is returned.
# The input array must be sorted.

real procedure pi_moder (a, n)

real	a[n]			# Data array
int	n			# Number of points

int	i, j, k, nmax
real	z1, z2, zstep, zbin
real	mode
bool	fp_equalr()

begin
	if (n < NMIN)
	    return (a[n/2])

	# Compute the mode.  The array must be sorted.  Consider a
	# range of values about the median point.  Use a bin size which
	# is ZBIN of the range.  Step the bin limits in ZSTEP fraction of
	# the bin size.

	i = 1 + n * (1. - ZRANGE) / 2.
	j = 1 + n * (1. + ZRANGE) / 2.
	z1 = a[i]
	z2 = a[j]
	if (fp_equalr (z1, z2)) {
	    mode = z1
	    return (mode)
	}

	zstep = ZSTEP * (z2 - z1)
	zbin = ZBIN * (z2 - z1)

	z1 = z1 - zstep
	k = i
	nmax = 0
	repeat {
	    z1 = z1 + zstep
	    z2 = z1 + zbin
	    for (; i < j && a[i] < z1; i=i+1)
		;
	    for (; k < j && a[k] < z2; k=k+1)
		;
	    if (k - i > nmax) {
	        nmax = k - i
	        mode = a[(i+k)/2]
	    }
	} until (k >= j)

	return (mode)
end


# PI_ALLOC -- Allocate a processing image structure.

procedure pi_alloc (prc, pi, name, exti, extn, tsec, prctype, im)

pointer	prc				#I Processing structure
pointer	pi				#O Processing image structure
char	name[ARB]			#I Image name
int	exti				#I Extension index
char	extn[ARB]			#I Extension name
char	tsec[ARB]			#I Trim section
int	prctype				#I Processing type
pointer	im				#U Image pointer

int	locpr()
extern	pi_iopen, pi_igline, pi_iclose

begin
	call calloc (pi, PI_PILEN, TY_STRUCT)
	call strcpy (name, PI_NAME(pi), PI_LENSTR)
	PI_EXTI(pi) = exti
	call strcpy (extn, PI_EXTN(pi), PI_LENSTR)
	PI_PRCTYPE(pi) = prctype
	PI_OPEN(pi) = locpr(pi_iopen)
	PI_GLINE(pi) = locpr(pi_igline)
	PI_CLOSE(pi) = locpr(pi_iclose)
	PI_SKYMODE(pi) = INDEFR
	if (im != NULL) {
	    PI_MAPPED(pi) = YES
	    PI_IM(pi) = im
	    PI_LEN(pi,1) = IM_LEN(im,1)
	    PI_LEN(pi,2) = IM_LEN(im,2)
	    PI_LEN(pi,3) = IM_LEN(im,3)
	} else
	    PI_MAPPED(pi) = NO

	# We wait until things are defined enough to open image.
	iferr (call prc_exprs (prc, pi, tsec, PI_TSEC(pi), PI_LENSTR))
	    call erract (EA_WARN)
	PI_TRIM(pi) = NO
end


# PI_FREE -- Free a processing image structure.

procedure pi_free (pi)

pointer	pi				#O Processing image structure

begin
	if (pi == NULL)
	    return

	call pi_unmap (PI_BPMPI(pi))
	call mfree (PI_BPMPI(pi), TY_STRUCT)
	call pi_unmap (PI_OBMPI(pi))
	call mfree (PI_OBMPI(pi), TY_STRUCT)
	call pi_unmap (PI_OMPI(pi))
	call mfree (PI_OMPI(pi), TY_STRUCT)
	call pi_unmap (PI_OPI(pi))
	call mfree (PI_OPI(pi), TY_STRUCT)
	call pi_unmap (pi)
	call mfree (pi, TY_STRUCT)
end


# PI_MAP -- Map image if needed.

procedure pi_map (pi)

pointer	pi				#O Processing image structure

errchk	zcall1

begin
	if (pi == NULL)
	    return

	if (PI_MAPPED(pi) == NO)
	    call zcall1 (PI_OPEN(pi), pi)
end


# PI_UNMAP -- Unmap image and free op pointer.

procedure pi_unmap (pi)

pointer	pi				#O Processing image structure

begin
	if (pi == NULL)
	    return

	if (PI_MAPPED(pi) == YES)
	    call zcall1 (PI_CLOSE(pi), pi)
	if (PI_OP(pi) != NULL)
	    call mfree (PI_OP(pi), TY_STRUCT)
	PI_MAPPED(pi) = NO
end


# PI_COMPARE -- Compare routine for PI structures.
#
# The ordering is set by the string Memc[PAR_SRTORDER(par)].

int procedure pi_compare (prc, pi1, pi2)

pointer	prc				# Processing data structure
pointer	pi1				# Processing image 1
pointer	pi2				# Processing image 2

int	i, strcmp()
pointer	cp

begin
	for (cp=PAR_SRTORDER(PRC_PAR(prc)); Memc[cp]!=EOS; cp=cp+1) {
	    switch (Memc[cp]) {
	    case 'P':
		if (PI_PRCTYPE(pi1) < PI_PRCTYPE(pi2))
		    return (-1)
		else if (PI_PRCTYPE(pi1) > PI_PRCTYPE(pi2))
		    return (1)
	    case 'F':
		i = strcmp (PI_FILTER(pi1), PI_FILTER(pi2))
		if (i != 0)
		    return (i)
	    case 'I':
		i = strcmp (PI_IMAGEID(pi1), PI_IMAGEID(pi2))
		if (i != 0)
		    return (i)
	    case 'S':
		if (PI_SORTVAL(pi1) < PI_SORTVAL(pi2))
		    return (-1)
		else if (PI_SORTVAL(pi1) > PI_SORTVAL(pi2))
		    return (1)
	    case 'N':
		i = strcmp (PI_NAME(pi1), PI_NAME(pi2))
		if (i != 0)
		    return (i)
	    }
	}

	return (0)
end
