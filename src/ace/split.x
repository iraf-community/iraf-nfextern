include	<pmset.h>
include	<mach.h>
include	"ace.h"
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>
include	"split.h"


# SPLIT - Split detected objects.
#
# Note that the sigma level map is modified and will be empty when done.

procedure split (spt, cat, objmask, siglevel, siglevels, logfd, verbose)

pointer	spt			#I Split parameters
pointer	cat			#U Catalog structure
pointer	objmask			#I Input and modified object mask
pointer	siglevel		#I Sigma level mask.
real	siglevels[ARB]		#I Sigma levels
int	logfd			#I Log FD
int	verbose			#I Verbose level

int	neighbors		# Neighbor type
int	dminpix			# Minimum number of pixels for split object
int	sminpix			# Minimum number of split pixels
real	sigavg			# Minimum average above sky in sigma
real	sigmax			# Minimum peak above sky in sigma
real	ssigavg			# Minimum split average above sky in sigma
real	ssigmax			# Minimum split peak above sky in sigma
real	splitmax		# Maximum convolved sigma for splitting
real	splitstep		# Minimum split step in convolved sigma
real	splitthresh		# Transition convolved sigma

int	i, c, c1, c2, cs, clast, l, nc, nc1, nl
int	level, nsobjs, navail, nalloc, nummax, val, num, pnum, oval, sval, bp
long	v[PM_MAXDIM]
real	threshold
pointer	sp, pnums, buf1, buf2, irl, orl, srl, outbuf, lastbuf
pointer	objs, obj, splitmask, irlptr, orlptr, srlptr
pointer	flags, ids, sobjs, links

int	andi()
bool	pm_linenotempty()
pointer	pm_create()

