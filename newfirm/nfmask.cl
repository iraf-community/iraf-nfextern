# NFMASK -- Make masks.

procedure nfmask (input)

file	input			{prompt="List of input NEWFIRM files"}
file	output = "+_msk"	{prompt="List of output mask files"}
string	maskkey = "MASK"	{prompt="Keyword to record mask in input (optional)\n"}

int	bpmvalue = 1		{prompt="Mask value for BPM"}
int	obmvalue = 2		{prompt="Mask value for OBM"}
int	satvalue = 3		{prompt="Mask value for saturation"}
int	pervalue = 4		{prompt="Mask value for persistence\n"}

string	lcoeffs = "parameter"	{prompt="Lin coeffs (parameter|exprdb|keyword|image)",
				    enum="parameter|exprdb|keyword|image"}
real	lin1 = -6.123E-6	{prompt="Linearity coefficient for im1"}
real	lin2 = -7.037E-6	{prompt="Linearity coefficient for im2"}
real	lin3 = -5.404E-6	{prompt="Linearity coefficient for im3"}
real	lin4 = -5.952E-6	{prompt="Linearity coefficient for im4"}
string	linimage = "nfdat$nflincoeffs"		{prompt="List of linearity coefficient images\n"}

string	scoeffs = "parameter"	{prompt="Sat coeffs (parameter|exprdb|keyword|image)",
				    enum="parameter|exprdb|keyword|image"}
real	sat1 = 10000		{prompt="Saturation threshold for im1"}
real	sat2 = 10000		{prompt="Saturation threshold for im2"}
real	sat3 = 10000		{prompt="Saturation threshold for im3"}
real	sat4 = 10000		{prompt="Saturation threshold for im4"}
string	satimage = ""		{prompt="List of saturation images\n"}

real	perwindow = 5		{prompt="Persistence window"}
real	perthresh = 0.8		{prompt="Persistence threshold as fraction of saturation"}
string	bpm = "nfdat$nfbpm"	{prompt="List of masks or expression"}
string	obm = "(objmask)"	{prompt="List of object masks or expression"}
file	exprdb = "nfdat$exprdb.dat" {prompt="Expression database"}
bool	list = no		{prompt="List only and show full expressions?"}
string	logfiles = "STDOUT,logfile"	{prompt="Log files"}

