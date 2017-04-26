include	<ctype.h>
include	<imhdr.h>
include	"ace.h"


# CONVOLVE -- Get a line of data possibly convolved.  Also get the unconvolved
# data, the sky data, the sky sigma data, and exposure map data.
#
# This routine must be called sequentially starting with the first line.
# It is initialized when the first line.  Memory is freed by using a final
# call with a line of zero.

procedure convolve (in, bpm, sky, sig, exp, bpval, bpdet, bpflg, offset, scale,
	line, cnv, scnv, indata, bp, cnvdata, scnvdata, skydata, sigdata,
	expdata, cnvwt, logfd, verbose)

pointer	in[2]		#I Image pointers
pointer	bpm[2]		#I BPM pointer
pointer	sky[2]		#I Sky map
pointer	sig[2]		#I Sigma map
pointer	exp[2]		#I Exposure map
int	bpval		#I Output bad pixel value
int	bpdet		#I Detection bad pixel ranges
int	bpflg		#I Flag bad pixel ranges
int	offset[2]	#I Offsets
real	scale[2]	#I Image scales
int	line		#I Line
char	cnv[ARB]	#I Convolution string
int	scnv		#I Convolve sky?
pointer	indata[2]	#O Pointers to unconvolved image data
pointer	bp		#O Bad pixel data
pointer	cnvdata		#O Pointer to convolved image data
pointer	scnvdata	#O Pointer to possibly convolved sky data
pointer	skydata[2]	#O Pointer to sky data
pointer	sigdata[2]	#O Pointer to sigma data corrected by exposure map
pointer	expdata[2]	#O Pointer to exposure map data
real	cnvwt		#O Weight for convolved sigma
int	logfd		#I Logfile
int	verbose		#I Verbose level

int	i, j, k,  nx, ny, nx2, ny2, nc, nl, mode, off
real	wts, wts1, wts2, asumr()
pointer	bpm2, kptr, ptr, symptr, symwptr
bool	dobpm, overlap, fp_equalr()

pointer	kernel, sym, symbuf, symwts
pointer bpbuf, bpwts, wtsl, scales
pointer	buf, buf2, buf3
data	kernel/NULL/, sym/NULL/, symbuf/NULL/, symwts/NULL/
data	bpbuf/NULL/, bpwts/NULL/, wtsl/NULL/, scales/NULL/
data	buf/NULL/, buf2/NULL/, buf3/NULL/

errchk	cnvparse, cnvgline2

