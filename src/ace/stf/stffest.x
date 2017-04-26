include	"starfocus.h"


# STF_FITFOCUS -- Find the best focus.

procedure stf_fitfocus (sf)

pointer	sf			#I Starfocus pointer

int	i, j, k, l, n, ns, nf, nit, nfmin
pointer	x, y, sfd, sfs, sff, sfi
real	f, r, m, w, wr, wf, asokr()
double	rsig, fsig
bool	fp_equalr()

begin
	# Set number of valid points, stars, focuses, images.
	SF_N(sf) = 0
	SF_YP1(sf) = 0
	SF_YP2(sf) = 0
	do i = 1, SF_NSFD(sf) {
	    sfd = SF_SFD(sf,i)
	    if (SFD_STATUS(sfd) != 0)
	        next
	    SF_N(sf) = SF_N(sf) + 1
	    SF_YP1(sf) = min (SF_YP1(sf), SFD_YP1(sfd))
	    SF_YP2(sf) = max (SF_YP2(sf), SFD_YP2(sfd))
	}
	SF_NS(sf) = 0
	do i = 1, SF_NSTARS(sf) {
	    sfs = SF_SFS(sf,i)
	    SFS_N(sfs) = 0
	    SFS_M(sfs) = 0.
	    SFS_NF(sfs) = 0
	    do j = 1, SFS_NSFD(sfs) {
		sfd = SFS_SFD(sfs,j)
		if (SFD_STATUS(SFS_SFD(sfs,j)) != 0)
		    next
		SFS_N(sfs) = SFS_N(sfs) + 1
		SFS_M(sfs) = SFS_M(sfs) + SFD_M(sfd)
		sff = SFD_SFF(sfd)
		for (k = 1; SFD_SFF(SFS_SFD(sfs,k)) != sff; k = k + 1)
		    ;
		if (k == j)
		    SFS_NF(sfs) = SFS_NF(sfs) + 1
	    }
	    if (SFS_N(sfs) > 0) {
		SFS_M(sfs) = SFS_M(sfs) / SFS_N(sfs)
		SF_NS(sf) = SF_NS(sf) + 1
	    }
	}
	if (SF_RSIG(sf) > 0)
	    nit = 2
	else
	    nit = 0
	SF_NF(sf) = 0
	do i = 1, SF_NFOCUS(sf) {
	    sff = SF_SFF(sf,i)
	    do l = 0, nit {
		SFF_W(sff) = 0.
		SFF_N(sff) = 0
		SFF_NI(sff) = 0
		wr = 0; rsig = 0
		do j = 1, SFF_NSFD(sff) {
		    sfd = SFF_SFD(sff,j)
		    if (SFD_STATUS(sfd) != 0)
			next
		    m = SFS_M(SFD_SFS(sfd))
		    r = SFD_W(sfd)
		    w = m
		    wr = wr + w
		    rsig = rsig + w * r * r
		    SFF_W(sff) = SFF_W(sff) + w * r
		    SFF_N(sff) = SFF_N(sff) + 1
		    sfi = SFD_SFI(sfd)
		    for (k = 1; SFD_SFI(SFF_SFD(sff,k)) != sfi; k = k + 1)
			;
		    if (k == j)
			SFF_NI(sff) = SFF_NI(sff) + 1
		}
		if (SFF_N(sff) > 0) {
		    SFF_W(sff) = SFF_W(sff) / wr
		    r = SFF_W(sff)
		    rsig = (rsig - r * r * wr) / wr
		    if (rsig > 0.)
			rsig = sqrt (rsig)
		} else
		    break
		if (l == nit || rsig <= 0)
		    break
		r = SFF_W(sff); rsig = SF_RSIG(sf) * rsig
		n = 0
		do j = 1, SFF_NSFD(sff) {
		    sfd = SFF_SFD(sff,j)
		    if (SFD_STATUS(sfd) != 0)
			next
		    if (SFD_W(sfd) < r-rsig || SFD_W(sfd) > r+rsig) {
			sfs = SFD_SFS(sfd)
			do k = 1, SFS_NSFD(sfs) {
			    sfd = SFS_SFD(sfs,k)
			    if (SFD_STATUS(sfd) > 0)
				next
			    SFD_STATUS(sfd) = -1
			}
			n = n + 1
		    }
		}
		if (n == 0)
		    break
	    }
	    if (SFF_N(sff) > 0) {
		call malloc (x, SFF_N(sff), TY_REAL)
		n = 0
		do j = 1, SFF_NSFD(sff) {
		    sfd = SFF_SFD(sff,j)
		    if (SFD_STATUS(sfd) != 0)
			next
		    Memr[x+n] = SFD_W(sfd)
		    n = n + 1
		}
		if (n > 1)
		    SFF_W(sff) = asokr (Memr[x], n, (n + 1) / 2)
		call mfree (x, TY_REAL)
		SF_NF(sf) = SF_NF(sf) + 1
	    }
	}
	SF_NI(sf) = 0
	do i = 1, SF_NIMAGES(sf) {
	    sfi = SF_SFI(sf,i)
	    SFI_N(sfi) = 0
	    do j = 1, SFI_NSFD(sfi)
		if (SFD_STATUS(SFI_SFD(sfi,j)) != 0)
		    SFI_N(sfi) = SFI_N(sfi) + 1
	    if (SFI_N(sfi) > 0)
		SF_NI(sf) = SF_NI(sf) + 1
	}

	# Set number of stars with all current focus values.
	do nit = 1, 2 {
	    if (nit == 1)
	        nf = max (3, SF_NF(sf) - 2)
	    else
	        nf = max (3, (SF_NF(sf) + 1) / 2)
	      
	    do k = SF_NF(sf), nf, -1 { 
		ns = 0
		do i = 1, SF_NSTARS(sf) {
		    sfs = SF_SFS(sf,i)

		    # Check number which have been thrown out by radius.
		    n = SFS_NF(sfs)
		    do j = 1, SFS_NSFD(sfs) {
			sfd = SFS_SFD(sfs,j)
			if (SFD_STATUS(sfd) < 0)
			    n = n - 1
		    }
		    if (n >= k)
			ns = ns + 1
		}

#call eprintf ("%d: Found %d with %d or more matches\n")
#call pargi (nit)
#call pargi (ns)
#call pargi (k)

		# If there aren't enough stars try a smaller focus number.
		if (ns >= 10)
		    break
	    }

	    if (ns >= 10)
	        break

	    # If there still aren't enough stars try eliminating the radius
	    # rejection.
	    do i = 1, SF_NSFD(sf) {
		sfd = SF_SFD(sf,i)
		SFD_STATUS(sfd) = max (0, SFD_STATUS(sfd))
	    }
	}
	nfmin = k

	# Mark those with insuffient focus matches as rejected.
	if (ns > 0) {
	    do i = 1, SF_NSTARS(sf) {
		sfs = SF_SFS(sf,i)
		if (SFS_NF(sfs) < nfmin) {
		    do j = 1, SFS_NSFD(sfs) {
			sfd = SFS_SFD(sfs,j)
			if (SFD_STATUS(sfd) > 0)
			    next
			SFD_STATUS(sfd) = -1
		    }
		}
	    }
	    SF_NS(sf) = ns
	}

	# Find the average magnitude, best focus, and radius for each star.
	# Find the brightest magnitude and average best focus and radius
	# over all stars.  If there are no stars with all focus values
	# then find best focus from averages at each focus.

	SF_BEST(sf) = SF_SFD(sf,1)
	SF_F(sf) = 0.
	SF_W(sf) = 0.
	SF_M(sf) = 0.

	if (ns > 0) {
	    if (SF_FSIG(sf) > 0.)
	        nit = 2
	    else
	        nit = 0
	    do l = 0, nit  {
		wr = 0.; wf = 0.; fsig = 0
		do i = 1, SF_NSTARS(sf) {
		    sfs = SF_SFS(sf,i)
		    SFS_F(sfs) = INDEF
		    SFS_W(sfs) = INDEF
		    SFS_N(sfs) = 0
		    if (SFS_NF(sfs) < nfmin) {
			SFS_M(sfs) = INDEF
			next
		    }
		    call malloc (x, SFS_NSFD(sfs), TY_REAL)
		    call malloc (y, SFS_NSFD(sfs), TY_REAL)
		    k = 0; n = 0
		    do j = 1, SFS_NSFD(sfs) {
			sfd = SFS_SFD(sfs,j)
			if (SFD_STATUS(sfd) != 0)
			    next
			r = SFD_W(sfd)
			f = SFD_F(sfd)
			if (!IS_INDEF(f))
			    k = k + 1
			Memr[x+n] = f
			Memr[y+n] = r
			n = n + 1
			if (r < SFD_W(SF_BEST(sf)))
			    SF_BEST(sf) = sfd
		    }

		    # Find the best focus and radius.
		    if (n == 0)
			SFS_M(sfs) = INDEF
		    else if (k == 0) {
			call alimr (Memr[y], n, f, r)
			f = INDEF
			m = SFS_M(sfs)
			wr = wr + m
			SFS_F(sfs) = f
			SFS_W(sfs) = r
			SFS_M(sfs) = m
			SFS_N(sfs) = n
			SF_W(sf) = SF_W(sf) + m * r
			SF_M(sf) = max (SF_M(sf), m)
		    } else {
			SFS_N(sfs) = n
			if (k < n) {
			    k = 0
			    do j = 0, n-1 {
				if (!IS_INDEF(Memr[x+j])) {
				    Memr[x+k] = Memr[x+j]
				    Memr[y+k] = Memr[y+j]
				    k = k + 1
				}
			    }
			}
			call xt_sort2 (Memr[x], Memr[y], k)
			n = 0
			do j = 1, k-1 {
			    if (fp_equalr (Memr[x+j], Memr[x+n])) {
				if (Memr[y+j] < Memr[y+n])
				    Memr[y+n] = Memr[y+j]
			    } else {
				n = n + 1
				Memr[x+n] = Memr[x+j]
				Memr[y+n] = Memr[y+j]
			    }
			}
			n = n + 1

			# Estimate focus.
			call stf_festimate (Memr[x], Memr[y], n, f, r)

			m = SFS_M(sfs)
			SFS_F(sfs) = f
			SFS_W(sfs) = r
			SFS_M(sfs) = m
			if (!IS_INDEFR(f)) {
			    w = k * m
			    wr = wr + w
			    wf = wf + w
			    fsig = fsig + w * f * f
			    SF_F(sf) = SF_F(sf) + w * f
			    SF_W(sf) = SF_W(sf) + w * r
			    SF_M(sf) = max (SF_M(sf), m)
			}
		    }
		    call mfree (x, TY_REAL)
		    call mfree (y, TY_REAL)
		}

		# Finish up the global weighted averages.
		if (wr > 0.)
		    SF_W(sf) = SF_W(sf) / wr
		else {
		    SF_W(sf) = INDEF
		    SF_M(sf) = INDEF
		}
		if (wf > 0.) {
		    SF_F(sf) = SF_F(sf) / wf
		    f = SF_F(sf)
		    fsig = (fsig - f * f * wf) / wf
		    if (fsig > 0.)
		        fsig = sqrt (fsig)
		} else {
		    SF_F(sf) = INDEF
		    break
		}

		# Apply sigma clipping if desired.
		if (l == nit || fsig <= 0.)
		    break
		f = SF_F(sf); fsig = SF_FSIG(sf) * fsig
		n =  SF_NS(sf); SF_NS(sf) = 0
		do i = 1, SF_NSTARS(sf) {
		    sfs = SF_SFS(sf,i)
		    if (SFS_NF(sfs) < nfmin)
			next
		    if (SFS_F(sfs) < f-fsig || SFS_F(sfs) > f+fsig) {
			do j = 1, SFS_NSFD(sfs) {
			    sfd = SFS_SFD(sfs,j)
			    if (SFD_STATUS(sfd) > 0)
				next
			    SFD_STATUS(sfd) = -1
			}
		    } else
			SF_NS(sf) = SF_NS(sf) + 1
		}
		if (SF_NS(sf) == n)
		    break
	    }
	}

	if (SF_W(sf) <= 0.) {
	    call malloc (x, SF_NFOCUS(sf), TY_REAL)
	    call malloc (y, SF_NFOCUS(sf), TY_REAL)
	    wr = 0; wf = 0
	    k = 0; n = 0
	    do j = 1, SF_NFOCUS(sf) {
		sff = SF_SFF(sf,j)
		if (SFF_N(sff) == 0)
		    next
		r = SFF_W(sff)
		f = SFF_F(sff)
		k = k + 1
		Memr[x+n] = f
		Memr[y+n] = r
		n = n + 1
	    }

	    # Find the best focus and radius.
	    call xt_sort2 (Memr[x], Memr[y], k)
	    n = 0
	    do j = 1, k-1 {
		if (fp_equalr (Memr[x+j], Memr[x+n])) {
		    if (Memr[y+j] < Memr[y+n])
			Memr[y+n] = Memr[y+j]
		} else {
		    n = n + 1
		    Memr[x+n] = Memr[x+j]
		    Memr[y+n] = Memr[y+j]
		}
	    }
	    n = n + 1

	    # Estimate focus.
	    call stf_festimate (Memr[x], Memr[y], n, f, r)

	    if (!IS_INDEFR(f)) {
		m = 1
		wr = wr + k * m
		wf = wf + k * m
		SF_F(sf) = SF_F(sf) + k * m * f
		SF_W(sf) = SF_W(sf) + k * m * r
		SF_M(sf) = m
	    }
	    call mfree (x, TY_REAL)
	    call mfree (y, TY_REAL)

	    if (wr > 0.)
		SF_W(sf) = SF_W(sf) / wr
	    else {
		SF_W(sf) = INDEF
		SF_M(sf) = INDEF
	    }
	    if (wf > 0.)
		SF_F(sf) = SF_F(sf) / wf
	    else
		SF_F(sf) = INDEF
	}
