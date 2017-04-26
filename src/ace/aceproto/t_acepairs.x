include	<error.h>
include	<math.h>
include	<acecat.h>
include	"ap.h"
include	"ap0.h"
include	"ap1.h"
include	"ap2.h"
include	"ap3.h"
include	"ap4.h"

define	NCATS	4		# Maximum number of output catalogs
define	DEBUG	false
#define	DEBUG	true


# T_ACEPAIRS -- Find pairs and write catalogs.

procedure t_acepairs ()

pointer	ap			# Catalog information
pointer	pars			# Parameter information

char	str[5]
int	i
pointer	sp

bool	clgetb()
int	clgeti(), clgwrd(), afn_gfn(), btoi()
real	clgetr()
pointer	afn_cl()

errchk	acepairs

begin
	call smark (sp)
	call salloc (ap, (NCATS+1)*AP_LEN, TY_STRUCT)
	call salloc (pars, APP_LEN, TY_STRUCT)
	call aclri (Memi[ap], (NCATS+1)*AP_LEN)
	call aclri (Memi[pars], APP_LEN)
	
	# Set parameters.

	AP_LIST(ap,0) = afn_cl ("icats", "catalog", NULL)
	AP_LIST(ap,1) = afn_cl ("ocats", "catalog", AP_LIST(ap,0))
	AP_LIST(ap,2) = afn_cl ("pcats", "catalog", AP_LIST(ap,0))
	call clgstr ("icatdef", AP_DEF(ap,0), AP_SZFNAME)
	call clgstr ("ocatdef", AP_DEF(ap,1), AP_SZFNAME)
	call clgstr ("pcatdef", AP_DEF(ap,2), AP_SZFNAME)

	call strcpy ("NOINDEF", APP_FILTER(pars,1), AP_SZFNAME)
	call clgstr ("filter", APP_FILTER(pars,8), AP_SZFNAME)
	APP_IWIN(pars) = clgeti ("iwindow")
	APP_MINSEP(pars) = clgetr ("minsep")
	APP_MAXSEP(pars) = clgetr ("maxsep")
	APP_MINRATE(pars) = clgetr ("minrate")
	APP_MAXRATE(pars) = clgetr ("maxrate")
	APP_MAXDM(pars) = clgetr ("maxdm")
	APP_MAXDW(pars) = clgetr ("maxdw")
	APP_MAXDE(pars) = clgetr ("maxde")
	APP_MAXDP(pars) = clgetr ("maxdp")
	APP_TYPE(pars) = clgwrd ("type", str, 5, APPTYPES)
	APP_WEMPTY(pars) = btoi(clgetb("wempty"))

	# Loop through catalogs.
	while (afn_gfn (AP_LIST(ap,0), AP_NAME(ap,0), AP_SZFNAME) != EOF) {
	    do i = 1, 2 {
		if (afn_gfn (AP_LIST(ap,i), AP_NAME(ap,i), AP_SZFNAME) == EOF)
		    AP_NAME(ap,i) = EOS
	    }

	    iferr {
		call acepairs (ap, pars)
	    } then
		call erract (EA_WARN)
	}

	# Clean up.
	do i = 2, 0, -1
	    call afn_cls (AP_LIST(ap,i))
	call sfree(sp)
end


# T_ACEPALIGN -- Find pair alignments (i.e. cosmic string candidates).

procedure t_acepalign ()

pointer	ap			# Catalog information
pointer	pars			# Parameter information

char	str[5]
int	i
pointer	sp

bool	clgetb()
int	clgeti(), clgwrd(), afn_gfn(), btoi()
real	clgetr()
pointer	afn_cl()

errchk	acepairs

begin
	call smark (sp)
	call salloc (ap, (NCATS+1)*AP_LEN, TY_STRUCT)
	call salloc (pars, APP_LEN, TY_STRUCT)
	call aclri (Memi[ap], (NCATS+1)*AP_LEN)
	call aclri (Memi[pars], APP_LEN)
	
	# Set parameters.

	AP_LIST(ap,0) = afn_cl ("icats", "catalog", NULL)
	AP_LIST(ap,1) = afn_cl ("ocats", "catalog", AP_LIST(ap,0))
	AP_LIST(ap,2) = afn_cl ("pcats", "catalog", AP_LIST(ap,0))
	AP_LIST(ap,3) = afn_cl ("bcats", "catalog", AP_LIST(ap,0))
	AP_LIST(ap,4) = afn_cl ("acats", "catalog", AP_LIST(ap,0))
	call clgstr ("icatdef", AP_DEF(ap,0), AP_SZFNAME)
	call clgstr ("ocatdef", AP_DEF(ap,1), AP_SZFNAME)
	call clgstr ("pcatdef", AP_DEF(ap,2), AP_SZFNAME)
	call clgstr ("bcatdef", AP_DEF(ap,3), AP_SZFNAME)
	call clgstr ("acatdef", AP_DEF(ap,4), AP_SZFNAME)

	call strcpy ("NOINDEF", APP_FILTER(pars,1), AP_SZFNAME)
	call clgstr ("filter", APP_FILTER(pars,8), AP_SZFNAME)
	APP_IWIN(pars) = clgeti ("iwindow")
	APP_MINSEP(pars) = clgetr ("minsep")
	APP_MAXSEP(pars) = clgetr ("maxsep")
	APP_MINRATE(pars) = clgetr ("minrate")
	APP_MAXRATE(pars) = clgetr ("maxrate")
	APP_MAXDM(pars) = clgetr ("maxdm")
	APP_MAXDW(pars) = clgetr ("maxdw")
	APP_MAXDE(pars) = clgetr ("maxde")
	APP_MAXDP(pars) = clgetr ("maxdp")
	APP_MAXDPP(pars) = clgetr ("maxdpp")
	APP_MAXDR(pars) = clgetr ("maxdr")
	APP_ALIGN(pars) = clgetr ("align")
	APP_TYPE(pars) = clgwrd ("type", str, 5, APPTYPES)
	APP_WEMPTY(pars) = btoi(clgetb("wempty"))

	# Loop through catalogs.
	while (afn_gfn (AP_LIST(ap,0), AP_NAME(ap,0), AP_SZFNAME) != EOF) {
	    do i = 1, NCATS {
		if (afn_gfn (AP_LIST(ap,i), AP_NAME(ap,i), AP_SZFNAME) == EOF)
		    AP_NAME(ap,i) = EOS
	    }

	    iferr {
		call acepairs (ap, pars)
	    } then
		call erract (EA_WARN)
	}

	# Clean up.
	do i = NCATS, 0, -1
	    call afn_cls (AP_LIST(ap,i))
	call sfree(sp)
