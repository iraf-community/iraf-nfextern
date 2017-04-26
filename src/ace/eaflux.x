include	<math.h>
include	<acecat.h>
include	<acecat1.h>
include	<aceobjs.h>
include	<aceobjs1.h>
include	"eaflux.h"


# EAF_GINIT -- Global initialization.
#	1. Allocate memory
#	2. Set Petrosian SB ratios to evaluate.
#	3. Set indices for object record.

procedure eaf_ginit (cat, eafs)

pointer	cat			#I Catalog structure
pointer	eafs			#O EAF global structure

int	i, j
real	pr
pointer	stp, sym

int	ctor()
pointer	stfind()
errchk	calloc

begin
	# Allocate memory.
	call calloc (eafs, EAFS_LEN(CAT_NUMMAX(cat)), TY_STRUCT)
	call amovki (-1, EAFS_FID(eafs,0), 10)
	call amovki (-1, EAFS_RID(eafs,0), 10)

	# Find SB ratios to evaluate for flux fields.
	stp = CAT_STP(cat)
	do i = 0, 9 {
	    call sprintf (CAT_STR(cat), CAT_SZSTR, "EAFLUX_%d")
	        call pargi (i)
	    sym = stfind (stp, CAT_STR(cat))
	    if (sym == NULL)
	        break
	    if (ENTRY_EVAL(sym) == NO || ENTRY_ARGS(sym) == EOS)
	        break
	    j = 1
	    if (ctor (ENTRY_ARGS(sym), j, pr) == 0)
	        call error (1, "Bad argument for elliptical aperture flux")
	    EAFS_FID(eafs,i) = i
	    EAFS_PR(eafs,i) = pr
	    EAFS_NAP(eafs) = EAFS_NAP(eafs) + 1
	}

	# Find SB ratios for radii fields.
	do i = 0, 9 {
	    call sprintf (CAT_STR(cat), CAT_SZSTR, "EAR_%d")
	        call pargi (i)
	    sym = stfind (stp, CAT_STR(cat))
	    if (sym == NULL)
	        break
	    if (ENTRY_EVAL(sym) == NO || ENTRY_ARGS(sym) == EOS)
	        break
	    j = 1
	    if (ctor (ENTRY_ARGS(sym), j, pr) == 0)
	        call error (1, "Bad argument for elliptical aperture flux")
	    do j = 0, EAFS_NAP(eafs)-1 {
	        if (EAFS_PR(eafs,j) == pr) {
		    EAFS_RID(eafs,j) = i
		    break
		}
	    }
	    if (j == EAFS_NAP(eafs) && j < 10) {
		EAFS_RID(eafs,j) = i
		EAFS_PR(eafs,j) = pr
		EAFS_NAP(eafs) = EAFS_NAP(eafs) + 1
	    }
	}
end


procedure eaf_gdone (cat, eafs)

pointer	cat			#I Catalog structure
pointer	eafs			#O EAF global structure

begin
	call mfree (eafs, TY_STRUCT)
end


# EAF_INIT -- Initialize elliptical aperture measurement.

procedure eaf_init (eaf, obj)

pointer eaf		#O EAF pointer for object
pointer obj		#I Object pointer

int	n
real	x2, y2, xy, r2, e, t
errchk	calloc

begin
	# Check if shape is defined.
	x2 = OBJ_XX(obj); y2 = OBJ_YY(obj); xy = OBJ_XY(obj)
	if (IS_INDEFR(x2) || IS_INDEFR(y2) || IS_INDEFR(xy)) {
	    eaf = -1
	    return
	}

	# Determine maximum flux radius.
	x2 = OBJ_X(obj); y2 = OBJ_Y(obj)
	r2= (OBJ_XMIN(obj)-x2)**2+(OBJ_YMIN(obj)-y2)**2
	r2= max (r2, (OBJ_XMAX(obj)-x2)**2+(OBJ_YMIN(obj)-y2)**2)
	r2= max (r2, (OBJ_XMIN(obj)-x2)**2+(OBJ_YMAX(obj)-y2)**2)
	r2= max (r2, (OBJ_XMAX(obj)-x2)**2+(OBJ_YMAX(obj)-y2)**2)

	# Allocate structure.
	n = min (nint(sqrt(r2)/EAFS_DR), EAFS_NMAX)
	call calloc (eaf, EAF_LEN(n), TY_STRUCT)
	EAF_N(eaf) = n

	# Set shape parameters.
	x2 = OBJ_XX(obj); y2 = OBJ_YY(obj); xy = OBJ_XY(obj)
	x2 = max (x2, 0.01); y2 = max (y2, 0.01)
	if (IS_INDEFR(OBJ_EAELLIP(obj))) {
	    r2= x2 + y2
	    e = sqrt ((x2-y2)**2 + 4 * xy**2)
	    e = max ((r2 - e) / (r2 + e), 0.01)
	    OBJ_EAELLIP(obj) = e
	}
	if (IS_INDEFR(OBJ_EATHETA(obj))) {
	    t = RADTODEG (atan2 (2*xy, x2-y2) / 2.)
	    OBJ_EATHETA(obj) = t
	}

	e = OBJ_EAELLIP(obj)
	t = DEGTORAD (OBJ_EATHETA(obj))
	EAF_E(eaf) = 1. / sqrt (e)
	EAF_C(eaf) = cos (t)
	EAF_S(eaf) = sin (t)
#	EAF_E(eaf) = 1.
#	EAF_C(eaf) = 1.
#	EAF_S(eaf) = 0.
end


# EAF_ACCUM -- Accumulate pixels for elliptical aperture measurement.

