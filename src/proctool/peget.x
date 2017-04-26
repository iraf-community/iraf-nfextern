include	<ctype.h>
include	<lexnum.h>
include	<evvexpr.h>
include	<imhdr.h>
include	"par.h"
include	"prc.h"
include	"ost.h"
include	"pi.h"


# PE_GETOP -- Get operand.

procedure pe_getop (prc, operand, o)

pointer	prc				#I Processing object
char	operand[ARB]			#I Operand name
pointer	o				#I Operand object

char	key[SZ_FNAME]
int	ip, type, nchars
pointer	sym, ost, op, im, cp, pi

bool	streq()
int	stridxs(), lexnum(), ctoi(), ctod(), nowhite()
int	imaccf(), imgeti(), imgftype()
double	imgetd()
pointer	pe_getim(), stfind(), stenter()
errchk	prc_error, pe_getim, zcall3, stenter

begin
	ip = stridxs (".", operand)
	if (operand[1] == '$') {
	    # Image vector.
	    op = pe_getim (prc, operand)
	    call amovi (Memi[op], Memi[o], LEN_OPERAND)
	} else if (ip > 2) {
	    # Parameter.
	    sym = stfind (PAR_OPERAND(PRC_PAR(prc)), operand)
	    if (sym == NULL) {
		call clgstr (operand, key, SZ_FNAME)
		ip = 1
		type = lexnum (key, ip, nchars)
		if (key[nchars+ip] != EOS)
		    type = LEX_NONNUM

		switch (type) {
		case LEX_OCTAL, LEX_DECIMAL, LEX_HEX:
		    sym = stenter (PAR_OPERAND(PRC_PAR(prc)), operand, 2)
		    Memi[sym] = TY_INT
		    ip = 1; nchars = ctoi (key, ip, Memi[sym+1])
		case LEX_REAL:
		    sym = stenter (PAR_OPERAND(PRC_PAR(prc)), operand, 4)
		    Memi[sym] = TY_DOUBLE
		    ip = 1; nchars = ctod (key, ip, Memd[P2D(sym+2)])
		case LEX_NONNUM:
		    sym = stenter (PAR_OPERAND(PRC_PAR(prc)), operand, 201)
		    Memi[sym] = TY_CHAR
		    #call strcpy (key, Memc[P2C(sym+1)], 199)
		    if (nowhite (key, Memc[P2C(sym+1)], 199) == 0)
		        ;
		}
	    }
	    type = Memi[sym]
	    switch (type) {
	    case TY_INT:
		call xvv_initop (o, 0, TY_INT)
		O_VALI(o) = Memi[sym+1]
	    case TY_DOUBLE:
		call xvv_initop (o, 0, TY_DOUBLE)
		O_VALD(o) = Memd[P2D(sym+2)]
	    case TY_CHAR:
		call xvv_initop (o, 199, TY_CHAR)
		call strcpy (Memc[P2C(sym+1)], O_VALC(o), 199)
	    }
	} else if (streq (operand, "gmean")) {
	    call xvv_initop (o, 0, TY_DOUBLE)
	    O_VALD(o) = PRC_GMEAN(prc)
	} else {
	    # Keyword.
	    call strcpy (operand, key, SZ_FNAME)
	    if (operand[2] == '.') {
	        key[2] = EOS
		call strupr (key)
		pi = NULL
		ost = stfind (PAR_OST(PRC_PAR(prc)), key)
		if (ost != NULL) {
		    pi = OST_PI(ost)
		    if (pi == NULL) {
			if (OST_OPEN(ost) != NULL) {
			    call zcall3 (OST_OPEN(ost), prc, ost,
			        PRC_PIKEY(prc))
			    pi = OST_PI(ost)
			}
		    }
		}
		call strcpy (key[3], key, SZ_FNAME)
	    } else if (operand[2] == '_') {
		key[2] = EOS
		call strupr (key)
	        switch (operand[1]) {
		case 'A':
		    pi = PRC_PIAKEY(prc)
		case 'B':
		    pi = PRC_PIBKEY(prc)
		default:
		    pi = NULL
		}
		call strcpy (key[3], key, SZ_FNAME)
	    } else
	        pi = PRC_PIKEY(prc)

	    if (pi == NULL)
		call prc_error (prc, PRCERR_IMREFNF,
		    "image reference `%s' not found", operand, "")
	    if (PI_MAPPED(pi) == NO)
	       iferr (call pi_map (pi))
		    call prc_error (prc, PRCERR_IMREFNF,
			"image reference `%s' not found", operand, "")

	    im = PI_IM(pi)

	    # Check for image index.
	    if (streq (key, "I")) {
	        call xvv_initop (o, IM_LEN(im,1), TY_INT)
		do ip = 1, O_LEN(o)
		    Memi[O_VALP(o)+ip-1] = ip
		return
	    } else if (streq (key, "J")) {
	        call xvv_initop (o, IM_LEN(im,1), TY_INT)
		call amovki (PRC_LINE(prc), Memi[O_VALP(o)], IM_LEN(im,1))
		return
	    }

	    sym = stfind (PAR_OPERAND(PRC_PAR(prc)), operand)
	    if (sym == NULL || PRC_LINE(prc) == 1) {
		call strupr (key)
		if (imaccf (im, key) == NO) {
		    if (sym == NULL)
			sym = stenter (PAR_OPERAND(PRC_PAR(prc)),
			    operand, 201)
		    Memi[sym] = TY_CHAR
		    Memc[P2C(sym+1)] = EOS
		    call xvv_initop (o, 199, TY_CHAR)
		    call strcpy (Memc[P2C(sym+1)], O_VALC(o), 199)
		    return
		}

		switch (imgftype (im, key)) {
		case TY_BOOL, TY_SHORT, TY_INT, TY_LONG:
		    if (sym == NULL)
			sym = stenter (PAR_OPERAND(PRC_PAR(prc)), operand, 2)
		    Memi[sym] = TY_INT
		    Memi[sym+1] = imgeti (im, key)

		case TY_REAL, TY_DOUBLE, TY_COMPLEX:
		    if (sym == NULL)
			sym = stenter (PAR_OPERAND(PRC_PAR(prc)), operand, 4)
		    Memi[sym] = TY_DOUBLE
		    Memd[P2D(sym+2)] = imgetd (im, key)
		default:
		    call malloc (cp, SZ_LINE, TY_CHAR)
		    call imgstr (im, key, Memc[cp], SZ_LINE)

		    ip = 1
		    type = lexnum (Memc[cp], ip, nchars)
		    if (Memc[cp+nchars+ip-1] != EOS)
			type = LEX_NONNUM

		    switch (type) {
		    case LEX_OCTAL, LEX_DECIMAL, LEX_HEX:
			if (sym == NULL)
			    sym = stenter (PAR_OPERAND(PRC_PAR(prc)),
			        operand, 2)
			Memi[sym] = TY_INT
			ip = 1; nchars = ctoi (Memc[cp], ip, Memi[sym+1])
		    case LEX_REAL:
			if (sym == NULL)
			    sym = stenter (PAR_OPERAND(PRC_PAR(prc)),
			        operand, 4)
			Memi[sym] = TY_DOUBLE
			ip = 1
			nchars = ctod (Memc[cp], ip, Memd[P2D(sym+2)])
		    case LEX_NONNUM:
			if (sym == NULL)
			    sym = stenter (PAR_OPERAND(PRC_PAR(prc)),
			        operand, 201)
			Memi[sym] = TY_CHAR
			#call strcpy (Memc[cp], Memc[P2C(sym+1)], 199)
			if (nowhite (Memc[cp], Memc[P2C(sym+1)], 199) == 0)
			    ;
		    }

		    call mfree (cp, TY_CHAR)
		}
	    }
	    type = Memi[sym]
	    switch (type) {
	    case TY_INT:
		call xvv_initop (o, 0, TY_INT)
		O_VALI(o) = Memi[sym+1]
	    case TY_DOUBLE:
		call xvv_initop (o, 0, TY_DOUBLE)
		O_VALD(o) = Memd[P2D(sym+2)]
	    case TY_CHAR:
		call xvv_initop (o, 199, TY_CHAR)
		call strcpy (Memc[P2C(sym+1)], O_VALC(o), 199)
	    }
	}