end


# STF_FESTIMATE -- Estimate focus value.

procedure stf_festimate (f, s, n, focus, size)

real	f[n]			#I Focus values (ordered)
real	s[n]			#I Size values
int	n			#I Number of values
real	focus			#O Focus estimate
real	size			#O Size estimate

int	i
double	a, b, c, w, wsum
#double	x12, x13, x23, x213, x223, y13, y23

begin
	focus = INDEF
	size = INDEF

	if (n < 3)
	    return

	# Sort by size and combine smallest ones.
	c = f[n] - f[1]
	call xt_sort2 (s, f, n)
	focus = 0; size = 0; wsum = 0
	do i = 1, min(3,n) {
	    a = 10 * abs (f[i] - f[1]) / c
	    b = 10 * (s[i] - s[1]) / s[1]
	    w = 1 + a * b
	    focus = focus + f[i] / w
	    size = size + s[i] / w
	    wsum = wsum + 1 / w
	}
	focus = focus / wsum; size = size / wsum

#	# Fit a parabola around the smallest size.
#	j = 1
#	do i = 2, n {
#	    if (s[i] < s[j])
#	        j = i
#	}
#	j = max (2, min (n-1, j))
#
#	if (s[j-1] < s[j]) {
#	    focus = f[j-1]
#	    size = s[j-1]
#	    return
#	} else if (s[j] > s[j+1]) {
#	    focus = f[j+1]
#	    size = s[j+1]
#	    return
#	}
#
#	x12 = f[j-1] - f[j]
#	x13 = f[j-1] - f[j+1]
#	x23 = f[j] - f[j+1]
#	x213 = x13 * x13
#	x223 = x23 * x23
#	y13 = s[j-1] - s[j+1]
#	y23 = s[j] - s[j+1]
#	c = (y13 - y23 * x13 / x23) / (x213 - x223 * x13 / x23)
#	b = (y23 - c * x223) / x23
#	a = s[j+1]
#	focus = -b / (2 * c)
#	size = a + b * focus + c * focus * focus
#	focus = focus + f[j+1]
end