begin
	bool	satflag, perflag
	string	linval, satval, outtype
	struct	satexpr, perexpr

	# Make sure one mask value will be used.
	if (satvalue==0 && pervalue==0)
	    error (1, "Both saturation and persistence mask values are zero")

	# Set parameters.
	if (lcoeffs == "parameter") {
	    linval = "nfmask.lin\I"
	} else if (lcoeffs == "exprdb") {
	    if (exprdb == "")
	        error (2, "Must specify expression database")
	    linval = "L\I"
	} else if (lcoeffs == "keyword") {
	    linval = "lincoeff"
	} else if (lcoeffs == "image") {
	    if (linimage == "")
	        error (2, "Must specify linearity coefficient image")
	    linval = "$L"
	} else
	    error (1, "Unknown linearity coefficient type")

	# Set parameters.
	if (scoeffs == "parameter") {
	    satval = "nfmask.sat\I"
	} else if (scoeffs == "exprdb") {
	    if (exprdb == "")
	        error (2, "Must specify expression database")
	    satval = "S\I"
	} else if (scoeffs == "keyword") {
	    satval = "saturate"
	} else if (scoeffs == "image") {
	    if (satimage == "")
	        error (2, "Must specify saturation threshold image")
	    satval = "$Z"
	} else
	    error (1, "Unknown coefficient type")

	# Set expressions.
	satflag = yes; perflag = no; satexpr = ""; perexpr = ""
	if (bpmvalue == 0 && obmvalue == 0) {
	    if (pervalue == 0) {
		if (exprdb == "")
		    printf ("($I<%s?0: %d)\n",
			satval, satvalue) | scan (satexpr)
		else
		    printf ("%%(sat(%s,%s,%d))\n",
			linval, satval, satvalue) | scan (satexpr)
	    } else if (satvalue == 0) {
		satflag = no; perflag = yes
		if (exprdb == "")
		    printf ("($P<%g*%s?0: %d)\n",
			perthresh, satval, pervalue) | scan (perexpr)
		else
		    printf ("%%(per(%s,%s,%g,%d))\n",
			linval, satval, perthresh, pervalue) | scan (perexpr)
	    } else {
		if (exprdb == "")
		    printf ("($I<%s?($P<%g*%s?0: %d): %d)\n",
			satval, perthresh, satval, pervalue, satvalue) |
			    scan (satexpr)
		else
		    printf ("%%(satper(%s,%s,%g,%d,%d))\n",
			linval, satval, perthresh, satvalue, pervalue) |
			    scan (satexpr)
	    }
	} else {
	    if (obmvalue == 0) {
		if (pervalue == 0) {
		    if (exprdb == "")
			printf ("($M==0?($I<%s?0: %d): %d)\n",
			    satval, satvalue, bpmvalue) |
			    scan (satexpr)
		    else
			printf ("%%(bsmask(%s,%s,%d,%d))\n",
			    linval, satval, bpmvalue, satvalue) |
			    scan (satexpr)
		} else if (satvalue == 0) {
		    if (exprdb == "")
			printf ("($M==0?($P<%g*%s?0: %d): %d)\n",
			    perthresh, satval, pervalue, bpmvalue) |
			    scan (satexpr)
		    else
			printf ("%%(bpmask(%s,%s,%g,%d,%d))\n",
			    linval, satval, perthresh, bpmvalue, pervalue) |
			    scan (satexpr)
		} else {
		    if (exprdb == "")
			printf ("($M==0?($I<%s?($P<%g*%s?0: %d): %d): %d)\n",
			    satval, perthresh, satval,
			    pervalue, satvalue, bpmvalue) | scan (satexpr)
		    else
			printf ("%%(bspmask(%s,%s,%g,%d,%d,%d))\n",
			    linval, satval, perthresh,
			    bpmvalue, satvalue, pervalue) | scan (satexpr)
		}
	    } else if (bpmvalue == 0) {
		if (pervalue == 0) {
		    if (exprdb == "")
			printf ("($O==0?($I<%s?0: %d): %d)\n",
			    satval, satvalue, obmvalue) |
			    scan (satexpr)
		    else
			printf ("%%(osmask(%s,%s,%d,%d))\n",
			    linval, satval, obmvalue, satvalue) |
			    scan (satexpr)
		} else if (satvalue == 0) {
		    if (exprdb == "")
			printf ("($O==0?($P<%g*%s?0: %d): %d)\n",
			    perthresh, satval, pervalue, obmvalue) |
			    scan (satexpr)
		    else
			printf ("%%(opmask(%s,%s,%g,%d,%d))\n",
			    linval, satval, perthresh, obmvalue, pervalue) |
			    scan (satexpr)
		} else {
		    if (exprdb == "")
			printf ("($O==0?($I<%s?($P<%g*%s?0: %d): %d): %d)\n",
			    satval, perthresh, satval,
			    pervalue, satvalue, obmvalue) | scan (satexpr)
		    else
			printf ("%%(ospmask(%s,%s,%g,%d,%d,%d))\n",
			    linval, satval, perthresh,
			    obmvalue, satvalue, pervalue) | scan (satexpr)
		}
	    } else {
		if (exprdb == "")
		    printf ("($M==0?($O==0?($I<%s?($P<%g*%s?0: %d): %d): %d): %d)\n",
			satval, perthresh, satval,
			pervalue, satvalue, obmvalue, bpmvalue) | scan (satexpr)
		else
		    printf ("%%(allmask(%s,%s,%g,%d,%d,%d,%d))\n",
			linval, satval, perthresh,
			bpmvalue, obmvalue, satvalue, pervalue) | scan (satexpr)
	    }
	}

	# Set output type.
	if (list)
	    outtype = "vlist"
	else
	    outtype = "mask " // maskkey
	
	# Compute mask or list the expressions.
	_nfproc (input, output, outtype=outtype, logfiles=logfiles,
	    permask=perflag, saturation=satflag, bpm=bpm, obm=obm,
	    persist=perexpr, perwindow=perwindow, satexpr=satexpr,
	    satimage=satimage, exprdb=exprdb, taskname="nfmask")

end
