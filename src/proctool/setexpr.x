include	<ctype.h>
include	"gettok.h"
include	"pi.h"


# SETEXPR -- Set an expression.
#
# The expression may be input or obtained from a parameter.
# This provides a place to change things dealing with expressions.
# In this version it removes leading whitespace, reads expressions in
# files and converts '!<expr>' to '(<expr>)'.  It also expands any
# macros in an expression database as with IMEXPR.  The parameter
# may begin with '!' to force the parameter value to always be
# treated as an expression.

procedure setexpr (param, value, maxchar)

char	param[ARB]			#I Parameter name
char	value[ARB]			#U Expression
int	maxchar

int	i, buflen, fd
int	strlen(), open(), getline(), gt_expand(), locpr()
pointer	line, ptr, ie_getexprdb(), gt_opentext
bool	streq()
extern	ie_gsym()
errchk	ie_getexprdb, gt_opentext, gt_expand, open

pointer	st, buf
data	st/NULL/, buf/NULL/

begin
	if (streq (param, "open")) {
	    # Expression symbol table.  This code is taken from imexpr.
	    if (value[1] != EOS) {
	        ptr = ie_getexprdb (value); st = ptr
		buflen = SZ_LINE
		call malloc (buf, buflen, TY_CHAR)
	    }
	    return
	} else if (streq (param, "close")) {
	    if (st != NULL)
	        call stclose (st)
	    call mfree (buf, TY_CHAR)
	    return
	}

	# Get parameter if needed.
	if (param[1] != EOS) {
	    if (param[1] == '!') {
	        value[1] = '!'
		call clgstr (param[2], value[2], maxchar-1)
	    } else
		call clgstr (param, value, maxchar)
	}

	# Strip leading whitespace.
	for (i=1; IS_WHITE(value[i]); i=i+1)
	    ;
	if (i > 1)
	    call strcpy (value[i], value, maxchar)

	# Check for expression in a file and read it in.
	if (value[1] == '@' && (value[2] == '(' || value[2] == '!')) {
	    if (value[2] == '(')
		call strcpy (value[3], value, strlen(value[3])-1)
	    else
		call strcpy (value[3], value, maxchar)
	    fd = open (value, READ_ONLY, TEXT_FILE)
	    call malloc (line, SZ_LINE, TY_CHAR)
	    call strcpy ("!", value, maxchar)
	    while (getline (fd, Memc[line]) != EOF) {
		for (i=1; IS_WHITE(Memc[line+i-1]); i=i+1)
		    ;
		if (i > 1)
		    call strcpy (Memc[line+i-1], Memc[line], SZ_LINE)
		i = strlen (Memc[line])
		if (Memc[line+i-1] == '\n')
		    Memc[line+i-1] = EOS
	        call strcat (Memc[line], value, maxchar)
	    }
	    call mfree (line, TY_CHAR)
	    call close (fd)
	}
	        
	# Convert '!' syntax to '()' syntax.
	if (value[1] == '!') {
	    value[1] = '('
	    call strcat (")", value, maxchar)
	}

	# Expand macros.
	if (st != NULL && value[1] == '(') {
	    ptr = gt_opentext (value, locpr(ie_gsym), st, 0, GT_NOFILE)
	    i = gt_expand (ptr, buf, buflen)
	    call gt_close (ptr)
	    if (i > 0) {
		# Remove whitespace while protecting certain patterns.
		ptr = buf+1
		for (i=ptr; Memc[i]!=EOS; i=i+1) {
		    if (Memc[i] != ' ') {
		        Memc[ptr] = Memc[i]
			ptr = ptr + 1
		    } else if (Memc[i-1] == ':') {
		        Memc[ptr] = Memc[i]
			ptr = ptr + 1
		    }
		}
		Memc[ptr] = EOS

		if (strlen(Memc[buf]) > maxchar) {
		    call sprintf (Memc[buf], buflen,
		        "Expression is too long (%s)")
			call pargstr (param)
		    call error (1, Memc[buf])
		}
		call strcpy (Memc[buf], value, maxchar)
	    }
	}