end
	

# ACEPAIRS -- Find pairs and write catalogs.
#
# This can be used to find cosmic strings.

procedure acepairs (ap, pars)

pointer	ap			#I AP data
pointer	pars			#I AP parameters

int	i
pointer	icat

errchk	catopen, catrecs, catsort
errchk	ap_pairs, ap_moving, ap_align, ap1_wcat, ap2_wcat, ap4_wcat

begin
	# Check if catalogs are specified.
	do i = 1, NCATS {
	    if (AP_NAME(ap,i) != EOS)
		break
	}
	if (i > NCATS)
	    return

	# Get the input records.
	call catopen (icat, AP_NAME(ap,0), "", AP_DEF(ap,0), AP0_DEF, NULL, 1) 
	call catrrecs (icat, APP_FILTER(pars,1), -1)
	AP_RECS(ap,0) = CAT_RECS(icat); AP_NRECS(ap,0) = CAT_NRECS(icat)

	# Find pairs and alignment of pairs (i.e. string candidates).
	call ap_pairs (icat, ap, pars)
	if (AP_NAME(ap,3) != NULL || AP_NAME(ap,4) != NULL) {
	    switch (APP_TYPE(pars)) {
	    case TY_MOVING:
		call ap_moving (ap, pars)
	    default:
		call ap_align (ap, pars)
	    }
	}

	# Write the catalogs as desired.
	call ap1_wcat (ap, pars, icat)
	call ap2_wcat (ap, pars, icat)
	call ap3_wcat (ap, pars, icat)
	call ap4_wcat (ap, pars, icat)

	# Free and close structures.
	do i = NCATS, 1, -1 {
	    if (AP_RECS(ap,i) != NULL)
		call mfree (AP_RECS(ap,i), TY_POINTER)
	}
	call catclose (icat, NO)

end


# AP_PAIRS -- Find pairs in input catalog.
# First pairs based on cartesian distances are found.
# Then the pair is evaluated against other criteria.

procedure ap_pairs (icat, ap, pars)

pointer	icat			#I Catalog
pointer	ap			#I AP data
pointer	pars			#I AP parameters

int	i, j, k, l, m, n
int	type, iwin, nim
real	minsep, maxsep, maxdm, maxde, maxdw, maxdp
real	xa, ya, xc, ma, ea, wa, pa, ua, sa
real	xb, yb, yc, mb, eb, wb, pb, ub, sb
real	xh, yh, dx, dy, dm, de, dw, dp, dt
real	minsep2, maxsep2, sep, sep2, p, p1, r, e, absr
pointer	recs, nrecs, reca, recb, rec

errchk	malloc, realloc

