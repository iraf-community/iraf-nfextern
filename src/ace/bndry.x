include	<pmset.h>
include	"ace.h"


# BNDRY --  Flag boundary pixels of unsplit objects.
# Assume the boundary flag is not set.

procedure bndry (om, logfd)

pointer	om			#I Object mask
int	logfd			#I Logfile

int	i, c, c1, c2, l, nc, nl, num, numc
int	bndryval, bndryvalg, val, vallast
int	lastc1, lastc2, lastnum, numl, nextc1, nextc2, nextnum, numr
int	numg, num1l, num1c, num1r, num3l, num3c, num3r
pointer	sp, v, irl, irlptr, orl, orlptr, bufs, buf1, buf2, buf3

int	andi(), ori(), noti()

begin
	call smark (sp)
	call salloc (v, PM_MAXDIM, TY_LONG)

	if (logfd != NULL)
	    call fprintf (logfd, "  Set boundary mask:\n")

	call pm_gsize (om, nc, Meml[v], nl)
	nc = Meml[v]; nl = Meml[v+1]
	Meml[v] = 1

	# Allocate buffers.
	call salloc (irl, 3+3*nc, TY_INT)
	call salloc (orl, 3+3*nc, TY_INT)
	call salloc (bufs, 3, TY_POINTER)
	call salloc (Memi[bufs], nc, TY_INT)
	call salloc (Memi[bufs+1], nc, TY_INT)
	call salloc (Memi[bufs+2], nc, TY_INT)

	Memi[orl+1] = nc

	# First line.
	l = 1
	buf2 = Memi[bufs+mod(l,3)]
	buf3 = Memi[bufs+mod(2,3)]

	Meml[v+1] = l + 1
	call pmglpi (om, Meml[v], Memi[buf3], 0, nc, 0)
	Meml[v+1] = l
	call pmglpi (om, Meml[v], Memi[buf2], 0, nc, 0)
	call pmglri (om, Meml[v], Memi[irl], 0, nc, 0)

	irlptr = irl
	orlptr = orl 
	do i = 2, Memi[irl] {
	    irlptr = irlptr + 3
	    c1 = Memi[irlptr] - 1
	    c2 = c1 + Memi[irlptr+1] - 1
	    num = Memi[irlptr+2]

	    if (num < NUMSTART || MSPLIT(num) || MBP(num)) {
		orlptr = orlptr + 3
		Memi[orlptr] = c1 + 1
		Memi[orlptr+1] = c2 - c1 + 1
		Memi[orlptr+2] = num
		next
	    }

	    bndryval = MSETFLAG (num, MASK_BNDRY)
	    do c = c1, c2
		Memi[buf2+c] = bndryval

	    orlptr = orlptr + 3
	    Memi[orlptr] = Memi[irlptr]
	    Memi[orlptr+1] = Memi[irlptr+1]
	    Memi[orlptr+2] = bndryval
	}
	Memi[orl] = 1 + (orlptr - orl) / 3
	call pmplri (om, Meml[v], Memi[orl], 0, nc, PIX_SRC)

	# Interior lines.
	do l = 2, nl-1 {
	    buf1 = Memi[bufs+mod(l-1,3)]
	    buf2 = Memi[bufs+mod(l,3)]
	    buf3 = Memi[bufs+mod(l+1,3)]

	    Meml[v+1] = l + 1
	    call pmglpi (om, Meml[v], Memi[buf3], 0, nc, 0)
	    Meml[v+1] = l
	    call pmglri (om, Meml[v], Memi[irl], 0, nc, 0)

	    irlptr = irl
	    orlptr = orl
	    do i = 2, Memi[irl] {
		irlptr = irlptr + 3

		if (i == 2) {
		    c1 = Memi[irlptr] - 1
		    c2 = c1 + Memi[irlptr+1] - 1
		    num = Memi[irlptr+2]
		    lastnum = 0
		    numl = 0
		    numc = MNUM(num)
		} else {
		    lastc1 = c1
		    lastc2 = c2
		    lastnum = num
		    c1 = nextc1
		    c2 = nextc2
		    num = nextnum
		    numc = MNUM(num)
		    #if (lastc2+1 == c1 && !(MSPLIT(lastnum) || MBP(lastnum)))
		    if (lastc2+1 == c1 && !MSPLIT(lastnum))
		        numl = MNUM(lastnum)
		    else
		        numl = 0
		}
		if (i < Memi[irl]) {
		    nextc1 = Memi[irlptr+3] - 1
		    nextc2 = nextc1 + Memi[irlptr+4] - 1
		    nextnum = Memi[irlptr+5]
		    if (c2+1 == nextc1 && !MSPLIT(nextnum))
		        numr = MNUM(nextnum)
		    else
		        numr = 0
		} else {
		    nextnum = 0
		    numr = 0
		}
		 
		if (num < NUMSTART || MSPLIT(num)) {
		    orlptr = orlptr + 3
		    Memi[orlptr] = c1 + 1
		    Memi[orlptr+1] = c2 - c1 + 1
		    Memi[orlptr+2] = num
		    call amovki (Memi[orlptr+2], Memi[buf2+Memi[orlptr]-1],
		        Memi[orlptr+1])
		    next
		}

		bndryval = MSETFLAG(num,MASK_BNDRY)

		orlptr = orlptr + 3
		Memi[orlptr] = c1 + 1
		do c = c1, c2 {
		    val = num

		    if (c == c1) {
			# Check for boundary on the left.
		        if (numl != numc)
			    val = bndryval
			Memi[orlptr+2] = val
			vallast = val
		    }

		    # Check for boundary on top and bottom.
		    numg = MUNSETFLAG(num,MASK_BP+MASK_GRW)
		    bndryvalg = MUNSETFLAG(bndryval,MASK_BP+MASK_GRW)
		    num1l = MUNSETFLAG(Memi[buf1+c-1],MASK_BP+MASK_GRW)
		    num1c = MUNSETFLAG(Memi[buf1+c],MASK_BP+MASK_GRW)
		    num1r = MUNSETFLAG(Memi[buf1+c+1],MASK_BP+MASK_GRW)
		    num3l = MUNSETFLAG(Memi[buf3+c-1],MASK_BP+MASK_GRW)
		    num3c = MUNSETFLAG(Memi[buf3+c],MASK_BP+MASK_GRW)
		    num3r = MUNSETFLAG(Memi[buf3+c+1],MASK_BP+MASK_GRW)
		    if (num3l != numg)
			val = bndryval
		    else if (num3c != numg)
			val = bndryval
		    else if (num3r != numg)
			val = bndryval
		    else if (num1l != numg && num1l != bndryvalg)
			val = bndryval
		    else if (num1c != numg && num1c != bndryvalg)
			val = bndryval
		    else if (num1r != numg && num1r != bndryvalg)
			val = bndryval

		    # Add new segment.
		    if (val != vallast) {
			if (c > c1) {
			    # Finish last segment.
			    Memi[orlptr+1] = c - Memi[orlptr] + 1
			    orlptr = orlptr + 3
			}
			Memi[orlptr] = c + 1
			Memi[orlptr+2] = val
			vallast = val
		    }

		    Memi[buf2+c] = val
		}
		if (numr != numc)
		    vallast = bndryval

		# Finish last segment
		if (vallast == Memi[orlptr+2]) {
		    Memi[orlptr+1] = c2 - Memi[orlptr] + 2
		    call amovki (Memi[orlptr+2], Memi[buf2+Memi[orlptr]-1],
		        Memi[orlptr+1])
		    next
		}

		# Split last segment.
		if (Memi[orlptr+2] == bndryval)
		    Memi[orlptr+1] = 1
		else
		    Memi[orlptr+1] = c2 - Memi[orlptr] + 1
		call amovki (Memi[orlptr+2], Memi[buf2+Memi[orlptr]-1],
		    Memi[orlptr+1])

		orlptr = orlptr + 3
		Memi[orlptr] = Memi[orlptr-3] + Memi[orlptr-2]
		Memi[orlptr+1] = c2 - Memi[orlptr] + 2
		Memi[orlptr+2] = vallast
		call amovki (Memi[orlptr+2], Memi[buf2+Memi[orlptr]-1],
		    Memi[orlptr+1])
	    }

	    Memi[orl] = 1 + (orlptr - orl) / 3
	    call pmplri (om, Meml[v], Memi[orl], 0, nc, PIX_SRC)
	}

	# Last line.
	l = nl
	buf2 = Memi[bufs+mod(l,3)]

	Meml[v+1] = l
	call pmglri (om, Meml[v], Memi[irl], 0, nc, 0)

	irlptr = irl
	orlptr = orl
	do i = 2, Memi[irl] {
	    irlptr = irlptr + 3
	    c1 = Memi[irlptr] - 1
	    c2 = c1 + Memi[irlptr+1] - 1
	    num = Memi[irlptr+2]

	    if (num < NUMSTART || MSPLIT(num) || MBP(num)) {
		orlptr = orlptr + 3
		Memi[orlptr] = c1 + 1
		Memi[orlptr+1] = c2 - c1 + 1
		Memi[orlptr+2] = num
		next
	    }

	    bndryval = MSETFLAG (num, MASK_BNDRY)
	    do c = c1, c2
		Memi[buf2+c] = bndryval

	    orlptr = orlptr + 3
	    Memi[orlptr] = Memi[irlptr]
	    Memi[orlptr+1] = Memi[irlptr+1]
	    Memi[orlptr+2] = bndryval
	}
	Memi[orl] = 1 + (orlptr - orl) / 3
	call pmplri (om, Meml[v], Memi[orl], 0, nc, PIX_SRC)

	call sfree (sp)
end