begin
	# Check for splitting map.
	if (siglevel == NULL)
	    return

	# Set parameters.
	call spt_pars ("open", "", spt)
	if (spt == NULL)
	    return

	neighbors = SPT_NEIGHBORS(spt)
	dminpix = SPT_MINPIX(spt)
	sminpix = SPT_SMINPIX(spt)
	sigavg = SPT_SIGAVG(spt)
	sigmax = SPT_SIGPEAK(spt)
	ssigavg = SPT_SSIGAVG(spt)
	ssigmax = SPT_SSIGPEAK(spt)
	splitmax = SPT_SPLITMAX(spt)
	splitstep = SPT_SPLITSTEP(spt)
	splitthresh = SPT_SPLITTHRESH(spt)

	if (logfd != NULL) {
	    call fprintf (logfd, "  Split objects: sminpix = %d\n")
		call pargi (sminpix)
	}
	if (verbose > 1) {
	    call printf ("  Split objects: sminpix = %d\n")
		call pargi (sminpix)
	}

	if (IS_INDEFR(splitmax))
	    splitmax = MAX_REAL

	call pm_gsize (objmask, c, v, l)
	splitmask = pm_create (c, v, l)
	nc = v[1]
	nl = v[2]

	call smark (sp)
	call salloc (pnums, nc, TY_INT)
	call salloc (buf1, nc+2, TY_INT)
	call salloc (buf2, nc+2, TY_INT)
	call salloc (irl, 3+3*nc, TY_INT)
	call salloc (orl, 3+3*nc, TY_INT)
	call salloc (srl, 3+3*nc, TY_INT)

	navail = 2 * CAT_NUMMAX(cat)
	call calloc (ids, navail, TY_INT) 
	call calloc (links, navail, TY_INT) 
	call calloc (sobjs, navail, TY_POINTER) 
	nalloc = 0

	# Go through sigma levels.
	do level = 1, ARB {

	    # Check if sigma value is in splitting range.
	    threshold = siglevels[level]
	    if (threshold == 0.)
		next
	    if (threshold > splitmax)
		break

	    # Initialize flags.
	    nummax = CAT_NUMMAX(cat)
	    objs = CAT_RECS(cat)
	    call calloc (flags, nummax+1, TY_SHORT)
	    do l = NUMSTART, nummax {
		obj = Memi[objs+l-1]
		if (obj == NULL)
		    next
		if (OBJ_FLAG(obj,SPLIT)=='M'||OBJ_FLAG(obj,SPLIT)=='S')
		    next
		if (OBJ_NPIX(obj) < 2 * sminpix) {
		    OBJ_FLAG(obj,SPLIT) = 'S'
		    next
		}
		Mems[flags+l] = 1
	    }

	    # Clear the mask.
	    call pm_clear (splitmask)

	    outbuf = NULL
	    nsobjs = NUMSTART - 1
	    do l = 1, nl {
		v[1] = 1
		v[2] = l
		if (!pm_linenotempty (siglevel, v)) {
		    outbuf = NULL
		    next
		}

		lastbuf = outbuf
		if (lastbuf == buf1)
		    outbuf = buf2
		else
		    outbuf = buf1

		# Get sigma level mask.
		call pmglri (siglevel, v, Memi[irl], 0, nc, 0) 

		# Get parent object mask. Skip end regions not in siglev mask.
		i = Memi[irl] - 1
		cs = Memi[irl+3]
		nc1 = Memi[irl+3*i] + Memi[irl+3*i+1] - cs
		v[1] = cs
		call pmglpi (objmask, v, Memi[pnums], 0, nc1, 0) 
		v[1] = 1

		# Initialize output range lists.
		orlptr = orl; Memi[orlptr] = 0
		srlptr = srl + 3; sval = 0
		clast = 0

		call aclri (Memi[outbuf], nc+2)
		irlptr = irl
		do i = 2, Memi[irl] {
		    irlptr = irlptr + 3
		    val = Memi[irlptr+2]
		    if (val < level)
			next
		    c1 = Memi[irlptr]
		    c2 = c1 + Memi[irlptr+1] - 1
		    do c = c1, c2 {
			pnum = Memi[pnums+c-cs]
			if (MSPLIT(pnum))
			    next
			if (MBP(pnum))
			    bp = -1
			else
			    bp = 0
			pnum = MNUM (pnum)
			if (Mems[flags+pnum] == 0)
			    next
			    
			if (lastbuf == NULL)
			    call sadd (c+1, l, Memi[outbuf], INDEFI, nc+2,
				Memi[ids], Memi[links], Memi[sobjs],
				nsobjs, nalloc, pnum, siglevels[val],
				threshold, neighbors, bp, num)
			else
			    call sadd (c+1, l, Memi[outbuf], Memi[lastbuf],
				nc+2, Memi[ids], Memi[links], Memi[sobjs],
				nsobjs, nalloc, pnum, siglevels[val],
				threshold, neighbors, bp, num)

			if (nalloc == navail) {
			    navail = max (100*nalloc*(nl+1)/l/100, nalloc+10000)
			    call realloc (ids, navail, TY_INT)
			    call realloc (links, navail, TY_INT)
			    call realloc (sobjs, navail, TY_POINTER)
			}

			# Update split object mask.
			if (num != oval || c != clast) {
			    Memi[orlptr+1] = clast - Memi[orlptr]
			    orlptr = orlptr + 3

			    oval = num
			    Memi[orlptr] = c
			    Memi[orlptr+2] = oval
			}

			# Update sigma level mask.
			if (val != sval || c != clast) {
			    if (sval > level) {
				Memi[srlptr+1] = clast - Memi[srlptr]
				srlptr = srlptr + 3
			    }

			    sval = val
			    if (sval > level) {
				Memi[srlptr] = c
				Memi[srlptr+2] = sval
			    }
			}

			clast = c + 1
		    }
		}

		# Update masks.
		i = 1 + (orlptr - orl) / 3
		if (i > 1) {
		    Memi[orlptr+1] = clast - Memi[orlptr]
		    Memi[orl] = i
		    Memi[orl+1] = nc
		    call pmplri (splitmask, v, Memi[orl], 0, nc, PIX_SRC) 
		}

		if (sval > level) {
		    Memi[srlptr+1] = clast - Memi[srlptr]
		    Memi[srl] = 1 + (srlptr - srl) / 3
		} else
		    Memi[srl] = (srlptr - srl) / 3
		Memi[srl+1] = nc
		call pmplri (siglevel, v, Memi[srl], 0, nc, PIX_SRC) 
	    }
	    if (nsobjs < NUMSTART)
		break

	    if (threshold <= splitthresh)
		call srenum (cat, objmask, splitmask, Memi[ids], Memi[sobjs],
		    nsobjs, CAT_RECLEN(cat), dminpix, sigavg, sigmax)
	    else
		call srenum (cat, objmask, splitmask, Memi[ids], Memi[sobjs],
		    nsobjs, CAT_RECLEN(cat), sminpix, ssigavg, ssigmax)

	    # Reuse object structures.
	    nsobjs = nalloc
	    nalloc = NUMSTART-1
	    do i = NUMSTART-1, nsobjs-1 {
		obj = Memi[sobjs+i]
		if (obj != NULL) {
		    Memi[sobjs+nalloc] = Memi[sobjs+i]
		    nalloc = nalloc + 1
		}
	    }

	    call mfree (flags, TY_SHORT)
	}

	# Set all non-multiple objects to single.
	do i = NUMSTART, nummax {
	    obj = Memi[objs+i-1]
	    if (obj == NULL)
		next
	    if (OBJ_FLAG(obj,SPLIT) != 'M')
		OBJ_FLAG(obj,SPLIT) = 'S'
	}

	do i = 0, nalloc-1
	    call mfree (Memi[sobjs+i], TY_POINTER)
	call mfree (ids, TY_INT)
	call mfree (links, TY_INT)
	call mfree (sobjs, TY_POINTER)

	call pm_close (splitmask)

	call sfree (sp)