end


# SETEXPR1 -- Set expressions with %, { and \I special characters.

procedure setexpr1 (prc, ipi, inexpr, outexpr, maxchar, level, debug)

pointer	prc				#I Processing object
pointer	ipi				#I Input image processing structure
char	inexpr[ARB]			#I Input expression
char	outexpr[maxchar]		#O Output expression
int	maxchar				#I Maximum length of output expression
int	level				#I Number of levels of expansion
int	debug				#I List expansion steps

bool	setexpr2(), streq()
int	i, j, k, stridxs()
pointer	sp, lastexpr, str1, str2 

errchk	prc_exprs, setexpr, setexpr2

begin
	call smark (sp)
	call salloc (lastexpr, maxchar, TY_CHAR)
	call salloc (str1, maxchar, TY_CHAR)
	call salloc (str2, maxchar, TY_CHAR)

	# Strip any leading %.
	if (inexpr[1] == '%')
	    call strcpy (inexpr[2], outexpr, maxchar)
	else
	    call strcpy (inexpr, outexpr, maxchar)
	Memc[lastexpr] = EOS

	k = 0
	repeat {
	    if (debug == YES) {
#		call eprintf ("%s\n")
#		    call pargstr (outexpr)
#call putline (STDERR, outexpr)
#call putline (STDERR, "\n")
	    }

	    k = k + 1
	    if (k > level)
	        break

	    # Save expression.
	    call strcpy (outexpr, Memc[lastexpr], maxchar)

	    # Replace \ characters.
	    if (setexpr2 (ipi, Memc[lastexpr], outexpr, maxchar, debug))
	        ;

	    # Evaluate any { expressions.
	    for (i=stridxs("{",outexpr); i!=0; i=stridxs("{",outexpr)) {
	        j = stridxs ("}", outexpr)
	        outexpr[i] = EOS
	        outexpr[j] = EOS
		call sprintf (Memc[str1], maxchar, "(%s)")
		    call pargstr (outexpr[i+1])
		call prc_exprs (prc, ipi, Memc[str1], Memc[str2], maxchar)
		call sprintf (Memc[str1], maxchar, "%s%s%s")
		    call pargstr(outexpr)
		    call pargstr(Memc[str2])
		    call pargstr(outexpr[j+1])
		call strcpy (Memc[str1], outexpr, maxchar)
		if (debug == YES) {
		    call eprintf ("%s\n")
			call pargstr (outexpr)
		}
		if (setexpr2 (ipi, outexpr, Memc[str1], maxchar, debug))
		    call strcpy (Memc[str1], outexpr, maxchar)
	    }

	    # Do macro replacement.
	    call setexpr ("", outexpr, maxchar)

	    k = k + 1
	} until (streq (outexpr, Memc[lastexpr]))

	call sfree (sp)
end


bool procedure setexpr2 (ipi, inexpr, outexpr, maxchar, debug)

pointer	ipi				#I Input image processing structure
char	inexpr[ARB]			#I Input expression
char	outexpr[maxchar]		#O Output expression
int	maxchar				#I Maximum length of output expression
int	debug				#I Debugging output?
bool	stat				#R Replacements occured?

int	i, j, strlen()

begin

	stat = false

	j = 1
	for (i=1; inexpr[i]!=EOS; i=i+1) {
	    if (inexpr[i] == '\\' && inexpr[i+1] == 'I') {
		call strcpy (PI_IMAGEID(ipi), outexpr[j], maxchar-j+1)
		j = strlen (outexpr) + 1
		i = i + 1
		stat = true
	    } else {
		outexpr[j] = inexpr[i]
		j = j + 1
	    }
	    if (j > maxchar)
	        break
	}
	outexpr[j] = EOS

	if (stat && debug == YES) {
	    call eprintf ("%s\n")
	        call pargstr (outexpr)
	}

	return (stat)
end