begin
	if (scnv == YES) {
	    call convolves (in, bpm, sky, sig, exp, bpval, bpdet, bpflg,
		offset, scale, line, cnv, scnv, indata, bp, cnvdata, scnvdata,
		skydata, sigdata, expdata, cnvwt, logfd, verbose)
	    return
	}

	# If no convolution.
	if (cnv[1] == EOS) {
	    if (line == 0)
		return

	    call cnvgline1 (line, offset, in, bpm, indata,
	        bp, bpval, bpdet, bpflg)
	    call cnvgline2 (line, offset, in, sky, sig, exp, skydata,
		sigdata, expdata)
	    cnvwt = 1
	    if (in[2] == NULL)
		cnvdata = indata[1]
	    else
		call asubr_scale (Memr[indata[1]], scale[1],
		    Memr[indata[2]], scale[2], Memr[cnvdata], IM_LEN(in[1],1))
	    scnvdata = skydata[1]

	    return
	}

	# Free memory and reinitialize.
	if (line == 0) {
	    if (symbuf != NULL) {
		do i = 0, ARB {
		    ptr = Memi[symbuf+i]
		    if (ptr == -1)
			break
		    call mfree (ptr, TY_REAL)
		}
	    }
	    if (symwts != NULL) {
		do i = 0, ARB {
		    ptr = Memi[symwts+i]
		    if (ptr == -1)
			break
		    call mfree (ptr, TY_REAL)
		}
	    }
	    call mfree (scales, TY_REAL)
	    call mfree (wtsl, TY_REAL)
	    call mfree (kernel, TY_REAL)
	    call mfree (scales, TY_REAL)
	    call mfree (sym, TY_INT)
	    call mfree (symbuf, TY_POINTER)
	    call mfree (symwts, TY_POINTER)
	    call mfree (buf, TY_REAL)
	    call mfree (buf2, TY_REAL)
	    call mfree (buf3, TY_REAL)
	    call mfree (bpbuf, TY_INT)
	    call mfree (bpwts, TY_REAL)

	    return
	}

	# Initialize by getting the kernel coefficients, setting the
	# image I/O buffers using a scrolling array, and allocate memory.

	if (line == 1 || buf == NULL) {
	    if (buf != NULL) {
		if (symbuf != NULL) {
		    do i = 0, ARB {
			ptr = Memi[symbuf+i]
			if (ptr == -1)
			    break
			call mfree (ptr, TY_REAL)
		    }
		}
		if (symwts != NULL) {
		    do i = 0, ARB {
			ptr = Memi[symwts+i]
			if (ptr == -1)
			    break
			call mfree (ptr, TY_REAL)
		    }
		}
		call mfree (scales, TY_REAL)
		call mfree (wtsl, TY_REAL)
		call mfree (kernel, TY_REAL)
		call mfree (scales, TY_REAL)
		call mfree (sym, TY_INT)
		call mfree (symbuf, TY_POINTER)
		call mfree (symwts, TY_POINTER)
		call mfree (buf, TY_REAL)
		call mfree (buf2, TY_REAL)
		call mfree (buf3, TY_REAL)
		call mfree (bpbuf, TY_INT)
		call mfree (bpwts, TY_REAL)
	    }

	    nc = IM_LEN(in[1],1)
	    nl = IM_LEN(in[1],2)

	    call cnvparse (cnv, kernel, nx, ny, i, logfd, verbose)
	    nx2 = nx / 2
	    ny2 = ny / 2
	    call malloc (scales, ny, TY_REAL)
	    call calloc (wtsl, ny, TY_REAL)
	    call amovkr (1., Memr[scales], ny)

	    wts1 = 0; wts2 = 0; kptr = kernel
	    do i = 1, nx*ny {
		wts = Memr[kptr]
	        wts1 = wts1 + wts
		wts2 = wts2 + wts * wts
		kptr = kptr + 1
	    }
	    cnvwt = wts1 / sqrt (wts2)

	    # Check for lines which are simple scalings of the first line.
	    do i = 2, ny {
		kptr = kernel + (i - 1) * nx
		wts1 = 0.
		do k = 0, nx-1 {
		    if (Memr[kptr+k] == 0. || Memr[kernel+k] == 0.) {
			wts1 = 0.
			break
		    }
		    if (wts1 == 0.)
			wts1 = Memr[kptr+k] / Memr[kernel+k]
		    else {
			wts2 = Memr[kptr+k] / Memr[kernel+k]
			if (!fp_equalr (wts1, wts2))
			    break
		    }
		}
		if (wts1 != 0. && fp_equalr (wts1, wts2)) {
		    Memr[scales+i-1] = wts1
		    call amovr (Memr[kernel], Memr[kptr], nx)
		}
	    }

	    wts1 = 0
	    do i = 1, ny {
		kptr = kernel + (i - 1) * nx
		wts2 = 0.
		do j = 1, nx {
		    wts2 = wts2 + Memr[kptr]
		    kptr = kptr + 1
		}
		wts2 = wts2 * Memr[scales+i-1]
		Memr[wtsl+i-1] = wts2
		wts1 = wts1 + wts2
	    }
	    if (wts1 != 0.) {
		call adivkr (Memr[wtsl], wts1, Memr[wtsl], ny)
		call adivkr (Memr[kernel], wts1, Memr[kernel], nx*ny)
	    }
	    wts1 = asumr (Memr[kernel], nx) * asumr(Memr[scales],ny)
	    if (wts1 > 0)
		call adivkr (Memr[scales], wts1, Memr[scales], ny)

	    if (in[2] == NULL)
		bpm2 = NULL
	    else
		bpm2 = bpm[2] 
	    if (bpm[1] == NULL && bpm2 == NULL)
		dobpm = false
	    else
		dobpm = true
	    if (dobpm) {
		call malloc (bpbuf, nc*ny, TY_INT)
		call malloc (bpwts, nc, TY_REAL)
		call calloc (symwts, ny*ny+1, TY_POINTER)
		Memi[symwts+ny*ny] = -1
	    }

	    # Check for any line symmetries in the kernel.
	    call malloc (sym, ny, TY_INT)
	    call calloc (symbuf, ny*ny+1, TY_POINTER)
	    Memi[symbuf+ny*ny] = -1
	    do i = ny, 1, -1 {
		kptr = kernel + (i - 1) * nx
		do j = ny, 1, -1 {
		    ptr = kernel + (j - 1) * nx
		    do k = 0, nx-1 {
			if (Memr[kptr+k] != Memr[ptr+k])
			    break
		    }
		    if (k == nx) {
			Memi[sym+i-1] = j
			break
		    }
		}
	    }
	    do i = ny, 1, -1 {
		k = 0
		do j = ny, 1, -1
		    if (Memi[sym+j-1] == i)
			k = k + 1
		if (k == 1)
		    Memi[sym+i-1] = 0
	    }

	    call malloc (buf, nc*ny, TY_REAL)
	    if (in[2] != NULL) {
		call malloc (buf2, nc*ny, TY_REAL)
		call malloc (buf3, nc*ny, TY_REAL)
	    }

	    if (in[2] != NULL) {
		overlap = true
		if (1-offset[1] < 1 || nc-offset[1] > IM_LEN(in[2],1))
		    overlap = false
		if (1-offset[2] < 1 || nl-offset[2] > IM_LEN(in[2],2))
		    overlap = false
	    }
	    do i = 1, ny {
		call cnvgline1 (i, offset, in, bpm, indata, bp, bpval,
		    bpdet, bpflg)
		off = mod (i, ny) * nc
		call amovr (Memr[indata[1]], Memr[buf+off], nc)
		if (in[2] != NULL) {
		    call amovr (Memr[indata[2]], Memr[buf2+off], nc)
		    call asubr_scale (Memr[buf+off], scale[1],
			Memr[buf2+off], scale[2], Memr[buf3+off], nc)
		}
		if (dobpm)
		    call amovi (Memi[bp], Memi[bpbuf+off], nc)
	    }
	}

	# Get new line.
	j = line +  ny2
	if (j > ny && j <= nl) {
	    call cnvgline1 (j, offset, in, bpm, indata, bp, bpval, bpdet, bpflg)
	    off = mod (j, ny) * nc
	    call amovr (Memr[indata[1]], Memr[buf+off], nc)
	    if (in[2] != NULL) {
		call amovr (Memr[indata[2]], Memr[buf2+off], nc)
		call asubr_scale (Memr[buf+off], scale[1],
		    Memr[buf2+off], scale[2], Memr[buf3+off], nc)
	    }
	    if (dobpm) {
		ptr = bpbuf + off
		call amovi (Memi[bp], Memi[ptr], nc)
	    }
	}

	# Compute the convolution vector with boundary reflection.
	# Save and reuse lines with the same kernel weights apart
	# from a scale factor.

	kptr = kernel
	call aclrr (Memr[cnvdata], nc)
	if (dobpm)
	    call aclrr (Memr[bpwts], nc)
	do i = 1, ny {
	    j = line + i - ny2 - 1
	    if (j < 1)
		j = 2 - j
	    else if (j > nl)
		j = 2 * nl - j
	    off = mod (j, ny) * nc
	    if (in[2] == NULL)
		ptr = buf
	    else
		ptr = buf3
	    k = Memi[sym+i-1]
	    if (k == 0) {
		mode = 1
		symptr = ptr
		symwptr = bpwts
	    } else {
		if (k == i)
		    mode = 2
		else
		    mode = 3
		symptr = Memi[symbuf+(k-1)*ny+mod(j,ny)]
		if (symptr == NULL) {
		    call malloc (symptr, nc, TY_REAL)
		    Memi[symbuf+(k-1)*ny+mod(j,ny)] = symptr
		    mode = 2
		}
		if (dobpm) {
		    symwptr = Memi[symwts+(k-1)*ny+mod(j,ny)]
		    if (symwptr == NULL) {
			call malloc (symwptr, nc, TY_REAL)
			Memi[symwts+(k-1)*ny+mod(j,ny)] = symwptr
		    }
		}
	    }
	    if (dobpm)
		call convolve2 (Memr[ptr+off], Memr[cnvdata], Memr[symptr],
		    nc, Memr[kptr], Memr[scales+i-1], nx, Memi[bpbuf+off],
		    Memr[wtsl+i-1], Memr[bpwts], Memr[symwptr], mode)
	    else
		call convolve1 (Memr[ptr+off], Memr[cnvdata], Memr[symptr],
		    nc, Memr[kptr], Memr[scales+i-1], nx, mode)
	    kptr = kptr + nx
	}
	if (dobpm) {
	    do i = 0, nc-1
		if (Memr[bpwts+i] != 0.)
		    Memr[cnvdata+i] = Memr[cnvdata+i] / Memr[bpwts+i]
	}

	# Set the output vectors.
	off = mod (line, ny) * nc
	indata[1] = buf + off 
	if (dobpm) {
	    if (bpm2 == NULL)
		bp = bpbuf + off
	    else
		call amovi (Memi[bpbuf+off], Memi[bp], nc)
	}
	if (in[2] != NULL) {
	    if (overlap)
		indata[2] = buf2 + off
	    else
		call amovr (Memr[buf2+off], Memr[indata[2]], nc)
	}
	call cnvgline2 (line, offset, in, sky, sig, exp, skydata, sigdata,
	   expdata)
	scnvdata = skydata[1]
