include	<math.h>
include	<acecat.h>
include	<acecat1.h>


# CATWCS -- Set catalog WCS information.

procedure catwcs (cat, im)

pointer	cat			#I Catalog pointer
pointer	im			#I IMIO pointer

pointer	mw, hdr

pointer	mw_openim()
errchk	mw_openim

begin
	if (cat == NULL)
	    return

	# Set catalog WCS.
	mw = mw_openim (im)
	call catwcs_open (cat, mw)
	call mw_close (mw)

	# Set catalog header WCS.
	mw = CAT_MW(CAT_WCS(cat))
	hdr = CAT_OHDR(cat)
	call mw_saveim (mw, hdr)
end


# CATWCS_OPEN -- Open a WCS attached to a catalog.
#
# This copies the MWCS pointer so it is safe for the application to
# close it without affecting the catalog WCS.  Note that the WCS need
# not be that in the catalog header.

procedure catwcs_open (cat, mw)

pointer	cat			#I Catalog pointer
pointer	mw			#I MWCS pointer

pointer	mw_newcopy()

begin
	if (cat == NULL)
	    return

	call catwcs_close (cat)

	if (mw == NULL)
	    return

	call calloc (CAT_WCS(cat), CAT_WCSLEN, TY_STRUCT)
	CAT_MW(CAT_WCS(cat)) = mw_newcopy (mw)
end


# CATWCS_CLOSE -- Close a WCS attached to a catalog.
#
# This frees all memory associated with the WCS.  Note that we rely on
# mw_close to free any CT structures.

procedure catwcs_close (cat)

pointer	cat			#I Catalog pointer

begin
	if (cat == NULL)
	    return
	if (CAT_WCS(cat) == NULL)
	    return

	if (CAT_MW(CAT_WCS(cat)) != NULL)
	    call mw_close (CAT_MW(CAT_WCS(cat)))
	call mfree (CAT_WCS(cat), TY_STRUCT)
end


# CAT_LW -- Evaluate world coordinates from logical coordinates.
#
# For efficiency this routine does not error check if catalog WCS is defined.
# It also assumes the CT pointer is not initially set.

procedure cat_lw (cat, x, y, wx, wy, ra, dec)

pointer	cat			#I Catalog pointer
double	x			#I X logical coordinate
double	y			#I Y logical coordinate
double	wx			#I X world coordinate
double	wy			#I Y world coordinate
double	ra			#I RA world coordinate
double	dec			#I DEC world coordinate

char	axtype[3]
double	w[2]
pointer	mw, ct, mw_sctran()
bool	streq()

int	raaxis, decaxis
common	/radecaxes/ raaxis, decaxis

begin
	if (IS_INDEFD(x) || IS_INDEFD(y)) {
	    wx = INDEFD
	    wy = INDEFD
	    ra = INDEFD
	    dec = INDEFD
	    return
	}

	ct = CAT_CTLW(CAT_WCS(cat))
	if (ct == NULL) {
	    mw = CAT_MW(CAT_WCS(cat))
	    ct = mw_sctran (mw, "logical", "world", 03B)
	    CAT_CTLW(CAT_WCS(cat)) = ct
	    raaxis = INDEFI
	    decaxis = INDEFI
	    ifnoerr (call mw_gwattrs (mw, 1, "axtype", axtype, 3)) {
	        if (streq (axtype, "ra"))
		    raaxis = 1
		else if (streq (axtype, "dec"))
		    decaxis = 1
	    }
	    ifnoerr (call mw_gwattrs (mw, 2, "axtype", axtype, 3)) {
	        if (streq (axtype, "ra"))
		    raaxis = 2
		else if (streq (axtype, "dec"))
		    decaxis = 2
	    }
	}

	call mw_c2trand (ct, x, y, w[1], w[2])
	wx = w[1]
	wy = w[2]
	if (IS_INDEFI(raaxis))
	    ra = INDEFD
	else
	    ra = w[raaxis]
	if (IS_INDEFI(decaxis))
	    dec = INDEFD
	else
	    dec = w[decaxis]
end


# CAT_LP -- Evaluate physical coordinates from logical coordinates.
#
# For efficiency this routine does not error check if catalog WCS is defined.

procedure cat_lp (cat, x, y, px, py)

pointer	cat			#I Catalog pointer
double	x			#I X logical coordinate
double	y			#I Y logical coordinate
double	px			#I X physical coordinate
double	py			#I Y physical coordinate

pointer	ct, mw_sctran()

begin
	if (IS_INDEFD(x) || IS_INDEFD(y)) {
	    px = INDEFD
	    py = INDEFD
	    return
	}

	ct = CAT_CTLP(CAT_WCS(cat))
	if (ct == NULL) {
	    ct = mw_sctran (CAT_MW(CAT_WCS(cat)), "logical", "physical", 03B)
	    CAT_CTLP(CAT_WCS(cat)) = ct
	}

	call mw_c2trand (ct, x, y, px, py)
