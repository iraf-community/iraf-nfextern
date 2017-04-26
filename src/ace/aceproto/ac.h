# ACECLUSTER

define	CL_STRUCT	"aceproto$ac.h"

define	ID_NUM		 0 # i		/ Record identification
define	ID_NA		 1 # i		/ Object ID
define	ID_NB		 2 # i		/ Object ID
define	ID_CLUSTER	 3 # i		/ Assigned cluster identification
define	ID_NCLUSTER	 4 # i		/ Number of records in cluster
define	ID_M1		 5 # r		/ Filter field 1 (e.g. magnitude)
define	ID_C1		 6 # r		/ Clustering field (2D)
define	ID_C2		 7 # r		/ Cond clustering field (2D)
define	ID_C3		 8 # r		/ Clustering field (1D)
define	ID_C4		 9 # r		/ Clustering field (1D)
define	ID_C5		10 # r		/ Clustering field (1D)
define	ID_F1		11 # r		/ Non-clustering field
define	ID_F2		12 # r		/ Non-clustering field
define	ID_F3		13 # r		/ Non-clustering field
define	ID_AVC1		14 # r		/ Averge of clustering field
define	ID_AVC2		15 # r		/ Averge of clustering field
define	ID_AVC3		16 # r		/ Averge of clustering field
define	ID_AVC4		17 # r		/ Averge of clustering field
define	ID_AVC5		18 # r		/ Averge of clustering field
define	ID_AVF1		19 # r		/ Average of non-clustering field
define	ID_AVF2		20 # r		/ Average of non-clustering field
define	ID_AVF3		21 # r		/ Average of non-clustering field

define	CL_NUM		RECI($1,ID_NUM)
define	CL_NA		RECI($1,ID_NA)
define	CL_NB		RECI($1,ID_NB)
define	CL_CL		RECI($1,ID_CLUSTER)
define	CL_NCL		RECI($1,ID_NCLUSTER)
define	CL_M1		RECR($1,ID_M1)
define	CL_C1		RECR($1,ID_C1)
define	CL_C2		RECR($1,ID_C2)
define	CL_C3		RECR($1,ID_C3)
define	CL_C4		RECR($1,ID_C4)
define	CL_C5		RECR($1,ID_C5)
define	CL_F1		RECR($1,ID_F1)
define	CL_F2		RECR($1,ID_F2)
define	CL_F3		RECR($1,ID_F3)
define	CL_AVC1		RECR($1,ID_AVC1)
define	CL_AVC2		RECR($1,ID_AVC2)
define	CL_AVC3		RECR($1,ID_AVC3)
define	CL_AVC4		RECR($1,ID_AVC4)
define	CL_AVC5		RECR($1,ID_AVC5)
define	CL_AVF1		RECR($1,ID_AVF1)
define	CL_AVF2		RECR($1,ID_AVF2)
define	CL_AVF3		RECR($1,ID_AVF3)

define	CL_NC		5	# Number of clustering fields
define	CL_NF		3	# Number of non-clustering fields