begin
	if (AP_RECS(ap,0) == NULL || AP_NRECS(ap,0) == 0)
	    return

	# Define criteria.
	type = APP_TYPE(pars)
	iwin = APP_IWIN(pars)
	minsep = APP_MINSEP(pars)
	maxsep = APP_MAXSEP(pars)
	maxdm = APP_MAXDM(pars)
	maxde = APP_MAXDE(pars)
	maxdw = APP_MAXDW(pars)
	maxdp = APP_MAXDP(pars)
	minsep2 = minsep * minsep
	maxsep2 = maxsep * maxsep

	# Sort the records by I and Y.
	call catsort (icat, Memi[AP_RECS(ap,0)], AP_NRECS(ap,0), AP0ID_I, 1)
	call malloc (recs, 100, TY_POINTER)
	call malloc (nrecs, 100, TY_POINTER)
	nim = 0
	do i = 0, AP_NRECS(ap,0)-1 {
	    rec = Memi[AP_RECS(ap,0)+i]
	    k = AP0_I(rec)
	    if (i == 0) {
		j = i
	        l = k
	    }
	    if (k != l) {
	        n = i - j
		call catsort (icat, Memi[AP_RECS(ap,0)+j], n, AP0ID_Y, 1)
		if (nim > 0 && mod(nim,100) == 0) {
		    call realloc (recs, nim+100, TY_POINTER)
		    call realloc (nrecs, nim+100, TY_POINTER)
		}
	        Memi[recs+nim] = AP_RECS(ap,0)+j
	        Memi[nrecs+nim] = n
		nim = nim + 1
		j = i
		l = k
	    }
	}
	n = i - j
	call catsort (icat, Memi[AP_RECS(ap,0)+j], n, AP0ID_Y, 1)
	if (nim > 0 && mod(nim,100) == 0) {
	    call realloc (recs, nim+100, TY_POINTER)
	    call realloc (nrecs, nim+100, TY_POINTER)
	}
	Memi[recs+nim] = AP_RECS(ap,0)+j
	Memi[nrecs+nim] = n
	nim = nim + 1

	# Loop through y sorted records.
	n = 0
	do l = 0, nim-1 {
	    do k = l, nim-1 {
		switch (type) {
		case TY_IMAGE:
		    if (k != l)
		       break
		case TY_MOVING:
		    if (k == l)
		       next
		    if (k-l+1 > iwin)
		        break

		    # Set separations based on rates.
		    reca = Memi[Memi[recs+l]]
		    recb = Memi[Memi[recs+k]]
		    #dt = max (abs(AP0_MJD(recb)-AP0_MJD(reca)) * 24., 0.01)
		    dt = (AP0_MJD(recb)-AP0_MJD(reca)) * 24. * 3600.
		    if (dt < 0)
		        dt = min (dt, -1.)
		    else
		        dt = max (dt, 1.)
		    if (!IS_INDEF(APP_MINRATE(pars)))
			minsep = max (abs(APP_MINRATE(pars) * dt / 3600.),
			    APP_MINSEP(pars))
		    else
			minsep = APP_MINSEP(pars)
		    if (!IS_INDEF(APP_MAXRATE(pars)))
			maxsep = min (abs(APP_MAXRATE(pars) * dt / 3600.),
			    APP_MAXSEP(pars))
		    else
			maxsep = APP_MAXSEP(pars)
		    minsep2 = minsep * minsep
		    maxsep2 = maxsep * maxsep

		default:
		    if (k-l+l > iwin)
		        break
		}

		do i = 0, Memi[nrecs+l]-1 {
		    reca = Memi[Memi[recs+l]+i]
		    xa = AP0_X(reca)
		    ya = AP0_Y(reca)
		    ma = AP0_M(reca)
		    ea = AP0_E(reca)
		    wa = (AP0_A(reca) + AP0_B(reca)) / 2
		    pa = AP0_P(reca)
		    sa = AP0_S(reca)
		    if (pa < 0.)
		        pa = pa + 180.
		    ua = AP0_U(reca)
		    if (k == l)
		        m = i + 1
		    else if (i == 0)
		        m = i
		    do j = m, Memi[nrecs+k]-1 {
			recb = Memi[Memi[recs+k]+j]

			if (DEBUG) {
			    call eprintf ("%d %d: %d %d - ")
				call pargi (AP0_I(reca))
				call pargi (AP0_I(recb))
				call pargi (AP0_N(reca))
				call pargi (AP0_N(recb))
			}

			# Check separation critera.
			yb = AP0_Y(recb)
			dy = yb - ya
			if (dy < -maxsep) {
			    m = j + 1
			    if (DEBUG) {
				call eprintf ("dy: %.1f < %.1f\n")
				    call pargr (dy)
				    call pargr (-maxsep)
			    }
			    next
			}
			if (dy > maxsep) {
			    if (DEBUG) {
				call eprintf ("dy: %.1f > %.1f\n")
				    call pargr (dy)
				    call pargr (maxsep)
			    }
			    break
			}
			xb = AP0_X(recb)
			dx = xb - xa

			if (abs(dx) > maxsep)
			    next
			sep2 = dx * dx + dy * dy
			if (sep2 > maxsep2 || sep2 < minsep2) {
			    if (DEBUG) {
				call eprintf ("sep: %.1f")
				    call pargr (sqrt(sep2))
			    }
			    next
			}
			sep = sqrt (sep2)

			# Set other quantities including Hough quantities.
			mb = AP0_M(recb)
			eb = AP0_E(recb)
			wb = (AP0_A(recb) + AP0_B(recb)) / 2
			pb = AP0_P(recb)
			sb = AP0_S(recb)
			if (pb < 0.)
			    pb = pb + 180.
			ub = AP0_U(recb)
			xc = INDEFR; yc = INDEFR; p = INDEFR
			xh = INDEFR; yh = INDEFR; r = INDEFR
			#call ap_hough (xa, ya, ua, xb, yb, ub, xc, yc,
			#    p, xh, yh, r)
			call ap_t0 (xa, ya, ua, xb, yb, ub, xc, yc,
			    p, xh, yh, r)
			p = RADTODEG(p)
			if (p < 0.)
			    p1 = p + 180.
			else
			    p1 = p

			# Apply type criteria.
			switch (type) {
			case TY_MOVING:

			    # Check magnitudes
			    dm = abs (mb - ma)
			    if (!IS_INDEFR(maxdm) && maxdm > 0. && dm > maxdm) {
				if (DEBUG) {
				    call eprintf ("dm: %.1f > %.1f\n")
					call pargr (dm)
					call pargr (maxdm)
				}
				next
			    }

			    # Check trailing directions are consistent with
			    # the motion.
			    dp = 0.
			    if (ea > 0.25) {
				e = abs(pa - p1)
				if (e > 90.)
				   e = 180. - e
				e = max (e, dp)
			    }
			    if (eb > 0.25) {
				e = abs (pb - p1)
				if (e > 90.)
				   e = 180. - e
				e = max (e, dp)
			    }
			    if (!IS_INDEFR(maxdp) && max(sa,sb)>4. &&
			        maxdp>0. && dp>maxdp){
				if (DEBUG) {
				    call eprintf ("dp: %.1f > %.1f\n")
					call pargr (dp)
					call pargr (maxdp)
				}
				next
			    }

			    # Check trailing ellipticity is consistent
			    # with the motion.  For large trails be less
			    # restrictive.
			    absr = abs (r)
			    wa = sqrt(AP0_A(reca)**2 - AP0_B(reca)**2)
			    de = absr * AP0_EXP(reca) / sqrt(12.)
			    dw = abs (wa - de)
			    if (de < 5.) {
				if (!IS_INDEFR(maxdw) && max(sa,sb)>4. &&
				    maxdw>0. && dw>maxdw) {
				    if (DEBUG) {
					call eprintf ("dw a: %.1f > %.1f\n")
					    call pargr (dw)
					    call pargr (maxdw)
				    }
				    next
				}
			    } else {
				if (ea < 0.4) {
				    if (DEBUG) {
					call eprintf ("ea: %.1f - de = %.1f\n")
					    call pargr (ea)
					    call pargr (de)
				    }
				    next
				}
			    }
			    wb = sqrt(AP0_A(recb)**2 - AP0_B(recb)**2)
			    de =  absr * AP0_EXP(recb) / sqrt(12.)
			    dw = max (abs(wb - de), dw)
			    if (de < 5.) {
				if (!IS_INDEFR(maxdw) && max(sa,sb)>4. &&
				    maxdw>0. && dw>maxdw) {
				    if (DEBUG) {
					call eprintf ("dw b: %.1f > %.1f\n")
					    call pargr (dw)
					    call pargr (maxdw)
				    }
				    next
				}
			    } else {
				if (eb < 0.4) {
				    if (DEBUG) {
					call eprintf ("eb: %.1f - de = %.1f\n")
					    call pargr (eb)
					    call pargr (de)
				    }
				    next
				}
			    }

			default:
			    # Check magnitudes
			    dm = abs (mb - ma)
			    if (!IS_INDEFR(maxdm) && maxdm > 0. && dm > maxdm)
				next

			    # Check ellipticities.
			    de = abs (eb - ea)
			    if (!IS_INDEFR(maxde) && max(sa,sb)>4. &&
			        maxde > 0. && de > maxde)
				next

			    # Check position angles.
			    dp = 0.
			    if (ea > 0.25 && eb > 0.25) {
				dp = abs(pb - pa)
				if (dp > 90.)
				   dp = 180 - dp
				if (!IS_INDEFR(maxdp) && max(sa,sb)>4. &&
				    maxdp>0. && dp>maxdp)
					next
			    }

			    # Check sizes.
			    dw = abs (wb - wa)
			    if (!IS_INDEFR(maxdw) && max(sa,sb)>4. &&
			        maxdw>0. &&  dw>maxdw)
				next

			    r = INDEFR
			}

			if (DEBUG)
			    call eprintf ("Accepted\n")
			    
			# Allocate records if necessary.
			if (AP_RECS(ap,2) == NULL)
			    call malloc (AP_RECS(ap,2), AP2_LEN*NALLOC,
			        TY_STRUCT)
			else if (mod (AP_NRECS(ap,2), NALLOC) == 0)
			    call realloc (AP_RECS(ap,2),
				AP2_LEN*(AP_NRECS(ap,2)+NALLOC), TY_STRUCT)

			# Record pair.
			AP_NRECS(ap,2) = AP_NRECS(ap,2) + 1
			n = n + 1
			rec = AP2_REC(AP_RECS(ap,2),n)
			AP2_RECA(rec) = reca
			AP2_RECB(rec) = recb
			AP2_ID(rec) = n
			AP2_XC(rec) = xc
			AP2_YC(rec) = yc
			AP2_MAV(rec) = (ma + mb) / 2
			AP2_UAV(rec) = (ua + ub) / 2
			AP2_PA(rec) = p
			AP2_XH1(rec) = xh
			AP2_YH1(rec) = yh
			AP2_SEP1(rec) = sep
			AP2_RATE1(rec) = r * 3600.
			AP2_DM1(rec) = dm
			AP2_DE1(rec) = de
			AP2_DW1(rec) = dw
			AP2_DP1(rec) = dp
			AP2_DU1(rec) = ub - ua
		    }
		}
	    }
	}