end


# PE_GETIM -- Get image data.

pointer procedure pe_getim (prc, operand)

pointer	prc				#I Processing pointer
char	operand[ARB]			#I Image operand request

int	i, line
pointer	ost, pi

pointer	stfind()
errchk	zcall2, prc_error

begin
	ost = stfind (PAR_OST(PRC_PAR(prc)), operand[2])
	if (ost == NULL)
	    call prc_error (prc, PRCERR_IMREFUK,
	        "unknown image reference `%s'", operand, "")
	pi = OST_PI(ost)
	if (pi == NULL)
	    call error (1, operand)
	if ((PI_IPI(pi) != NULL && PI_IPI(pi) != PRC_PI(prc)) ||
	    (pi == PI_IPI(pi) && OST_PRCTYPE(ost) != PRC_INPUT))
	    call error (1, operand)

	line = PRC_LINE(prc)
	if (PI_LINE(pi) != line) {
	    if (PI_MAPPED(pi) == NO) {
	       iferr (call pi_map (pi))
		    call prc_error (prc, PRCERR_IMREFNF,
			"image reference `%s' not found", operand, "")
	    }
	    if (PI_OP(pi) == NULL) {
		call malloc (PI_OP(pi), LEN_OPERAND, TY_STRUCT)
		switch (PI_PRCTYPE(pi)) {
		case PRC_BPM, PRC_OBM, PRC_MASK:
		    O_TYPE(PI_OP(pi)) = TY_SHORT
		default:
		    O_TYPE(PI_OP(pi)) = TY_REAL
		}
		O_FLAGS(PI_OP(pi)) = 0
		if (PI_LEN(pi,1) == 1)
		    O_LEN(PI_OP(pi)) = 0
		else
		    O_LEN(PI_OP(pi)) = PI_LEN(pi,1)
	    }
	    call zcall2 (PI_GLINE(pi), pi, line)
	    if (O_LEN(PI_OP(pi)) == 0) {
		if (O_TYPE(PI_OP(pi)) == TY_SHORT)
		    O_VALS(PI_OP(pi)) = Mems[PI_DATA(pi)]
		else
		    O_VALR(PI_OP(pi)) = Memr[PI_DATA(pi)]
	    } else
		O_VALP(PI_OP(pi)) = PI_DATA(pi)
	    if (line == 2) {
	        call sprintf (PRC_STR(prc), PRC_LENSTR, "%s = %s%s")
		    call pargstr (operand)
		    call pargstr (PI_NAME(pi))
		    call pargstr (PI_TSEC(pi))
	        call prclog (PRC_STR(prc), NULL, YES)
	    }
	}
	if (PI_LEN(pi,3) > 1) {
	    if (operand[3] == EOS)
		if (O_LEN(PI_OP(pi)) == 0) {
		    if (O_TYPE(PI_OP(pi)) == TY_SHORT)
			O_VALS(PI_OP(pi)) = Mems[PI_DATA(pi)]
		    else
			O_VALR(PI_OP(pi)) = Memr[PI_DATA(pi)]
		} else
		    O_VALP(PI_OP(pi)) = PI_DATA(pi)
	    else {
	        i = operand[3] - '0'
		if (i < 1 || i > PI_LEN(pi,3))
		    call prc_error (prc, PRCERR_IMREFNF,
		        "image reference `%s' not found", operand, "")
		if (O_LEN(PI_OP(pi)) == 0) {
		    if (O_TYPE(PI_OP(pi)) == TY_SHORT)
			O_VALS(PI_OP(pi)) = Mems[PI_DATA(pi)+i-1]
		    else
			O_VALR(PI_OP(pi)) = Memr[PI_DATA(pi)+i-1]
		} else
		    O_VALP(PI_OP(pi)) = PI_DATA(pi) + (i - 1) * PI_LEN(pi,1)
	    }
	}

	return (PI_OP(pi))
