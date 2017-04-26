define	MOM_N	Memi[$1]		# Pointer to number array
define	MOM_I	Memi[$1+1]		# Pointer to intensity profile array
define	MOM_X	Memi[$1+2]		# Pointer to x centroid sums
define	MOM_Y	Memi[$1+3]		# Pointer to y centroid sums

define	MOM_XC	Memr[P2R($1)]		# X aperture center
define	MOM_YC	Memr[P2R($1)]		# Y aperture center


# MOM_GOPEN -- Global open for moment measurements.

procedure mom_gopen ()

begin
	# Allocate memory.
	call calloc (gmom, , TY_STRUCT)
end


# MOM_GCLOSE -- Global close for moment measurements.

procedure mom_gclose ()


# MOM_OPEN -- Open new object.

procedure mom_open ()

begin
end


# MOM_ACCUM -- Accumulate data for moment measurement.

procedure mom_accum (gmom, mom, obj, c, l, v)

pointer	gmom			#I GMOM structure
pointer	mom			#I MOM structure
pointer	obj			#O Object structure
int	c, l			#I Pixel coordinate
real	v			#I Sky subtracted flux value

begin
	xc = c - MOM_XC(mom)
	yc = l - MOM_YC(mom)
	x2 = xc * xc
	y2 = yc * yc
	r = sqrt (x2 + y2)
	rbin = min (r/MOM_RBIN, MOM_RMAX(mom))
	
end


# MOM_CLOSE -- Close object.

procedure mom_close ()

begin
end