end


# SPLITADD -- Add a pixel to the object list and set the mask value.

procedure sadd (c, l, z, zlast, nc, ids, links, objs, nobjs, nalloc,
	pnum, data, threshold, neighbors, bp, num)

int	c, l		#I Pixel coordinate 
int	z[nc]		#I Pixel values for current line
int	zlast[nc]	#I Pixel values for last line
int	nc		#I Number of pixels in a line
int	ids[ARB]	#I Mask ids
int	links[ARB]	#I Link to other mask ids with same number
int	objs[ARB]	#I Object numbers
int	nobjs		#U Number of objects
int	nalloc		#U Number of allocated objects
int	pnum		#I Parent number
real	data		#I Approximate (I(convolved) - sky) / sigma(convolved)
real	threshold	#I Threshold above sky in sigma units
int	neighbors	#I Neighbor type
int	bp		#I Bad pixel value
int	num		#O Assigned mask value.

int	i, num1, c1, c2
real	val
bool	merge
pointer	obj, obj1

begin
	# Inherit number of a neighboring pixel.
	num = INDEFI
	merge = false
	if (neighbors == 4) {
	    c1 = c - 1
	    c2 = c
	    if (IS_INDEFI(zlast[1])) {
		if (z[c1] >= NUMSTART)
		    num = z[c1]
	    } else {
		if (z[c1] >= NUMSTART) {
		    num = z[c1]
		    merge = true
		} else if (zlast[c] >= NUMSTART)
		    num = ids[zlast[c]]
	    }
	} else {
	    c1 = c - 1
	    c2 = c + 1
	    if (IS_INDEFI(zlast[1])) {
		if (z[c1] >= NUMSTART)
		    num = z[c1]
	    } else {
		if (z[c1] >= NUMSTART) {
		    num = z[c1]
		    merge = true
		} else if (zlast[c1] >= NUMSTART)
		    num = ids[zlast[c1]]
		else if (zlast[c] >= NUMSTART)
		    num = ids[zlast[c]]
		else if (zlast[c2] >= NUMSTART)
		    num = ids[zlast[c2]]
	    }
	}

	# If no number assign a new number.
	if (num == INDEFI) {
	    nobjs = nobjs + 1
	    num = nobjs
	    ids[num] = num
	    links[num] = 0
	    if (nalloc < nobjs) {
		call malloc (objs[num], OBJ_DETLEN, TY_STRUCT)
		nalloc = nobjs
	    }
	    obj = objs[num]
	    OBJ_PNUM(obj) = pnum
	    OBJ_FLUX(obj) = 0.
	    OBJ_NPIX(obj) = 0
	    OBJ_ISIGAVG(obj) = 0.
	    OBJ_ISIGMAX(obj) = 0.
	    call strcpy ("------", OBJ_FLAGS(objs[num]), SZ_FLAGS)
	}
	obj = objs[num]

	# Merge overlapping objects from previous line. 
	if (merge) {
	    i = zlast[c2]
	    if (i >= NUMSTART && num != ids[i]) {
		num1 = ids[i]

		obj1 = objs[num1]
		OBJ_FLUX(obj) = OBJ_FLUX(obj) + OBJ_FLUX(obj1)
		OBJ_NPIX(obj) = OBJ_NPIX(obj) + OBJ_NPIX(obj1)
		OBJ_ISIGAVG(obj) = OBJ_ISIGAVG(obj) + OBJ_ISIGAVG(obj1)
		if (OBJ_ISIGMAX(obj) < OBJ_ISIGMAX(obj1))
		    OBJ_ISIGMAX(obj) = OBJ_ISIGMAX(obj1)
		call amaxc (OBJ_FLAGS(obj), OBJ_FLAGS(obj1),
		    OBJ_FLAGS(obj), SZ_FLAGS)

		i = num
		while (links[i] != 0)
		    i = links[i]
		links[i] = num1 
		repeat {
		    i = links[i]
		    ids[i] = num
		} until (links[i] == 0)

		nalloc = nalloc + 1
		objs[nalloc] = obj1
		objs[num1] = NULL
	    }
	}

	z[c] = num
	OBJ_NPIX(obj) = OBJ_NPIX(obj) + 1
	val = data - threshold
	OBJ_FLUX(obj) = OBJ_FLUX(obj) + val
	OBJ_ISIGAVG(obj) = OBJ_ISIGAVG(obj) + val
	if (OBJ_ISIGMAX(obj) < val)
	    OBJ_ISIGMAX(obj) = val
	if (bp < 0)
	    OBJ_FLAG(obj,BP) = 'B'