end


# AP_MOVING -- Find moving alignments in the pair data.

procedure ap_moving (ap, pars)

pointer	ap			#I AP data
pointer	pars			#I AP parameters

int	i, j, n
real	maxsep, maxdm, maxdp, maxdpp, maxdr
real	maxsep2, sep, sep2
real	xa, ya, xb, yb, xc, yc, xh, yh, p, pa, pb, r, r1
real	dx, dy, dm, dp1, dr
pointer	recs, reca, recb, recaa, recab, recba, recbb, rec

int	ap2_compare()
errchk	malloc, realloc
extern	ap2_compare

begin
	if (AP_RECS(ap,2) == NULL || AP_NRECS(ap,2) == 0)
	    return

	# Define criteria.
	maxsep = APP_MAXSEP(pars)
	maxdm = APP_MAXDM(pars)
	maxdp = APP_MAXDP(pars)
	maxdpp = APP_MAXDPP(pars)
	maxdr = APP_MAXDR(pars)
	maxsep2 = maxsep * maxsep

	# Sort in y.  The pairs will already be nearly sorted but not exactly.
	call malloc (recs, AP_NRECS(ap,2), TY_POINTER)
	do i = 1, AP_NRECS(ap,2)
	    Memi[recs+i-1] = AP2_REC(AP_RECS(ap,2),i)
	call qsort (Memi[recs], AP_NRECS(ap,2), ap2_compare)

	# Loop through y sorted records.
	n = 0
	do i = 1, AP_NRECS(ap,2)-1 {
	    reca = Memi[recs+i-1]
	    recaa = AP2_RECA(reca)
	    recab = AP2_RECB(reca)
	    xa = AP2_XC(reca)
	    ya = AP2_YC(reca)
	    do j = i+1, AP_NRECS(ap,2) {
		recb = Memi[recs+j-1]
		recba = AP2_RECA(recb)
		recbb = AP2_RECB(recb)

		# Pairs must contain at least three image IDs.
		if (min(AP0_I(recaa),AP0_I(recab)) == 
		    min(AP0_I(recba),AP0_I(recbb)) &&
		    max(AP0_I(recaa),AP0_I(recab)) == 
		    max(AP0_I(recba),AP0_I(recbb)))
		    next

		# Check separation critera.
	        yb = AP2_YC(recb)
	        dy = yb - ya
	        if (abs(dy) > maxsep)
	            break
	        xb = AP2_XC(recb)
	        dx = xb - xa
		if (abs(dx) > maxsep)
		    next
		sep2 = dx * dx + dy * dy
		if (sep2 > maxsep2)
		    next
		sep = sqrt (sep2)

		# Check magnitudes
		dm = abs (AP2_MAV(recb) - AP2_MAV(reca))
		if (!IS_INDEFR(maxdm) && maxdm > 0. && dm > maxdm)
		    next

		# Check position angles.
		pa = AP2_PA(reca)
		if (pa < 180.)
		    pa = pa + 180.
		pb = AP2_PA(recb)
		if (pb < 180.)
		    pb = pb + 180.
		dp1 = abs (pb - pa)
		if (dp1 > 90.)
		   dp1 = 180 - dp1
		if (dp1 > maxdp)
		    next

		# Check rates.
		if (!IS_INDEFR(maxdr) && abs(maxdr) > 0.) {
		    dr = abs (AP2_RATE1(reca)-AP2_RATE1(recb))
		    if (maxdr > 0.) {
		        if (dr > maxdr)
			    next
		    } else {
			r = min (AP2_RATE1(reca),AP2_RATE1(recb))
			if (dr > abs(maxdr) * r)
			    next
		    }
		}
		r = (AP2_RATE1(reca) + AP2_RATE1(recb)) / 2

		# Allocate records if necessary.
		if (AP_NRECS(ap,4) > 5000000) {
		    call eprintf ("WARNING: Too many pairs in ap_moving\n")
		    call mfree (AP_RECS(ap,4), TY_STRUCT)
		    AP_NRECS(ap,4) = 0
		    return
		}
		if (AP_RECS(ap,4) == NULL)
		    call malloc (AP_RECS(ap,4), AP4_LEN*NALLOC, TY_STRUCT)
		else if (mod (AP_NRECS(ap,4), NALLOC) == 0)
		    call realloc (AP_RECS(ap,4),
		        AP4_LEN*(AP_NRECS(ap,4)+NALLOC), TY_STRUCT)

		# Compute Hough distance.
		xc = (xa + xb) / 2
		yc = (ya + yb) / 2
		p = DEGTORAD ((AP2_PA(reca) + AP2_PA(recb)) / 2)
		xh = INDEFR; yh = INDEFR; r1 = INDEFR
		#call ap_hough (xa, ya, 0., xb, yb, 0., xc, yc, p, xh, yh, r1)
		call ap_t0 (xa, ya, 0., xb, yb, 0., xc, yc, p, xh, yh, r1)
		p = RADTODEG(p)

		# Record pair.
		AP_NRECS(ap,4) = AP_NRECS(ap,4) + 1
		n = n + 1
		rec = AP4_REC(AP_RECS(ap,4),n)
		AP4_RECA(rec) = reca
		AP4_RECB(rec) = recb
		AP4_ID(rec) = n
		AP4_XC(rec) = xc
		AP4_YC(rec) = yc
		AP4_PA(rec) = p
		AP4_XH1(rec) = xh
		AP4_YH1(rec) = yh
		AP4_DPA1(rec) = dp1
		AP4_DPA2(rec) = INDEFR

		# Override Hough values and average the rates.
		AP2_PA(reca) = AP4_PA(rec)
		AP2_XH1(reca) = AP4_XH1(rec)
		AP2_YH1(reca) = AP4_YH1(rec)
		AP2_RATE1(reca) = r
		AP2_PA(recb) = AP4_PA(rec)
		AP2_XH1(recb) = AP4_XH1(rec)
		AP2_YH1(recb) = AP4_YH1(rec)
		AP2_RATE1(recb) = r
	    }
	}

	AP_NRECS(ap,4) = n