end


# CONVOLVES -- Get a line of convolved data.  Also get the unconvolved
# data, the sky data, sigma data, and exposure data.
#
# This routine must be called sequentially starting with the first line.
# It is initialized when the first line.  Memory is freed by using a final
# call with a line of zero.

procedure convolves (in, bpm, sky, sig, exp, bpval, bpdet, bpflg, offset, scale,
	line, cnv, scnv, indata, bp, cnvdata, scnvdata, skydata, sigdata,
	expdata, cnvwt, logfd, verbose)

pointer	in[2]		#I Image pointers
pointer	bpm[2]		#I BPM pointer
pointer	sky[2]		#I Sky map
pointer	sig[2]		#I Sigma map
pointer	exp[2]		#I Exposure map
int	bpval		#I Output bad pixel value
int	bpdet		#I Detection bad pixel ranges
int	bpflg		#I Flag bad pixel ranges
int	offset[2]	#I Offsets
real	scale[2]	#I Image scales
int	line		#I Line
char	cnv[ARB]	#I Convolution string
int	scnv		#I Convolve sky?
pointer	indata[2]	#O Pointers to unconvolved image data
pointer	bp		#O Bad pixel data
pointer	cnvdata		#O Pointer to convolved image data
pointer	scnvdata	#O Pointer to convolved sky data
pointer	skydata[2]	#O Pointer to sky data
pointer	sigdata[2]	#O Pointer to sigma data corrected by exposure map
pointer	expdata[2]	#O Pointer to exposure map data
real	cnvwt		#O Weight for convolved sigma
int	logfd		#I Logfile
int	verbose		#I Verbose level

int	i, j, k,  nx, ny, nx2, ny2, nc, nl, mode, off
real	wts, wts1, wts2, asumr()
pointer	bpm2, kptr, ptr, sptr, symptr, symwptr
bool	dobpm, overlap, fp_equalr()

pointer	kernel, sym, symbuf, symwts
pointer bpbuf, bpwts, wtsl, scales
pointer	buf, buf2, buf3
pointer	sbuf, sbuf2, sbuf3
pointer	sigbuf, sigbuf2
pointer	ebuf, ebuf2
data	kernel/NULL/, sym/NULL/, symbuf/NULL/, symwts/NULL/
data	bpbuf/NULL/, bpwts/NULL/, wtsl/NULL/, scales/NULL/
data	buf/NULL/, buf2/NULL/, buf3/NULL/
data	sbuf/NULL/, sbuf2/NULL/, sbuf3/NULL/
data	sigbuf/NULL/, sigbuf2/NULL/
data	ebuf/NULL/, ebuf2/NULL/

errchk	cnvparse, cnvgline2

