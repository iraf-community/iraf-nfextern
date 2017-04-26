include	<evvexpr.h>
include <mach.h>
include	"prc.h"

define	KEYWORDS "|substr|strmap|mskmap|mskmin|mskmax|mskadd|mskor|irr|irs|"

define	F_SUBSTR		1	# substr (str, index1, index2)
define	F_STRMAP		2	# strmap (refstr, in1, out1, ...)
define	F_MSKMAP		3	# mskmap (in1, out1, in2, out2, ...)
define	F_MSKMIN		4	# mskmin (in1, in2, ...)
define	F_MSKMAX		5	# mskmax (in1, in2, ...)
define	F_MSKADD		6	# mskadd (in1, in2, ...)
define	F_MSKOR			7	# mskor (in1, in2, ...)

# The following are from the Dickinson linearity paper.
define	F_IRR			8	# irr (Nm,L,ti,tr)
define	F_IRS			9	# irs (L,S,ti,tr)

# PE_FUNC -- Special processing functions.

procedure pe_func (prc, func, args, nargs, out)

pointer	prc			#I client data
char	func[ARB]		#I function to be called
pointer	args[ARB]		#I pointer to arglist descriptor
int	nargs			#I number of arguments
pointer	out			#O output operand (function value)

int	i, j, k, optype, oplen, opcode, v_nargs
real	rval, L, S, ti, tr, tt, x
pointer	presult, ptr

bool	strne(), streq()
int	strdic(), strlen()
errchk	astfunc()

