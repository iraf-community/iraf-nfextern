include	<evvexpr.h>
include	<lexnum.h>
include	<time.h>
include	<mach.h>

define	KEYWORDS "|sexstr|epoch|julday|mst|precess|ra_precess|dec_precess|\
		  |airmass|eairmass|obsdb|arcsep|"

define	F_SEXSTR		1	# sexstr (value)
define	F_EPOCH			2	# epoch (date[, ut])
define	F_JULDAY		3	# julday (date[, ut])
define	F_MST			4	# mst (date[, ut], longitude)
define	F_PRECESS		5	# precess (ra, dec, epoch1, epoch2)
define	F_RAPRECESS		6	# ra_precess (ra, dec, epoch1, epoch2)
define	F_DECPRECESS		7	# dec_precess (ra, dec, epoch1, epoch2)
define	F_AIRMASS		9	# airmass (ra, dec, st, latitude)
define	F_EAIRMASS		10	# eairmass (ra, dec, st, exptime, lat)
define	F_OBSDB			11	# obsdb (observatory, parameter)
define	F_ARCSEP		12	# arcsep (ra1, dec1, ra2, dec2)

define  SOLTOSID        (($1)*1.00273790935d0)

# AST_FUNC -- Special astronomical functions.
# This is the same as in ASTUTIL except for removal of the I/O functions.

procedure ast_func (ast, func, args, nargs, out)

pointer	ast			#I client data
char	func[ARB]		#I function to be called
pointer	args[ARB]		#I pointer to arglist descriptor
int	nargs			#I number of arguments
pointer	out			#O output operand (function value)

int	yr, mo, day
double	time, epoch, ra, dec, longitude, latitude
double	ast_julday(), ast_mst(), airmass()

double	dresult
int	iresult, optype, oplen, opcode, v_nargs, i, ip, flags
pointer	sp, buf, dval, obs

bool	strne()
pointer	obsopen()
double	ast_arcsep()
int	strdic(), ctod(), btoi(), dtm_decode()
errchk	malloc, obsopen, obsgstr