begin
	# If no convolution.
	if (cnv[1] == EOS) {
	    if (line == 0)
		return

	    call cnvgline1 (line, offset, in, bpm, indata,
	        bp, bpval, bpdet, bpflg)
	    call cnvgline2 (line, offset, in, sky, sig, exp, skydata,
		sigdata, expdata)
	    cnvwt = 1
	    if (in[2] == NULL)
		cnvdata = indata[1]
	    else
		call asubr_scale (Memr[indata[1]], scale[1],
		    Memr[indata[2]], scale[2], Memr[cnvdata], IM_LEN(in[1],1))
	    scnvdata = skydata[1]

	    return
	}

	# Free memory and initialize.
	if (line == 0) {
	    if (symbuf != NULL) {
		do i = 0, ARB {
		    ptr = Memi[symbuf+i]
		    if (ptr == -1)
			break
		    call mfree (ptr, TY_REAL)
		}
	    }
	    if (symwts != NULL) {
		do i = 0, ARB {
		    ptr = Memi[symwts+i]
		    if (ptr == -1)
			break
		    call mfree (ptr, TY_REAL)
		}
	    }
	    call mfree (scnvdata, TY_REAL)
	    call mfree (scales, TY_REAL)
	    call mfree (wtsl, TY_REAL)
	    call mfree (kernel, TY_REAL)
	    call mfree (scales, TY_REAL)
	    call mfree (sym, TY_INT)
	    call mfree (symbuf, TY_POINTER)
	    call mfree (symwts, TY_POINTER)
	    call mfree (buf, TY_REAL)
	    call mfree (buf2, TY_REAL)
	    call mfree (buf3, TY_REAL)
	    call mfree (bpbuf, TY_INT)
	    call mfree (bpwts, TY_REAL)
	    call mfree (sbuf, TY_REAL)
	    call mfree (sbuf2, TY_REAL)
	    call mfree (sbuf3, TY_REAL)
	    call mfree (sigbuf, TY_REAL)
	    call mfree (ebuf, TY_REAL)

	    return
	}

	# Initialize by getting the kernel coefficients, setting the
	# image I/O buffers using a scrolling array, and allocate memory.

	if (line == 1 || buf == NULL) {
	    if (buf != NULL) {
		if (symbuf != NULL) {
		    do i = 0, ARB {
			ptr = Memi[symbuf+i]
			if (ptr == -1)
			    break
			call mfree (ptr, TY_REAL)
		    }
		}
		if (symwts != NULL) {
		    do i = 0, ARB {
			ptr = Memi[symwts+i]
			if (ptr == -1)
			    break
			call mfree (ptr, TY_REAL)
		    }
		}
		call mfree (scnvdata, TY_REAL)
		call mfree (scales, TY_REAL)
		call mfree (wtsl, TY_REAL)
		call mfree (kernel, TY_REAL)
		call mfree (scales, TY_REAL)
		call mfree (sym, TY_INT)
		call mfree (symbuf, TY_POINTER)
		call mfree (symwts, TY_POINTER)
		call mfree (buf, TY_REAL)
		call mfree (buf2, TY_REAL)
		call mfree (buf3, TY_REAL)
		call mfree (bpbuf, TY_INT)
		call mfree (bpwts, TY_REAL)
		call mfree (sbuf, TY_REAL)
		call mfree (sbuf2, TY_REAL)
		call mfree (sbuf3, TY_REAL)
		call mfree (sigbuf, TY_REAL)
		call mfree (ebuf, TY_REAL)
	    }

	    nc = IM_LEN(in[1],1)
	    nl = IM_LEN(in[1],2)

	    call cnvparse (cnv, kernel, nx, ny, i, logfd, verbose)
	    nx2 = nx / 2
	    ny2 = ny / 2
	    call malloc (scnvdata, nc, TY_REAL)
	    call malloc (scales, ny, TY_REAL)
	    call calloc (wtsl, ny, TY_REAL)
	    call amovkr (1., Memr[scales], ny)

	    wts1 = 0; wts2 = 0; kptr = kernel
	    do i = 1, nx*ny {
		wts = Memr[kptr]
	        wts1 = wts1 + wts
		wts2 = wts2 + wts * wts
		kptr = kptr + 1
	    }
	    cnvwt = wts1 / sqrt (wts2)

	    # Check for lines which are simple scalings of the first line.
	    do i = 2, ny {
		kptr = kernel + (i - 1) * nx
		wts1 = 0.
		do k = 0, nx-1 {
		    if (Memr[kptr+k] == 0. || Memr[kernel+k] == 0.) {
			wts1 = 0.
			break
		    }
		    if (wts1 == 0.)
			wts1 = Memr[kptr+k] / Memr[kernel+k]
		    else {
			wts2 = Memr[kptr+k] / Memr[kernel+k]
			if (!fp_equalr (wts1, wts2))
			    break
		    }
		}
		if (wts1 != 0. && fp_equalr (wts1, wts2)) {
		    Memr[scales+i-1] = wts1
		    call amovr (Memr[kernel], Memr[kptr], nx)
		}
	    }

	    wts1 = 0
	    do i = 1, ny {
		kptr = kernel + (i - 1) * nx
		wts2 = 0.
		do j = 1, nx {
		    wts2 = wts2 + Memr[kptr]
		    kptr = kptr + 1
		}
		wts2 = wts2 * Memr[scales+i-1]
		Memr[wtsl+i-1] = wts2
		wts1 = wts1 + wts2
	    }
	    if (wts1 != 0.) {
		call adivkr (Memr[wtsl], wts1, Memr[wtsl], ny)
		call adivkr (Memr[kernel], wts1, Memr[kernel], nx*ny)
	    }
	    wts1 = asumr (Memr[kernel], nx) * asumr(Memr[scales],ny)
	    if (wts1 > 0)
		call adivkr (Memr[scales], wts1, Memr[scales], ny)

	    if (in[2] == NULL)
		bpm2 = NULL
	    else
		bpm2 = bpm[2] 
	    if (bpm[1] == NULL && bpm2 == NULL)
		dobpm = false
	    else
		dobpm = true
	    if (dobpm) {
		call malloc (bpbuf, nc*ny, TY_INT)
		call malloc (bpwts, nc, TY_REAL)
		call calloc (symwts, ny*ny+1, TY_POINTER)
		Memi[symwts+ny*ny] = -1
	    }

	    # Check for any line symmetries in the kernel.
	    call malloc (sym, ny, TY_INT)
	    call calloc (symbuf, ny*ny+1, TY_POINTER)
	    Memi[symbuf+ny*ny] = -1
	    do i = ny, 1, -1 {
		kptr = kernel + (i - 1) * nx
		do j = ny, 1, -1 {
		    ptr = kernel + (j - 1) * nx
		    do k = 0, nx-1 {
			if (Memr[kptr+k] != Memr[ptr+k])
			    break
		    }
		    if (k == nx) {
			Memi[sym+i-1] = j
			break
		    }
		}
	    }
	    do i = ny, 1, -1 {
		k = 0
		do j = ny, 1, -1
		    if (Memi[sym+j-1] == i)
			k = k + 1
		if (k == 1)
		    Memi[sym+i-1] = 0
	    }

	    call malloc (buf, nc*ny, TY_REAL)
	    call malloc (sbuf, nc*ny, TY_REAL)
	    call malloc (sigbuf, nc*ny, TY_REAL)
	    call malloc (ebuf, nc*ny, TY_REAL)
	    if (in[2] != NULL) {
		call malloc (buf2, nc*ny, TY_REAL)
		call malloc (buf3, nc*ny, TY_REAL)
		call malloc (sbuf2, nc*ny, TY_REAL)
		call malloc (sbuf3, nc*ny, TY_REAL)
		call malloc (sigbuf2, nc*ny, TY_REAL)
		call malloc (ebuf2, nc*ny, TY_REAL)
	    }

	    if (in[2] != NULL) {
		overlap = true
		if (1-offset[1] < 1 || nc-offset[1] > IM_LEN(in[2],1))
		    overlap = false
		if (1-offset[2] < 1 || nl-offset[2] > IM_LEN(in[2],2))
		    overlap = false
	    }
	    do i = 1, ny {
		call cnvgline1 (i, offset, in, bpm, indata, bp, bpval,
		    bpdet, bpflg)
		call cnvgline2 (i, offset, in, sky, sig, exp, skydata, sigdata,
		   expdata)
		off = mod (i, ny) * nc
		call amovr (Memr[indata[1]], Memr[buf+off], nc)
		call amovr (Memr[skydata[1]], Memr[sbuf+off], nc)
		call amovr (Memr[sigdata[1]], Memr[sigbuf+off], nc)
		call amovr (Memr[expdata[1]], Memr[ebuf+off], nc)
		if (in[2] != NULL) {
		    call amovr (Memr[indata[2]], Memr[buf2+off], nc)
		    call amovr (Memr[sigdata[2]], Memr[sigbuf2+off], nc)
		    call amovr (Memr[expdata[2]], Memr[ebuf2+off], nc)
		    call asubr_scale (Memr[buf+off], scale[1],
			Memr[buf2+off], scale[2], Memr[buf3+off], nc)
		}
		if (dobpm)
		    call amovi (Memi[bp], Memi[bpbuf+off], nc)
	    }
	}

	# Get new line.
	j = line +  ny2
	if (j > ny && j <= nl) {
	    call cnvgline1 (j, offset, in, bpm, indata, bp, bpval, bpdet, bpflg)
	    call cnvgline2 (j, offset, in, sky, sig, exp, skydata, sigdata,
	       expdata)
	    off = mod (j, ny) * nc
	    call amovr (Memr[indata[1]], Memr[buf+off], nc)
	    call amovr (Memr[skydata[1]], Memr[sbuf+off], nc)
	    call amovr (Memr[sigdata[1]], Memr[sigbuf+off], nc)
	    call amovr (Memr[expdata[1]], Memr[ebuf+off], nc)
	    if (in[2] != NULL) {
		call amovr (Memr[indata[2]], Memr[buf2+off], nc)
		call asubr_scale (Memr[buf+off], scale[1],
		    Memr[buf2+off], scale[2], Memr[buf3+off], nc)
		call amovr (Memr[skydata[2]], Memr[sbuf2+off], nc)
		call amovr (Memr[sigdata[2]], Memr[sigbuf2+off], nc)
		call amovr (Memr[expdata[2]], Memr[ebuf2+off], nc)
		call asubr_scale (Memr[sbuf+off], scale[1],
		    Memr[sbuf2+off], scale[2], Memr[sbuf3+off], nc)
	    }
	    if (dobpm) {
		ptr = bpbuf + off
		call amovi (Memi[bp], Memi[ptr], nc)
	    }
	}

	# Compute the convolution vector with boundary reflection.
	# Save and reuse lines with the same kernel weights apart
	# from a scale factor.

	kptr = kernel
	call aclrr (Memr[cnvdata], nc)
	call aclrr (Memr[scnvdata], nc)
	if (dobpm)
	    call aclrr (Memr[bpwts], nc)
	do i = 1, ny {
	    j = line + i - ny2 - 1
	    if (j < 1)
		j = 2 - j
	    else if (j > nl)
		j = 2 * nl - j
	    off = mod (j, ny) * nc
	    if (in[2] == NULL) {
		ptr = buf
		sptr = sbuf
	    } else {
		ptr = buf3
		sptr = sbuf3
	    }
	    k = Memi[sym+i-1]
	    if (k == 0) {
		mode = 1
		symptr = ptr
		symwptr = bpwts
	    } else {
		if (k == i)
		    mode = 2
		else
		    mode = 3
		symptr = Memi[symbuf+(k-1)*ny+mod(j,ny)]
		if (symptr == NULL) {
		    call malloc (symptr, nc, TY_REAL)
		    Memi[symbuf+(k-1)*ny+mod(j,ny)] = symptr
		    mode = 2
		}
		if (dobpm) {
		    symwptr = Memi[symwts+(k-1)*ny+mod(j,ny)]
		    if (symwptr == NULL) {
			call malloc (symwptr, nc, TY_REAL)
			Memi[symwts+(k-1)*ny+mod(j,ny)] = symwptr
		    }
		}
	    }
	    if (dobpm) {
		call convolve2 (Memr[ptr+off], Memr[cnvdata], Memr[symptr],
		    nc, Memr[kptr], Memr[scales+i-1], nx, Memi[bpbuf+off],
		    Memr[wtsl+i-1], Memr[bpwts], Memr[symwptr], mode)
		call convolve2 (Memr[sptr+off], Memr[scnvdata], Memr[symptr],
		    nc, Memr[kptr], Memr[scales+i-1], nx, Memi[bpbuf+off],
		    Memr[wtsl+i-1], Memr[bpwts], Memr[symwptr], mode)
	    } else {
		call convolve1 (Memr[ptr+off], Memr[cnvdata], Memr[symptr],
		    nc, Memr[kptr], Memr[scales+i-1], nx, mode)
		call convolve1 (Memr[sptr+off], Memr[scnvdata], Memr[symptr],
		    nc, Memr[kptr], Memr[scales+i-1], nx, mode)
	    }
	    kptr = kptr + nx
	}
	if (dobpm) {
	    do i = 0, nc-1 {
		if (Memr[bpwts+i] != 0.) {
		    Memr[cnvdata+i] = Memr[cnvdata+i] / Memr[bpwts+i]
		    Memr[scnvdata+i] = Memr[scnvdata+i] / Memr[bpwts+i]
		}
	    }
	}

	# Set the output vectors.
	off = mod (line, ny) * nc
	indata[1] = buf + off 
	skydata[1] = sbuf + off 
	sigdata[1] = sigbuf + off 
	expdata[1] = ebuf + off 
	if (dobpm) {
	    if (bpm2 == NULL)
		bp = bpbuf + off
	    else
		call amovi (Memi[bpbuf+off], Memi[bp], nc)
	}
	if (in[2] != NULL) {
	    if (overlap) {
		indata[2] = buf2 + off
		skydata[2] = sbuf2 + off
		sigdata[2] = sigbuf2 + off
		expdata[2] = ebuf2 + off
	    } else {
		call amovr (Memr[buf2+off], Memr[indata[2]], nc)
		call amovr (Memr[sbuf2+off], Memr[skydata[2]], nc)
		call amovr (Memr[sigbuf2+off], Memr[sigdata[2]], nc)
		call amovr (Memr[ebuf2+off], Memr[expdata[2]], nc)
	    }
	}
