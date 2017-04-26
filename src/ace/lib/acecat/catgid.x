include	<acecat1.h>

int procedure catgid (cat, name)

pointer	cat			#I Catalog
char	name[ARB]		#I Field name
int	id			#O ID (not found = -1)

bool	streq()
pointer	stp, sym, stfind(), sthead(), stnext()

begin
	id = -1

	if (cat == NULL)
	    return (id)
	stp = CAT_STP(cat)
	if (stp == NULL)
	    return (id)

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
	if (sym != NULL)
	    id = ENTRY_ID(sym)
	return (id)
end