end


# CAT_STD -- Conversion between equitorial and standard coordinates.
# The direction is set by input INDEF values.

procedure cat_std (ra, dec, xi, eta, raz, decz)

double	ra			#U RA coordinate (hr)
double	dec			#U DEC coordinate (deg)
double	xi			#U XI standard coordinate (arcsec)
double	eta			#U ETA standard coordinate (arcsec)
double	raz			#I RA reference coordinate (hr)
double	decz			#I DEC reference coordinate (deg)

double	r, d, x, e, rz, dz, denom
double	sdz, sd, cdz, cd, srdif, crdif

begin
	if (IS_INDEFD(raz) || IS_INDEFD(decz))
	    return

	rz = DEGTORAD(raz*15D0)
	dz = DEGTORAD(decz)
	sdz = sin (dz)
	cdz = cos (dz)

	if (!IS_INDEFD(ra) && !IS_INDEFD(dec) &&
	    IS_INDEFD(xi) && IS_INDEFD(eta)) {
	
	    r = DEGTORAD(ra*15D0)
	    d = DEGTORAD(dec)

	    sd = sin (d)
	    cd = cos (d)
	    srdif = sin (r - rz)
	    crdif = cos (r - rz)

	    denom = sd * sdz + cd * cdz * crdif
	    xi = cd * srdif / denom
	    eta = (sd * cdz - cd * sdz * crdif) / denom

	    xi = RADTODEG (xi) * 3600D0
	    eta = RADTODEG (eta) * 3600D0

	} else if (IS_INDEFD(ra) && IS_INDEFD(dec) &&
	    !IS_INDEFD(xi) && !IS_INDEFD(eta)) {

	    x = DEGTORAD(xi/3600D0)
	    e = DEGTORAD(eta/3600D0)

	    denom = cdz - e * sdz
	    ra = mod (atan2 (x, denom) + rz, TWOPI)
	    dec = atan2 (sdz + e * cdz, sqrt (x * x + denom * denom))

	    if (ra < 0.)
		ra = ra + TWOPI

	    ra = RADTODEG (ra) / 15D0
	    dec = RADTODEG (dec)
	}
end


#define	SE	0.39777699402185	# sin of ecliptic tilt
#define	CE	0.91748213226577	# cos of ecliptic tilt
#
## CAT_EC -- Conversion between equitorial and ecliptic coordinates.
## The direction is set by input INDEF values.
#
#procedure cat_ec (ra, dec, lon, lat)
#
#double	ra			#U RA coordinate (hr)
#double	dec			#U DEC coordinate (deg)
#double	lon			#U Ecliptic longitude coordinate (deg)
#double	lat			#U Ecliptic latitude coordinate (deg)
#
#double	x, y, sx, cx, sy, cy
#
#begin
#	if (!IS_INDEFD(ra) && !IS_INDEFD(dec) &&
#	    IS_INDEFD(lon) && IS_INDEFD(lat)) {
#	
#	    x = DEGTORAD(ra*15D0)
#	    y = DEGTORAD(dec)
#
#	    sx = sin (x)
#	    cx = cos (x)
#	    sy = sin (y)
#	    cy = cos (y)
#
#	    x = atan2 (SE * sy + CE * sx * cy, cx * cy)
#	    y = asin (CE * sy - SE * sx * cy)
#
#	    if (x < 0.)
#	        x = x + TWOPI
#
#	    lon = RADTODEG (x)
#	    lat = RADTODEG (y)
#
#	} else if (IS_INDEFD(ra) && IS_INDEFD(dec) &&
#	    !IS_INDEFD(lon) && !IS_INDEFD(lat)) {
#
#	    x = DEGTORAD(lon)
#	    y = DEGTORAD(lat)
#
#	    sx = sin (x)
#	    cx = cos (x)
#	    sy = sin (y)
#	    cy = cos (y)
#
#	    x = atan2 (CE * sx * cy - SE * sy, cx * cy)
#	    y = asin (SE * sx * cy + CE * sy)
#
#	    if (x < 0.)
#		x = x + TWOPI
#
#	    ra = RADTODEG (x) / 15D0
#	    dec = RADTODEG (y)
#	}
#end


define	GORA	4.649644328325647D0
define	GODEC	-0.5050314830500388D0
define	GPRA	3.366032941500769D0
define	GPDEC	0.473477302196699D0
define	GOL	1.681402544186484D0
define	GOB	-1.050488417982601D0
define	GPL	2.145566750101994D0
define	GPB	0.4734772828041517D0

# CAT_GAL -- Conversion between equitorial and galactic coordinates.
# The direction is set by input INDEF values.