end


# PRC_EXPRS -- Evaluate string expression.

procedure prc_exprs (prc, pi, expr, val, maxchar)

pointer	prc				#I Processing parameters
pointer	pi				#I Processing data for keywords
char	expr[ARB]			#I Expression
char	val[maxchar]			#O String value
int	maxchar				#I Maximum number characters

pointer	o, p, evvexpr()
errchk	evvexpr, prc_error

begin
	# If not an expression return the literal string.
	if (expr[1] != '(')
	    call strcpy (expr, val, maxchar)
	else {
	    # Evaluate the expression.
	    p = PRC_PIKEY(prc)
	    PRC_PIKEY(prc) = pi
	    o = evvexpr (expr, PRC_GETOP(prc), prc, PRC_FUNC(prc), prc,
	        O_FREEOP)
	    PRC_PIKEY(prc) = p

	    if (O_TYPE(o) != TY_CHAR) {
		call evvfree (o)
		call prc_error (prc, PRCERR_EXPRS,
		    "Bad string expression (%s)", expr, "")
	    }

	    call strcpy (O_VALC(o), val, maxchar)
	    call evvfree (o)
	}
end


# PRC_EXPRR -- Evaluate real expression.

real procedure prc_exprr (prc, pi, expr)

pointer	prc				#I Processing parameters
pointer	pi				#I Processing data for keywords
char	expr[ARB]			#I Expression
real	val				#R Real value