end


# SRENUM -- Find detected pieces with a common parent and add to the
# catalog and the object mask.

procedure srenum (cat, om, sm, ids, sobjs, nsobjs, objlen, minpix,
	sigavg, sigmax)

pointer	cat			#I Catalog structure
pointer	om			#I Object mask
pointer	sm			#I Split mask
int	ids[nsobjs]		#I Mask IDs
pointer	sobjs[nsobjs]		#U Input and output object list
int	nsobjs			#U Number of objects
int	objlen			#I Object record length
int	minpix			#I Minimum number of pixels
real	sigavg			#I Cutoff of SIGAVG
real	sigmax			#I Cutoff of SIGMAX

int	i, j, n, nummax, nc, nl
real	rval
pointer	sp, nsplit, v, irl, srl, orl
pointer	objs, obj, pobj

begin
	nummax = CAT_NUMMAX(cat)
	objs = CAT_RECS(cat)

	call smark (sp)
	call salloc (nsplit, nummax, TY_INT)
	call aclri (Memi[nsplit], nummax)

	# Eliminate objects, by setting ids to zero, which don't satisfy
	# the selection criteria (size, peak value, etc).  Find objects
	# that have split by counting, in the nsplit array, how many pieces
	# belong to each parent.

	do i = NUMSTART, nsobjs {
	    obj = sobjs[i]
	    if (obj == NULL)
		next

	    n = OBJ_NPIX(obj)
	    #rval = sqrt (real(n))
	    rval = real(n)
	    OBJ_ISIGAVG(obj) = OBJ_ISIGAVG(obj) / rval
	    if (n < minpix ||
		(OBJ_ISIGMAX(obj) < sigmax && OBJ_ISIGAVG(obj) < sigavg)) {
		ids[i] = 0
		next
	    }

	    n = OBJ_PNUM(obj)
	    Memi[nsplit+n-1] = Memi[nsplit+n-1] + 1

	    pobj = Memi[objs+n-1]
	    if (pobj != NULL)
	        OBJ_SIG(obj) = OBJ_SIG(pobj)
	}

	# Count objects that have a common parent (nsplit > 1) and assign
	# new object numbers.  Those not split are eliminated by setting
	# ids to zero.  Mark those unsplit objects whose parent objects
	# are too small at the current size threshold as single to eliminate
	# them from future attempts to split.

	j = nummax
	do i = NUMSTART, nsobjs {
	    obj = sobjs[i]
	    if (obj == NULL || ids[i] == 0)
		next

	    n = OBJ_PNUM(obj)
	    if (Memi[nsplit+n-1] < 2) {
		pobj = Memi[objs+n-1]
		if (pobj != NULL) {
		    if (OBJ_NPIX(obj) < 2 * minpix)
			OBJ_FLAG(obj,SPLIT) = 'S'
		}
		ids[i] = 0
	    } else {
		j = j + 1
		OBJ_NUM(obj) = j
		nummax = nummax + 1
	    }
	}

	# If there are no split objects return.
	if (nummax == CAT_NUMMAX(cat)) {
	    call sfree (sp)
	    return
	}

	# Update the object mask for the split objects.
	call salloc (v, PM_MAXDIM, TY_LONG)
	call pm_gsize (om, i, Meml[v], j)
	nc = Meml[v]; nl = Meml[v+1]
	call salloc (irl, 3+3*nc, TY_INT)
	call salloc (srl, 3+3*nc, TY_INT)
	call salloc (orl, 3+3*nc, TY_INT)

	call srenum1 (om, sm, nc, nl, ids, sobjs, Memi[nsplit],
	    Meml[v], Memi[irl], Memi[srl], Memi[orl])

	# Add split objects to catalog.  Expand object structure.
	call realloc (objs, nummax, TY_POINTER)
	j = CAT_NUMMAX(cat)
	do i = NUMSTART, nsobjs {
	    obj = sobjs[i]
	    if (obj == NULL || ids[i] == 0)
		next

	    call newobj (obj, objlen)

	    sobjs[i] = NULL
	    Memi[objs+j] = obj
	    j = j + 1
	}

	# Set split flags for the split parent objects.
	do i = NUMSTART, CAT_NUMMAX(cat)-1 {
	    obj = Memi[objs+i-1]
	    if (obj == NULL)
		next
	    if (Memi[nsplit+i-1] > 1)
		OBJ_FLAG(obj,SPLIT) = 'M'
	}

	# Update catalog info.
	CAT_NRECS(cat) = nummax
	CAT_NUMMAX(cat) = nummax
	CAT_RECS(cat) = objs

	call sfree (sp)