end


# AP_ALIGN -- Find alignments in the pair data.

procedure ap_align (ap, pars)

pointer	ap			#I AP data
pointer	pars			#I AP parameters

int	i, j, n
real	maxdpp, align
real	xa, ya, xb, yb, xc, yc, pa, pb, dx, dy, dp1, dp2, xh, yh, r
pointer	recs, reca, recb, rec

int	ap2_compare()
errchk	malloc, realloc
extern	ap2_compare

begin
	if (AP_RECS(ap,2) == NULL || AP_NRECS(ap,2) == 0)
	    return

	# Define pair criteria.
	maxdpp = APP_MAXDPP(pars)
	align = APP_ALIGN(pars)

	# Sort in y.  The pairs will already be nearly sorted but not exactly.
	call malloc (recs, AP_NRECS(ap,2), TY_POINTER)
	do i = 1, AP_NRECS(ap,2)
	    Memi[recs+i-1] = AP2_REC(AP_RECS(ap,2),i)
	call qsort (Memi[recs], AP_NRECS(ap,2), ap2_compare)

	# Loop through y sorted records.
	n = 0
	do i = 1, AP_NRECS(ap,2)-1 {
	    reca = Memi[recs+i-1]
	    xa = AP2_XC(reca)
	    ya = AP2_YC(reca)
	    do j = i+1, AP_NRECS(ap,2) {
		recb = Memi[recs+j-1]
	        xb = AP2_XC(recb)
	        yb = AP2_YC(recb)

	        dx = xb - xa
	        dy = yb - ya
		pa = AP2_PA(reca)
		if (pa < 0.)
		    pa = pa + 180.
		pb = AP2_PA(recb)
		if (pb < 0.)
		    pb = pb + 180.
		dp1 = abs (pb - pa)
		if (dp1 > 90.)
		   dp1 = 180 - dp1
		if (abs(dp1) > maxdpp)
		    next

		if (pa < pb)
		    pa = pa + dp1 / 2
		else
		    pa = pa - dp1 / 2
		pa = pa + align
		if (pa < 180.)
		    pa = pa + 180
		pb = RADTODEG (atan2(dx,dy))
		if (pb < 180.)
		    pb = pb + 180.
		dp2 = abs (pb - pa)
		if (dp2 > 90.)
		   dp2 = 180 - dp2
		if (dp2 > maxdpp)
		    next

		# Allocate records if necessary.
		if (AP_RECS(ap,4) == NULL)
		    call malloc (AP_RECS(ap,4), AP4_LEN*NALLOC, TY_STRUCT)
		else if (mod (AP_NRECS(ap,4), NALLOC) == 0)
		    call realloc (AP_RECS(ap,4),
		        AP4_LEN*(AP_NRECS(ap,4)+NALLOC), TY_STRUCT)

		# Compute Hough distance.
		xc = INDEFR; yc = INDEFR; pb = INDEFR
		xh = INDEFR; yh = INDEFR; r = INDEFR
		#call ap_hough (xa, ya, 0., xb, yb, 0., xc, yc, pb, xh, yh, r)
		call ap_t0 (xa, ya, 0., xb, yb, 0., xc, yc, pb, xh, yh, r)
		pb = RADTODEG(pb)

		# Record pair.
		AP_NRECS(ap,4) = AP_NRECS(ap,4) + 1
		n = n + 1
		rec = AP4_REC(AP_RECS(ap,4),n)
		AP4_RECA(rec) = reca
		AP4_RECB(rec) = recb
		AP4_ID(rec) = n
		AP4_XC(rec) = xc
		AP4_YC(rec) = yc
		AP4_PA(rec) = pb
		AP4_XH1(rec) = xh
		AP4_YH1(rec) = yh
		AP4_DPA1(rec) = dp1
		AP4_DPA2(rec) = dp2
	    }
	}
	AP_NRECS(ap,4) = n
