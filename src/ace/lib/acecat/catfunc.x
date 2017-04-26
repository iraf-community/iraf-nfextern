include	<math.h>
include	<ctype.h>
include	<evvexpr.h>
include	<acecat.h>
include	<acecat1.h>


define	FUNCS	"|FT|FI|FR|FD|MAG|DMAG|PX|PY|WX|WY|RA|DEC|\
		|WRA|WDEC|WXD|WYD|RAD|DECD|XI|ETA|RAS|DECS|GPA|\
		|ELON|ELAT|RAE|DECE|GLON|GLAT|RAG|DECG|"

define	F_FT			1	# FT(arg)
define	F_FI			2	# FI(arg)
define	F_FR			3	# FR(arg)
define	F_FD			4	# FD(arg)
define	F_MAG			5	# MAG(flux)
define	F_DMAG			6	# DMAG(flux1,flux2)
define	F_PX			7	# PX(x,y)
define	F_PY			8	# PY(x,y)
define	F_WX			9	# WX(x,y)
define	F_WY			10	# WY(x,y)
define	F_RA			11	# RA(x,y)
define	F_DEC			12	# DEC(x,y)
define	F_WRA			14	# WRA(x,y)
define	F_WDEC			15	# WDEC(x,y)
define	F_WXD			16	# WXD(x,y)
define	F_WYD			17	# WYD(x,y)
define	F_RAD			18	# RAD(x,y)
define	F_DECD			19	# DECD(x,y)
define	F_XI			20	# XI(ra,dec,ratan,dectan)
define	F_ETA			21	# ETA(ra,dec,ratan,dectan)
define	F_RAS			22	# RAS(xi,eta,ratan,dectan)
define	F_DECS			23	# DECS(xi,eta,ratan,dectan)
define	F_GPA			24	# GPA(x,y,pa,ratan,dectan)
define	F_ELON			26	# ELON(ra,dec)
define	F_ELAT			27	# ELAT(ra,dec)
define	F_RAE			28	# RAE(long,lat)
define	F_DECE			29	# DECE(long,lat)
define	F_GLON			30	# GLON(ra,dec)
define	F_GLAT			31	# GLAT(ra,dec)
define	F_RAG			32	# RAG(l,b)
define	F_DECG			33	# DECG(l,b)

# CATFUNC -- Catalog functions.

procedure catfunc (cat, func, args, nargs, out)

pointer	cat			#I client data
char	func[ARB]		#I function to be called
pointer	args[ARB]		#I pointer to arglist descriptor
int	nargs			#I number of arguments
pointer	out			#O output operand (function value)

int	i, ip, iresult, optype, oplen, opcode, v_nargs
double	x, y, ra, dec, xi, eta, dresult
pointer	dval

int	btoi(), ctod()
errchk	xvv_error, xvv_error1, xvv_error2, malloc