end


# CONVOLVE1 --  One dimensional convolution with boundary reflection.
#
# The convolution is added to the output so that it might be used
# as part of a 2D convolution.

procedure convolve1 (in, out, save, nc, xkernel, scale, nx, mode)

real	in[nc]			#I Input data to be convolved
real	out[nc]			#O Output convolved data
real	save[nc]		#U Output saved data
int	nc			#I Number of data points
real	xkernel[nx]		#I Convolution weights
real	scale			#I Scale for saved vector
int	nx			#I Number of convolution points (must be odd)
int	mode			#I Mode (1=no save, 2=save, 3=use save)

int	i, j, k, nx2
real	val
bool	fp_equalr()

begin
	if (mode == 1) {
	    nx2 = nx / 2
	    do i = 1, nx2 {
		val = 0
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k < 1)
			k = 2 - k
		    val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
	    }
	    do i = nx2+1, nc-nx2 {
		k = i - nx2
		val = 0
		do j = 1, nx {
		    val = val + in[k] * xkernel[j]
		    k = k + 1
		}
		out[i] = out[i] + val
	    }
	    do i = nc-nx2+1, nc {
		val = 0
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k > nc)
			k = 2 * nc - k
		    val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
	    }
	} else if (mode == 2) {
	    nx2 = nx / 2
	    do i = 1, nx2 {
		val = 0
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k < 1)
			k = 2 - k
		    val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
		save[i] = val
	    }
	    do i = nx2+1, nc-nx2 {
		k = i - nx2
		val = 0
		do j = 1, nx {
		    val = val + in[k] * xkernel[j]
		    k = k + 1
		}
		out[i] = out[i] + val
		save[i] = val
	    }
	    do i = nc-nx2+1, nc {
		val = 0
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k > nc)
			k = 2 * nc - k
		    val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
		save[i] = val
	    }
	} else {
	    if (fp_equalr (1., scale)) {
		do i = 1, nc
		    out[i] = out[i] + save[i]
	    } else {
		do i = 1, nc
		    out[i] = out[i] + scale * save[i]
	    }
	}
end


# CONVOLVE2 --  One dimensional convolution with boundary reflection & masking.
#
# The convolution is added to the output so that it might be used
# as part of a 2D convolution.

procedure convolve2 (in, out, save, nc, xkernel, scale, nx, bp,
	wtssum, wts, wtsave, mode)