begin
	call smark (sp)
	call salloc (buf, SZ_LINE, TY_CHAR)
	call salloc (dval, nargs, TY_DOUBLE)

	# Lookup the function name in the dictionary.  An exact match is
	# required (strdic permits abbreviations).  Abort if the function
	# is not known.

	opcode = strdic (func, Memc[buf], SZ_LINE, KEYWORDS)
	if (opcode == 0 || strne (func, Memc[buf]))
	    call xvv_error1 ("unknown function `%s' called", func)

	# Verify correct number of arguments.
	switch (opcode) {
	case F_SEXSTR:
	    v_nargs = -1
	case F_EPOCH, F_JULDAY:
	    v_nargs = -1
	case F_MST:
	    v_nargs = -2
	case F_PRECESS, F_RAPRECESS, F_DECPRECESS:
	    v_nargs = 4
	case F_AIRMASS:
	    v_nargs = 4
	case F_EAIRMASS:
	    v_nargs = 5
	case F_OBSDB:
	    v_nargs = 2
	case F_ARCSEP:
	    v_nargs = 4
	default:
	    v_nargs = 1
	}

	if (v_nargs > 0 && nargs != v_nargs)
	    call xvv_error2 ("function `%s' requires %d arguments",
		func, v_nargs)
	else if (v_nargs < 0 && nargs < abs(v_nargs))
	    call xvv_error2 ("function `%s' requires at least %d arguments",
		func, abs(v_nargs))

	# Convert datatypes to double.
	do i = 1, nargs {
	    switch (O_TYPE(args[i])) {
	    case TY_CHAR:
		ip = 1
		if (ctod (O_VALC(args[i]), ip, Memd[dval+i-1]) == 0)
		    Memd[dval+i-1] = 0.
	    case TY_INT:
		Memd[dval+i-1] = O_VALI(args[i])
	    case TY_REAL:
		Memd[dval+i-1] = O_VALR(args[i])
	    case TY_DOUBLE:
		Memd[dval+i-1] = O_VALD(args[i])
	    }
	}


	# Expand date and time.
	switch (opcode) {
	case F_EPOCH, F_JULDAY, F_MST:
	    if (dtm_decode (O_VALC(args[1]), yr, mo, day, time, flags) == ERR)
		call xvv_error ("unrecognized date format")
	    switch (opcode) {
	    case F_EPOCH, F_JULDAY:
		if (nargs > 1)
		    time = Memd[dval+1]
	    case F_MST:
		if (nargs > 2)
		    time = Memd[dval+1]
	    }
	    if (IS_INDEFD(time))
		time = 0.
	    call ast_date_to_epoch (yr, mo, day, time, epoch)
	}

	# Evaluate the function.
	oplen = 0
	optype = TY_DOUBLE
	switch (opcode) {
	case F_SEXSTR:
	    optype = TY_CHAR
	    oplen = MAX_DIGITS
	    call malloc (iresult, oplen, TY_CHAR)
	    call sprintf (Memc[iresult], oplen, "%.*h")
		if (nargs > 1)
		    call pargi (max (0, nint (Memd[dval+1])))
		else
		    call pargi (0)
		call pargd (Memd[dval]+1E-7)
	    
	case F_EPOCH:
	    dresult = epoch

	case F_JULDAY:
	    dresult = ast_julday (epoch)

	case F_MST:
	    longitude = Memd[dval+nargs-1]
	    dresult = ast_mst (epoch, longitude)

	case F_PRECESS:
	    call ast_precess (Memd[dval], Memd[dval+1], Memd[dval+2],
		ra, dec, Memd[dval+3])

	    optype = TY_CHAR
	    oplen = SZ_LINE
	    call malloc (iresult, oplen, TY_CHAR)
	    call sprintf (Memc[iresult], oplen, "%11.2h %11.1h %7g")
		call pargd (ra)
		call pargd (dec)
		call pargd (Memd[dval+3])

	case F_RAPRECESS:
	    call ast_precess (Memd[dval], Memd[dval+1], Memd[dval+2],
		ra, dec, Memd[dval+3])
	    dresult = ra

	case F_DECPRECESS:
	    call ast_precess (Memd[dval], Memd[dval+1], Memd[dval+2],
		ra, dec, Memd[dval+3])
	    dresult = dec

	case F_AIRMASS:
	    ra = Memd[dval]
	    dec = Memd[dval+1]
	    time = Memd[dval+2]
	    latitude = Memd[dval+3]
	    dresult = airmass (time-ra, dec, latitude)

	case F_EAIRMASS:
	    ra = Memd[dval]
	    dec = Memd[dval+1]
	    time = Memd[dval+2]
	    Memd[dval+3] = Memd[dval+3] / 3600.
	    latitude = Memd[dval+4]
	    dresult = airmass (time-ra, dec, latitude)
	    time = time + SOLTOSID(Memd[dval+3]) / 2.
	    dresult = dresult + 4 * airmass (time-ra, dec, latitude)
	    time = time + SOLTOSID(Memd[dval+3]) / 2.
	    dresult = dresult + airmass (time-ra, dec, latitude)
	    dresult = dresult / 6.

	case F_OBSDB:
	    optype = TY_CHAR
	    oplen = SZ_LINE
	    call malloc (iresult, oplen, TY_CHAR)
	    obs = obsopen (O_VALC(args[1]))
	    call obsgstr (obs, O_VALC(args[2]), Memc[iresult], oplen)
	    call obsclose (obs)

	case F_ARCSEP:
	    dresult = ast_arcsep (Memd[dval], Memd[dval+1], Memd[dval+2],
		Memd[dval+3])

	default:
	    call xvv_error ("bad switch in user function")
	}

	# Format sexigesimal strings.
	switch (opcode) {
	case F_MST, F_RAPRECESS, F_DECPRECESS:
	    optype = TY_CHAR
	    oplen = MAX_DIGITS
	    call malloc (iresult, oplen, TY_CHAR)
	    call sprintf (Memc[iresult], oplen, "%.2h")
		call pargd (dresult)
	}

	# Write the result to the output operand.  Bool results are stored in
	# iresult as an integer value, string results are stored in iresult as
	# a pointer to the output string, and integer and real/double results
	# are stored in iresult and dresult without any tricks.

	call xvv_initop (out, oplen, optype)
	switch (optype) {
	case TY_BOOL:
	    O_VALI(out) = btoi (iresult != 0)
	case TY_CHAR:
	    O_VALP(out) = iresult
	case TY_INT:
	    O_VALI(out) = iresult
	case TY_REAL:
	    O_VALR(out) = dresult
	case TY_DOUBLE:
	    O_VALD(out) = dresult
	}

	# Free any storage used by the argument list operands.
	do i = 1, nargs
	    call xvv_freeop (args[i])

	call sfree (sp)
	return
end


include	<math.h>



# AIRMASS -- Compute airmass from DEC, LATITUDE and HA

# Airmass formulation from Allen "Astrophysical Quantities" 1973 p.125,133.
# and John Ball's book on Algorithms for the HP-45

double procedure airmass (ha, dec, lat)

double  ha, dec, lat, cos_zd, x

define  SCALE   750.0d0                 # Atmospheric scale height

begin
        if (IS_INDEFD (ha) || IS_INDEFD (dec) || IS_INDEFD (lat))
            call error (1, "Can't determine airmass")

        cos_zd = sin(DEGTORAD(lat)) * sin(DEGTORAD(dec)) +
                 cos(DEGTORAD(lat)) * cos(DEGTORAD(dec)) * cos(DEGTORAD(ha*15.))

        x  = SCALE * cos_zd

        return (sqrt (x**2 + 2*SCALE + 1) - x)
end