end


# AP1_WCAT -- Write single source catalog.

procedure ap1_wcat (ap, pars, icat)

pointer	ap				#I AP data
pointer	pars				#I AP parameters
pointer	icat				#I Input catalog pointer

int	i, j, nrecs
pointer	cat, recs, rec, orec

errchk	malloc, catopen, catcreate, im2im, catwrec

begin
	# Writing a catalog is optional.
	if (AP_NAME(ap,1) == EOS)
	    return
	if (AP_NRECS(ap,2) == 0 && APP_WEMPTY(pars) == NO)
	    return

	# Create the catalog
	call catopen (cat, "", AP_NAME(ap,1), AP_DEF(ap,1), AP1_DEF, NULL, 1)
	call catcreate (cat)

	# Copy the input catalog header.
	call im2im (CAT_IHDR(icat), CAT_OHDR(cat))

	# Check for empty catalog.
	if (AP_NRECS(ap,2) == 0) {
	    CAT_NRECS(cat) = 0
	    call catclose (cat, NO)
	    return
	}

	# A source may be in multiple pairs so sort and remove records.
	nrecs = 2 * AP_NRECS(ap,2)
	call malloc (recs, nrecs, TY_POINTER)
	do i = 1, AP_NRECS(ap,2) {
	    Memi[recs+2*i-2] = AP2_RECA(AP2_REC(AP_RECS(ap,2),i))
	    Memi[recs+2*i-1] = AP2_RECB(AP2_REC(AP_RECS(ap,2),i))
	}
	call asrti (Memi[recs], Memi[recs], nrecs)

	call malloc (orec, CAT_RECLEN(cat), TY_STRUCT)
	j = 0
	do i = 1, nrecs {
	    rec = Memi[recs+i-1]
	    if (i > 1 && rec == Memi[recs+i-2])
	        next
	    AP1_I(orec) = AP0_I(rec)
	    AP1_N(orec) = AP0_N(rec)
	    AP1_X(orec) = AP0_X(rec)
	    AP1_Y(orec) = AP0_Y(rec)
	    AP1_M(orec) = AP0_M(rec)
	    AP1_W(orec) = (AP0_A(rec) + AP0_B(rec)) / 2
	    AP1_E(orec) = AP0_E(rec)
	    AP1_P(orec) = AP0_P(rec)
	    AP1_U(orec) = AP0_U(rec)

	    j = j + 1
	    call catwrec (cat, orec, j)
	}
	CAT_NRECS(cat) = j
	call mfree (orec, TY_STRUCT)

	call catclose (cat, NO)
end


# AP2_WCAT -- Write pair catalog.

procedure ap2_wcat (ap, pars, icat)

pointer	ap				#I AP data
pointer	pars				#I AP parameters
pointer	icat				#I Input catalog pointer

int	i
pointer	cat, rec, reca, recb, orec

errchk	malloc, catopen, catcreate, im2im, catwrec

begin
	# Writing a catalog is optional.
	if (AP_NAME(ap,2) == EOS)
	    return
	if (AP_NRECS(ap,2) == 0 && APP_WEMPTY(pars) == NO)
	    return

	# Create the catalog
	call catopen (cat, "", AP_NAME(ap,2), AP_DEF(ap,2), AP2_DEF, NULL, 1)
	call catcreate (cat)

	# Copy the input catalog header.
	call im2im (CAT_IHDR(icat), CAT_OHDR(cat))

	# Check for empty catalog.
	if (AP_NRECS(ap,2) == 0) {
	    CAT_NRECS(cat) = 0
	    call catclose (cat, NO)
	    return
	}

	call malloc (orec, CAT_RECLEN(cat), TY_STRUCT)
	do i = 1, AP_NRECS(ap,2) {
	    rec = AP2_REC(AP_RECS(ap,2),i)
	    reca = AP2_RECA(rec)
	    recb = AP2_RECB(rec)
	    AP2_N(orec) = AP2_ID(rec)
	    AP2_X(orec) = AP2_XC(rec)
	    AP2_Y(orec) = AP2_YC(rec)
	    AP2_M(orec) = AP2_MAV(rec)
	    AP2_U(orec) = AP2_UAV(rec)
	    AP2_P(orec) = AP2_PA(rec)
	    AP2_XH(orec) = AP2_XH1(rec)
	    AP2_YH(orec) = AP2_YH1(rec)
	    AP2_SEP(orec) = AP2_SEP1(rec)
	    AP2_RATE(orec) = AP2_RATE1(rec)
	    AP2_DM(orec) = AP2_DM1(rec)
	    AP2_DE(orec) = AP2_DE1(rec)
	    AP2_DW(orec) = AP2_DW1(rec)
	    AP2_DP(orec) = AP2_DP1(rec)
	    AP2_DU(orec) = AP2_DU1(rec)
	    AP2_NA(orec) = AP0_N(reca)
	    AP2_XA(orec) = AP0_X(reca)
	    AP2_YA(orec) = AP0_Y(reca)
	    AP2_NB(orec) = AP0_N(recb)
	    AP2_XB(orec) = AP0_X(recb)
	    AP2_YB(orec) = AP0_Y(recb)
	    call catwrec (cat, orec, i)
	}
	CAT_NRECS(cat) = AP_NRECS(ap,2)
	call mfree (orec, TY_STRUCT)

	call catclose (cat, NO)