real	in[nc]			#I Input data to be convolved
real	out[nc]			#O Output convolved data
real	save[nc]		#U Output saved data
int	nc			#I Number of data points
real	xkernel[nx]		#I Convolution weights
real	scale			#I Scale for saved vector
int	nx			#I Number of convolution points (must be odd)
int	bp[nc]			#I Bad pixel data
real	wtssum			#I Sum of weights
real	wts[nc]			#I Weights
real	wtsave[nc]		#U Output saved weight data
int	mode			#I Mode (1=no save, 2=save, 3=use save)

int	i, j, k, nx2
real	val, wt
bool	fp_equalr()

begin
	if (mode == 1) {
	    nx2 = nx / 2
	    do i = 1, nx2 {
		val = 0
		wt = wtssum
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k < 1)
			k = 2 - k
		    if (bp[k] > 0)
			wt = wt - xkernel[j]
		    else
			val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
		wts[i] = wts[i] + wt
	    }
	    do i = nx2+1, nc-nx2 {
		k = i - nx2
		val = 0
		wt = wtssum
		do j = 1, nx {
		    if (bp[k] > 0)
			wt = wt - xkernel[j]
		    else
			val = val + in[k] * xkernel[j]
		    k = k + 1
		}
		out[i] = out[i] + val
		wts[i] = wts[i] + wt
	    }
	    do i = nc-nx2+1, nc {
		val = 0
		wt = wtssum
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k > nc)
			k = 2 * nc - k
		    if (bp[k] > 0)
			wt = wt - xkernel[j]
		    else
			val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
		wts[i] = wts[i] + wt
	    }
	} else if (mode == 2) {
	    nx2 = nx / 2
	    do i = 1, nx2 {
		val = 0
		wt = wtssum
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k < 1)
			k = 2 - k
		    if (bp[k] > 0)
			wt = wt - xkernel[j]
		    else
			val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
		wts[i] = wts[i] + wt
		save[i] = val
		wtsave[i] = wt
	    }
	    do i = nx2+1, nc-nx2 {
		k = i - nx2
		val = 0
		wt = wtssum
		do j = 1, nx {
		    if (bp[k] > 0)
			wt = wt - xkernel[j]
		    else
			val = val + in[k] * xkernel[j]
		    k = k + 1
		}
		out[i] = out[i] + val
		wts[i] = wts[i] + wt
		save[i] = val
		wtsave[i] = wt
	    }
	    do i = nc-nx2+1, nc {
		val = 0
		wt = wtssum
		do j = 1, nx {
		    k = i + j - nx2 - 1
		    if (k > nc)
			k = 2 * nc - k
		    if (bp[k] > 0)
			wt = wt - xkernel[j]
		    else
			val = val + in[k] * xkernel[j]
		}
		out[i] = out[i] + val
		wts[i] = wts[i] + wt
		save[i] = val
		wtsave[i] = wt
	    }
	} else {
	    if (fp_equalr (1., scale)) {
		do i = 1, nc {
		    out[i] = out[i] + save[i]
		    wts[i] = wts[i] + wtsave[i]
		}
	    } else {
		do i = 1, nc {
		    out[i] = out[i] + scale * save[i]
		    wts[i] = wts[i] + scale * wtsave[i]
		}
	    }
	}
end


# ASUBR_SCALE -- out = in1 * scale1 - in2 * scale2

procedure asubr_scale (in1, scale1, in2, scale2, out, n)

real	in1[n]			#I Input vector
real	scale1			#I Scale
real	in2[n]			#I Input vector
real	scale2			#I Scale
real	out[n]			#O Output vector
int	n			#I Number of points

int	i

begin
	if (scale1 == 1. && scale2 == 1.)
	    call asubr (in1, in2, out, n)
	else if (scale1 == 1.) {
	    do i = 1, n
		out[i] = in1[i] - in2[i] * scale2
	} else if (scale2 == 1.) {
	    do i = 1, n
		out[i] = in1[i] * scale1 - in2[i]
	} else {
	    do i = 1, n
		out[i] = in1[i] * scale1 - in2[i] * scale2
	}
end


procedure cnvgline1 (line, offset, im, bpm, imdata, bp, bpval, bpdet, bpflg)

int	line			#I Line to be read
int	offset[2]		#I Offsets
pointer	im[2]			#I Image pointers
pointer	bpm[2]			#I Bad pixel mask pointers
pointer	imdata[2]		#U Image data
pointer	bp			#U Bad pixel data
int	bpval			#I Output bad pixel value
int	bpdet			#I Detection bad pixel ranges
int	bpflg			#I Flag bad pixel ranges

bool	overlap
int	nl1, nl2, loff, l2
int	nc1, nc2, nc3, off1, off2, off3, c1, c2
pointer	bp2
pointer	imgl2r(), imgl2i()


begin
	# Get data for first image.  Use IMIO buffers except the
	# bad pixel buffer is not used if there is a second image.

	imdata[1] = imgl2r (im[1], line)
	if (bpm[1] != NULL) {
	    if (im[2] == NULL)
		bp = imgl2i (bpm[1], line)
	    else
		call amovi (Memi[imgl2i(bpm[1],line)], Memi[bp],
		    IM_LEN(bpm[1],1))
	    call cnvbp (Memi[bp], IM_LEN(bpm[1],1), bpval, bpdet, bpflg)
	}
	if (im[2] == NULL)
	    return

	# Initialize.
	if (line == 1) {
	    nc1 = IM_LEN(im[1],1)
	    nc2 = IM_LEN(im[2],1)
	    nl1 = IM_LEN(im[1],2)
	    nl2 = IM_LEN(im[2],2)

	    overlap = true
	    if (1-offset[1] < 1 || nc1-offset[1] > nc2)
		overlap = false
	    if (1-offset[2] < 1 || nl1-offset[2] > nl2)
		overlap = false

	    off2 = -offset[1]
	    c1 = max (1, 1+off2)
	    c2 = min (nc2, nc1+off2)
	    nc2 = c2 - c1 + 1
	    off1 = c1 - off2 - 1
	    off3 = c2 - off2
	    off2 = max (0, off2)
	    nc3 = nc1 - off3
	    if (off1 > 0) {
		call aclrr (Memr[imdata[2]], off1)
		if (bpm[1] == NULL)
		    call amovki (1, Memi[bp], off1)
	    }
	    if (nc3 > 0) {
		call aclrr (Memr[imdata[2]+off3], nc3)
		if (bpm[1] == NULL)
		    call amovki (1, Memi[bp+off3], nc3)
	    }

	    loff = -offset[2]
	    if (loff < 0)
		call aclrr (Memr[imdata[2]], nc1)
	}

	l2 = line + loff
	if (l2 < 1 || l2 > nl2) {
	    call amovki (1, Memi[bp], nc1)
	    return
	}

	if (overlap) {
	    imdata[2] = imgl2r (im[2], l2) + off2
	    if (bpm[1] != NULL && bpm[2] != NULL) {
		bp2 = imgl2i (bpm[2], l2)
		call cnvbp (Memi[bp2+off2], nc1, bpval, bpdet, bpflg)
		call amaxi (Memi[bp2+off2], Memi[bp], Memi[bp], nc1)
	    } else if (bpm[2] != NULL) {
		call amovi (Memi[imgl2i(bpm[2],l2)+off2], Memi[bp], nc1)
		call cnvbp (Memi[bp], nc1, bpval, bpdet, bpflg)
	    }
	} else {
	    # Copy the overlapping parts of the second image to the output
	    # buffers which must be allocated externally.  Use the bad pixel
	    # mask to flag regions where there is no overlap.

	    call amovr (Memr[imgl2r(im[2],l2)+off2], Memr[imdata[2]+off1], nc2)
	    if (bpm[1] != NULL && bpm[2] != NULL) {
		bp2 = imgl2i (bpm[2], l2)
		call cnvbp (Memi[bp2+off2], nc2, bpval, bpdet, bpflg)
		call amaxi (Memi[bp2+off2], Memi[bp+off1], Memi[bp+off1], nc2)
		if (off1 > 0)
		    call amovki (1, Memi[bp], off1)
		if (nc3 > 0)
		    call amovki (1, Memi[bp+off3], nc3)
	    } else if (bpm[2] != NULL) {
		call amovi (Memi[imgl2i(bpm[2],l2)+off2], Memi[bp+off1], nc2)
		call cnvbp (Memi[bp+off1], nc2, bpval, bpdet, bpflg)
	    }
	}