procedure eaf_accum (eaf, obj, c, l, val)

pointer	eaf			#I EAF pointer for object
pointer	obj			#I Object pointer
int	c, l			#I Pixel coordinate
real	val			#I Pixel sky subtracted flux value

int	i, n
real	a, b, e, f, r, x, y, dx, dy, dc, dl, x1, y1
pointer	pn, pf

begin
	# Initialize.
	n = EAF_N(eaf)
	pn = EAF_PN(eaf)
	pf = EAF_PF(eaf)
	a = EAF_C(eaf)
	b = EAF_S(eaf)
	e = EAF_E(eaf)

	# Accumulate.
	dx = 1. / EAFS_NSUB
	dy = 1. / EAFS_NSUB
	f = val / EAFS_NSUB**2
	for (dl=-EAFS_NSUB/2*dy; dl < 0.5; dl = dl + dy) {
	    y1 = l + dl - OBJ_Y(obj)
	    for (dc=-EAFS_NSUB/2*dx; dc < 0.5; dc = dc + dx) {
		x1 = c + dc - OBJ_X(obj)
		x = x1 * a + y1 * b
		y = e * (-x1 * b + y1 * a)
		r = sqrt (x**2 + y**2)
		i = min (nint (r / EAFS_DR), n-1)
		call aaddkr (Memr[pf+i], f, Memr[pf+i], n-i)
		call aaddki (Memi[pn+i], 1, Memi[pn+i], n-i)
	    }
	}
end


# EAF_DONE -- Finish elliptical aperture measurement.

procedure eaf_done (eafs, eaf, obj)

pointer	eafs			#I EAFS structure
pointer	eaf			#U EAF pointer for object
pointer	obj			#I Object pointer

int	i, j, i1, i2, n
real	x, y, r, dr, r1, r2, rp, pr, pr1, pr2, xlast
real	a, b, sum, sumx, sumr, sumx2, sumxr
pointer	pn, pf

bool	foo

begin
	# Initialize.
	n = EAF_N(eaf)
	pn = EAF_PN(eaf)
	pf = EAF_PF(eaf)
	dr = EAFS_DR
	r1 = EAFS_R1
	r2 = EAFS_R2

foo = ((OBJ_X(obj)-256)**2+(OBJ_Y(obj)-256)**2 < 3)

	do j = 0, EAFS_NAP(eafs)-1 {
	    pr = EAFS_PR(eafs,j)
	    pr1 = pr + EAFS_PR1
	    pr2 = pr + EAFS_PR2

	    # Compute Petrosian ratio and radius.
if (foo) {
call eprintf ("Profile %d %g\n")
call pargi (j)
call pargr (pr)
}
	    xlast = 1
	    sum = 0.; sumx = 0.; sumr = 0.; sumx2 = 0.; sumxr = 0.
	    do i=nint(2./dr), n-1 {
		r = i * dr
		#i1 = nint (r * 0.8 / dr); i2 = nint (r * 1.25 / dr)
		i1 = nint ((r + r1) / dr); i2 = nint ((r + r2) / dr)
		if (i2 > n-1)
		    break
		x = (Memr[pf+i2]-Memr[pf+i1]) /
		    max(2*((r+r2)**2-(r+r1)**2),real(Memi[pn+i2]-Memi[pn+i1]))
#		x = (Memr[pf+i2]-Memr[pf+i1]) / (3.14*((r+r2)**2-(r+r1)**2))
#		x = (Memr[pf+i2]-Memr[pf+i1]) / max(1,Memi[pn+i2]-Memi[pn+i1])
		y = Memr[pf+i] / Memi[pn+i]
#		y = Memr[pf+i] / (3.14*r*r)
		x = x / y
		x = min (x, xlast)
		xlast = x
if (foo) {
call eprintf ("%6.2f %6.4f\n")
call pargr (r)
call pargr (x)
}
		if (x < pr2 && x > pr1) {
		    sum = sum + 1
		    sumx = sumx + x
		    sumr = sumr + r
		    sumx2 = sumx2 + x * x
		    sumxr = sumxr + x * r
		}
	    }

	    # Fit a line to estimate the radius and set parameters.
	    if (xlast <= pr && sum > 0) {
		y = sum * sumx2 - sumx * sumx
		a = (sumr * sumx2 - sumx * sumxr) / y
		b = (sum * sumxr - sumx * sumr) / y
		rp = a + b * pr
if (foo) {
call eprintf ("Fit %d %g\n")
call pargi (j)
call pargr (rp)
for (x=pr2; x>=pr1; x=x-0.01) {
r = a + b * x
call eprintf ("%6.2f %6.4f\n")
call pargr (r)
call pargr (x)
}
}
	    } else
		rp = n * dr

	    # Set object values.
	    i = nint (rp / dr)
	    if (i < n-1) {
		if (EAFS_RID(eafs,j) >= 0)
		    OBJ_EAR(obj,EAFS_RID(eafs,j)) = rp
		if (EAFS_FID(eafs,j) >= 0)
		    OBJ_EAFLUX(obj,EAFS_FID(eafs,j)) = Memr[pf+i]
	    } else {
		if (EAFS_RID(eafs,j) >= 0)
		    OBJ_EAR(obj,EAFS_RID(eafs,j)) = INDEFR
		if (EAFS_FID(eafs,j) >= 0)
		    OBJ_EAFLUX(obj,EAFS_FID(eafs,j)) = Memr[pf+n-1]
	    }
	}

	# Free memory.
	call mfree (eaf, TY_STRUCT)
end
