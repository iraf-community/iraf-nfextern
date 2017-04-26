include	<error.h>
include	<acecat.h>
include	"ac.h"


# T_ACECLUSTER -- Find clusters in catalogs.
# This entry point gets parameters and expands input lists.

procedure t_acecluster ()

pointer	ilist			# Input catalog list
pointer	olist			# Output catalog list
pointer	seplist			# Cluster separations
int	mincluster		# Minimum in cluster
pointer	icatdef			# Input catalog definition file
pointer	ocatdef			# Output catalog definition file
pointer	ifilter			# Input catalog filter
pointer	ofilter			# Output catalog filter

int	i, j
real	sep[CL_NC]
pointer	sp, iname, oname

int	clgeti(), afn_gfn(), ctor(), strlen()
pointer	afn_cl()
errchk	afn_cl, afn_gfn, acecluster

begin
	call smark (sp)
	call salloc (iname, SZ_FNAME, TY_CHAR)
	call salloc (oname, SZ_FNAME, TY_CHAR)
	call salloc (icatdef, SZ_FNAME, TY_CHAR)
	call salloc (ocatdef, SZ_FNAME, TY_CHAR)
	call salloc (ifilter, SZ_FNAME, TY_CHAR)
	call salloc (ofilter, SZ_FNAME, TY_CHAR)

	# Set parameters.
	ilist = afn_cl ("icats", "catalog", NULL)
	olist = afn_cl ("ocats", "catalog", ilist)
	seplist = afn_cl ("seps", "file", NULL)
	mincluster = clgeti ("mincluster")
	call clgstr ("icatdef", Memc[icatdef], SZ_FNAME)
	call clgstr ("ocatdef", Memc[ocatdef], SZ_FNAME)
	call clgstr ("ifilter", Memc[ifilter], SZ_FNAME)
	call clgstr ("ofilter", Memc[ofilter], SZ_FNAME)

	# Extract the separation values.
	do i = 1, CL_NC {
	    if (afn_gfn (seplist, Memc[iname], SZ_FNAME) != EOF) {
		j = 1
	        if (ctor (Memc[iname], j, sep[i]) != strlen (Memc[iname]))
		    call error (1, "Syntax error in seps parameter")
	    } else
	        sep[i] = INDEFR
	}
	call afn_cls (seplist)

	# Loop through catalogs.
	while (afn_gfn (ilist, Memc[iname], SZ_FNAME) != EOF) {
	    if (afn_gfn (olist, Memc[oname], SZ_FNAME) == EOF)
	        break

	    iferr {
	        call acecluster (Memc[iname], Memc[oname], Memc[icatdef],
		    Memc[ocatdef], Memc[ifilter], Memc[ofilter], sep,
		    mincluster)
	    } then
	        call erract (EA_WARN)
	}

	call afn_cls (olist)
	call afn_cls (ilist)
	call sfree (sp)
end


# ACECLUSTER -- Find clusters in a catalog.

procedure acecluster (iname, oname, icatdef, ocatdef, ifilter, ofilter,
	sep, mincluster)

char	iname[ARB]			#I Input catalog name
char	oname[ARB]			#I Input catalog name
char	icatdef[ARB]			#I Input catalog definition file
char	ocatdef[ARB]			#I Input catalog definition file
char	ifilter[ARB]			#I Input catalog filter
char	ofilter[ARB]			#I Input catalog filter
real	sep[ARB]			#I Cluster separations
int	mincluster			#I Minimum cluster

int	i, j, cluster
pointer	icat, ocat, rec

bool	filter()
errchk	acecluster1
errchk	catopen, catrrecs, catcreate, catwrecs, im2im

begin
	# Get input records.
	call catopen (icat, iname, "", icatdef, CL_STRUCT, NULL, 1)
	call catrrecs (icat, ifilter, -1)

	# Find clusters.
	if (CAT_NRECS(icat) > 0) {
	    cluster = 0
	    call acecluster1 (icat, CAT_RECS(icat), CAT_NRECS(icat), ID_C1, sep,
		mincluster, cluster)
	}

	# Write output catalog.

	call catopen (ocat, "", oname, ocatdef, CL_STRUCT, NULL, 1)
	call catcreate (ocat)
	call im2im (CAT_IHDR(icat), CAT_OHDR(ocat))
	j = 0
	do i = 0, CAT_NRECS(icat)-1 {
	    rec = Memi[CAT_RECS(icat)+i]
	    if (IS_INDEFI(CL_CL(rec)) || !filter (icat, rec, ofilter))
	        next
	    j = j + 1
	    call catwrec (ocat, rec, j)
	}
	CAT_NRECS(ocat) = j
	call catclose (ocat, NO)

	# Close input catalog.
	call catclose (icat, NO)
end


# ACECLUSTER_AVG -- Compute average of a field over a cluster.

procedure acecluster_avg (recs, nrecs, field, avfield)

pointer	recs			#I Records in cluster
int	nrecs			#I Number of records in cluster
int	field			#I Field to be averaged
int	avfield			#I Field for average

int	i, navg
real	val, avg

begin
	avg = 0.; navg = 0
	do i = 0, nrecs-1 {
	    val = RECR(Memi[recs+i],field)
	    if (IS_INDEFR(val))
	        next
	    avg = avg + val
	    navg = navg + 1
	}
	if (navg > 0)
	    avg = avg / navg
	else
	    avg = INDEFR
	do i = 0, nrecs-1
	    RECR(Memi[recs+i],avfield) = avg
end