procedure cat_gal (ra, dec, l, b)

double	ra			#U RA coordinate (hr)
double	dec			#U DEC coordinate (deg)
double	l			#U Galactic longitude coordinate (deg)
double	b			#U Galactic latitude coordinate (deg)

double	x, y

begin
	if (!IS_INDEFD(ra) && !IS_INDEFD(dec) &&
	    IS_INDEFD(l) && IS_INDEFD(b)) {
	
	    x = DEGTORAD(ra*15D0)
	    y = DEGTORAD(dec)

	    call ast_coord (GORA, GODEC, GPRA, GPDEC, x, y, x, y)

	    if (x < 0.)
	        x = x + TWOPI

	    l = RADTODEG (x)
	    b = RADTODEG (y)

	} else if (IS_INDEFD(ra) && IS_INDEFD(dec) &&
	    !IS_INDEFD(l) && !IS_INDEFD(b)) {

	    x = DEGTORAD(l)
	    y = DEGTORAD(b)

	    call ast_coord (GOL, GOB, GPL, GPB, x, y, x, y)

	    if (x < 0.)
		x = x + TWOPI

	    ra = RADTODEG (x) / 15D0
	    dec = RADTODEG (y)
	}
end


define	EORA	0.0D0
define	EODEC	0.0D0
define	EPRA	-1.5707963267949D0
define	EPDEC	1.1617036990448D0
define	EOG	0.0D0
define	EOB	0.0D0
define	EPG	1.5707963267949D0
define	EPB	1.1617036990448D0

# CAT_EC -- Conversion between equitorial and galactic coordinates.
# The direction is set by input INDEF values.

procedure cat_ec (ra, dec, gamma, beta)

double	ra			#U RA coordinate (hr)
double	dec			#U DEC coordinate (deg)
double	gamma			#U Ecliptic longitude coordinate (deg)
double	beta			#U Ecliptic latitude coordinate (deg)

double	x, y

begin
	if (!IS_INDEFD(ra) && !IS_INDEFD(dec) &&
	    IS_INDEFD(gamma) && IS_INDEFD(beta)) {
	
	    x = DEGTORAD(ra*15D0)
	    y = DEGTORAD(dec)

	    call ast_coord (EORA, EODEC, EPRA, EPDEC, x, y, x, y)

	    if (x < 0.)
	        x = x + TWOPI

	    gamma = RADTODEG (x)
	    beta = RADTODEG (y)

	} else if (IS_INDEFD(ra) && IS_INDEFD(dec) &&
	    !IS_INDEFD(gamma) && !IS_INDEFD(beta)) {

	    x = DEGTORAD(gamma)
	    y = DEGTORAD(beta)

	    call ast_coord (EOG, EOB, EPG, EPB, x, y, x, y)

	    if (x < 0.)
		x = x + TWOPI

	    ra = RADTODEG (x) / 15D0
	    dec = RADTODEG (y)
	}
end


# AST_COORD -- Convert spherical coordinates to new system.
#
# This procedure converts the longitude-latitude coordinates (a1, b1)
# of a point on a sphere into corresponding coordinates (a2, b2) in a
# different coordinate system that is specified by the coordinates of its
# origin (ao, bo).  The range of a2 will be from -pi to pi.

procedure ast_coord (ao, bo, ap, bp, a1, b1, a2, b2)

double	ao, bo		# Origin of new coordinates (radians)
double	ap, bp		# Pole of new coordinates (radians)
double	a1, b1		# Coordinates to be converted (radians)
double	a2, b2		# Converted coordinates (radians)

double	sao, cao, sbo, cbo, sbp, cbp
double	x, y, z, xp, yp, zp, temp

begin
	x = cos (a1) * cos (b1)
	y = sin (a1) * cos (b1)
	z = sin (b1)
	xp = cos (ap) * cos (bp)
	yp = sin (ap) * cos (bp)
	zp = sin (bp)

	# Rotate the origin about z.
	sao = sin (ao)
	cao = cos (ao)
	sbo = sin (bo)
	cbo = cos (bo)
	temp = -xp * sao + yp * cao
	xp = xp * cao + yp * sao
	yp = temp
	temp = -x * sao + y * cao
	x = x * cao + y * sao
	y = temp

	# Rotate the origin about y.
	temp = -xp * sbo + zp * cbo
	xp = xp * cbo + zp * sbo
	zp = temp
	temp = -x * sbo + z * cbo
	x = x * cbo + z * sbo
	z = temp

	# Rotate pole around x.
	sbp = zp
	cbp = yp
	temp = y * cbp + z * sbp
	y = y * sbp - z * cbp
	z = temp

	# Final angular coordinates.
	a2 = atan2 (y, x)
	b2 = asin (z)
end