begin
	# Determine the function and type. 
	call catfuncs (func, CAT_STR(cat), opcode, optype,
	    CAT_STR(cat), CAT_STR(cat))
	if (opcode == 0)
	    call xvv_error1 ("unknown function `%s' called", func)

	# Verify correct number of arguments.
	switch (opcode) {
	case F_DMAG:
	    v_nargs = 2
	case F_PX, F_PY:
	    v_nargs = 2
	case F_WX, F_WY, F_WRA, F_WDEC:
	    v_nargs = 2
	case F_WXD, F_WYD, F_RAD, F_DECD, F_RA, F_DEC:
	    v_nargs = 2
	case F_XI, F_ETA, F_RAS, F_DECS:
	    v_nargs = 4
	case F_GPA:
	    v_nargs = 5
	case F_ELON, F_ELAT, F_RAE, F_DECE:
	    v_nargs = 2
	case F_GLON, F_GLAT, F_RAG, F_DECG:
	    v_nargs = 2
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
	call malloc (dval, nargs, TY_DOUBLE)
	do i = 1, nargs {
	    switch (O_TYPE(args[i])) {
	    case TY_CHAR:
		ip = 1
		if (ctod (O_VALC(args[i]), ip, Memd[dval+i-1]) == 0)
		    Memd[dval+i-1] = INDEFD
	    case TY_INT:
		if (IS_INDEFI(O_VALI(args[i])))
		    Memd[dval+i-1] = INDEFD
		else
		    Memd[dval+i-1] = O_VALI(args[i])
	    case TY_REAL:
		if (IS_INDEFR(O_VALR(args[i])))
		    Memd[dval+i-1] = INDEFD
		else
		    Memd[dval+i-1] = O_VALR(args[i])
	    case TY_DOUBLE:
		Memd[dval+i-1] = O_VALD(args[i])
	    default:
		Memd[dval+i-1] = INDEFD
	    }
	}

	# Evaluate the function.
	oplen = 0
	switch (opcode) {
	case F_FT:
	    oplen = SZ_LINE
	    call malloc (iresult, oplen, TY_CHAR)
	    switch (O_TYPE(args[1])) {
	    case TY_CHAR:
	        call strcpy (O_VALC(args[1]), Memc[iresult], oplen)
	    case TY_BOOL:
	        call sprintf (Memc[iresult], oplen, "%b")
		    call pargi (O_VALI(args[1]))
	    case TY_INT:
	        call sprintf (Memc[iresult], oplen, "%d")
		    call pargi (O_VALI(args[1]))
	    case TY_REAL:
	        call sprintf (Memc[iresult], oplen, "%g")
		    call pargr (O_VALR(args[1]))
	    case TY_DOUBLE:
	        call sprintf (Memc[iresult], oplen, "%g")
		    call pargd (O_VALD(args[1]))
	    }
	case F_FI:
	    iresult = Memd[dval]
	case F_FR, F_FD:
	    dresult = Memd[dval]
	case F_MAG:
	    if (Memd[dval] > 0 && !IS_INDEFD(Memd[dval]))
		dresult = -2.5 * log10 (Memd[dval]) + CAT_MAGZERO(cat)
	    else
	        dresult = INDEFD
	case F_DMAG:
	    if (Memd[dval] > 0 && !IS_INDEFD(Memd[dval]) &&
	        Memd[dval+1] > 0 && !IS_INDEFD(Memd[dval+1]))
		dresult = -2.5 * (log10 (Memd[dval]) - log10 (Memd[dval+1]))
	    else
	        dresult = INDEFD
	case F_PX:
	    call cat_lp (cat, Memd[dval], Memd[dval+1], dresult, y)
	case F_PY:
	    call cat_lp (cat, Memd[dval], Memd[dval+1], x, dresult)
	case F_WX, F_WXD:
	    call cat_lw (cat, Memd[dval], Memd[dval+1], dresult, y, ra, dec)
	case F_WY, F_WYD:
	    call cat_lw (cat, Memd[dval], Memd[dval+1], x, dresult, ra, dec)
	case F_RA, F_WRA, F_RAD:
	    call cat_lw (cat, Memd[dval], Memd[dval+1], x, y, dresult, dec)
	    if (!IS_INDEFD(dresult))
		dresult = dresult / 15D0
	case F_DEC, F_WDEC, F_DECD:
	    call cat_lw (cat, Memd[dval], Memd[dval+1], x, y, ra, dresult)
	case F_XI:
	    xi = INDEFD; eta = INDEFD
	    call cat_std (Memd[dval], Memd[dval+1], xi, eta,
	        Memd[dval+2], Memd[dval+3])
	    dresult = xi
	case F_ETA:
	    xi = INDEFD; eta = INDEFD
	    call cat_std (Memd[dval], Memd[dval+1], xi, eta,
	        Memd[dval+2], Memd[dval+3])
	    dresult = eta 
	case F_RAS:
	    ra = INDEFD; dec = INDEFD
	    call cat_std (ra, dec, Memd[dval], Memd[dval+1],
	        Memd[dval+2], Memd[dval+3])
	    dresult = ra 
	case F_DECS:
	    ra = INDEFD; dec = INDEFD
	    call cat_std (ra, dec, Memd[dval], Memd[dval+1],
	        Memd[dval+2], Memd[dval+3])
	    dresult = dec 
	case F_GPA:
	    x = Memd[dval] + cos (DEGTORAD(Memd[dval+2]))
	    y = Memd[dval+1] + sin (DEGTORAD(Memd[dval+2]))
	    call cat_lw (cat, Memd[dval], Memd[dval+1], x, y, ra, dec)
	    if (!IS_INDEFD(ra))
		ra = ra / 15D0
	    xi = INDEFD; eta = INDEFD
	    call cat_std (ra, dec, xi, eta, Memd[dval+3], Memd[dval+4])
	    x = Memd[dval] + cos (DEGTORAD(Memd[dval+2]+180D0))
	    y = Memd[dval+1] + sin (DEGTORAD(Memd[dval+2]+180D0))
	    call cat_lw (cat, Memd[dval], Memd[dval+1], x, y, ra, dec)
	    if (!IS_INDEFD(ra))
		ra = ra / 15D0
	    x = INDEFD; y = INDEFD
	    call cat_std (ra, dec, x, y, Memd[dval+3], Memd[dval+4])
	    dresult = RADTODEG (atan2 (eta-y, xi-x))
	case F_ELON:
	    x = INDEFD; y = INDEFD
	    call cat_ec (Memd[dval], Memd[dval+1], x, y)
	    dresult = x
	case F_ELAT:
	    x = INDEFD; y = INDEFD
	    call cat_ec (Memd[dval], Memd[dval+1], x, y)
	    dresult = y 
	case F_RAE:
	    ra = INDEFD; dec = INDEFD
	    call cat_ec (ra, dec, Memd[dval], Memd[dval+1])
	    dresult = ra 
	case F_DECE:
	    ra = INDEFD; dec = INDEFD
	    call cat_ec (ra, dec, Memd[dval], Memd[dval+1])
	    dresult = dec 
	case F_GLON:
	    x = INDEFD; y = INDEFD
	    call cat_gal(Memd[dval], Memd[dval+1], x, y)
	    dresult = x
	case F_GLAT:
	    x = INDEFD; y = INDEFD
	    call cat_gal(Memd[dval], Memd[dval+1], x, y)
	    dresult = y 
	case F_RAG:
	    ra = INDEFD; dec = INDEFD
	    call cat_gal(ra, dec, Memd[dval], Memd[dval+1])
	    dresult = ra 
	case F_DECG:
	    ra = INDEFD; dec = INDEFD
	    call cat_gal(ra, dec, Memd[dval], Memd[dval+1])
	    dresult = dec 
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
	    if (IS_INDEFD(dresult))
		O_VALR(out) = INDEFR
	    else
		O_VALR(out) = dresult
	case TY_DOUBLE:
	    O_VALD(out) = dresult
	}

	# Free any storage used by the argument list operands.
	do i = 1, nargs
	    call xvv_freeop (args[i])
	call mfree (dval, TY_DOUBLE)

	# Trigger error on INDEF.
	switch (optype) {
	case TY_INT:
	    if (IS_INDEFI(O_VALI(out)))
	        call xvv_error ("INDEF")
	case TY_REAL:
	    if (IS_INDEFR(O_VALR(out)))
	        call xvv_error ("INDEF")
	case TY_DOUBLE:
	    if (IS_INDEFD(O_VALD(out)))
	        call xvv_error ("INDEF")
	}
end


# CATFUNCS -- Parse the input expression and set function parameters.
#
# This encapsulates the set of functions.  It is also called externally.

procedure catfuncs (expr, func, code, datatype, units, format)

char	expr[ARB]		#I Input expression
char	func[ARB]		#O Function string
int	code			#O Function code
int	datatype		#O Function datatype
char	units[ARB]		#O Function units
char	format[ARB]		#O Function format

int	i

int	stridxs(), strdic()

begin
	# Initialize return
	code = 0
	datatype = 0
	units[1] = EOS
	format[1] = EOS

	# Parse the expression and set the function string.
	# Return if the function is not recognized.
	call strcpy (expr, func, ARB)
	i = stridxs ("(", func)
	if (i > 0)
	    func[i] = EOS
	#call strupr (func)
	code = strdic (func, func, ARB, FUNCS)
	if (code == 0)
	    return

	# Set function parameters.
	switch (code) {
	case F_FT:
	    datatype = TY_CHAR
	case F_FI:
	    datatype = TY_INT
	case F_FR:
	    datatype = TY_REAL
	case F_FD:
	    datatype = TY_DOUBLE
	case F_PX, F_PY:
	    datatype = TY_DOUBLE
	    call strcpy ("pixel", units, ARB)
	    call strcpy ("%9.2f", format, ARB)
	case F_WX, F_WY, F_WRA, F_WDEC:
	    datatype = TY_DOUBLE
	    call strcpy ("deg", units, ARB)
	case F_WXD, F_WYD, F_DEC, F_RAD, F_DECD, F_DECS, F_DECE, F_DECG:
	    datatype = TY_DOUBLE
	    call strcpy ("deg", units, ARB)
	    call strcpy ("%13.2h", format, ARB)
	case F_RA, F_RAS, F_RAE, F_RAG:
	    datatype = TY_DOUBLE
	    call strcpy ("hr", units, ARB)
	    call strcpy ("%13.3h", format, ARB)
	case F_MAG:
	    datatype = TY_DOUBLE
	    call strcpy ("mag", units, ARB)
	    call strcpy ("%8.3f", format, ARB)
	case F_DMAG:
	    datatype = TY_DOUBLE
	    call strcpy ("mag", units, ARB)
	    call strcpy ("%8.3f", format, ARB)
	case F_XI, F_ETA:
	    datatype = TY_DOUBLE
	    call strcpy ("arcsec", units, ARB)
	    call strcpy ("%8.2f", format, ARB)
	case F_GPA:
	    datatype = TY_DOUBLE
	    call strcpy ("deg", units, ARB)
	    call strcpy ("%6.1f", format, ARB)
	case F_ELON, F_ELAT:
	    datatype = TY_DOUBLE
	    call strcpy ("deg", units, ARB)
	    call strcpy ("%13.2h", format, ARB)
	case F_GLON, F_GLAT:
	    datatype = TY_DOUBLE
	    call strcpy ("deg", units, ARB)
	    call strcpy ("%13.2h", format, ARB)
	}
end


# CATOP -- Get operand for expressions.
#
# Operand names that being with '$' are catalog header keywords.
# The keyword is sought first in the output catalog header and then
# in the input catalog header.
#
# Any other operand name is a record field name.
#
# Missing values are set to INDEFR followed by an error return.
# Any INDEF value causes and error return.
# Error returns may be by the caller.

procedure catop (rec, name, o)

pointer	rec			#I Record structure
char	name[ARB]		#I Field name
pointer	o			#O Pointer to output operand

int	id, itype, otype
pointer	im, stp, ufunc, optr, sym

int	imgeti(), imgftype(), btoi()
bool	imgetb(), imaccf(), streq()
real	imgetr()
double	imgetd()
pointer	stfind(), sthead(), stnext()
errchk	xvv_error1

pointer	cat
common	/catexprcom/ cat

begin
	# Get keyword value.  Note that currently this only works for
	# keywords from the first image in a multicat.
	if (name[1] == '$') {
	    im =  NULL
	    if (cat != NULL) {
	        if (CAT_OHDR(cat) != NULL) {
		    if (imaccf(CAT_OHDR(cat), name[2]))
		        im = CAT_OHDR(cat)
		} else if (CAT_IHDR(cat) != NULL) {
		    if (imaccf(CAT_IHDR(cat), name[2]))
		        im = CAT_IHDR(cat)
		}
	    }
	    if (im == NULL) {
		call xvv_initop (o, 0, TY_REAL)
		O_VALR(o) = INDEFR
		call xvv_error1 ("Keyword `%s' not found", name[2])
	    }
	    otype = imgftype (im, name[2])
	    switch (otype) {
	    case TY_BOOL:
		call xvv_initop (o, 0, TY_BOOL)
		O_VALI(o) = btoi (imgetb (im, name[2]))
		if (IS_INDEFI(O_VALI(o)))
		    call xvv_error1 ("INDEF (%s)", name)
	    case TY_INT, TY_LONG:
		call xvv_initop (o, 0, TY_INT)
		O_VALI(o) = imgeti (im, name[2])
		if (IS_INDEFI(O_VALI(o)))
		    call xvv_error1 ("INDEF (%s)", name)
	    case TY_REAL:
		call xvv_initop (o, 0, TY_REAL)
		O_VALR(o) = imgetr (im, name[2])
		if (IS_INDEFR(O_VALR(o)))
		    call xvv_error1 ("INDEF (%s)", name)
	    case TY_DOUBLE:
		call xvv_initop (o, 0, TY_DOUBLE)
		O_VALD(o) = imgetd (im, name[2])
		if (IS_INDEFD(O_VALD(o)))
		    call xvv_error1 ("INDEF (%s)", name)
	    default:
		call xvv_initop (o, 68, TY_CHAR)
	        call imgstr (im, name[2], O_VALC(o), 68)
	    }
	    return
	}

	# Get record value.
	id = -1
	if (cat != NULL) {
	    ufunc = CAT_UFUNC(cat)
	    stp = CAT_STP(cat)
	    if (stp != NULL) {
		call strcpy (name, CAT_STR(cat), CAT_SZSTR)
		#call strupr (CAT_STR(cat))
		sym = stfind (stp, CAT_STR(cat))
		if (sym != NULL) {
		    if (!streq (CAT_STR(cat), ENTRY_NAME(sym)))
		        sym = NULL
		}
		if (sym == NULL) {
		    for (sym=sthead(stp); sym!=NULL; sym=stnext(stp,sym)) {
			if (streq (CAT_STR(cat), ENTRY_NAME(sym)))
			    break
		    }
		}
		if (sym != NULL) {
		    id = ENTRY_ID(sym)
		    itype = ENTRY_TYPE(sym)
		}
	    }
	}

	if (id == -1) {
	    call xvv_initop (o, 0, TY_REAL)
	    O_VALR(o) = INDEFR
	    call xvv_error1 ("Field `%s' not found", name)
	}

	if (ufunc != NULL) {
	    optr = CAT_BUF(cat)
	    call zcall6 (ufunc, cat, rec, id, itype, optr, otype)
	} else {
	    otype = itype
	    optr = rec+id
	}

	switch (otype) {
	case TY_INT:
	    call xvv_initop (o, 0, TY_INT)
	    O_VALI(o) = RECI(optr,0)
	    if (IS_INDEFI(O_VALI(o)))
	        call xvv_error1 ("INDEF (%s)", name)
	case TY_REAL:
	    call xvv_initop (o, 0, TY_REAL)
	    O_VALR(o) = RECR(optr,0)
	    if (IS_INDEFR(O_VALR(o)))
	        call xvv_error1 ("INDEF (%s)", name)
	case TY_DOUBLE:
	    call xvv_initop (o, 0, TY_DOUBLE)
	    O_VALD(o) = RECD(optr,0)
	    if (IS_INDEFD(O_VALD(o)))
	        call xvv_error1 ("INDEF (%s)", name)
	default:
	    call xvv_initop (o, -otype, TY_CHAR)
	    call strcpy (RECT(optr,0), O_VALC(o), -otype)
	}
end