end


# AP3_WCAT -- Write single pair align catalog.

procedure ap3_wcat (ap, pars, icat)

pointer	ap				#I AP data
pointer	pars				#I AP parameters
pointer	icat				#I Input catalog pointer

int	i, j, nrecs
pointer	cat, recs, rec, orec, reca, recb

errchk	malloc, catopen, catcreate, im2im, catwrec

begin
	# Writing a catalog is optional.
	if (AP_NAME(ap,3) == EOS)
	    return
	if (AP_NRECS(ap,4) == 0 && APP_WEMPTY(pars) == NO)
	    return

	# Create the catalog
	call catopen (cat, "", AP_NAME(ap,3), AP_DEF(ap,3), AP3_DEF, NULL, 1)
	call catcreate (cat)

	# Copy the input catalog header.
	call im2im (CAT_IHDR(icat), CAT_OHDR(cat))

	# Check for empty catalog.
	if (AP_NRECS(ap,4) == 0) {
	    CAT_NRECS(cat) = 0
	    call catclose (cat, NO)
	    return
	}

	# A pair may be in multiple pairs of pairs so sort and remove records.
	nrecs = 2 * AP_NRECS(ap,4)
	call malloc (recs, nrecs, TY_POINTER)
	do i = 1, AP_NRECS(ap,4) {
	    Memi[recs+2*i-2] = AP4_RECA(AP4_REC(AP_RECS(ap,4),i))
	    Memi[recs+2*i-1] = AP4_RECB(AP4_REC(AP_RECS(ap,4),i))
	}
	call asrti (Memi[recs], Memi[recs], nrecs)

	call malloc (orec, CAT_RECLEN(cat), TY_STRUCT)
	j = 0
	do i = 1, nrecs {
	    rec = Memi[recs+i-1]
	    if (i > 1 && rec == Memi[recs+i-2])
	        next
	    reca = AP2_RECA(rec)
	    recb = AP2_RECB(rec)
	    AP3_N(orec) = AP2_ID(rec)
	    AP3_X(orec) = AP2_XC(rec)
	    AP3_Y(orec) = AP2_YC(rec)
	    AP3_M(orec) = AP2_MAV(rec)
	    AP3_U(orec) = AP2_UAV(rec)
	    AP3_P(orec) = AP2_PA(rec)
	    AP3_XH(orec) = AP2_XH1(rec)
	    AP3_YH(orec) = AP2_YH1(rec)
	    AP3_SEP(orec) = AP2_SEP1(rec)
	    AP3_RATE(orec) = AP2_RATE1(rec)
	    AP3_DM(orec) = AP2_DM1(rec)
	    AP3_DE(orec) = AP2_DE1(rec)
	    AP3_DW(orec) = AP2_DW1(rec)
	    AP3_DP(orec) = AP2_DP1(rec)
	    AP3_DU(orec) = AP2_DU1(rec)
	    AP3_NA(orec) = AP0_N(reca)
	    AP3_XA(orec) = AP0_X(reca)
	    AP3_YA(orec) = AP0_Y(reca)
	    AP3_NB(orec) = AP0_N(recb)
	    AP3_XB(orec) = AP0_X(recb)
	    AP3_YB(orec) = AP0_Y(recb)

	    j = j + 1
	    call catwrec (cat, orec, j)
	}
	CAT_NRECS(cat) = j
	call mfree (orec, TY_STRUCT)

	call catclose (cat, NO)
end


# AP4_WCAT -- Write line catalog.

procedure ap4_wcat (ap, pars, icat)

pointer	ap				#I AP data
pointer	pars				#I AP parameters
pointer	icat				#I Input catalog pointer

int	i
pointer	cat, rec, reca, recb, orec

errchk	malloc, catopen, catcreate, im2im, catwrec

begin
	# Writing a catalog is optional.
	if (AP_NAME(ap,4) == EOS)
	    return
	if (AP_NRECS(ap,4) == 0 && APP_WEMPTY(pars) == NO)
	    return

	# Create the catalog
	call catopen (cat, "", AP_NAME(ap,4), AP_DEF(ap,4), AP4_DEF, NULL, 1)
	call catcreate (cat)

	# Copy the input catalog header.
	call im2im (CAT_IHDR(icat), CAT_OHDR(cat))

	# Check for empty catalog.
	if (AP_NRECS(ap,4) == 0) {
	    CAT_NRECS(cat) = 0
	    call catclose (cat, NO)
	    return
	}

	call malloc (orec, CAT_RECLEN(cat), TY_STRUCT)
	do i = 1, AP_NRECS(ap,4) {
	    rec = AP4_REC(AP_RECS(ap,4),i)
	    reca = AP4_RECA(rec)
	    recb = AP4_RECB(rec)
	    AP4_N(orec) = AP4_ID(rec)
	    AP4_X(orec) = AP4_XC(rec)
	    AP4_Y(orec) = AP4_YC(rec)
	    AP4_P(orec) = AP4_PA(rec)
	    AP4_XH(orec) = AP4_XH1(rec)
	    AP4_YH(orec) = AP4_YH1(rec)
	    AP4_DP1(orec) = AP4_DPA1(rec)
	    AP4_DP2(orec) = AP4_DPA2(rec)
	    AP4_NA(orec) = AP2_ID(reca)
	    AP4_XA(orec) = AP2_XC(reca)
	    AP4_YA(orec) = AP2_YC(reca)
	    AP4_NB(orec) = AP2_ID(recb)
	    AP4_XB(orec) = AP2_XC(recb)
	    AP4_YB(orec) = AP2_YC(recb)
	    AP4_NAA(orec) = AP0_N(AP2_RECA(reca))
	    AP4_NBA(orec) = AP0_N(AP2_RECB(reca))
	    AP4_NAB(orec) = AP0_N(AP2_RECA(recb))
	    AP4_NBB(orec) = AP0_N(AP2_RECB(recb))
	    call catwrec (cat, orec, i)
	}
	CAT_NRECS(cat) = AP_NRECS(ap,4)
	call mfree (orec, TY_STRUCT)

	call catclose (cat, NO)
