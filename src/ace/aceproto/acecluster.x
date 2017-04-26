include	<acecat.h>
include	"ac.h"

# ACECLUSTER -- Cluster on a specified field.
#
# The logic here is:
#    1.	Cluster on field 1
#    2.	Cluster on field 2
#    3.	Cluster on field 1
#    4.	Cluster on field 2
#    5.	Cluster on field 3
#    6.	Cluster on field 4
#    7.	Cluster on field 1
#    8.	Cluster on field 2
#    9.	Cluster on field 1
#    a.	Cluster on field 2
#    b.	Cluster on field 3
#    c.	Cluster on field 4
#    d.	Cluster on field 5


procedure acecluster1 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster2

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster2 (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster2 (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure acecluster2 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster3

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster3 (icat, rec1, rec2-rec1, field-1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster3 (icat, rec1, rec2-rec1, field-1, sep,
	    mincluster, cluster)
end


procedure acecluster3 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster4

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster4 (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster4 (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure acecluster4 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster5

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster5 (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster5 (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure acecluster5 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster6

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster6 (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster6 (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure acecluster6 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster7

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster6 (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster7 (icat, rec1, rec2-rec1, field-3, sep,
	    mincluster, cluster)
end


procedure acecluster7 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster8

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster8 (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster8 (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure acecluster8 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	acecluster9

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call acecluster9 (icat, rec1, rec2-rec1, field-1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call acecluster9 (icat, rec1, rec2-rec1, field-1, sep,
	    mincluster, cluster)
end


procedure acecluster9 (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	aceclustera

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call aceclustera (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call aceclustera (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure aceclustera (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	aceclusterb

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call aceclusterb (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call aceclusterb (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure aceclusterb (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	aceclusterc

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call aceclusterc (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call aceclusterc (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure aceclusterc (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
errchk	aceclusterd

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Cluster on next field.
		call aceclusterd (icat, rec1, rec2-rec1, field+1, sep,
		    mincluster, cluster)
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	call aceclusterd (icat, rec1, rec2-rec1, field+1, sep,
	    mincluster, cluster)
end


procedure aceclusterd (icat, recs, nrecs, field, sep, mincluster, cluster)

pointer	icat			#I Input catalog
pointer	recs			#I Records to cluster
pointer	nrecs			#I Number of records
int	field			#I Field number
real	sep[ARB]		#I Cluster separations
int	mincluster		#I Minimum cluster
int	cluster			#U Last cluster ID

int	i, cl, ncluster
real	sep1, val1, val2
pointer	rec1, rec2
pointer	rec

begin
	# If there is only a single record assign the cluster and return.
	if (nrecs == 1) {
	    rec1 = recs
	    ncluster = 1
	    if (ncluster < mincluster)
		cl = INDEFI
	    else {
		cluster = cluster + 1
		cl = cluster
	    }
	    CL_CL(Memi[rec1]) = cl
	    CL_NCL(Memi[rec1]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	    return
	}

	# Sort by field to be clustered if a separation is specified.
	sep1 = sep[field-ID_C1+1]
	if (!IS_INDEFR(sep1))
	    call catsort (icat, Memi[recs], nrecs, field, 1)

	# Find breaks of sep or more.
	rec1 = recs
	val1 = RECR(Memi[rec1],field)
	do rec2 = rec1+1, recs+nrecs-1 {
	    if (IS_INDEFR(sep1) || IS_INDEFR(val1)) {
	        rec2 = recs+nrecs
		break
	    }
	    val2 = RECR(Memi[rec2],field)
	    if (IS_INDEFR(val2) || (sep1>0.&&val2-val1>sep1)||
	        (sep1<0.&&val2-val1>-sep1*min(abs(val1),abs(val2)))) {
		# Assign cluster ID and averages.
		ncluster = rec2 - rec1
		if (ncluster < mincluster)
		    cl = INDEFI
		else {
		    cluster = cluster + 1
		    cl = cluster
		}
		do rec = rec1, rec2-1 {
		    CL_CL(Memi[rec]) = cl
		    CL_NCL(Memi[rec]) = ncluster
		    do i = 1, CL_NC+CL_NF
			call acecluster_avg (rec1, ncluster, ID_C1+i-1,
			    ID_AVC1+i-1)
		}
		rec1 = rec2
	    } 
	    val1 = val2
	}

	# Do last cluster.
	ncluster = rec2 - rec1
	if (ncluster < mincluster)
	    cl = INDEFI
	else {
	    cluster = cluster + 1
	    cl = cluster
	}
	do rec = rec1, rec2-1 {
	    CL_CL(Memi[rec]) = cl
	    CL_NCL(Memi[rec]) = ncluster
	    do i = 1, CL_NC+CL_NF
		call acecluster_avg (rec1, ncluster, ID_C1+i-1, ID_AVC1+i-1)
	}
end