end


# CNVBP -- Reset a bad pixel line based on user parameters.
#
# Bad pixels in the bpdet ranges will be set to the value specified by the
# bpval argument.  Note that if bpval is INDEF it passes the input value but
# limits the value to be less than NUMSTART since values equal to or greater
# than this are used for object information.  Bad pixels in the bpflg ranges
# will be set to -1 and will not be excluded from detection and evaluation
# but will result in a flag being set for the object.  Bad pixels which are
# not in either range list will be ignored by setting the return value to 0.

procedure cnvbp (bp, nbp, bpval, bpdet, bpflg)

int	bp[nbp]				#U Bad pixel array
int	nbp				#I Number of pixels
int	bpval				#I Output bad pixel value
int	bpdet				#I Bad pixel ranges in detect
int	bpflg				#I Bad pixel ranges to flag

int	i, j
bool	is_in_range()

begin
	do i = 1, nbp {
	    j = bp[i]
	    if (j == 0)
		next
		
	    if (IS_INDEFI(bpdet)) {
		if (IS_INDEFI(bpval))
		    bp[i] = min (j, NUMSTART-1)
		else
		    bp[i] = min (bpval, NUMSTART-1)
	    } else if (is_in_range (bpdet, j)) {
		if (IS_INDEFI(bpval))
		    bp[i] = min (j, NUMSTART-1)
		else
		    bp[i] = min (bpval, NUMSTART-1)
	    } else if (IS_INDEFI(bpflg))
		bp[i] = 0
	    else if (is_in_range (bpflg, j))
		bp[i] = -1
	    else
		bp[i] = 0
	}
end


procedure cnvgline2 (line, offset, im, skymap, sigmap, expmap,
	skydata, sigdata, expdata)

int	line			#I Line to be read
int	offset[2]		#I Offsets
pointer	im[2]			#I Image pointers
pointer	skymap[2]		#I Sky map
pointer	sigmap[2]		#I Sky sigma map
pointer	expmap[2]		#I Exposure map
pointer	skydata[2]		#U Sky data
pointer	sigdata[2]		#U Sky sigma data
pointer	expdata[2]		#U Exposure map data

bool	overlap
int	nl1, nl2, loff, l2
int	nc1, nc2, nc3, off1, off2, off3, c1, c2
pointer	ptr

pointer	map_glr()
errchk	map_glr

begin
	# Get data for first image.

	skydata[1] = map_glr (skymap[1], line, READ_ONLY)
	if (expmap[1] == NULL)
	    sigdata[1] = map_glr (sigmap[1], line, READ_ONLY)
	else {
	    sigdata[1] = map_glr (sigmap[1], line, READ_WRITE)
	    expdata[1] = map_glr (expmap[1], line, READ_ONLY)
	    call expsigma (Memr[sigdata[1]], Memr[expdata[1]],
		IM_LEN(im[1],1), 0)
	}
	if (im[2] == NULL)
	    return

	# Initialize.
	if (line == 1) {
	    nc1 = IM_LEN(im[1],1)
	    nc2 = IM_LEN(im[2],1)
	    nl1 = IM_LEN(im[1],2)
	    nl2 = IM_LEN(im[2],2)

	    overlap = true
	    if (1-offset[1] < 1 || nc1-offset[1] > nc2)
		overlap = false
	    if (1-offset[2] < 1 || nl1-offset[2] > nl2)
		overlap = false

	    off2 = -offset[1]
	    c1 = max (1, 1+off2)
	    c2 = min (nc2, nc1+off2)
	    nc2 = c2 - c1 + 1
	    off1 = c1 - off2 - 1
	    off3 = c2 - off2
	    nc3 = nc1 - off3
	    if (off1 > 0) {
		call aclrr (Memr[skydata[2]], off1)
		call aclrr (Memr[sigdata[2]], off1)
		if (expmap[2] != NULL)
		    call aclrr (Memr[expdata[2]], off1)
	    }
	    if (nc3 > 0) {
		call aclrr (Memr[skydata[2]+off3], nc3)
		call aclrr (Memr[sigdata[2]+off3], nc3)
		if (expmap[2] != NULL)
		    call aclrr (Memr[expdata[2]+off3], nc3)
	    }

	    loff = -offset[2]
	    if (loff < 0) {
		call aclrr (Memr[skydata[2]], nc1)
		call aclrr (Memr[sigdata[2]], nc1)
		if (expmap[2] != NULL)
		    call aclrr (Memr[expdata[2]], nc1)
	    }
	}

	l2 = line + loff
	if (l2 < 1 || l2 > nl2)
	    return

	if (overlap) {
	    skydata[2] = map_glr (skymap[2], l2, READ_ONLY) + off2
	    if (expmap[2] == NULL)
		sigdata[2] = map_glr (sigmap[2], l2, READ_ONLY) + off2
	    else {
		sigdata[2] = map_glr (sigmap[2], l2, READ_WRITE) + off2
		expdata[2] = map_glr (expmap[2], l2, READ_ONLY) + off2
		call expsigma (Memr[sigdata[2]], Memr[expdata[2]], nc2, 0)
	    }
	} else {
	    # Copy the overlapping parts of the second image to the output
	    # buffers which must be allocated externally.

	    ptr = map_glr(skymap[2],l2,READ_ONLY)
	    call amovr (Memr[ptr+off2], Memr[skydata[2]+off1], nc2)
	    ptr = map_glr(sigmap[2],l2,READ_ONLY)
	    call amovr (Memr[ptr+off2], Memr[sigdata[2]+off1], nc2)
	    if (expmap[2] != NULL) {
		ptr = map_glr(expmap[2],l2,READ_ONLY)
		call amovr (Memr[ptr+off2], Memr[expdata[2]+off1], nc2)
		call expsigma (Memr[sigdata[2]], Memr[expdata[2]], nc2, 0)
	    }
	}