end


procedure srenum1 (om, sm, nc, nl, ids, objs, nsplit, v, irl, srl, orl)

pointer	om			#I Object mask pointer
pointer	sm			#I Split mask pointer
int	nc, nl			#I Dimensions
int	ids[ARB]		#I Mask IDs
pointer	objs[ARB]		#I Split objects
int	nsplit[ARB]		#I Number of split pieces
long	v[PM_MAXDIM]		#I Work array for line index
int	irl[3,nc]		#I Work array for input range list
int	srl[3,nc]		#I Work array for split range list
int	orl[3,nc]		#I Work array for output range list

int	i, j, k, l, n, c1, c2, sc1, sc2, mid, id, sid, flags, andi(), ori()

begin
	v[1] = 1
	do l = 1, nl {
	    v[2] = l
	    call pmglri (om, v, irl, 0, nc, 0) 
	    call pmglri (sm, v, srl, 0, nc, 0) 

	    srl[1,srl[1,1]+1] = nc + 1
	    sc1 = srl[1,2]
	    sc2 = sc1 + srl[2,2] - 1

	    j = 1
	    k = 2
	    do i = 2, irl[1,1] {
		mid = irl[3,i]
		id = MNUM(mid)
		flags = 0
		if (MBP(mid))
		    flags = flags + MASK_BP

		# Unsplit object.
		if (id < NUMSTART || nsplit[id] < 2) {
		    j = j + 1
		    orl[1,j] = irl[1,i]
		    orl[2,j] = irl[2,i]
		    orl[3,j] = mid
		    next
		}

		c1 = irl[1,i]
		c2 = c1 + irl[2,i] - 1
		id = MSETFLAG (id, MASK_SPLIT+flags)

		while (sc1 < c1) {
		    k = k + 1
		    sc1 = srl[1,k]
		}

		while (sc1 <= c2) {
		    sid = ids[srl[3,k]]

		    # Check for split piece that was eliminated.
		    if (sid == 0) {
			k = k + 1
			sc1 = srl[1,k]
			next
		    }
		    sid = ids[sid]
		    if (sid == 0) {
			k = k + 1
			sc1 = srl[1,k]
			next
		    }

		    # Add split piece to output.
		    # Handle cases with flagged bad pixel regions.

		    if (sc1 > c1) {
			j = j + 1
			orl[1,j] = c1
			orl[2,j] = sc1 - c1
			orl[3,j] = id
		    }

		    sc2 = sc1 + srl[2,k] - 1
		    repeat {
		        n = min (sc2, c2) - sc1 + 1
			j = j + 1
			orl[1,j] = sc1
			orl[2,j] = n
			if (OBJ_FLAG(objs[sid],BP) == 'B')
			    orl[3,j] = MSETFLAG(OBJ_NUM(objs[sid]),
			        flags+MASK_BPFLAG)
			else
			    orl[3,j] = MSETFLAG(OBJ_NUM(objs[sid]),flags)

			sc1 = sc1 + n
			c1 = sc1

			if (sc2 <= c2)
			    break

			i = i + 1
			mid = irl[3,i]
			id = MNUM(mid)
			flags = 0
			if (MBP(mid))
			    flags = flags + MASK_BP

			c1 = irl[1,i]
			c2 = c1 + irl[2,i] - 1
			id = MSETFLAG (id, MASK_SPLIT+flags)
		    }

		    k = k + 1
		    sc1 = srl[1,k]
		}

		if (c1 <= c2) {
		    j = j + 1
		    orl[1,j] = c1
		    orl[2,j] = c2 - c1 + 1
		    orl[3,j] = id
		}
	    }
	    orl[1,1] = j
	    orl[2,1] = nc
	    call pmplri (om, v, orl, 0, nc, PIX_SRC) 
	}
end