begin
	# Lookup the function name in the dictionary.  An exact match is
	# required (strdic permits abbreviations).  Abort if the function
	# is not known.

	opcode = strdic (func, PRC_STR(prc), PRC_LENSTR, KEYWORDS)
	if (opcode == 0) {
	    call ast_func (prc, func, args, nargs, out)
	    return
	} else if (strne (func, PRC_STR(prc)))
	    call xvv_error1 ("unknown function `%s' called", func)

	# Verify correct number of arguments.
	switch (opcode) {
	case F_SUBSTR:
	    v_nargs = 3
	case F_STRMAP:
	    v_nargs = 1 + 2 * (nargs-1) / 2
	    if (nargs != v_nargs)
		call xvv_error1 ("function `%s' requires odd number of arguments",
		    func)
	case F_MSKMAP:
	    v_nargs = 2 * (nargs / 2)
	    if (nargs != v_nargs)
		call xvv_error1 ("function `%s' requires even number of arguments",
		    func)
	case F_MSKMIN, F_MSKMAX, F_MSKADD, F_MSKOR:
	    v_nargs = -1
	case F_IRR, F_IRS:
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

	# Check and convert arguments.  Allocate output memory.
	switch (opcode) {
	case F_SUBSTR:
	    if (O_TYPE(args[1]) != TY_CHAR)
		call xvv_error1 ("function `%s' requires a string argument",
		    func)
	    if (O_TYPE(args[2]) != TY_INT || O_TYPE(args[3]) != TY_INT)
		call xvv_error1 ("function `%s' requires a integer indices",
		    func)
	    optype = TY_CHAR
	    oplen = strlen (O_VALC(args[1]))
	    call xvv_initop (out, oplen, optype)
	    presult = O_VALP(out)
	case F_STRMAP:
	    do i = 1, nargs
	        if (O_TYPE(args[i]) != TY_CHAR)
		    call xvv_error1 ("function `%s' requires string arguments",
			func)
	    optype = TY_CHAR
	    oplen = SZ_LINE
	    call xvv_initop (out, oplen, optype)
	    presult = O_VALP(out)
	case F_MSKMAP, F_MSKMIN, F_MSKMAX, F_MSKADD, F_MSKOR:
	    optype = TY_INT
	    oplen = O_LEN(args[1])
	    do i = 1, nargs {
	        if (O_TYPE(args[i]) == TY_CHAR)
		    call xvv_error1 (
		        "function `%s' requires numeric arguments", func)
	        if (O_LEN(args[i]) != oplen) {
	            if (mod(i,2)==1 || O_LEN(args[i]) != 0)
			call xvv_error1 (
			    "function `%s' requires equal line lengths", func)
		}
	    }
	    call xvv_initop (out, oplen, optype)
	    presult = O_VALP(out)
	case F_IRR, F_IRS:
	    optype = TY_REAL
	    oplen = O_LEN(args[4])
	    do i = 1, nargs {
	        if (O_TYPE(args[i]) == TY_CHAR)
		    call xvv_error1 (
		        "function `%s' requires numeric arguments", func)
	        if (O_LEN(args[i]) != oplen) {
	            if (O_LEN(args[i]) != 0)
			call xvv_error1 (
			    "function `%s' requires equal line lengths", func)
		}
	    }
	    call xvv_initop (out, oplen, optype)
	    presult = O_VALP(out)
	}

	# Evaluate the function.
	switch (opcode) {
	case F_SUBSTR:
	    i = max (1, min (oplen, O_VALI(args[2])))
	    j = max (1, min (oplen, O_VALI(args[3])))
	    if (j < i) {
	        do k = i, j, -1
		    Memc[presult+i-k] = Memc[O_VALP(args[1])+k-1]
	    } else
		call strcpy (Memc[O_VALP(args[1])+i-1], Memc[presult], j-i+1)
	case F_STRMAP:
	    call strcpy (O_VALC(args[1]), Memc[presult], oplen)
	    do i = 2, nargs, 2 {
	        if (streq (O_VALC(args[i]), O_VALC(args[1]))) {
		    call strcpy (O_VALC(args[i+1]), Memc[presult], oplen)
		    break
		}
	    }
	case F_MSKMAP:
	    do j = 0, oplen-1 {
		Memi[presult+j] = 0
		do i = 1, nargs, 2 {
		    switch (O_TYPE(args[i])) {
		    case TY_SHORT:
			k = Mems[O_VALP(args[i])+j]
		    case TY_INT:
			k = Memi[O_VALP(args[i])+j]
		    case TY_REAL:
			k = Memr[O_VALP(args[i])+j]
		    case TY_DOUBLE:
			k = Memd[O_VALP(args[i])+j]
		    }
		    if (k == 0)
		        next
		    switch (O_TYPE(args[i+1])) {
		    case TY_SHORT:
			if (O_LEN(args[i+1]) == 0)
			    Memi[presult+j] = O_VALS(args[i+1])
			else
			    Memi[presult+j] = Mems[O_VALP(args[i+1])+j]
		    case TY_INT:
			if (O_LEN(args[i+1]) == 0)
			    Memi[presult+j] = O_VALI(args[i+1])
			else
			    Memi[presult+j] = Memi[O_VALP(args[i+1])+j]
		    case TY_REAL:
			if (O_LEN(args[i+1]) == 0)
			    Memi[presult+j] = O_VALR(args[i+1])
			else
			    Memi[presult+j] = Memr[O_VALP(args[i+1])+j]
		    case TY_DOUBLE:
			if (O_LEN(args[i+1]) == 0)
			    Memi[presult+j] = O_VALD(args[i+1])
			else
			    Memi[presult+j] = Memd[O_VALP(args[i+1])+j]
		    }
		    break
		}
	    }
	case F_MSKMIN:
	    do j = 0, oplen-1 {
		Memi[presult+j] = MAX_INT
		do i = 1, nargs {
		    switch (O_TYPE(args[i])) {
		    case TY_SHORT:
			k = Mems[O_VALP(args[i])+j]
		    case TY_INT:
			k = Memi[O_VALP(args[i])+j]
		    case TY_REAL:
			k = Memr[O_VALP(args[i])+j]
		    case TY_DOUBLE:
			k = Memd[O_VALP(args[i])+j]
		    }
		    if (k != 0)
			Memi[presult+j] = min (Memi[presult+j], k)
		}
		if (Memi[presult+j] == MAX_INT)
		    Memi[presult+j] = 0
	    }
	case F_MSKMAX:
	    do j = 0, oplen-1 {
		Memi[presult+j] = -MAX_INT
		do i = 1, nargs {
		    switch (O_TYPE(args[i])) {
		    case TY_SHORT:
			k = Mems[O_VALP(args[i])+j]
		    case TY_INT:
			k = Memi[O_VALP(args[i])+j]
		    case TY_REAL:
			k = Memr[O_VALP(args[i])+j]
		    case TY_DOUBLE:
			k = Memd[O_VALP(args[i])+j]
		    }
		    if (k != 0)
			Memi[presult+j] = max (Memi[presult+j], k)
		}
		if (Memi[presult+j] == -MAX_INT)
		    Memi[presult+j] = 0
	    }
	case F_MSKADD:
	    do j = 0, oplen-1 {
		Memi[presult+j] = 0
		do i = 1, nargs {
		    switch (O_TYPE(args[i])) {
		    case TY_SHORT:
			k = Mems[O_VALP(args[i])+j]
		    case TY_INT:
			k = Memi[O_VALP(args[i])+j]
		    case TY_REAL:
			k = Memr[O_VALP(args[i])+j]
		    case TY_DOUBLE:
			k = Memd[O_VALP(args[i])+j]
		    }
		    Memi[presult+j] = Memi[presult+j] + k
		}
	    }
	case F_MSKOR:
	    switch (O_TYPE(args[i])) {
	    case TY_SHORT:
		call malloc (ptr, oplen, TY_INT)
	        call achtsi (Mems[O_VALP(args[1])], Memi[presult], oplen)
		do i = 2, nargs {
		    call achtsi (Mems[O_VALP(args[i])], Memi[ptr], oplen)
		    call abori (Memi[ptr], Memi[presult], Memi[presult], oplen)
		}
		call mfree (ptr, TY_SHORT)
	    case TY_INT:
	        call amovi (Memi[O_VALP(args[1])], Memi[presult], oplen)
		do i = 2, nargs {
		    call abori (Memi[O_VALP(args[i])], Memi[presult],
		        Memi[presult], oplen)
		}
	    case TY_REAL:
		call malloc (ptr, oplen, TY_INT)
	        call achtri (Memr[O_VALP(args[1])], Memi[presult], oplen)
		do i = 2, nargs {
		    call achtri (Memr[O_VALP(args[i])], Memi[ptr], oplen)
		    call abori (Memi[ptr], Memi[presult], Memi[presult], oplen)
		}
		call mfree (ptr, TY_REAL)
	    case TY_DOUBLE:
		call malloc (ptr, oplen, TY_INT)
	        call achtdi (Memd[O_VALP(args[1])], Memi[presult], oplen)
		do i = 2, nargs {
		    call achtdi (Memd[O_VALP(args[i])], Memi[ptr], oplen)
		    call abori (Memi[ptr], Memi[presult], Memi[presult], oplen)
		}
		call mfree (ptr, TY_DOUBLE)
	    }
	case F_IRR:
	    switch (O_TYPE(args[3])) {
	    case TY_SHORT:
		ti =  O_VALS(args[3])
	    case TY_INT:
		ti =  O_VALI(args[3])
	    case TY_REAL:
		ti =  O_VALR(args[3])
	    case TY_DOUBLE:
		ti =  O_VALD(args[3])
	    }
	    do j = 0, oplen-1 {
	        if (O_LEN(args[2]) == 0) {
		    switch (O_TYPE(args[2])) {
		    case TY_SHORT:
			L =  O_VALS(args[2])
		    case TY_INT:
			L =  O_VALI(args[2])
		    case TY_REAL:
			L =  O_VALR(args[2])
		    case TY_DOUBLE:
			L =  O_VALD(args[2])
		    }
		} else {
		    ptr = O_VALP(args[2]) + j
		    switch (O_TYPE(args[2])) {
		    case TY_SHORT:
			L =  Mems[ptr]
		    case TY_INT:
			L =  Memi[ptr]
		    case TY_REAL:
			L =  Memr[ptr]
		    case TY_DOUBLE:
			L =  Memd[ptr]
		    }
		}
		ptr = O_VALP(args[4]) + j
		switch (O_TYPE(args[4])) {
		case TY_SHORT:
		    tr =  Mems[ptr]
		case TY_INT:
		    tr =  Memi[ptr]
		case TY_REAL:
		    tr =  Memr[ptr]
		case TY_DOUBLE:
		    tr =  Memd[ptr]
		}
		ptr = O_VALP(args[1]) + j
		switch (O_TYPE(args[1])) {
		case TY_SHORT:
		    rval =  Mems[ptr]
		case TY_INT:
		    rval =  Memi[ptr]
		case TY_REAL:
		    rval =  Memr[ptr]
		case TY_DOUBLE:
		    rval =  Memd[ptr]
		}
		tt = ti + tr
		x = tt ** 2 - tr ** 2
		Memr[presult+j] = (sqrt(max(0.,ti**2+4*L*x*rval))-ti)/(2*L*x)
	    }
	case F_IRS:
	    switch (O_TYPE(args[3])) {
	    case TY_SHORT:
		ti =  O_VALS(args[3])
	    case TY_INT:
		ti =  O_VALI(args[3])
	    case TY_REAL:
		ti =  O_VALR(args[3])
	    case TY_DOUBLE:
		ti =  O_VALD(args[3])
	    }
	    do j = 0, oplen-1 {
	        if (O_LEN(args[1]) == 0) {
		    switch (O_TYPE(args[1])) {
		    case TY_SHORT:
			L =  O_VALS(args[1])
		    case TY_INT:
			L =  O_VALI(args[1])
		    case TY_REAL:
			L =  O_VALR(args[1])
		    case TY_DOUBLE:
			L =  O_VALD(args[1])
		    }
		} else {
		    ptr = O_VALP(args[1]) + j
		    switch (O_TYPE(args[1])) {
		    case TY_SHORT:
			L =  Mems[ptr]
		    case TY_INT:
			L =  Memi[ptr]
		    case TY_REAL:
			L =  Memr[ptr]
		    case TY_DOUBLE:
			L =  Memd[ptr]
		    }
		}
	        if (O_LEN(args[2]) == 0) {
		    switch (O_TYPE(args[2])) {
		    case TY_SHORT:
			S =  O_VALS(args[2])
		    case TY_INT:
			S =  O_VALI(args[2])
		    case TY_REAL:
			S =  O_VALR(args[2])
		    case TY_DOUBLE:
			S =  O_VALD(args[2])
		    }
		} else {
		    ptr = O_VALP(args[2]) + j
		    switch (O_TYPE(args[2])) {
		    case TY_SHORT:
			S =  Mems[ptr]
		    case TY_INT:
			S =  Memi[ptr]
		    case TY_REAL:
			S =  Memr[ptr]
		    case TY_DOUBLE:
			S =  Memd[ptr]
		    }
		}
		ptr = O_VALP(args[4]) + j
		switch (O_TYPE(args[4])) {
		case TY_SHORT:
		    tr =  Mems[ptr]
		case TY_INT:
		    tr =  Memi[ptr]
		case TY_REAL:
		    tr =  Memr[ptr]
		case TY_DOUBLE:
		    tr =  Memd[ptr]
		}
		tt = ti + tr
		x = tr / tt
		Memr[presult+j] = S * (1 - x) + L * S**2 * (1 - x**2)
	    }
	}

	# Free any storage used by the argument list operands.
	do i = 1, nargs
	    call xvv_freeop (args[i])
end