end


# CNVPARSE -- Parse convolution string.

procedure cnvparse (cnvstr, kernel, nx, ny, scnv, logfd, verbose)

char	cnvstr[ARB]		#I Convolution string
pointer	kernel			#O Pointer to convolution kernel elements
int	nx, ny			#O Convolution size
int	scnv			#O Convolve sky?
int	logfd			#I Log file descriptor
int	verbose			#I Verbose level

int	i, j, nx2, ny2
int	ip, fd, open(), fscan(), nscan(), ctor(), ctoi(), strncmp()
real	val, sx, sy
pointer	ptr
errchk	open

define	unknown_	10

begin
	# Determine if the sky should be convolved.
	for (ip=1; IS_WHITE(cnvstr[ip]); ip=ip+1)
	    ;
	if (strncmp (cnvstr[ip], "sky", 3) == 0) {
	    scnv = YES
	    ip = ip + 3
	    for (;IS_WHITE(cnvstr[ip]); ip=ip+1)
		;
	} else
	    scnv = NO

	# Parse the convolution function.
	kernel = NULL
	if (cnvstr[ip] == EOS) {
	    scnv = NO
	    nx = 1
	    ny = 1
	    call malloc (kernel, 1, TY_REAL)
	    Memr[kernel] = 1
	} else if (cnvstr[ip] == '@') {
	    fd = open (cnvstr[ip+1], READ_ONLY, TEXT_FILE)
	    call malloc (kernel, 100, TY_REAL)
	    i = 0
	    nx = 0
	    ny = 0
	    while (fscan (fd) != EOF) {
		do j = 1, ARB {
		    call gargr (val)
		    if (nscan() < j)
			break
		    Memr[kernel+i] = val
		    i = i + 1
		    if (mod (i, 100) == 0)
			call realloc (kernel, i+100, TY_REAL)
		}
		j = j - 1
		if (nx == 0)
		    nx = j
		else if (j != nx) {
		    call close (fd)
		    call error (1,
			"Number of convolution elements inconsistent")
		}
		ny = ny + 1
	    }
	    call close (fd)
	} else if (IS_ALPHA(cnvstr[ip])) {
	    if (strncmp ("block", cnvstr[ip], 5) == 0) {
		i = 6
		if (ctoi (cnvstr[ip], i, nx) == 0 ||
		    ctoi (cnvstr[ip], i, ny) == 0)
		    goto unknown_
		call malloc (kernel, nx*ny, TY_REAL)
		call amovkr (1., Memr[kernel], nx*ny)
	    } else if (strncmp ("bilinear", cnvstr[ip], 8) == 0) {
		i = 9
		if (ctoi (cnvstr[ip], i, nx) == 0 ||
		    ctoi (cnvstr[ip], i, ny) == 0)
		    goto unknown_
		call malloc (kernel, nx*ny, TY_REAL)

		nx2 = nx / 2
		ny2 = ny / 2
		ptr = kernel
		do j = 0, ny-1 {
		    do i = 0, nx-1 {
			Memr[ptr] = (nx2-abs(nx2-i)+1) * (ny2-abs(ny2-j)+1)
			ptr = ptr + 1
		    }
		}
	    } else if (strncmp ("gauss", cnvstr[ip], 5) == 0) {
		i = 6
		if (ctoi (cnvstr[ip], i, nx) == 0 ||
		    ctoi (cnvstr[ip], i, ny) == 0)
		    goto unknown_
		if (ctor (cnvstr[ip], i, sx) == 0 ||
		    ctor (cnvstr[ip], i, sy) == 0)
		    goto unknown_
		call malloc (kernel, nx*ny, TY_REAL)

		nx2 = nx / 2
		ny2 = ny / 2
		val = 2 * sx * sy
		ptr = kernel
		do j = 0, ny-1 {
		    do i = 0, nx-1 {
			Memr[ptr] = exp (-((i-nx2)**2+(j-ny2)**2) / val)
			ptr = ptr + 1
		    }
		}
	    }
	} else {
	    call malloc (kernel, 100, TY_REAL)
	    i = 0
	    nx = 0
	    ny = 0
	    while (cnvstr[ip] != EOS) {
		do j = 1, ARB {
		    if (ctor (cnvstr, ip, val) == 0)
			break
		    Memr[kernel+i] = val
		    i = i + 1
		    if (mod (i, 100) == 0)
			call realloc (kernel, i+100, TY_REAL)
		}
		j = j - 1
		if (nx == 0)
		    nx = j
		else if (j != nx)
		    call error (1,
			"Number of convolution elements inconsistent")
		ny = ny + 1
		if (cnvstr[ip] != EOS)
		    ip = ip + 1
		for (; IS_WHITE(cnvstr[ip]); ip=ip+1)
		    ;
	    }
	}

	if (kernel == NULL)
unknown_    call error (1, "Unrecognized convolution")

	if (mod (nx, 2) != 1 || mod (ny, 2) != 1) {
	    call mfree (kernel, TY_REAL)
	    call error (1, "Convolution size must be odd")
	}

	if (logfd != NULL) {
	    ptr = kernel
	    if (scnv == YES)
		call fprintf (logfd, "    Convolution for input and sky:\n")
	    else
		call fprintf (logfd, "    Convolution:\n")
	    do j = 1, ny {
		call fprintf (logfd, "     ")
		do i = 1, nx {
		    call fprintf (logfd, " %7.3g")
			call pargr (Memr[ptr])
		    ptr = ptr + 1
		}
		call fprintf (logfd, "\n")
	    }
	}
	if (verbose > 1) {
	    ptr = kernel
	    if (scnv == YES)
		call printf ("    Convolution for input and sky:\n")
	    else
		call printf ("    Convolution:\n")
	    do j = 1, ny {
		call printf ("     ")
		do i = 1, nx {
		    call printf (" %7.3g")
			call pargr (Memr[ptr])
		    ptr = ptr + 1
		}
		call printf ("\n")
	    }
	}
end