double	prc_exprd()
errchk	prc_exprd

begin
	val = prc_exprd (prc, pi, expr)
	return (val)
end


# PRC_EXPRD -- Evaluate double expression.

double procedure prc_exprd (prc, pi, expr)

pointer	prc				#I Processing parameters
pointer	pi				#I Processing data for keywords
char	expr[ARB]			#I Expression
double	val				#R Double value

int	i, ctod()
pointer	o, p, evvexpr()
errchk	evvexpr, prc_error

begin
	# If not an expression return the literal value.
	if (expr[1] != '(') {
	    i = 1
	    if (ctod (expr, i, val) == 0)
		call prc_error (prc, PRCERR_EXPRN,
		    "Bad numeric value (%s)", expr, "")
	} else {
	    # Evaluate the expression.
	    p = PRC_PIKEY(prc)
	    PRC_PIKEY(prc) = pi
	    o = evvexpr (expr, PRC_GETOP(prc), prc, PRC_FUNC(prc), prc,
	        O_FREEOP)
	    PRC_PIKEY(prc) = p

	    switch (O_TYPE(o)) {
	    case TY_SHORT:
		val = O_VALS(o)
	    case TY_INT:
		val = O_VALI(o)
	    case TY_REAL:
		val = O_VALR(o)
	    case TY_DOUBLE:
		val = O_VALD(o)
	    default:
		call evvfree (o)
		call prc_error (prc, PRCERR_EXPRN,
		    "Bad numeric expression (%s)", expr, "")
	    }
	    call evvfree (o)
	}

	return (val)
end


# PRC_EXPRB -- Evaluate boolean expression.

bool procedure prc_exprb (prc, pi, expr)

pointer	prc				#I Processing parameters
pointer	pi				#I Processing data for keywords
char	expr[ARB]			#I Expression
bool	val				#R Boolean value

bool	streq()
int	i, nowhite()
pointer	o, p, evvexpr()
errchk	evvexpr, prc_error

begin
	# If not an expression return the literal value.
	if (expr[1] != '(') {
	    i = nowhite (expr, PRC_STR(prc), PRC_LENSTR)
	    call strupr (PRC_STR(prc))
	    if (streq (PRC_STR(prc), "YES"))
	        val = true
	    else if (streq (PRC_STR(prc), "NO"))
	        val = false
	    else
		call prc_error (prc, PRCERR_EXPRB,
		    "Bad boolean value (%s)", expr, "")
	} else {
	    # Evaluate the expression.
	    p = PRC_PIKEY(prc)
	    PRC_PIKEY(prc) = pi
	    o = evvexpr (expr, PRC_GETOP(prc), prc, PRC_FUNC(prc), prc,
	        O_FREEOP)
	    PRC_PIKEY(prc) = p

	    switch (O_TYPE(o)) {
	    case TY_BOOL:
		val = (O_VALI(o) == YES)
	    default:
		call evvfree (o)
		call prc_error (prc, PRCERR_EXPRB,
		    "Bad boolean expression (%s)", expr, "")
	    }
	    call evvfree (o)
	}

	return (val)
end


# PRC_EXPRP -- Evaluate pointer expression.
# This is an interface directly to evvexpr.

pointer procedure prc_exprp (prc, pi, expr)

pointer	prc				#I Processing parameters
pointer	pi				#I Processing data for keywords
char	expr[ARB]			#I Expression
pointer	o				#R Pointer value

pointer	p, evvexpr()
errchk	evvexpr

begin
	# Evaluate the expression.
	p = PRC_PIKEY(prc)
	PRC_PIKEY(prc) = pi
	o = evvexpr (expr, PRC_GETOP(prc), prc, PRC_FUNC(prc), prc, O_FREEOP)
	PRC_PIKEY(prc) = p

	return (o)
end