end


# AP_HOUGH -- Compute the Hough coordinate, line position angle, and rate
# along the line.
#
#    Variables:
#	(x,y) = a point on the line
#	d = distance between two points on the line
#	r = distance from origin to a point on the line
#	(xh,yh) = Hough point: minimizes r
#	p = the position angle of the line
#	dh = distance between (x,y) and (xh,yh)
#
#    Position angle:
#        dx = xb - xa, dy = yb - ya, d = sqrt (dx**2 + dy**2)
#        cos(p) = dx / d, sin(p) = dy / d, p = atan2 (dy, dx)
#
#    Basic equation:
#	x - xh = dh * cos(p),  y - yh = dh * sin(p)
#
#    Minimizing r**2 = x**2 + y**2 with respect to d from (xc,yc) yields:
#       x = xc + d * cos(p), y = yc + d * cos(p)
#	dh = = -d = x * cos(p) + y * sin(p)
#	xh = x - dh * cos(p)
#	yh = y - dh * sin(p)
#
#    We want to define dh' to be signed so we can discriminate direction
#    of motion and side of the Hough point.
#
#    dh' = (x - xh) * cos(p) + (y - yh) * sin(p)
#    if (p <= -90 || p > 90)
#        dh' = -dh'
#
#    Rate:
#	dh'(tb) = dh'(ta) + r * (tb - ta)
#	r = (dh'(tb) - dh'(ta)) / (tb - ta)

procedure ap_hough (xa, ya, ta, xb, yb, tb, xc, yc, p, xh, yh, r)

real	xa, ya, ta		#I Point on the line
real	xb, yb, tb		#I Point on the line
real	xc, yc			#O Reference point (average of two points)
real	p			#O Position angle (radians)
real	xh, yh			#O Hough coordinate
real	r			#O Rate

real	dx, dy, d, dh, cosp, sinp, da, db

begin
	# Compute position angle and reference point.
	if (IS_INDEFR(p)) {
	    dx = xb - xa
	    dy = yb - ya
	    d = sqrt (dx**2 + dy**2)
	    cosp = dx / d
	    sinp = dy / d
	    p = atan2 (dy, dx)
	} else {
	    cosp = cos (p)
	    sinp = sin (p)
	}

	# Reference point.
	if (IS_INDEFR(xc))
	    xc = (xa + xb) / 2
	if (IS_INDEFR(yc))
	    yc = (ya + yb) / 2

	# Compute Hough point.
	dh = xc * cosp + yc * sinp
	if (IS_INDEFR(xh))
	    xh = xc - dh * cosp
	if (IS_INDEFR(yh))
	    yh = yc - dh * sinp
	if (IS_INDEFR(r) && abs(tb - ta) > 0) {
	    da = (xa - xh) * cosp + (ya - yh) * sinp
	    db = (xb - xh) * cosp + (yb - yh) * sinp
	    if (p <= -HALFPI || p > HALFPI) {
	        da = -da
		db = -db
	    }
	    r = (db - da) / (tb - ta)
	}
end


# AP_T0 -- Compute the coordinate at t=0, line position angle, and rate.

procedure ap_t0 (x1, y1, t1, x2, y2, t2, xc, yc, p, x0, y0, r)

real	x1, y1, t1		#I Point on the line
real	x2, y2, t2		#I Point on the line
real	xc, yc			#O Reference point (average of two points)
real	p			#O Position angle (radians)
real	x0, y0			#O Origin coordinate
real	r			#O Rate

real	xa, ya, ta, xb, yb, tb
real	dx, dy, d, dh, cosp, sinp, da, db

begin
	# Order the input.
	if (t1 < t2) {
	    xa = x1; ya = y1; ta = t1
	    xb = x2; yb = y2; tb = t2
	} else {
	    xa = x2; ya = y2; ta = t2
	    xb = x1; yb = y1; tb = t1
	}

	# Compute position angle and reference point.
	if (IS_INDEFR(p)) {
	    dx = xb - xa
	    dy = yb - ya
	    d = sqrt (dx**2 + dy**2)
	    cosp = dx / d
	    sinp = dy / d
	    p = atan2 (dy, dx)
	} else {
	    cosp = cos (p)
	    sinp = sin (p)
	}

	# Compute rate.
	if (IS_INDEFR(r))
	    r = d / (tb - ta)

	# Compute origin point.
	if (IS_INDEFR(x0))
	    x0 = xa - r * ta * cosp
	if (IS_INDEFR(y0))
	    y0 = ya - r * ta * sinp

	# Pair reference point.
	if (IS_INDEFR(xc))
	    xc = (xa + xb) / 2
	if (IS_INDEFR(yc))
	    yc = (ya + yb) / 2
end


# AP2_COMPARE -- Sort comparison for pairs.

int procedure ap2_compare (rec1, rec2)

pointer	rec1, rec2

begin
	if (AP2_YC(rec1) < AP2_YC(rec2))
	    return (-1)
	else if (AP2_YC(rec1) == AP2_YC(rec2))
	    return (0)
	else
	    return (1)
end
