include	<ctype.h>
include	<lexnum.h>
include	<evvexpr.h>


# GETKEYS -- Get keyword as string.

procedure getkeys (im, key, o)

pointer	im				#I Image
char	key[ARB]			#I Operand name
pointer	o				#I Operand object

int	imaccf()

begin
	if (imaccf (im, key) == NO)
	    call xvv_error1 ("image keyword `%s' not found", key)

	call xvv_initop (o, SZ_FNAME, TY_CHAR)
	call imgstr (im, key, O_VALC(o), SZ_FNAME)
end


# GETKEY -- Get keyword.

procedure getkey (im, key, o)

pointer	im				#I Image
char	key[ARB]			#I Operand name
pointer	o				#I Operand object

int	ip, type, nchars
pointer	cp

int	lexnum(), ctoi(), ctor(), imaccf(), imgeti(), imgftype()
double	imgetd()

begin
	if (imaccf (im, key) == NO)
	    call xvv_error1 ("image keyword `%s' not found", key)

	switch (imgftype (im, key)) {
	case TY_BOOL, TY_SHORT, TY_INT, TY_LONG:
	    call xvv_initop (o, 0, TY_INT)
	    O_VALI(o) = imgeti (im, key)

	case TY_REAL, TY_DOUBLE, TY_COMPLEX:
	    call xvv_initop (o, 0, TY_DOUBLE)
	    O_VALD(o) = imgetd (im, key)

	default:
	    call malloc (cp, SZ_LINE, TY_CHAR)
	    call imgstr (im, key, Memc[cp], SZ_LINE)

	    ip = 1
	    type = lexnum (Memc[cp], ip, nchars)
	    if (Memc[cp+nchars+ip-1] != EOS)
		type = LEX_NONNUM

	    switch (type) {
	    case LEX_OCTAL, LEX_DECIMAL, LEX_HEX:
		ip = 1
		call xvv_initop (o, 0, TY_INT)
		nchars = ctoi (Memc[cp], ip, O_VALI(o))
	    case LEX_REAL:
		ip = 1
		call xvv_initop (o, 0, TY_REAL)
		nchars = ctor (Memc[cp], ip, O_VALR(o))
	    case LEX_NONNUM:
		call xvv_initop (o, SZ_LINE, TY_CHAR)
		call strcpy (Memc[cp], O_VALC(o), SZ_LINE)
	    }

	    call mfree (cp, TY_CHAR)
	}
end


define	KEYWORDS "|strmap|substr|mkid|"

define	F_STRMAP		1	# strmap (ref, def, in, out, ...)
define	F_SUBSTR		2	# substr (str, i1, i2)
define	F_MKID			3	# mkid (str, w1, w2)

# GETFUNC -- Special processing functions.

procedure getfunc (im, func, args, nargs, out)

pointer	im			#I client data
char	func[ARB]		#I function to be called
pointer	args[ARB]		#I pointer to arglist descriptor
int	nargs			#I number of arguments
pointer	out			#O output operand (function value)

double	dresult
int	iresult, optype, oplen, opcode, v_nargs, i, i1, i2
pointer	str

bool	strne(), streq()
int	strdic(), strlen(), btoi()
errchk	malloc

begin
	# Lookup the function name in the dictionary.  An exact match is
	# required (strdic permits abbreviations).  Abort if the function
	# is not known.

	call malloc (str, SZ_LINE, TY_CHAR)
	opcode = strdic (func, Memc[str], SZ_LINE, KEYWORDS)
	if (opcode == 0 || strne (func, Memc[str]))
	    call xvv_error1 ("unknown function `%s' called", func)
	call mfree (str, TY_CHAR)

	# Verify correct number of arguments.
	switch (opcode) {
	case F_STRMAP:
	    v_nargs = 2 + 2 * (nargs-1) / 2
	    if (nargs != v_nargs)
		call xvv_error1 ("function `%s' requires even number of args",
		    func)
	case F_SUBSTR, F_MKID:
	    v_nargs = 3
	default:
	    v_nargs = 1
	}

	if (v_nargs > 0 && nargs != v_nargs)
	    call xvv_error2 ("function `%s' requires %d arguments",
		func, v_nargs)
	else if (v_nargs < 0 && nargs < abs(v_nargs))
	    call xvv_error2 ("function `%s' requires at least %d arguments",
		func, abs(v_nargs))

	# Evaluate the function.
	switch (opcode) {
	case F_STRMAP:
	    optype = TY_CHAR
	    oplen = SZ_LINE
	    call malloc (iresult, oplen, TY_CHAR)
	    call strcpy (O_VALC(args[2]), Memc[iresult], oplen)
	    do i = 3, nargs, 2 {
	        if (streq (O_VALC(args[i]), O_VALC(args[1]))) {
		    call strcpy (O_VALC(args[i+1]), Memc[iresult], oplen)
		    break
		}
	    }
	case F_SUBSTR:
	    optype = TY_CHAR
	    oplen = strlen (O_VALC(args[1]))
	    call malloc (iresult, oplen, TY_CHAR)
	    call strcpy (O_VALC(args[1]), Memc[iresult], oplen)
	    i1 = max (1, O_VALI(args[2]))
	    i2 = min (oplen, O_VALI(args[3]))
	    if (i2 < i1)
	        Memc[iresult] = EOS
	    else
		call strcpy (Memc[iresult+i1-1], Memc[iresult], i2-i1+1)
	case F_MKID:
	    optype = TY_CHAR
	    oplen = strlen (O_VALC(args[1]))
	    call malloc (iresult, oplen, TY_CHAR)
	    call mkid (O_VALC(args[1]), O_VALI(args[2]), O_VALI(args[3]),
	        Memc[iresult], oplen)
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

end


# MKID -- Make an ID string from the specified words.
# An ID string has no whitespace or nonalphanumerics except period.

procedure mkid (in, w1, w2, out, maxchar)

char	in[ARB]			#I Input string
int	w1, w2			#I Range of words to use
char	out[maxchar]		#O Output ID string
int	maxchar			#I Maximum character in ID string

int	i, j, k
pointer	sp, s1

int	ctowrd(), strlen()

begin
	call smark (sp)
	call salloc (s1, SZ_LINE, TY_CHAR)

	out[1] = EOS

	# Extract the words.
	i = 1
	do j = 1, w1-1
	    k = ctowrd (in, i, Memc[s1], SZ_LINE)
	do j = w1, w2 {
	    k = ctowrd (in, i, Memc[s1], SZ_LINE)
	    call strcat (Memc[s1], out, maxchar)
	}

	# Replace characters.
	for (i=1; out[i]!=EOS; i=i+1)
	    if (!(IS_ALNUM(out[i])||out[i]=='.'))
	        out[i] = '_'

	# Remove trailing period.
	i = strlen (out)
	if (out[i] == '.')
	    out[i] = EOS

	call sfree (sp)
end
