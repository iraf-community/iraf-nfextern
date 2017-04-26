define	CAT_EXTNS	 "|tab|fits|fit|fxb|txt|dat|cat|tmp|"

# CATEXTN -- Add extension if needed.
# Input may be the same as output.
# A null input can be used to determine the default extension.

procedure catextn (input, output, maxlen)

char	input[ARB]			#I Input filename
char	output[maxlen]			#O Output filename
int	maxlen				#I Maximum output length

bool	streq()
int	i, j, stridxs(), strdic(), envfind(), nowhite()
pointer	sp, extname

begin
	call smark (sp)
	call salloc (extname, SZ_FNAME, TY_CHAR)

	# Default.
	call strcpy (input, output, maxlen)
	if (stridxs ("[", input) > 0)
	    return

	# Check for known extension.
	call zfnbrk (input, i, j)
	if (j > 0 && input[j] != EOS) {
	    i = strdic (input[j+1], Memc[extname], SZ_FNAME, CAT_EXTNS)
	    if (streq (input[j+1], Memc[extname]))
	        return
	}

	# Add extension from CAT_EXTN environment or default.
	i = envfind ("CAT_EXTN", Memc[extname], SZ_FNAME)
	if (i >= 0) {
	    if (nowhite (Memc[extname], Memc[extname], SZ_FNAME) == 0)
	        return
	    if (streq (input[j+1], Memc[extname]))
	        return
	}

	if (Memc[extname] == EOS)
	    call strcat (".txt", output, maxlen)
	else {
	    call strcat (".", output, maxlen)
	    call strcat (Memc[extname], output, maxlen)
	}

	call sfree (sp)
end
